%% sample_ReadAndWriteFile
% This is a sample script to demonstrate how to read a LAS-File and then
% write it as a different point data format
fprintf('-------------------------------------------------------------\n');
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
pcloud = readLASfile(lasFilePath);

%% Manipulate coordinates
% Add a random offset to move the cloud
pcloud.x = pcloud.x + 420696;
pcloud.y = pcloud.y + 420696;
pcloud.z = pcloud.z - 69;

% Update the header offsets because in this case, we  moved the cloud too
% far from the old offset to represent this number with the former offset
roundingValue = 10;
pcloud = updateOffsets(pcloud, roundingValue);

%% Write LAS-File
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
writeLASfile(pcloud, outPath, 1, 3, 0);

%% Read new LAS-File again to check the results
pcloud_new = readLASfile(outPath);
fprintf('-------------------------------------------------------------\n');