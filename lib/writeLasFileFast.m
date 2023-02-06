function las = writeLasFileFast(las, filename, majorversion, minorversion, pointformat, optional)
% las = writeLasFileFast(las, filename, majorversion, minorversion, pointformat)
%
%   Writes lasdata style struct to a Las-File. This function tries to
%   compensate for errors in the header and data. Point Count is determined
%   by the number of elements in field las.x. If a data field is bigger
%   than point count, an exception will be thrown. If field has less
%   elements then the array will be padded with zeros.
%   But e.g. the header coordinate offsets have to be provided by the user.
%   compatibility with lasdata matlab class by Teemu Kumpum�ki (2016)
%
%   Input:
%       las [struct]        : Struct containing point cloud data
%       filename [string]   : Full Path to output file
%       majorversion [uint] : Major Version of LAS File
%       minorversion [uint] : Minor Verison of LAS File
%       pointformat [uint]  : Point Data Format of LAS File
%       optional [struct]   : Optional input arguments
%
%       optional options:
%           keepCreationDate : If true then the file creation info from
%                              header is kept, if False then current date
%                              is used
%
%   Returns:
%       las [struct]        : Struct containing the written cloud data
%

MException = []; % Empty Matlab Exception
record_lengths       = [20, 28, 26, 34, 57, 63, 30, 36, 38, 59, 67];
LASContainsColor     = [2,3,5,7,8,9,10];
LASContainsTime      = [0,1,3:10];
LASContainsNIR       = [8,10];
LASContainsWavePackets = [4, 5, 9, 10];
inputIsLegacyLasdata = 0;

keepCreationDate = 0;

try
%% Input and header checks
    % Check LAS header for consistency and modify to fit point data
    lasHeader = las.header;
    
    % Safe source PDRF for the transformation of bit fields later
    sourcePDRF = lasHeader.point_data_format;
    
    if nargin > 4
        lasHeader.point_data_format = pointformat;
    end
    if nargin > 3
        lasHeader.version_minor = minorversion;
    end
    if nargin > 2
        lasHeader.version_major = majorversion;
    end
    if nargin == 6
        if isfield(optional, 'keepCreationDate')
            keepCreationDate = optional.keepCreationDate;
        end
    end
    if nargin < 2
        error('Not enough input arguments! Needs at least las and filename')
    end
    
    % Create output directory if doesn't exist (isdir for backwards comp)
    [pathtmp,~,ext]=fileparts(filename);
    if ~isdir(pathtmp) 
        mkdir(pathtmp);
    end 
    if ~strcmp(ext,'.las')
       error('writeStruct2las: Output File does not have extension .las !');
    end
    
    % Provide backwards compatibility to writeLas from lasdata
    if (isfield(las.header, 'file_creation_daobj'))
        if (isfield(las.header.file_creation_daobj, 'y') && ~isfield(las.header, 'file_creation_day_of_year'))
            % Copy day of year from lasdata to new struct layout
            las.header.file_creation_day_of_year = las.header.file_creation_dalas.y;
            inputIsLegacyLasdata = 1;
        end
    end
    
    % Check header consitency and format accordingly
    lasHeader = CheckHeader(las, keepCreationDate);
   
%% Check if data is compatible with chosen point data record format
    % No function for this task to make sure matlab doesn't copy the whole
    % structure if changes to it are made
    pointCount = lasHeader.number_of_point_records;
    
    % Check if X, Y, Z have pointCount points
    if length(las.x) ~= pointCount || length(las.y) ~= pointCount || length(las.z) ~= pointCount
        error('X,Y,Z do not all have a length of point count %d', pointCount)
    end
    
    % Zero Padding of necessary fields if their count does not match the
    % point count
    % Intensity
    if length(las.intensity) ~= pointCount
        warning('Zero padding of intensity necessary')
        las.intensity = ZeroPaddingOfField(las, pointCount, 'intensity', 'uint16');
    end
    
    % Bitfields
    if length(las.bits) ~= pointCount
        warning('Zero padding of bit values necessary (return nr, scan dir. flag, edge of flight line)')
        las.bits = ZeroPaddingOfField(las, pointCount, 'bits', 'uint8');
    end
    
    if lasHeader.point_data_format > 5 && isempty(las.bits2)
        warning('Zero padding of bit values necessary')
        las.bits2 = ZeroPaddingOfField(las, pointCount, 'bits2', 'uint8');
    end
    
    if (sourcePDRF < 6 && lasHeader.point_data_format > 5) || ...
       (sourcePDRF > 5 && lasHeader.point_data_format < 6)
   
        % Decode and encode bitfields for specified data format
        bitfields = decode_bit_fields(lasStruct, optsReturnType);
        las = encode_bit_fields(las, bitfields);
    end

    % Classification
    if length(las.classification) ~= pointCount
        warning('Zero padding of classification necessary')
        las.classification = ZeroPaddingOfField(las, pointCount, 'classification', 'uint8');
    end
    
    % Scan Angle depending on PDRF
    if length(las.scan_angle) ~= pointCount
        warning('Zero padding of scan angle necessary')
        if lasHeader.point_data_format > 5
            las.scan_angle = ZeroPaddingOfField(las, pointCount, 'scan_angle', 'uint16');
        else
            las.scan_angle = ZeroPaddingOfField(las, pointCount, 'scan_angle', 'uint8');
        end
    end
    
    % User Data
    if length(las.user_data) ~= pointCount
        warning('Zero padding of user data necessary')
        las.user_data = ZeroPaddingOfField(las, pointCount, 'user_data', 'uint8');
    end
    
    % Point Source ID
    if length(las.point_source_id) ~= pointCount
        warning('Zero padding of point source id necessary')
        las.point_source_id = ZeroPaddingOfField(las, pointCount, 'point_source_id', 'uint16');
    end
    
    % GPS Time
    if any(lasHeader.point_data_format == LASContainsTime)
        if length(las.gps_time) ~= pointCount
            warning('Zero padding of gps time necessary')
            las.gps_time = ZeroPaddingOfField(las, pointCount, 'gps_time', 'double');
        end
    end
    
    % Color
    if any(lasHeader.point_data_format == LASContainsColor)
        if length(las.red) ~= pointCount
            warning('Zero padding of gps time necessary')
            las.red = ZeroPaddingOfField(las, pointCount, 'red', 'uint16');
        end
        if length(las.green) ~= pointCount
            warning('Zero padding of gps time necessary')
            las.green = ZeroPaddingOfField(las, pointCount, 'green', 'uint16');
        end
        if length(las.blue) ~= pointCount
            warning('Zero padding of gps time necessary')
            las.blue = ZeroPaddingOfField(las, pointCount, 'blue', 'uint16');
        end
    end
    
    % Near Infrared
    if any(lasHeader.point_data_format == LASContainsNIR)
        if length(las.nir) ~= pointCount
            warning('Zero padding of Near Infrared Channel necessary')
            las.nir = ZeroPaddingOfField(las, pointCount, 'nir', 'uint16');
        end
    end
    
    % Wave Packets
    if any(lasHeader.point_data_format == LASContainsWavePackets)
        if length(las.wave_packet_descriptor) ~= pointCount
            warning('Zero padding of wave packet descriptor necessary')
            las.wave_packet_descriptor = ZeroPaddingOfField(las, pointCount, 'wave_packet_descriptor', 'uint8');
        end
        if length(las.wave_byte_offset) ~= pointCount
            warning('Zero padding of wave byte offset necessary')
            las.wave_byte_offset = ZeroPaddingOfField(las, pointCount, 'wave_byte_offset', 'uint64');
        end
        if length(las.wave_packet_size) ~= pointCount
            warning('Zero padding of wave packet size necessary')
            las.wave_packet_size = ZeroPaddingOfField(las, pointCount, 'wave_packet_size', 'uint32');
        end
        if length(las.wave_return_point) ~= pointCount
            warning('Zero padding of wave return point necessary')
            las.wave_return_point = ZeroPaddingOfField(las, pointCount, 'wave_return_point', 'single');
        end
        if length(las.Xt) ~= pointCount
            warning('Zero padding of Parametric dX necessary')
            las.Xt = ZeroPaddingOfField(las, pointCount, 'Xt', 'single');
        end
        if length(las.Yt) ~= pointCount
            warning('Zero padding of Parametric dY necessary')
            las.Yt = ZeroPaddingOfField(las, pointCount, 'Yt', 'single');
        end
        if length(las.Zt) ~= pointCount
            warning('Zero padding of Parametric dZ necessary')
            las.Zt = ZeroPaddingOfField(las, pointCount, 'Zt', 'single');
        end 
    end
    
    % Transpose Extra Bytes if input was legacy lasdata class
    if inputIsLegacyLasdata
        las.extradata = las.extradata';
    end
    
%% Now finally write the data to drive
    las = writeLASFile_mex(las, filename);
    
catch MException
end

% % Close all opened file IDs because at least one is never closed
% h_las=fopen('all');
% for h=1:length(h_las)
%     if strcmp(fopen(h_las(h)),filename)
%         fclose(h_las(h));
%     end
% end

% If Exception was thrown then throw it again after all files are closed
if ~isempty(MException)
   rethrow(MException);
end

end
    
function dateStruct = GetCreationDate()
% dateStruct = GetCreationDate()
%   Returns day of year and the year itself
%   Returns:
%       date [struct]:
%           day_of_year : Current day of year
%           year        : Current year
date_now=datestr(now,26);
dateStruct.day_of_year     =  day(datetime(now,'ConvertFrom','datenum'),'dayofyear');        
dateStruct.year   =  str2double(date_now(1:4));
end

function lasHeader = CheckHeader(las, keepCreationDate)
% lasHeader = CheckHeader(las, keepCreationDate)
%
%   Checks LAS header for consitency issues and resolves them. If a fields
%   has wrong length, then it will be set to zero or an exception will be
%   thrown
%
%   Arguments:
%       las [struct]            : las struct
%       keepCreationDate [bool] : Keep creation date from header or use
%                                 current date
%
%   Returns:
%       lasHeader [struct]      : A consistent LAS Header

record_lengths  = [20, 28, 26, 34, 57, 63, 30, 36, 38, 59, 67];
supportedPDRF        = 0:10;
supportedVerMinor    = [1, 2, 3, 4];
supportedVerMajor    = 1;

lasHeader       = las.header;

if length(lasHeader.source_id) ~= 1
    lasHeader.source_id = 0;
end

if length(lasHeader.global_encoding) ~= 1
    lasHeader.global_encoding = 0;
end

if length(lasHeader.project_id_guid1) ~= 1
    lasHeader.project_id_guid1 = 0;
end

if length(lasHeader.project_id_guid2) ~= 1
    lasHeader.project_id_guid2 = 0;
end

if length(lasHeader.project_id_guid3) ~= 1
    lasHeader.project_id_guid3 = 0;
end

if length(lasHeader.project_id_guid4) ~= 8
    lasHeader.project_id_guid4 = zeros(1,8);
end

% Version and PDRF
if ~any(lasHeader.version_major == supportedVerMajor)
    error('Version Major is not supported!')
end
if ~any(lasHeader.version_minor == supportedVerMinor)
    error('Version Minor is not supported!')
end
if ~any(lasHeader.point_data_format == supportedPDRF)
    error('Point Data Record Format must be a value between 0 and 10')
end

% Get date if argument set or fields are missing in the first place
if ~keepCreationDate || ~isfield(lasHeader, 'file_creation_day_of_year') || ~isfield(lasHeader, 'file_creation_year')
    dateStruct = GetCreationDate();
    lasHeader.file_creation_day_of_year = dateStruct.day_of_year;
    lasHeader.file_creation_year        = dateStruct.year;
end

% Set header size
if lasHeader.version_minor < 6
    lasHeader.header_size = 235;
else
    lasHeader.header_size = 375;
end

% Number of variable length records, point data record length and count
lasHeader.number_of_variable_records = length(las.variablerecords);
lasHeader.point_data_record_length = record_lengths(lasHeader.point_data_format);
lasHeader.number_of_point_records = length(las.x);

% Number of points by return change according to version major
pointsByReturnCount = length(lasHeader.number_of_points_by_return);
if lasHeader.version_minor > 3
    if pointsByReturnCount  ~= 15
        pointsByReturn = zeros(15,1);
        pointsByReturn(1:pointsByReturnCount) = lasHeader.number_of_points_by_return;
        lasHeader.number_of_points_by_return = pointsByReturn;
    end
else
    lasHeader.number_of_points_by_return = lasHeader.number_of_points_by_return(1:8);
end
    
% Scale Factors (Default is 1e-4)
if ~length(lasHeader.scale_factor_x) == 1 || isnan(lasHeader.scale_factor_x)
    lasHeader.scale_factor_x = 0.0001;
else
    lasHeader.scale_factor_x = lasHeader.scale_factor_x(1);
end
if ~length(lasHeader.scale_factor_y) == 1 || isnan(lasHeader.scale_factor_y)
    lasHeader.scale_factor_y = 0.0001;
else
    lasHeader.scale_factor_y = lasHeader.scale_factor_y(1);
end
if ~length(lasHeader.scale_factor_z) == 1 || isnan(lasHeader.scale_factor_z)
    lasHeader.scale_factor_z = 0.0001;
else
    lasHeader.scale_factor_z = lasHeader.scale_factor_z(1);
end

if ~any([lasHeader.scale_factor_x, lasHeader.scale_factor_y, lasHeader.scale_factor_z] == 0)
    error('Scale Factor can not be zero');
end

% Offsets
% Should be provided by the user. For different Scenarios, different
% offsets make sense. So there will be no guesses here, just check if the
% offsets are there
if ~isfield(lasHeader,'x_offset') || ~isfield(lasHeader,'y_offset') || ~isfield(lasHeader,'z_offset')
    error('Coordinate Offsets are incomplete!');
end

if length(lasHeader.x_offset) ~= 1
    lasHeader.x_offset = lasHeader.x_offset(1);
end
if length(lasHeader.y_offset) ~= 1
    lasHeader.y_offset = lasHeader.y_offset(1);
end
if length(lasHeader.z_offset) ~= 1
    lasHeader.z_offset = lasHeader.z_offset(1);
end

% Recalculate point count, min, max and VLR count
lasHeader.max_x = max(las.x);
lasHeader.min_x = min(las.x);
lasHeader.max_y = max(las.y);
lasHeader.min_y = min(las.y);
lasHeader.max_z = max(las.z);
lasHeader.min_z = min(las.z);

if lasHeader.version_minor > 2
    if length(lasHeader.start_of_waveform_data) ~= 1
        lasHeader.start_of_waveform_data = 0;
    end
end

if lasHeader.version_minor > 3
    if ~isfield(lasHeader,'number_of_extended_variable_length_record')
        lasHeader.number_of_variable_records = length(las.extendedvariables);
    end
end

end

function zeroPaddedField = ZeroPaddingOfField(structure, count, fieldname, datatype)
paddingArray = zeros(count,1,datatype);
paddingArray(1:length(structure.(fieldname))) = structure.(fieldname);
zeroPaddedField = paddingArray;
end