function las = newPointCloud(versionMinor)
% las = newPointCloud(versionMinor)
%
%   Creates a empty point cloud structure that can be populated and then
%   written with the corresponding writer function
%
%   Input:  
%       versionMinor (numeric) : Optionally create header fields 
%                                for the selcted version
%                                Default: 4
%
%   Output: 
%       las [struct]           : Structure that is writable to LAS file
%
%   The default Version Minor, if function is called with no arguments, is
%   four. This has the most versatility but is overkill for many
%   applications

if nargin < 1
    versionMinor = 4;
end
las = PCloudFun.newPointCloud(versionMinor);
end


