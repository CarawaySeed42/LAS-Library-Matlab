function las = updateOffsets(las, roundingValue, leftside)
%las = updateOffsets(las, onesided) This function sets the offsets for x, y and z for the las header
%   Offsets will be rounded to the next specified value.
%   Offsets will be set near the median of the data.
%   They can also be leftsided. If so then the offset will be towards the
%   minimum of the data and all values are bigger than the offset
%
%   Input:
%       las (struct)           : Structure containing las data with x,y,z
%       roundingValue (numeric): Optional closest multiple to round to
%                                Default is 1
%       leftside (bool)        : Place offset near the minimum of x,y,z?
%   Returns:
%       las (struct)           : las structure with updated x,y,z offsets

% Input checks
roundVal = 1;
leftside_internal = false;

if nargin > 1
    roundVal = roundingValue;
end
if nargin > 2
    leftside_internal = logical(leftside);
end

if ~isstruct(las)
    error('First argument has to be a LAS structure')
end

% All points right of the offset or around the median value
roundingFunc = @(x) round(x);
if ~leftside_internal
    xVal = median(las.x);
    yVal = median(las.y);
    zVal = median(las.z);
else
    xVal = min(las.x);
    yVal = min(las.y);
    zVal = min(las.z);
    roundingFunc = @(x) floor(x);
end

las.header.x_offset = roundingFunc((xVal / roundVal)) * roundVal;
las.header.y_offset = roundingFunc((yVal / roundVal)) * roundVal;
las.header.z_offset = roundingFunc((zVal / roundVal)) * roundVal;

end

