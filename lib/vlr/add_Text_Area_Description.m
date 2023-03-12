function las = add_Text_Area_Description(las, description)
%las = add_Text_Area_Description(las, description)
%   Adds a Text Area Description VLR to a LAS structure.
%   "This VLR/EVLR is used for providing a textual description of the 
%   content of the LAS file. It is a null-terminated, free-form ASCII 
%   string" (LAS 1.4 R15)
%
%   Text Area Description Record
%   User ID     : LASF_Spec
%   Record ID   : 3
%
%   Input:
%       las [struct]             : LAS structure representing point cloud data
%       description [char array] : The Text Area Description to add
%
%   Returns:
%       las [struct]    : Input LAS structure with added VLR
%
%   Caution: If a VLR of this kind already exists, then it will be
%   overwritten because only one VLR of this kind is allowed per file
%   If necessary because the payload is too big, then Extended VLR is used
VLR_index = [];
ExtVLR_index = [];
useExtVLR = false;

description = char(description);
record_id_value = uint16(3);

% Check if the record already exists
if ~isempty(las.variablerecords)
    VLR_index = find([las.variablerecords.record_id] == 3);
end
if ~isempty(las.extendedvariables)
    ExtVLR_index = find([las.extendedvariables.record_id] == 3);
end

% Create the record
record_length = numel(description);
if record_length > 65535
    useExtVLR = true;
    record_length = uint64(record_length);
else
    record_length = uint16(record_length);
end

Text_Area_VLR = struct('reserved', uint16(0), 'user_id', 'LASF_Spec',...
    'record_id', record_id_value, 'record_length', record_length, ...
    'description', 'Text Area Description','data', uint8(description), 'data_as_text', description);

% If a record exists as VLR and a ExtVLR then delete one
% If a field gets empty in the process then properly clean them up
if ~isempty(VLR_index) && ~isempty(ExtVLR_index)
    if useExtVLR
        las.variablerecords(VLR_index) = [];
        VLR_index = [];
        
        if isempty(las.variablerecords)
            las.variablerecords = [];
        end
    else
        las.extendedvariables(ExtVLR_index) = [];
        ExtVLR_index = [];
        
        if isempty(las.extendedvariables)
            las.extendedvariables = [];
        end
    end
end

% Set VLR or ExtVLR
if ~useExtVLR
    if isempty(VLR_index)
        VLR_index = length(las.variablerecords) + 1;
    end
    las.variablerecords(VLR_index,1) = Text_Area_VLR;
else
    if isempty(ExtVLR_index)
        ExtVLR_index = length(las.extendedvariables) + 1;
    end
    las.variablerecords(ExtVLR_index,1) = Text_Area_VLR;
end

end

