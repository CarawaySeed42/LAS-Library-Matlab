function test_ReadWriteLAS(test_cloud_point_count)
%test_ReadWriteLAS Tests general read and write functionality of LAS Library
%   function test_ReadWriteLAS(test_cloud_point_count)
%
%   Creates random point clouds of all record formats with specified point count. 
%   The function writes them to subfolder unit_test_files and reads them again. 
%   The results of what has been written, what has been read and what
%   should have been read are then compared. 
%   Which tests succeeded and which failed is printed to console
%
%   Arguments:
%       test_cloud_point_count [numeric] : Number of random points
%                                          Default: 100
%
%   Example:
%       test_ReadWriteLAS(100);
%
%   Uses and thereby (partially) tests the following functions and classes:
%   \lib\addLASLibPaths.m             
%   \lib\classes\PCloudFun.m       
%   \lib\mex\readLASfile_cpp.mex(platform)
%   \lib\mex\writeLASfile_cpp.mex(platform)
%   \lib\readLASfile.m              
%   \lib\writeLASfile.m        
fprintf('\nRunning: test_ReadWriteLAS.m\n\n');

%% Test parameter
if nargin < 1
    test_cloud_point_count = 100; % How many points to write in test LAS
end

%% Add and get required paths
if ~isdeployed  
    mpath = mfilename('fullpath');
    [root_path,~,~] = fileparts(fileparts(mpath));
    addpath(fullfile(root_path, 'lib'));
    addLASLibPaths()
    
    out_dir = fullfile(root_path, 'examples', 'unit_test_files');
else
    out_dir = fullfile(pwd, 'unit_test_files');
end

if ~isdir(out_dir) %#ok
   [status, msg, msgID]  = mkdir(out_dir); 
   if ~status
       error('Could not create unit test dir:\n%s: %s', msgID, msg);
   end
end

%% Write all point data record formats
error_count = 0;
test_formats = PCloudFun.supported_record_formats;
for i = 1:numel(test_formats)
    
    %% Reset warnings
    lastwarn('','');
    
    %% Current record format and version minor that are tested
    record_format = test_formats(i);
    version_minor = (record_format <= 5) * 3 + (record_format >= 6) * 4;
    fprintf('--- Start Test Record Format %d ---\n', record_format);
    
    %% Allocate random point cloud
    try
        fprintf('   Allocate Cloud...\n');
        las = PCloudFun.Allocate(test_cloud_point_count, version_minor, record_format);
        las.x = round(rand(test_cloud_point_count, 1)/las.header.scale_factor_x)*las.header.scale_factor_x;
        las.y = round(rand(test_cloud_point_count, 1)/las.header.scale_factor_y)*las.header.scale_factor_y;
        las.z = round(rand(test_cloud_point_count, 1)/las.header.scale_factor_z)*las.header.scale_factor_z;
        las.intensity = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');
        las.bits = cast(rand(test_cloud_point_count, 1)*255, 'uint8');
        las.classification = cast(rand(test_cloud_point_count, 1)*255, 'uint8');
        las.user_data = cast(rand(test_cloud_point_count, 1)*255, 'uint8');
        las.scan_angle = cast((rand(test_cloud_point_count, 1)*255)-128, 'int8');
        las.point_source_id = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');

        % Add random data to record format specific fields
        recordFormatInfo = PCloudFun.RecordFormatInfo(record_format);

        if recordFormatInfo.has16bitAngle
            las.scan_angle  = cast((rand(test_cloud_point_count, 1)*20000)-10000, 'int16');
        else
            las.scan_angle  = cast((rand(test_cloud_point_count, 1)*255)-128, 'int8');
        end
        if recordFormatInfo.hasBit2Field
            las.bits2       = cast(rand(test_cloud_point_count, 1)*255, 'uint8');
        end
        if recordFormatInfo.hasTime
            las.gps_time    = (1:test_cloud_point_count)'*1e-6;
        end
        if recordFormatInfo.hasColor
            las.red      = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');
            las.green    = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');
            las.blue     = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');
        end
        if recordFormatInfo.hasNIR
            las.nir = cast(rand(test_cloud_point_count, 1)*65535, 'uint16');
        end

        if recordFormatInfo.hasWavepackets
            las.wave_packet_descriptor = cast(rand(test_cloud_point_count, 1)*255, 'uint8');
            las.wave_byte_offset  = cast(rand(test_cloud_point_count, 1)*2^31, 'uint64');
            las.wave_packet_size  = cast(rand(test_cloud_point_count, 1)*(2^32-1), 'uint32');
            las.wave_return_point = cast(rand(test_cloud_point_count, 1)*4000, 'single');
            las.Xt = cast(rand(test_cloud_point_count, 1)*4000, 'single');
            las.Yt = cast(rand(test_cloud_point_count, 1)*4000, 'single');
            las.Zt = cast(rand(test_cloud_point_count, 1)*4000, 'single');
        end
    catch ME
        fprintf('   Failure Record Format %d: Could not allocate random cloud\n', record_format);
        fprintf('                             ErrorID: %s | ErrorMSg: %s\n', ME.identifier, ME.message);
        error_count = error_count + 1;
        continue;
    end
    
    %% Test some PCloud functions
    optimal_format = PCloudFun.GetOptimalRecordFormat(las);
    if (optimal_format ~= record_format)
        fprintf('   GetOptimalRecordFormat returns %d instead of the targeted format %d...\n', optimal_format, record_format);
    end
    
    %% Write file and read it again, then compare results
    fprintf('   Test writing and reading...\n');
    testfile_name = fullfile(out_dir, strcat('unit_test_format_', num2str(record_format), '.las'));
    
    % Write LAS
    try
        lasOut        = writeLASfile(las, testfile_name, 1, version_minor, record_format);
    catch ME
        fprintf('   Failure Record Format %d: Could not write random cloud\n', record_format);
        fprintf('                             ErrorID: %s | ErrorMSg: %s\n', ME.identifier, ME.message);
        error_count = error_count + 1; 
        continue;
    end
    
    % Read LAS
    try
        lasIn         = readLASfile(testfile_name);
    catch ME
        fprintf('   Failure Record Format %d: Could not read random cloud after write\n', record_format);
        fprintf('                             ErrorID: %s | ErrorMSg: %s\n', ME.identifier, ME.message);
        error_count = error_count + 1;
        continue;
    end
    
    % Check if warnings occured
    [msg,~] = lastwarn;
    if ~isempty(msg)
        fprintf('   Failure Record Format %d: Warning occured, see warning message in console!\n', record_format);
        error_count = error_count + 1; 
        continue;
    end
    
    % Make system id and gen software the same length for comparison
    lasOut.header.system_identifier   = lasOut.header.system_identifier(1:32);
    lasOut.header.generating_software = lasOut.header.generating_software(1:32);
    
    % Ignore read only legacy number of point records
    if isfield(lasIn.header, 'legacy_number_of_point_records_READ_ONLY')
        lasIn.header = rmfield(lasIn.header, 'legacy_number_of_point_records_READ_ONLY');
    end
    if isfield(lasIn.header, 'legacy_number_of_points_by_return_READ_ONLY')
        lasIn.header = rmfield(lasIn.header, 'legacy_number_of_points_by_return_READ_ONLY');
    end
    
    %% Use isequal to check if structs have exactly the same contents
    if isequal(lasIn, lasOut)
        fprintf('   Success Record Format %d: Read and Write LAS return identical data\n', record_format);
    else
        fprintf('   Failure Record Format %d: Read and Write LAS do NOT return identical data\n', record_format);
        error_count = error_count + 1;
        
        % If not equal then print the fields that show differences
        fields = fieldnames(lasIn);
        for j = 1:length(fields)
            field = fields{j};
            if isequal(lasIn.(field), lasOut.(field))
                fprintf('      Field %s shows differences!\n', field);
            end
        end
    end
end

fprintf('--- Results ---\n');
if error_count > 1
    fprintf('!!! Failure: Encountered %d errors and warnings !!!!\n', error_count);
else
    fprintf('Success: No errors or warnings encountered\n');
end
fprintf('\nFinished: test_ReadWriteLAS.m\n');
