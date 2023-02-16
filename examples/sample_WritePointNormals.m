% sample_WritePointNormals
% The LAS Specification as of now (2022) does not have a field to store
% point cloud normals in. But we can store inside the extrabyte payload.
% This sample will give you an example how to do that.
%
% The normals will be written as 2-byte uint16 values and are stretched and
% shifted into that range using the scale and offset fields. This leads to
% a slight compression and accuracy loss. Run the script to find out by how
% much the normals change!
% You could of course just write them as float or double values but where
% is the fun in that. It also wastes precious storage 
%
% For simplicity: Normals will be estimated with the respective Matlab
% function. This capability was introduced in MATLAB2015b. Older versions
% will not be able to run this sample. Sorry

if verLessThan('matlab', '8.6')
   error('This script can only be run in Matlab 2015b or newer!') 
end

fprintf('\nRun: sample_WritePointNormals\n');

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

%% Calculate Point Cloud Normals
fprintf('     Create Matlab Point Cloud object...\n');
ptCloud = pointCloud([pcloud.x, pcloud.y, pcloud.z]);
fprintf('     Calculate Normals...\n');
normals = pcnormals(ptCloud, 100);

% Flip normals that point in the wrong direction
wrongDir = normals(:,3) < 0;
normals(wrongDir, :) = -normals(wrongDir, :); 

%% Add extrabytes
fprintf('     Creating Extra Bytes...\n');
extraNames = {'vX', 'vY', 'vZ'};
extrabytes = Extrabytes(extraNames);

%% Add Data
extrabytes.SetData(extrabytes.ExtrabyteNames{1}, normals(:,1));
extrabytes.SetData(extrabytes.ExtrabyteNames{2}, normals(:,2));
extrabytes.SetData(extrabytes.ExtrabyteNames{3}, normals(:,3));

%% Set the data type
% We will choose the data type uint16 which takes up 2 byte per
% value. This will lead to lossy compression
extrabytes.SetDataType(extrabytes.ExtrabyteNames, 'uint16');

%% Set No Data, Min, Max, Offset and Scale
% No_Data, Min and Max will not be set, because we have no No_Data value
% and Min and Max are not neccessarily representable in this compressed
% state. But they have to be written in its raw form by specification
% For example: Negative Values can not be represented as uint16 
for i = 1:length(extrabytes.ExtrabyteNames)
    field_name = extrabytes.ExtrabyteNames{i};
%     extrabytes.SetNoData(field_name, 0);
%     extrabytes.SetMin(field_name, 0);
%     extrabytes.SetMax(field_name, 0);
    extrabytes.SetOffset(field_name, -1);
    extrabytes.SetScale(field_name, 1/(2^15-1))
end

% Set No_Data, Min and Max bit to false, set Offset and Scale bit to true
extrabytes.SetOptions(extrabytes.ExtrabyteNames, false, false, false, true, true);

% Additionally to the name we can add a little description for our extra
% bytes
extrabytes.SetDescription(extrabytes.ExtrabyteNames{1}, 'X vector component');
extrabytes.SetDescription(extrabytes.ExtrabyteNames{2}, 'Y vector component');
extrabytes.SetDescription(extrabytes.ExtrabyteNames{3}, 'Z vector component');

%% Encode our extra bytes into pcloud structure
fprintf('     Encoding Extra Bytes...\n');
pcloud_modified = encode_extrabytes(pcloud, extrabytes, 'Point Cloud Normals');

%% Write new cloud to modified_samples folder
targetDir = strcat(path, '\', 'modified_samples');
if ~exist(targetDir, 'dir')
    mkdir(targetDir)
end
outPath = fullfile(targetDir, 'sample_pcloud_normals.las');

% Write the new file
fprintf('     Writing File: %s\n', outPath);
writeLASfile(pcloud_modified, outPath, 1, 3, pcloud_modified.header.point_data_format);

% Finished. We added two extra byte values per point of data type single.
% Our Point Data Record Length has grown to 28 bytes per record (20 + 2*4)
fprintf('     Finished Writing!\n');

%% Read written cloud again and decode extra bytes
pcloud_new = readLASfile(outPath);
extrabytes = decode_extrabytes(pcloud_new);

% Output the maximum deviation of calculated normals and compressed normals
devX = abs(extrabytes.vX.decoded_data - normals(:,1));
devY = abs(extrabytes.vY.decoded_data - normals(:,2));
devZ = abs(extrabytes.vZ.decoded_data - normals(:,3));
maxDeviation = max(max([devX, devY, devZ]));

fprintf('\n     Checking results...!\n');
fprintf('     Maximum of accuracy loss due to compression: %f\n', maxDeviation);
fprintf('\n     Finished Script!\n');