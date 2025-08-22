function las = optimizeScaleFactors(las)
%las = optimizeScaleFactors(las) Optimize scale factors in las header
%   This function calculates the smallest scale factors to fit the
%   las bounding boxes (min/max xyz) into the range -2^31-1 to + 2^31-1
%
%   Please make sure that the bounding boxes and the offsets in the las
%   header are up to date and in sync with the coordinate data before
%   calling this function. Otherwise you might lose precision.
%
%   Input:
%       las (struct) : Structure containing las header
%   Returns:
%       las (struct) : las structure with optimized scale factors
int32_max = 2^31-1;
head = las.header;

% Maximum distance of coordinate bounding box from offset to find the scale
% we need to get into int32 range
x_max_dist = max(abs([head.min_x-head.x_offset, head.max_x-head.x_offset]));
y_max_dist = max(abs([head.min_y-head.y_offset, head.max_y-head.y_offset]));
z_max_dist = max(abs([head.min_z-head.z_offset, head.max_z-head.z_offset]));

las.header.scale_factor_x = x_max_dist/int32_max;
las.header.scale_factor_y = y_max_dist/int32_max;
las.header.scale_factor_z = z_max_dist/int32_max;

end

