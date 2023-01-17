function extrabytes = decode_extrabytes(lasStruct)
%extrabytesStruct = decode_extrabytes(lasStruct)
%   Decode variable length record (VLR) and extra bytes (extradata) 
%   following point data of LAS struct to Extrabytes object.
%   Extra Byte descriptors with the same name will be changed for class
%   properties. Undocumented extra bytes will be ignored
%
%   Decoding und structuring is done according to specification:
%   LAS Specification 1.4 R15
%
% Input:
%   lasStruct (struct)          : Structure containing las data with
%                                 variable length records and extradata
% Returns:
%   extrabytes (Extrabytes)     : Extrabytes object containing decoded data
%
%
%   Extrabytes class:
%   - Cell array property called ExtrabyteNames containing extra byte names
%   - n properties named after the extra byte specified in it's descriptor
%     With n being the amount of extra data present
%       - descriptor:   Contents of the decoded descriptor
%       - decoded_data: The decoded value of one extradata point with the
%                       data type specified in descriptor. If scaling or 
%                       offset is  set, then decoded_data will be converted
%                       to double 
%
% Example:
%   There are 4 bytes following point data. Descriptors specifies that
%   there are two extra data byte values and both of them are uint16.
%   Descriptors states the names "extra1" and "extra2". This results in 
%   three properties in extrabytes. Two properties contain their respective 
%   decoded descriptor field and the decoded uint16 value in decoded_data.
%   ExtrabyteNames property specifies the names of the extra data values
%
% Caution:
%   It will be assumed that the first extra byte VLR describes the first
%   extra value, the second describes the second,...
%
%   Undocumented extra bytes will have their specified size extracted but
%   are assumed to be of type uint64 in any case
%   Undocumented AND undescribed extra bytes will be ignored and can not 
%   exist between two described extra values. Undocumented extra bytes in
%   general have to be decoded by the user if they know their content.
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
%
%-------------------------------------------------------------------------
% The following is how an extrabyte descriptor is set up according to
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

% Static information about potential data types of extrabytes
datatypeLookup = Extrabytes.GetDataTypeLUT();
datatypeIndices = Extrabytes.GetDataTypeIndices();

%% Input Check and Initializations

if ~isstruct(lasStruct)
    error('Argument has to be a LAS Struct')
end

las_extrabyte_count = size(lasStruct.extradata, 1);

if las_extrabyte_count == 0
    error('LAS Struct has no extradata field!')
end

% How many extra byte VLRs exist. There should be only 0 or 1 but if a
% writer writes a extrabyte VLR per extradata value then this will also be
% supported
vlr_documented_bytes_count  = 0;
vlr_is_extrabyte_index      = find([lasStruct.variablerecords.record_id] == 4);
vlr_extrabyte_count         = numel(vlr_is_extrabyte_index);

%% Processing

% Unpack extrabyte vlr data and create entry in extrabyte class instance
extrabytes = Extrabytes();
descriptor_Size = 192;

% Iterate through extrabyte VLRs (Should be zero or one)
for k = 1:vlr_extrabyte_count
    
    current_vlr_index = vlr_is_extrabyte_index(k);
    extrabyte_descriptor_count = round(length(lasStruct.variablerecords(current_vlr_index).data) / descriptor_Size);
     if (mod(lasStruct.variablerecords(current_vlr_index).record_length, 192) ~= 0)
        error('Record Length of Extra Byte Variable Length Record is not a multiple of %d', descriptor_Size);
    end
    
    % Extract information from every descriptor
    for i = 1:extrabyte_descriptor_count
        
        descriptor_data = lasStruct.variablerecords(current_vlr_index).data(((i-1)*descriptor_Size)+1:i*descriptor_Size);
        
        % Add property with name of extra value, but make sure that the
        % name is unique and valid
        extrabyte_name = char(descriptor_data(5:36))';
        field_name = VariableNames.MakeValid(extrabyte_name);
        nameOccupied = strcmp(extrabytes.ExtrabyteNames, field_name);
        if any(nameOccupied)
            field_name = strcat(field_name,'_', num2str(sum(nameOccupied)+1));
        end
        
        extrabytes.AddExtrabytes({field_name});
        
        extrabytes.(field_name).descriptor.reserved       = uint8(descriptor_data(1:2));            % 2 Bytes
        extrabytes.(field_name).descriptor.data_type.raw  = uint8(descriptor_data(3));              % 1 Byte
        extrabytes.(field_name).descriptor.options.raw    = uint8(descriptor_data(4));              % 1 Byte
        
        % Lookup Data Type in table
        typeTmp         = extrabytes.(field_name).descriptor.data_type.raw;
        typeIndexTmp    = find(typeTmp >= cell2mat(datatypeLookup(:,1)) & typeTmp <= cell2mat(datatypeLookup(:,2)));
        matlabType      = datatypeLookup{typeIndexTmp,3};
        dataSize        = datatypeLookup{typeIndexTmp,4};
        
        % If data type is zero then the options field specifies how many
        % undocumented bytes there are
        if (typeTmp == 0)
            dataSize = extrabytes.(field_name).descriptor.options.raw;
        end
        
        % No_data, min and max should have been upcast to 8 bytes
        upcastTmp       = 'uint64';
        if sum(typeTmp == datatypeIndices.signed) > 0
            upcastTmp       = 'int64';
        elseif sum(typeTmp == datatypeIndices.float) > 0
            upcastTmp       = 'double';
        end
        
        extrabytes.(field_name).descriptor.data_type.matlab_type = matlabType;
        extrabytes.(field_name).descriptor.data_type.size = uint8(dataSize);
        
        extrabytes.(field_name).descriptor.name        = extrabyte_name;                                       % 32 Byte
        extrabytes.(field_name).descriptor.unused      = uint8(descriptor_data(37:40));                        % 4 Byte
        extrabytes.(field_name).descriptor.no_data     = typecast(descriptor_data(41:48), upcastTmp);          % 8 Bytes any type
        extrabytes.(field_name).descriptor.deprecated1 = uint8(descriptor_data(49:64));                        % 16 Bytes
        extrabytes.(field_name).descriptor.min         = typecast(descriptor_data(65:72), upcastTmp);          % 8 Bytes any type
        extrabytes.(field_name).descriptor.deprecated2 = uint8(descriptor_data(73:88));                        % 16 Bytes
        extrabytes.(field_name).descriptor.max         = typecast(descriptor_data(89:96), upcastTmp);          % 8 Bytes any type
        extrabytes.(field_name).descriptor.deprecated3 = uint8(descriptor_data(97:112));                       % 16 Bytes
        extrabytes.(field_name).descriptor.scale       = typecast(uint8(descriptor_data(113:120)), 'double');  % 8 Bytes
        extrabytes.(field_name).descriptor.deprecated4 = uint8(descriptor_data(121:136));                      % 16 Bytes
        extrabytes.(field_name).descriptor.offset      = typecast(uint8(descriptor_data(137:144)), 'double');  % 8 Bytes
        extrabytes.(field_name).descriptor.deprecated5 = uint8(descriptor_data(145:160));                      % 16 Bytes
        extrabytes.(field_name).descriptor.description = char(descriptor_data(161:192))';                      % 32 Bytes
        
        % Decode options
        extrabytes.(field_name).descriptor.options.no_data_bit = bitand(extrabytes.(field_name).descriptor.options.raw, 1);
        extrabytes.(field_name).descriptor.options.min_bit     = bitand(bitshift(extrabytes.(field_name).descriptor.options.raw, -1, 'uint8'), 1);
        extrabytes.(field_name).descriptor.options.max_bit     = bitand(bitshift(extrabytes.(field_name).descriptor.options.raw, -2, 'uint8'), 1);
        extrabytes.(field_name).descriptor.options.scale_bit   = bitand(bitshift(extrabytes.(field_name).descriptor.options.raw, -3, 'uint8'), 1);
        extrabytes.(field_name).descriptor.options.offset_bit  = bitand(bitshift(extrabytes.(field_name).descriptor.options.raw, -4, 'uint8'), 1);
        
        % Sum the number of extrabytes
        vlr_documented_bytes_count = vlr_documented_bytes_count + extrabytes.(field_name).descriptor.data_type.size;
    end
end

if vlr_documented_bytes_count > las_extrabyte_count
    error('Extra bytes mismatch! Variable Length Records specify more extrabytes than point data has!');
end

if vlr_documented_bytes_count < las_extrabyte_count
    warning('There are %d undocumented and undescribed or unsupported extra bytes! Those will be ignored!', las_extrabyte_count-vlr_documented_bytes_count);
end

% Now finally decode the extrabytes at the end of every single data point
byte_start = 1;
for i = 1:length(extrabytes.ExtrabyteNames)
    
    name = extrabytes.ExtrabyteNames{i};
    byte_count = extrabytes.(name).descriptor.data_type.size;
    
    % If undocumented or unsupported extra bytes then do not decode
    if extrabytes.(name).descriptor.options.raw == 0
        extrabytes.(name).decoded_data = [];
        byte_start = byte_start + byte_count;
        continue;
    elseif byte_count == 0
        extrabytes.(name).decoded_data = [];
        warning(['Extrabyte type according to LAS 1.4 R15 not supported! ',...
            'Extra data after ''%s'' will desync!'],  name);
        continue;
    end
        
    % Create extrabyte data with correct data type
    extrabytes.(name).decoded_data = zeros(size(lasStruct.extradata, 2),1);
    tmpVector = reshape(lasStruct.extradata(byte_start:byte_start+byte_count-1, :), [], 1);
    extrabytes.(name).decoded_data = typecast(tmpVector, extrabytes.(name).descriptor.data_type.matlab_type);
    
    if extrabytes.(name).descriptor.options.scale_bit
        extrabytes.(name).decoded_data = double(extrabytes.(name).decoded_data) * extrabytes.(name).descriptor.scale;
    end
    
    if extrabytes.(name).descriptor.options.offset_bit
        extrabytes.(name).decoded_data = double(extrabytes.(name).decoded_data) + extrabytes.(name).descriptor.offset;
    end
    
    % Go to next column
    byte_start = byte_start + byte_count;
end

end