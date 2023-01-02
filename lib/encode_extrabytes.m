function lasStruct = encode_extrabytes(lasStruct, extrabytes, VLRDescription, addToExisting)
%lasStruct = encode_extrabytes(lasStruct, extrabytes, VLRDescription, addToExisting)
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
extradata_Count = size(extrabytes.extrabytenames,2);

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
    curPropName = extrabytes.extrabytenames{i};
    curProp = extrabytes.(curPropName);
    descriptor_data = zeros(descriptor_Size, 1, 'uint8');
    
    % Write information to descriptor data field (Deprecated and unused
    % fields stay NULL)
    descriptor_data(3)          = uint8(curProp.descriptor.data_type.raw);          % 1  Byte
    descriptor_data(4)          = uint8(curProp.descriptor.options.raw);            % 1  Byte
    descriptor_data(5:36)       = curProp.descriptor.name;                          % 32 Bytes
    descriptor_data(41:48)      = typecast(curProp.descriptor.no_data, 'uint8');    % 8 Bytes any type
    descriptor_data(65:72)      = typecast(curProp.descriptor.min, 'uint8');        % 8 Bytes any type
    descriptor_data(89:96)      = typecast(curProp.descriptor.max, 'uint8');        % 8 Bytes any type
    descriptor_data(113:120)    = typecast(curProp.descriptor.scale, 'uint8');      % 8 Bytes       
    descriptor_data(137:144)    = typecast(curProp.descriptor.offset, 'uint8');     % 8 Bytes 
    descriptor_data(161:192)    = curProp.descriptor.description;                   % 8 Bytes 
    
    % Dynamically add descriptor (Unneccessary memory usage but data is
    % small enough)
    lasStruct.variablerecords(vlr_index).data = [lasStruct.variablerecords(vlr_index).data; descriptor_data];
end

% Create data as text
lasStruct.variablerecords(vlr_index).data_as_text = char(lasStruct.variablerecords(vlr_index).data)';

%% Encode the extrabytes
for i = 1:length(extrabytes.extrabytenames)
    
    curPropName = extrabytes.extrabytenames{i};
    curProp     = extrabytes.(curPropName);
    
    scale       = curProp.descriptor.scale;
    offset      = curProp.descriptor.offset;
    dataCount   = size(curProp.decoded_data, 1);
    byteCount   = numel(typecast((curProp.decoded_data(1)), 'uint8'));
    
    lasStruct.extradata = [lasStruct.extradata; reshape(typecast((curProp.decoded_data-offset)/scale, 'uint8')', byteCount, dataCount)];
    
end

end