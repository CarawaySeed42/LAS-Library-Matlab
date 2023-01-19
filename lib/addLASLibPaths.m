function addLASLibPaths()
%addLibraryPaths()
%   Adds the necessary paths to the matlab search path
%   Relative paths are used, so if you move this file or the file in the
%   target paths then relative paths will break
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
if ~isdeployed
    mpath = mfilename('fullpath');
    [path,~,~] = fileparts(mpath);
    
    addpath(path);
    addpath(fullfile(path,'/classes'));
    addpath(fullfile(path,'/writer'));
end
end

