function extByteStruct = decode_extrabytes(lasStruct)
%extrabytesStruct = decode_extrabytes(lasStruct)
%   Decode variable length record (VLR) and extra bytes (extradata) of 
%   LAS struct into a new struct. 
%
% Input:
%   lasStruct (struct)          : Structure containing las data with
%                                 variable length records and extradata
% Returns:
%   extByteStruct (struct)      : Struct containing decoded data
%
%
%   extByteStruct Fields:
%   - n fields named by the name of the extra byte specified in it's VLR
%     With n being the amount of extra data present
%       - vlr_record: Contents of the decoded VLR
%       - decoded_data: The decoded value of one extradata point with the
%                       data type specified in VLR. If scaling or offset is 
%                       set, then decoded_data will be converted to double 
%
% Example:
%   There are 4 extra bytes. VLR specifies that both of them are uint16.
%   VLR states the names "extra1" and "extra2". This results in two fields 
%   in extByteStruct. Both fields contain their respective decoded VLR in
%   vlr_record and the decoded uint16 value in decoded_data
%
% Caution:
%   It will be assumed that the first extra byte VLR describes the first
%   extra value, the second describes the second,...
%   Undocumented extra bytes will be ignored and can not exist between two
%   described extra values. Undocumented extra bytes have to be decoded by
%   the user if they know their content.
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
%
%-------------------------------------------------------------------------
% The following is how an extrabyte VLR is set up according to
% LAS 1.4 Revision 15 specification
%
% struct EXTRA_BYTES {
% unsigned char reserved[2];        // 2 bytes
% unsigned char data_type;          // 1 byte
% unsigned char options;            // 1 byte
% char name[32];                    // 32 bytes
% unsigned char unused[4];          // 4 bytes
% anytype no_data;                  // 8 bytes
% unsigned char deprecated1[16];    // 16 bytes
% anytype min;                      // 8 bytes
% unsigned char deprecated2[16];    // 16 bytes
% anytype max;                      // 8 bytes
% unsigned char deprecated3[16];    // 16 bytes
% double scale;                     // 8 bytes
% unsigned char deprecated4[16];    // 16 bytes
% double offset;                    // 8 bytes
% unsigned char deprecated5[16];    // 16 bytes
% char description[32];             // 32 bytes
% }; 

%% Data Type Lookup Table

% Unused and undocumented types get the size of 0 bytes
% Layout: [from_num, to_num, matlab_data_type, sizeof_type] 
datatypeLookup = [...
    0,  0,  {'uint64'},  0;   ...  %  undocumented extra bytes specify value in options field
    1,  1,  {'uint8'},   1;   ...  %  unsigned char 1 byte
    2,  2,  {'char'},    1;   ...  %  char 1 byte
    3,  3,  {'uint16'},  2;   ...  %  unsigned short 2 bytes
    4,  4,  {'int16'},   2;   ...  %  short 2 bytes
    5,  5,  {'uint32'},  4;   ...  %  unsigned long 4 bytes
    6,  6,  {'int32'},   4;   ...  %  long 4 bytes
    7,  7,  {'uint64'},  8;   ...  %  unsigned long long 8 bytes
    8,  8,  {'int64'},   8;   ...  %  long long 8 bytes
    9,  9,  {'float'},   4;   ...  %  float 4 bytes
    10, 10, {'double'},  8;   ...  %  double 8 bytes
    11, 30, {'uint64'},  0;   ...  %  Deprecated deprecated
    31, 255,{'uint64'},  0;   ...  %  Reserved not assigned
];

unsignedIndices = [0,1,3,5,7];
signedIndices   = [2,4,6,8];
floatingIndices = [9,10];

%% Input Check and Initializations

if ~isstruct(lasStruct)
    error('Argument has to be a LAS Struct')
end

las_extrabyte_count = size(lasStruct.extradata, 2);

if las_extrabyte_count == 0
    error('LAS Struct has no extradata field!')
end

vlr_documented_bytes_count   = 0;
vlr_is_extrabyte            = [lasStruct.variablerecords.record_id] == 4;
vlr_is_extrabyte_index      = find(vlr_is_extrabyte);
vlr_extrabyte_count         = numel(vlr_is_extrabyte_index);

%% Processing

% Unpack extrabyte vlr data and create struct field with extracted name
extByteStruct = struct();
field_names_array = cell(vlr_extrabyte_count,1);

for i = 1:vlr_extrabyte_count
    
    extrabyte_name = char(lasStruct.variablerecords(i).data(5:36))';
    field_name = strrep(strcat(extrabyte_name), ' ', '_');
    field_names_array(i) = {field_name};
    
    extByteStruct.(field_name).vlr_record.reserved       = uint8(lasStruct.variablerecords(i).data(1:2));             % 2 Bytes
    extByteStruct.(field_name).vlr_record.data_type.raw   = uint8(lasStruct.variablerecords(i).data(3));              % 1 Byte
    
    % Lookup Data Type in table
    typeTmp         = extByteStruct.(field_name).vlr_record.data_type.raw;
    typeIndexTmp    = find(typeTmp >= cell2mat(datatypeLookup(:,1)) & typeTmp <= cell2mat(datatypeLookup(:,2)));
    castTmp         = datatypeLookup{typeIndexTmp,3};
    dataSizeTmp     = datatypeLookup{typeIndexTmp,4};
    
    % No_data, min and max should be upcast to 8 bytes
    upcastTmp       = 'uint64';
    if sum(typeTmp == signedIndices) > 0
        upcastTmp       = 'int64';
    elseif sum(typeTmp == floatingIndices) > 0
        upcastTmp       = 'double';
    end
        
    extByteStruct.(field_name).vlr_record.data_type.matlab_type = castTmp;
    extByteStruct.(field_name).vlr_record.data_type.size = dataSizeTmp;
    
    extByteStruct.(field_name).vlr_record.options.raw = uint8(lasStruct.variablerecords(i).data(4));                            % 1 Byte
    extByteStruct.(field_name).vlr_record.name        = extrabyte_name;                                                         % 32 Byte
    extByteStruct.(field_name).vlr_record.unused      = uint8(lasStruct.variablerecords(i).data(37:40));                        % 4 Byte
    extByteStruct.(field_name).vlr_record.no_data     = typecast(lasStruct.variablerecords(i).data(41:48), upcastTmp);          % 8 Bytes any type
    extByteStruct.(field_name).vlr_record.deprecated1 = uint8(lasStruct.variablerecords(i).data(49:64));                        % 16 Bytes
    extByteStruct.(field_name).vlr_record.min         = typecast(lasStruct.variablerecords(i).data(65:72), upcastTmp);          % 8 Bytes any type
    extByteStruct.(field_name).vlr_record.deprecated2 = uint8(lasStruct.variablerecords(i).data(73:88));                        % 16 Bytes
    extByteStruct.(field_name).vlr_record.max         = typecast(lasStruct.variablerecords(i).data(89:96), upcastTmp);          % 8 Bytes any type
    extByteStruct.(field_name).vlr_record.deprecated3 = uint8(lasStruct.variablerecords(i).data(97:112));                       % 16 Bytes
    extByteStruct.(field_name).vlr_record.scale       = typecast(uint8(lasStruct.variablerecords(i).data(113:120)), 'double');  % 8 Bytes
    extByteStruct.(field_name).vlr_record.deprecated4 = uint8(lasStruct.variablerecords(i).data(121:136));                      % 16 Bytes
    extByteStruct.(field_name).vlr_record.offset      = typecast(uint8(lasStruct.variablerecords(i).data(137:144)), 'double');  % 8 Bytes
    extByteStruct.(field_name).vlr_record.deprecated5 = uint8(lasStruct.variablerecords(i).data(145:160));                      % 16 Bytes
    extByteStruct.(field_name).vlr_record.description = char(lasStruct.variablerecords(i).data(161:192))';                      % 32 Bytes
    
    % Decode options
    extByteStruct.(field_name).vlr_record.options.no_data_bit = bitand(extByteStruct.(field_name).vlr_record.options.raw, 1);
    extByteStruct.(field_name).vlr_record.options.min_bit     = bitand(bitshift(extByteStruct.(field_name).vlr_record.options.raw, -1, 'uint8'), 1);
    extByteStruct.(field_name).vlr_record.options.max_bit     = bitand(bitshift(extByteStruct.(field_name).vlr_record.options.raw, -2, 'uint8'), 1);
    extByteStruct.(field_name).vlr_record.options.scale_bit   = bitand(bitshift(extByteStruct.(field_name).vlr_record.options.raw, -3, 'uint8'), 1);
    extByteStruct.(field_name).vlr_record.options.offset_bit  = bitand(bitshift(extByteStruct.(field_name).vlr_record.options.raw, -4, 'uint8'), 1);
    
    % Sum the number of extrabytes
    vlr_documented_bytes_count = vlr_documented_bytes_count + extByteStruct.(field_name).vlr_record.data_type.size;
end

if vlr_documented_bytes_count > las_extrabyte_count
    error('Extra bytes mismatch! Variable Length Records specify more extrabytes than point data has!');
end

if vlr_documented_bytes_count < las_extrabyte_count
    warning('There are %d undocumented and undescribed extra bytes! Those will be ignored!', las_extrabyte_count-vlr_documented_bytes_count);
end

% Now finally decode the extrabytes at the end of every single data point
byte_start = 1;
for i = 1:vlr_extrabyte_count
    
    currentField = extByteStruct.(field_names_array{i});
    byte_count = currentField.vlr_record.data_type.size;
    
    % Create extrabyte data with correct data type
    extByteStruct.(field_names_array{i}).decoded_data = zeros(size(lasStruct.extradata, 1),1);
    tmpVector = reshape(lasStruct.extradata(:,byte_start:byte_start+byte_count-1)', 1, [])';
    extByteStruct.(field_names_array{i}).decoded_data = typecast(tmpVector, currentField.vlr_record.data_type.matlab_type);
    
    if currentField.vlr_record.options.scale_bit
        extByteStruct.(field_names_array{i}).decoded_data = double(extByteStruct.(field_names_array{i}).decoded_data) * extByteStruct.(field_name).vlr_record.scale;
    end
    
    if currentField.vlr_record.options.offset_bit
        extByteStruct.(field_names_array{i}).decoded_data = double(extByteStruct.(field_names_array{i}).decoded_data) + extByteStruct.(field_name).vlr_record.offset;
    end
    
    % Go to next column
    byte_start = byte_start + byte_count;
end

end