function las = writeLASfile(las, filename, majorversion, minorversion, pointformat, optional)
% las = writeLasFile(las, filename, majorversion, minorversion, pointformat)
% las = writeLASfile(las, filename, majorversion, minorversion, pointformat, optional)
%
%   Supports Versions LAS 1.1 - 1.4
%   Supports Point Data Record Format 0 to 10
%
%   Writes lasdata style struct to a Las-File. This function tries to
%   compensate for errors in the header and data. Point Count is determined
%   by the number of elements in field las.x. If a data field is bigger
%   than point count, an exception will be thrown. If field has less
%   elements then the array will be padded with zeros.
%   Header coordinate offsets and scale factor have to be provided 
%   by the user.
%   Retains compatibility with lasdata matlab class by
%   Teemu Kumpumäki (2016)
%
%   Input:
%       las [struct]        : Struct containing point cloud data
%       filename [string]   : Full Path to output file
%       majorversion [uint] : Optional Major Version of output LAS File
%       minorversion [uint] : Optional Minor Verison of output LAS File
%       pointformat [uint]  : Optional Point Data Record Format of output LAS File
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

LASContainsColor       = PCloudFun.LASContainsColor;
LASContainsTime        = PCloudFun.LASContainsTime;
LASContainsNIR         = PCloudFun.LASContainsNIR;
LASContainsWavePackets = PCloudFun.LASContainsWavePackets;
inputIsLegacyLasdata = 0;

keepCreationDate = 0;

%% Input and header checks
% Safe source PDRF for the transformation of bit fields later
sourcePDRF = las.header.point_data_format;

if nargin > 4
    las.header.point_data_format = pointformat;
end
if nargin > 3
    las.header.version_minor = minorversion;
end
if nargin > 2
    las.header.version_major = majorversion;
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
[pathtmp,filenametmp,ext]=fileparts(filename);
if ~isdir(pathtmp) %#ok
    mkdir(pathtmp);
end
if ~strcmp(ext,'.las')
    warning('Extension of file changed to .las');
    filename = fullfile(pathtmp, strcat(filenametmp, '.las'));
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
lasHeader = PrepareHeader(las, keepCreationDate);

%% Check if data is compatible with chosen point data record format
% No function for this task to make sure matlab doesn't copy the whole
% structure if changes to it are made
pointCount = lasHeader.number_of_point_records;

% If point count too big or PDRF 6-10 is used then version minor 4
% is necessary
if pointCount > 2^31-1 || las.header.point_data_format > 5
    las.header.version_minor = 4;
end

% Check if X, Y, Z have pointCount points
if length(las.x) ~= pointCount || length(las.y) ~= pointCount || length(las.z) ~= pointCount
    error('X,Y,Z do not all have a length of point count %d', pointCount)
end

las.x = FixDataType(las.x, 'double');
las.y = FixDataType(las.y, 'double');
las.z = FixDataType(las.z, 'double');

% Zero Padding of necessary fields if their count does not match the
% point count
% Intensity
if length(las.intensity) ~= pointCount
    warning('Zero padding of intensity necessary')
    las.intensity = ZeroPadField(las, pointCount, 'intensity', 'uint16');
end

las.intensity = FixDataType(las.intensity, 'uint16');

% Bitfields
if length(las.bits) ~= pointCount
    warning('Zero padding of bit values necessary')
    las.bits = ZeroPadField(las, pointCount, 'bits', 'uint8');
end

las.bits = FixDataType(las.bits, 'uint8');

if (lasHeader.point_data_format > 5) && (length(las.bits2) ~= pointCount)
    warning('Zero padding of bit2 values necessary')
    las.bits2 = ZeroPadField(las, pointCount, 'bits2', 'uint8');
end

las.bits2 = FixDataType(las.bits2, 'uint8');

if (sourcePDRF < 6 && lasHeader.point_data_format > 5)
    % Decode and encode bitfields for specified data format
    bitfields = decode_bit_fields(las, 'class');
    bitfields.Extend();
    bitfields.classification_flags = zeros(pointCount, 1, 'uint8');
    bitfields.scanner_channel = zeros(pointCount, 1, 'uint8');
    las = encode_bit_fields(las, bitfields);
    
elseif (sourcePDRF > 5 && lasHeader.point_data_format < 6)
    % Decode and encode bitfields for specified data format
    bitfields = decode_bit_fields(las, 'class');
    bitfields.Shorten();
    las = encode_bit_fields(las, bitfields);
end

% Classification
if length(las.classification) ~= pointCount
    warning('Zero padding of classification necessary')
    las.classification = ZeroPadField(las, pointCount, 'classification', 'uint8');
end

las.classification = FixDataType(las.classification, 'uint8');

% Scan Angle depending on PDRF (can have different data types)
if length(las.scan_angle) ~= pointCount
    warning('Zero padding of scan angle necessary')
    if lasHeader.point_data_format > 5
        las.scan_angle = ZeroPadField(las, pointCount, 'scan_angle', 'int16');
    else
        las.scan_angle = ZeroPadField(las, pointCount, 'scan_angle', 'int8');
    end
end

if lasHeader.point_data_format > 5
    if isa(las.scan_angle(1), 'int8')
        las.scan_angle = int16(las.scan_angle);
    end
else
    if isa(las.scan_angle(1), 'int16')
        las.scan_angle = int8(las.scan_angle);
    end
end

% User Data
if length(las.user_data) ~= pointCount
    warning('Zero padding of user data necessary')
    las.user_data = ZeroPadField(las, pointCount, 'user_data', 'uint8');
end

las.user_data = FixDataType(las.user_data, 'uint8');

% Point Source ID
if length(las.point_source_id) ~= pointCount
    warning('Zero padding of point source id necessary')
    las.point_source_id = ZeroPadField(las, pointCount, 'point_source_id', 'uint16');
end

las.point_source_id = FixDataType(las.point_source_id, 'uint16');

% GPS Time
if any(lasHeader.point_data_format == LASContainsTime)
    if length(las.gps_time) ~= pointCount
        warning('Zero padding of gps time necessary')
        las.gps_time = ZeroPadField(las, pointCount, 'gps_time', 'double');
    end
end

las.gps_time = FixDataType(las.gps_time, 'double');

% Color
if any(lasHeader.point_data_format == LASContainsColor)
    if length(las.red) ~= pointCount
        warning('Zero padding of Red Channel necessary')
        las.red = ZeroPadField(las, pointCount, 'red', 'uint16');
    end
    las.red = FixDataType(las.red, 'uint16');
    
    if length(las.green) ~= pointCount
        warning('Zero padding of Green Channel necessary')
        las.green = ZeroPadField(las, pointCount, 'green', 'uint16');
    end
    las.green = FixDataType(las.green, 'uint16');
    
    if length(las.blue) ~= pointCount
        warning('Zero padding of Blue Channel necessary')
        las.blue = ZeroPadField(las, pointCount, 'blue', 'uint16');
    end
    las.blue = FixDataType(las.blue, 'uint16');
end

% Near Infrared
if any(lasHeader.point_data_format == LASContainsNIR)
    if length(las.nir) ~= pointCount
        warning('Zero padding of Near Infrared Channel necessary')
        las.nir = ZeroPadField(las, pointCount, 'nir', 'uint16');
    end
end

las.nir = FixDataType(las.nir, 'uint16');

% Wave Packets
if any(lasHeader.point_data_format == LASContainsWavePackets)
    if length(las.wave_packet_descriptor) ~= pointCount
        warning('Zero padding of wave packet descriptor necessary')
        las.wave_packet_descriptor = ZeroPadField(las, pointCount, 'wave_packet_descriptor', 'uint8');
    end
    las.wave_packet_descriptor = FixDataType(las.wave_packet_descriptor, 'uint8');
    if length(las.wave_byte_offset) ~= pointCount
        warning('Zero padding of wave byte offset necessary')
        las.wave_byte_offset = ZeroPadField(las, pointCount, 'wave_byte_offset', 'uint64');
    end
    las.wave_byte_offset = FixDataType(las.wave_byte_offset, 'uint64');
    if length(las.wave_packet_size) ~= pointCount
        warning('Zero padding of wave packet size necessary')
        las.wave_packet_size = ZeroPadField(las, pointCount, 'wave_packet_size', 'uint32');
    end
    las.wave_packet_size = FixDataType(las.wave_packet_size, 'uint32');
    if length(las.wave_return_point) ~= pointCount
        warning('Zero padding of wave return point necessary')
        las.wave_return_point = ZeroPadField(las, pointCount, 'wave_return_point', 'single');
    end
    las.wave_return_point = FixDataType(las.wave_return_point, 'single');
    if length(las.Xt) ~= pointCount
        warning('Zero padding of Parametric dX necessary')
        las.Xt = ZeroPadField(las, pointCount, 'Xt', 'single');
    end
    las.Xt = FixDataType(las.Xt, 'single');
    if length(las.Yt) ~= pointCount
        warning('Zero padding of Parametric dY necessary')
        las.Yt = ZeroPadField(las, pointCount, 'Yt', 'single');
    end
    las.Yt = FixDataType(las.Yt, 'single');
    if length(las.Zt) ~= pointCount
        warning('Zero padding of Parametric dZ necessary')
        las.Zt = ZeroPadField(las, pointCount, 'Zt', 'single');
    end
    las.Zt = FixDataType(las.Zt, 'single');
end

% Transpose Extra Bytes if input was legacy lasdata class
if inputIsLegacyLasdata
    las.extradata = las.extradata';
end

% Update Header
las.header = lasHeader;

% Check types because Interleaved Complex getter return nullptr on
% wrong type
las = checkHeaderFieldTypes(las);

% Check variable records for typing and array lengths
las = checkVariableRecords(las);


%% Now finally write the data to drive
writeLASfile_cpp(las, char(filename));


end
    
function dateStruct = GetCreationDate()
% dateStruct = GetCreationDate()
%   Returns day of year and the year itself
%   Returns:
%       date [struct]:
%           day_of_year : Current day of year
%           year        : Current year
date_now                  = datetime(now,'ConvertFrom','datenum');
dateStruct.day_of_year    =  day(date_now,'dayofyear');
dateStruct.year           =  date_now.Year;
end

function lasHeader = PrepareHeader(las, keepCreationDate)
% lasHeader = PrepareHeader(las, keepCreationDate)
%
%   Checks LAS header for consitency issues and resolves them. 
%   Char array fields will be streched to correct length.
%   Current day and year will be determined, if not declined. If a fields
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

% Turn System identifier and Generating Software to a valid zero terminated
% char array
lasHeader.system_identifier = zeroTerminateString(lasHeader.system_identifier, 32);
lasHeader.generating_software = zeroTerminateString(lasHeader.generating_software, 32);

% Get date if argument set or fields are missing in the first place
if ~keepCreationDate || ~isfield(lasHeader, 'file_creation_day_of_year') || ~isfield(lasHeader, 'file_creation_year')
    dateStruct = GetCreationDate();
    lasHeader.file_creation_day_of_year = dateStruct.day_of_year;
    lasHeader.file_creation_year        = dateStruct.year;
end

% Set header size
if lasHeader.version_minor < 3
	lasHeader.header_size = 227;
elseif lasHeader.version_minor < 4
    lasHeader.header_size = 235;
else
    lasHeader.header_size = 375;
end

% Number of variable length records, point data record length and count
lasHeader.number_of_variable_records = length(las.variablerecords);
lasHeader.point_data_record_length = record_lengths(supportedPDRF == lasHeader.point_data_format);
lasHeader.number_of_point_records = length(las.x);

if ~isempty(las.extradata)
    lasHeader.point_data_record_length = lasHeader.point_data_record_length + size(las.extradata, 1);
end

% Number of points by return change according to version major
pointsByReturnCount = length(lasHeader.number_of_points_by_return);
if lasHeader.version_minor > 3
    if pointsByReturnCount  ~= 15
        pointsByReturn = zeros(15,1);
        pointsByReturn(1:pointsByReturnCount) = lasHeader.number_of_points_by_return;
        lasHeader.number_of_points_by_return = pointsByReturn;
    end
else
    lasHeader.number_of_points_by_return = lasHeader.number_of_points_by_return(1:5);
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

if any([lasHeader.scale_factor_x, lasHeader.scale_factor_y, lasHeader.scale_factor_z] == 0)
    error('Scale Factor can not be zero');
end

% Recalculate point count, min, max and VLR count
lasHeader.max_x = max(las.x);
lasHeader.min_x = min(las.x);
lasHeader.max_y = max(las.y);
lasHeader.min_y = min(las.y);
lasHeader.max_z = max(las.z);
lasHeader.min_z = min(las.z);

% Coordinate Offsets
% Should be provided by the user. Just check if the offsets are there and
% if they are enough to represent the coordinates as int32 in LAS file
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

minimums_int32 = ([lasHeader.min_x, lasHeader.min_y,lasHeader.min_z]-...
    [lasHeader.x_offset, lasHeader.y_offset, lasHeader.z_offset])./...
    [lasHeader.scale_factor_x, lasHeader.scale_factor_y,lasHeader.scale_factor_y];
    
maximums_int32 = ([lasHeader.max_x, lasHeader.max_y,lasHeader.max_z]-...
    [lasHeader.x_offset, lasHeader.y_offset, lasHeader.z_offset])./...
    [lasHeader.scale_factor_x, lasHeader.scale_factor_y,lasHeader.scale_factor_y];

if any(abs(minimums_int32) > 2^31-1) || any(abs(maximums_int32) > 2^31-1)
    warning('Data can not be represented with current offsets! Offsets will be recalculated! Please check results!');
    las = updateOffsets(las);
    lasHeader.x_offset = las.header.x_offset;
    lasHeader.y_offset = las.header.y_offset;
    lasHeader.z_offset = las.header.z_offset;
end
    
% Offset to point data is header size plus Variable Length Records Length
% of 54 bytes plus the VLR itself
variable_record_bytesize = 0;
for i = 1:length(las.variablerecords)
    variable_record_bytesize = variable_record_bytesize + 54 + las.variablerecords(i).record_length;
end

lasHeader.offset_to_point_data = double(lasHeader.header_size) + double(variable_record_bytesize);

% Version exclusive fields
if lasHeader.version_minor > 2
	if ~isfield(lasHeader,'start_of_waveform_data')
		lasHeader.start_of_waveform_data = 0;
	end
    if length(lasHeader.start_of_waveform_data) ~= 1
        lasHeader.start_of_waveform_data = 0;
    end
end

if lasHeader.version_minor > 3
    if ~isfield(lasHeader,'start_of_extended_variable_length_record')
        extendedStart = lasHeader.number_of_point_records *...
            lasHeader.point_data_record_length + lasHeader.offset_to_point_data;
        if ~isempty(las.extendedvariables)
            lasHeader.start_of_extended_variable_length_record = extendedStart;
        else
            lasHeader.start_of_extended_variable_length_record = 0;
        end
    end
    if ~isfield(lasHeader,'number_of_extended_variable_length_record')
        lasHeader.number_of_extended_variable_length_record = length(las.extendedvariables);
    end
end

end

function las = checkHeaderFieldTypes(las)
% las = checkHeaderFieldTypes(las)
%
% Checks if all header fields of las structure is of type double. If not it
% is casted to double. Returns las structure with valid header
%
%   Arguments:
%       las [struct]  : LAS Point Cloud structure
%
%   Returns:
%       las [struct]  : LAS Point Cloud structure
headerFields = fieldnames(las.header);
for k=1:numel(headerFields)
    if( isnumeric(las.header.(headerFields{k})) )
        if ~isa(las.header.(headerFields{k}), 'double')
            las.header.(headerFields{k}) = double(las.header.(headerFields{k}));
        end
    end
end

end

function las = checkVariableRecords(las)
% las = checkVariableRecords(las)
%
% Checks (Extended) Variable Length Records in LAS structure for validity
% and does error correction. Fixes datatypes and record lengths in header 
% regarding VLRs and sets start of waveform data if present
%
%   Arguments:
%       las [struct]  : LAS Point Cloud structure
%
%   Returns:
%       las [struct]  : LAS Point Cloud structure

if ~isempty(las.variablerecords)
    for i = 1:length(las.variablerecords)
        
        % Check Datatypes
        if ~isa(las.variablerecords(i).reserved,'uint16')
            las.variablerecords(i).reserved = uint16(las.variablerecords(i).reserved);
        end
        if ~isa(las.variablerecords(i).record_id,'uint16')
            las.variablerecords(i).record_id = uint16(las.variablerecords(i).record_id);
        end
        if ~isa(las.variablerecords(i).record_length,'uint16')
            las.variablerecords(i).record_length = uint16(las.variablerecords(i).record_length);
        end
        if ~isa(las.variablerecords(i).data,'uint8')
            las.variablerecords(i).data = uint8(las.variablerecords(i).data);
        end
        if ~isa(las.variablerecords(i).user_id,'char')
            las.variablerecords(i).user_id = char(las.variablerecords(i).user_id);
        end
        if ~isa(las.variablerecords(i).description,'char')
            las.variablerecords(i).description = char(las.variablerecords(i).description);
        end
        
        % Properly size char fields
        if length(las.variablerecords(i).user_id) < 16
            las.variablerecords(i).user_id = zeroTerminateString(las.variablerecords(i).user_id, 16);
        end
        if length(las.variablerecords(i).description) < 32
            las.variablerecords(i).description = zeroTerminateString(las.variablerecords(i).description, 32);
        end
        
        % Check data field count and change record_length according to
        % actual data
        if las.variablerecords(i).record_length ~= length(las.variablerecords(i).data)
            las.variablerecords(i).record_length = uint16(length(las.variablerecords(i).data));
        end
    end
end

record_lengths_sum = 0;
waveform_EVLR_found = false;

if ~isempty(las.extendedvariables)
    for i = 1:length(las.extendedvariables)
        % Check Datatypes
        if ~isa(las.extendedvariables(i).reserved,'uint16')
            las.extendedvariables(i).reserved = uint16(las.extendedvariables(i).reserved);
        end
        if ~isa(las.extendedvariables(i).record_id,'uint16')
            las.extendedvariables(i).record_id = uint16(las.extendedvariables(i).record_id);
        end
        if ~isa(las.extendedvariables(i).record_length,'uint64')
            las.extendedvariables(i).record_length = uint64(las.extendedvariables(i).record_length);
        end
        if ~isa(las.extendedvariables(i).data,'uint8')
            las.extendedvariables(i).data = uint8(las.extendedvariables(i).data);
        end
        if ~isa(las.extendedvariables(i).user_id,'char')
            las.extendedvariables(i).user_id = char(las.extendedvariables(i).user_id);
        end
        if ~isa(las.extendedvariables(i).description,'char')
            las.extendedvariables(i).description = char(las.extendedvariables(i).description);
        end
        
        % Properly size char fields
        if length(las.extendedvariables(i).user_id) < 16
            las.extendedvariables(i).user_id = zeroTerminateString(las.extendedvariables(i).user_id, 16);
        end
        if length(las.extendedvariables(i).description) < 32
            las.extendedvariables(i).description = zeroTerminateString(las.extendedvariables(i).description, 32);
        end
        
        % Check data field count and change record_length according to
        % actual data
        if las.extendedvariables(i).record_length ~= length(las.extendedvariables(i).data)
            las.extendedvariables(i).record_length = uint64(length(las.extendedvariables(i).data));
        end
        
        % Check for waveform data and then set start of waveform data if
        % EVLR with Waveform record id is found
        if las.extendedvariables(i).record_id == 65535 && ~waveform_EVLR_found
            las.header.start_of_waveform_data = las.header.start_of_extended_variable_length_record + record_lengths_sum;
            waveform_EVLR_found = true;
        end
        
        record_lengths_sum = record_lengths_sum + las.extendedvariables(i).record_length + 60;
    end
end

end

function stringOutput = zeroTerminateString(stringInput, strlength)
% stringOutput = zeroTerminateString(stringInput, strlength)
% 
% Turns input into a zero terminated char array of a specified length
%
%   Arguments:
%       stringInput [1xn char] : character array to terminate
%       strlength [numeric]    : output array length
%
%   Returns:
%       stringOutput [1xn char]: zero terminated char array of length
%                                strlength
%
terminatedArray = zeros(1,strlength+1, 'uint8');
char_array_length = min([length(stringInput), strlength]);
terminatedArray(1:char_array_length) = uint8(stringInput(1:char_array_length));
stringOutput = char(terminatedArray);
end

function zeroPaddedField = ZeroPadField(structure, count, fieldname, datatype)
% zeroPaddedField = ZeroPadField(structure, count, fieldname, datatype)
% 
% Pads the field of a structure with zeros and returns it as array of size
% count with type datatype. If count is smaller than field size, then the
% field is reduced to size of count
%
%   Arguments:
%       structure [struct]     : input structure
%       count [numeric]        : target size of field
%       fieldname [1xn char]   : name of field to pad in structure
%       datatype [1xn char]    : desired datatype of padded field
%
%   Returns:
%       zeroPaddedField [nx1]  : zero padded field of type datatype
%
paddingArray = zeros(count,1,datatype);
paddingArray(1:length(structure.(fieldname))) = structure.(fieldname);
zeroPaddedField = paddingArray;
end

function lasField = FixDataType(lasField, datatype)
% lasField = FixDataType(lasField, datatype)
% 
% Casts the contents of lasField to type of datatype, if it was not of the
% type before. Used to fix the datatype of a LAS field if input is of
% incorrect type
%
%   Arguments:
%       lasField [nx1]         : input array
%       datatype [1xn char]    : desired target datatype
%
%   Returns:
%       lasField [nx1]         : array of type datatype
%
if ~isa(lasField, datatype)
    lasField = cast(lasField, datatype);
end
end