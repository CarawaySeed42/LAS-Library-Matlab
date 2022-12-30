function addLASLibPaths()
%addLibraryPaths()
%   Adds the necessary paths to the matlab search path
%   Relative paths are used, so if you move this file or the file in the
%   target paths then relative paths will break
if ~isdeployed
    mpath = mfilename('fullpath');
    [path,~,~] = fileparts(mpath);
    addpath(fullfile(path,'/classes'));
end
end

