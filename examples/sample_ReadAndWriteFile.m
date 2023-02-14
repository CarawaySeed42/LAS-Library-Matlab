%% sample_ReadAndWriteFile
% This is a sample script to demonstrate how to read a LAS-File and then
% write it as a different point data format
fprintf('\nRun: sample_ReadAndWriteFile\n');

%% Add required paths
addpath('../lib')
addLASLibPaths();

%% Read LAS-File
mpath = mfilename('fullpath');
[path,~,~] = fileparts(mpath);
lasFilePath = fullfile(path, 'sample.las');
fprintf('     Reading File: %s\n', lasFilePath);

% Read the sample file
pcloud = readLasFile(lasFilePath);
%% Read LAS-File
targetDir = strcat(path, '\', 'modified_samples');
if ~exist(targetDir, 'dir')
    mkdir(targetDir)
end
outPath = fullfile(targetDir, 'sample_write.las');

% Write the new file as point data record format (PDRF) 1
% This PDRF supports the GPS-Time field
% Because the source was PDRF 0, the GPS-Time will be set to zero for all
% points
fprintf('     Writing File: %s\n', outPath);
writeLasFile(pcloud, outPath, 1, 3, 1);