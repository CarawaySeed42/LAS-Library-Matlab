% sample_WritePointNormals
% The LAS Specification as of now (2022) does not have a field to store
% point cloud normals in. But we can store inside the extrabyte payload.
% This sample will give you an example how to do that.
%
% The normals are present as double value and stored as 3 * 4 byte
% single precision values. This leads to a compression by factor 2. 
% The reduced precision could lead to accuracy loss, but for normals that
% should not be a problem if they are normalized.
%
% The normals could also be written as 3*2 byte uint16 values and are 
% stretched into that range using the scale field. 
% This leads to a bigger compression but also accuracy loss. 
% Note: This is potentially out of spec and might only work with this library.
% The reason is, that this library assumes that the stored values are
% floating point values, if a scale factor is involved. But I have not
% found confirmation in the specification.
% This option can be turned on by setting "write_as_uint16" to true
%
% For simplicity: Normals have already been calculated and are laoded from
% file mat/pcnormals.mat

write_as_uint16 = false;

if verLessThan('matlab', '7.3')
    error('This script will only be run in Matlab 2011b or newer!')
end

fprintf('\nRun: sample_WritePointNormals\n');

%% Add required paths
addpath('../lib')
addLASLibPaths();

%% Read LAS-File
mpath = mfilename('fullpath');
[path,~,~] = fileparts(mpath);
lasFilePath = fullfile(path, 'sample.las');
fprintf('     Reading File: %s\n', lasFilePath);

% Read the sample file
pcloud = readLASfile(lasFilePath);

%% Calculate Point Cloud Normals
fprintf('     Load Normals...\n');
load('mat/pcnormals.mat')

%% Add extrabytes
fprintf('     Creating Extra Bytes...\n');
extraNames = {'vX', 'vY', 'vZ'};
extrabytes = Extrabytes(extraNames);

%% Add Data
extrabytes.SetData(extrabytes.ExtrabyteNames{1}, pcnormals(:,1));
extrabytes.SetData(extrabytes.ExtrabyteNames{2}, pcnormals(:,2));
extrabytes.SetData(extrabytes.ExtrabyteNames{3}, pcnormals(:,3));

%% Set the data type
% We will choose the data type uint16 which takes up 2 byte per
% value. This will lead to lossy compression
if write_as_uint16
    extrabytes.SetDataType(extrabytes.ExtrabyteNames, 'int16');
else
    extrabytes.SetDataType(extrabytes.ExtrabyteNames, 'single');
end

%% Set No Data, Min, Max, Offset and Scale
% For float (single):
% Set Min and Max value. Omit No_Data, Scale and Offset because they are
% unused.
%
% For uint16 compression:
% Min and Max will not be set, because Min and Max are not neccessarily 
% representable in this compressed state.
% They would have to be written in their raw form according to specification
% Problem: We can not express floating point values in this case

for i = 1:length(extrabytes.ExtrabyteNames)
    field_name = extrabytes.ExtrabyteNames{i};
    extrabytes.SetNoData(field_name, 0);
    if ~write_as_uint16
        extrabytes.SetMin(field_name, min(extrabytes.(field_name).decoded_data));
        extrabytes.SetMax(field_name, max(extrabytes.(field_name).decoded_data));
    else
        extrabytes.SetScale(field_name, 1/(2^15-1))
    end
end

% If float set Min and Max bit to true
% If uint16 then only set  Scale bit to true
% Two ways to do this are shown here. Either all are set in one 
% function call or specify each individual option separately
if ~write_as_uint16
    extrabytes.SetOptions(extrabytes.ExtrabyteNames, false, true, true, false, false);
else
    extrabytes.SetScaleBit(extrabytes.ExtrabyteNames, true);
end

% Additionally to the name we can add a little description for our extra
% bytes
extrabytes.SetDescription(extrabytes.ExtrabyteNames{1}, 'X vector component');
extrabytes.SetDescription(extrabytes.ExtrabyteNames{2}, 'Y vector component');
extrabytes.SetDescription(extrabytes.ExtrabyteNames{3}, 'Z vector component');

%% Encode our extra bytes into pcloud structure
fprintf('     Encoding Extra Bytes...\n');
pcloud_modified = encode_extrabytes(pcloud, extrabytes, 'Point Cloud Normals');

%% Add a text area description
textAreaDescription = ['This is a LAS file with normal vectors stored ',...
                       'inside extrabytes'];
pcloud_modified = add_Text_Area_Description(pcloud_modified, textAreaDescription);

%% Write new cloud to modified_samples folder
targetDir = strcat(path, '\', 'modified_samples');
if ~exist(targetDir, 'dir')
    mkdir(targetDir)
end
outPath = fullfile(targetDir, 'sample_pcloud_normals.las');

% Write the new file
fprintf('     Writing File: %s\n', outPath);
writeLASfile(pcloud_modified, outPath, 1, 3, pcloud_modified.header.point_data_format);

% Finished. We added two extra byte values per point of data type single.
% Our Point Data Record Length has grown to 28 bytes per record (20 + 2*4)
fprintf('     Finished Writing!\n');

%% Read written cloud again and decode extra bytes
pcloud_new = readLASfile(outPath);
extrabytes = decode_extrabytes(pcloud_new);

% Output the maximum deviation of calculated normals and compressed normals
devX = abs(double(extrabytes.vX.decoded_data) - pcnormals(:,1));
devY = abs(double(extrabytes.vY.decoded_data) - pcnormals(:,2));
devZ = abs(double(extrabytes.vZ.decoded_data) - pcnormals(:,3));
maxDeviation = max(max([devX, devY, devZ]));

fprintf('\n     Checking results...!\n');
fprintf('     Maximum of accuracy loss due to compression: %f\n', maxDeviation);
fprintf('\n     Finished Script!\n');