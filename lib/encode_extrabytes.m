function lasStruct = encode_extrabytes(lasStruct, extrabytes, VLRDescription, addToExisting)
%lasStruct = encode_extrabytes(lasStruct, extrabytes, VLRDescription, addToExisting)
%   Encode an extrabytes object and write its decoded data to LAS structure. 
%   The encoding options and values have to be set inside the descriptor 
%   fields of the extrabytes. Then the extrabytes will be added to
%   the already existing if addToExisting flag is true. Otherwise it will
%   be overwritten. If more then one extrabytes VLR exists then only
%   the first will be recognized and the other one will be deleted!
%   Undocumented extrabytes will be encoded as uint64!
%
%
%   Encoding und structuring is done according to specification:
%   LAS Specification 1.4 R15
%
% Input:
%   lasStruct (struct)          : Structure containing las data with
%                                 variable length records and extradata
%   extrabytes (Extrabytes)     : Instance of extrabytes object containing
%                                 extrabytes data
%   Optional:
%   VLRDescription (char array) : Description of the VLR. If none is
%                                 provided then 'Extrabytes' will be written
%   addToExisting (bool)        : If False existing extrabytes will be
%                                 overwritten. If True extrabytes will be
%                                 added
% Returns:
%   lasStruct (struct)          : Modified Input struct with encoded
%                                 extradata and corresponding VLR
%
%   Extrabytes class:
%   - Cell array property called ExtrabyteNames containing extra byte names
%   - n properties named after the extra byte specified in it's descriptor
%     With n being the amount of extra data present
%       - descriptor:   Contents of the decoded descriptor
%       - decoded_data: The decoded value of one extradata point with the
%                       data type specified in descriptor.
%
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
%


if nargin < 3
    VLRDescription = 'Extrabytes';
end
if nargin < 4
    addToExisting = false;
end

%% Definitions and Initializations
descriptor_Size = 192;
extradata_Count = size(extrabytes.ExtrabyteNames,2);
extrabytes_Data_Type = cell(extradata_Count, 1);

% Data Type Lookup Table
% Static information about potential data types of extrabytes
datatypeLookup = Extrabytes.GetDataTypeLUT();
datatypeIndices = Extrabytes.GetDataTypeIndices();

%% Input Check and Initializations

if ~isstruct(lasStruct)
    error('Argument has to be a LAS Struct')
end

if ~isa(extrabytes, 'Extrabytes')
    error('Second argument has to an Extrabytes object')
end

% Check if Extrabytes VLR already exists. If so get index and overwrite with
% new data if specified. If not then create the VLR and take the index
vlr_index         = find([lasStruct.variablerecords.record_id] == 4);
vlr_count         = numel(vlr_index);

if isempty(vlr_index)
    vlr_index = length(lasStruct.variablerecords) + 1;
end

% If multiple VLR with extrabytes then delete them all and force overwrite
if length(vlr_index) > 1
    lasStruct.variablerecords(vlr_index) = [];
    addToExisting = false;
end

if ~addToExisting || (vlr_count == 0)
    lasStruct.variablerecords(vlr_index).reserved       = 0;
    lasStruct.variablerecords(vlr_index).user_id        = 'LASF_Spec';
    lasStruct.variablerecords(vlr_index).record_id      = 4;
    lasStruct.variablerecords(vlr_index).record_length  = 0;
    lasStruct.variablerecords(vlr_index).data           = [];%zeros(descriptor_Size*extradata_Count, 1, 'uint8');
    lasStruct.variablerecords(vlr_index).data_as_text   = [];%blanks(descriptor_Size*extradata_Count);
    
    lasStruct.extradata = [];
end

% Set VLR Descripton
lasStruct.variablerecords(vlr_index).description    = VLRDescription;

%% Processing

for i = 1:extradata_Count
    
    % Get the property that we are encoding
    curPropName = extrabytes.ExtrabyteNames{i};
    curProp = extrabytes.(curPropName);
    descriptor_data = zeros(descriptor_Size, 1, 'uint8');
    
    % Lookup encoded data type in lookup table
    data_type_encoded       = curProp.descriptor.data_type.raw;
    typeIndexTmp            = data_type_encoded >= cell2mat(datatypeLookup(:,1)) & ...
                              data_type_encoded <= cell2mat(datatypeLookup(:,2));
    extrabytes_Data_Type{i} = datatypeLookup{typeIndexTmp,3};
    
    % No_data, min and max should be upcast to 8 bytes
    upcastTmp       = 'uint64';
    if sum(data_type_encoded == datatypeIndices.signed) > 0
        upcastTmp       = 'int64';
    elseif sum(data_type_encoded == datatypeIndices.float) > 0
        upcastTmp       = 'double';
    end
    
    % Write information to descriptor data field (Deprecated and unused
    % fields stay NULL)
    descriptor_data(3)          = uint8(curProp.descriptor.data_type.raw);                      % 1  Byte
    descriptor_data(4)          = uint8(curProp.descriptor.options.raw);                        % 1  Byte
    descriptor_data(5:36)       = curProp.descriptor.name;                                      % 32 Bytes
    descriptor_data(41:48)      = typecast(cast(curProp.descriptor.no_data,upcastTmp) ,'uint8');% 8 Bytes any type
    descriptor_data(65:72)      = typecast(cast(curProp.descriptor.min,upcastTmp), 'uint8');    % 8 Bytes any type
    descriptor_data(89:96)      = typecast(cast(curProp.descriptor.max,upcastTmp), 'uint8');    % 8 Bytes any type
    descriptor_data(113:120)    = typecast(cast(curProp.descriptor.scale, 'double'), 'uint8');  % 8 Bytes
    descriptor_data(137:144)    = typecast(cast(curProp.descriptor.offset, 'double'), 'uint8'); % 8 Bytes
    descriptor_data(161:192)    = curProp.descriptor.description;                               % 8 Bytes
    
    % Dynamically add descriptor (Unneccessary memory usage but data is
    % small enough)
    lasStruct.variablerecords(vlr_index).data = [lasStruct.variablerecords(vlr_index).data; descriptor_data];
end

% Create data as text and record length
lasStruct.variablerecords(vlr_index).data_as_text = char(lasStruct.variablerecords(vlr_index).data)';
lasStruct.variablerecords(vlr_index).record_length  = length(lasStruct.variablerecords(vlr_index).data);

%% Encode the extrabytes
for i = 1:length(extrabytes.ExtrabyteNames)
    
    curPropName = extrabytes.ExtrabyteNames{i};
    curProp     = extrabytes.(curPropName);
    
    % Apply scale and offset and turn data into target type
    scale       = curProp.descriptor.scale;
    offset      = curProp.descriptor.offset;
    
    % Apply scale and offset and turn data into target type
    scale_bit   = bitand(bitshift(curProp.descriptor.options.raw, -3, 'uint8'), 1);
    offset_bit  = bitand(bitshift(curProp.descriptor.options.raw, -4, 'uint8'), 1);
    
    if scale_bit && offset_bit
        curProp.decoded_data = cast((curProp.decoded_data-offset)/scale, extrabytes_Data_Type{i});
    elseif offset_bit
        curProp.decoded_data = cast(curProp.decoded_data-offset, extrabytes_Data_Type{i});
    elseif scale_bit
        curProp.decoded_data = cast(curProp.decoded_data/scale, extrabytes_Data_Type{i});
    else
        curProp.decoded_data = cast(curProp.decoded_data, extrabytes_Data_Type{i});
    end
    
    % Count of data elements and bytes per element
    dataCount   = size(curProp.decoded_data, 1);
    byteCount   = numel(typecast((curProp.decoded_data(1)), 'uint8'));
    
    % Encode data type simply by getting byte representation and adding
    % to extradata, if a datatype if specified. Else trim the bytes
    % to the specified value in to options field
    if curProp.descriptor.data_type.raw ~= 0
        lasStruct.extradata = [lasStruct.extradata; reshape(typecast(curProp.decoded_data, 'uint8')', byteCount, dataCount)];
    else
        byteCountInArray = curProp.descriptor.options.raw;
        extradataTmp = reshape(typecast(curProp.decoded_data, 'uint8')', byteCount, dataCount);
        lasStruct.extradata = [lasStruct.extradata; extradataTmp(:,1:byteCountInArray)];
    end
    
end

end