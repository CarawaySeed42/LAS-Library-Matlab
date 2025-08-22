function las = updateOffsets(las, rounding_value, leftside)
%las = updateOffsets(las, onesided) This function sets the offsets for x, y and z for the las header
%   Offsets will be rounded to the next specified value.
%   Offsets will be set near the middle of the bounding box of the data.
%   They can also be leftsided. If so then the offset will be towards the
%   minimum of the data and all values are bigger than the offset
%
%   Input:
%       las (struct)            : Structure containing las data with x,y,z
%       rounding_value (numeric): Optional closest multiple to round to.
%                                 Set to zero for no rounding.
%                                 Default is 1
%       leftside (bool)         : Place offset near the minimum of x,y,z?
%                                 This forces all coordinates relative to 
%                                 offsets to be positive
%   Returns:
%       las (struct)            : las structure with updated x,y,z offsets

% Input checks
roundVal = 1;
leftside_internal = false;

if nargin > 1
    roundVal = rounding_value;
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
    xVal = 0.5*(max(las.x)+min(las.x));
    yVal = 0.5*(max(las.y)+min(las.y));
    zVal = 0.5*(max(las.z)+min(las.z));
else
    xVal = min(las.x);
    yVal = min(las.y);
    zVal = min(las.z);
    roundingFunc = @(x) floor(x);
end

% If roundingVal is smaller or equal zero, then do no rounding
if roundVal <= 0
    roundingFunc = @(x) x;
    roundVal = 1;
end

las.header.x_offset = roundingFunc((xVal / roundVal)) * roundVal;
las.header.y_offset = roundingFunc((yVal / roundVal)) * roundVal;
las.header.z_offset = roundingFunc((zVal / roundVal)) * roundVal;

end

