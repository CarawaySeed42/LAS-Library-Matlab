function las = add_OGC_Coordinate_System_WKT_Record(las, data)
%las = add_OGC_Coordinate_System_WKT_Record(las) Add CRS VLR to LAS 
%   Adds a OGC Coordinate System WKT Record VLR to a LAS structure.
%   This function is for CRS info in Well Known Text format (WKT).
%
%   The VLR description has to be set by the user.
%   The WKT bit in global endcoding field will also be set.
%   There is an example within the examples directory how
%   to do so.
%
%   OGC Coordinate System WKT Record
%   User ID     : LASF_Projection
%   Record ID   : 2112
%
%   Input:
%       las [struct]      : LAS structure representing point cloud data
%       data [char array] : Optional VLR data
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

if nargin == 1
    data = [];
else
    data = char(data);
end

% Check if the record already exists
if ~isempty(las.variablerecords)
    VLR_index = find([las.variablerecords.record_id] == 2112);
end
if ~isempty(las.extendedvariables)
    ExtVLR_index = find([las.extendedvariables.record_id] == 2112);
end

% Create the record
record_length = numel(data);
if record_length > 65535
    useExtVLR = true;
    record_length = uint64(record_length);
else
    record_length = uint16(record_length);
end

CRS_VLR = struct('reserved', uint16(0), 'user_id', 'LASF_Projection',...
    'record_id', uint16(2112), 'record_length', record_length, ...
    'description', '','data', uint8(data), 'data_as_text', data);

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
    las.variablerecords(VLR_index,1) = CRS_VLR;
else
    if isempty(ExtVLR_index)
        ExtVLR_index = length(las.extendedvariables) + 1;
    end
    las.variablerecords(ExtVLR_index,1) = CRS_VLR;
end

% Set the WKT bit in global Encoding
globalEncoding = decode_global_encoding(las);
globalEncoding.wkt = 1;
las = encode_global_encoding(las, globalEncoding);

end

