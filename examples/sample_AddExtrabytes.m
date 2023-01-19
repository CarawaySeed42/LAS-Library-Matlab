%% sample_AddExtrabytes
% This is a sample script to demonstrate how to add extra bytes to a
% point cloud and then write the modified cloud as a new file
% The extra bytes are arbitrarily chosen to be the X,Y distance to the middle
% of the point data
fprintf('\nRun: sample_AddExtrabytes\n');

%% Add required paths
addpath('../lib')
addLASLibPaths()

%% Load File to add extrabytes
mpath = mfilename('fullpath');
[path,~,~] = fileparts(mpath);
lasFilePath = fullfile(path,'sample.las');
fprintf('     Reading File: %s\n', lasFilePath);

pcloud = readLasFile(lasFilePath);

% As an example we will add the X,Y difference to the mean point coordinate 
% as two extrabytes (dx, dy)
meanXY = [mean(pcloud.x), mean(pcloud.y)];
differenceX = pcloud.x-mean(pcloud.x);
differenceY = pcloud.y-mean(pcloud.y);

% Construct Extrabytes object with the names of our extrabytes and get the
% valid variable names of our selected names.  The names of our
% extra bytes within the descriptor can have whitespaces.
% But they prevent our names to be valid matlab variable names. So they
% will be made valid
fprintf('     Creating Extra Bytes...\n');
extraNames = {'dX', 'dY'};
extrabytes = Extrabytes(extraNames);
validExtraNames = extrabytes.ExtrabyteNames;

%% Add Data
extrabytes.SetData(validExtraNames{1}, differenceX);
extrabytes.SetData(validExtraNames{2}, differenceY);

%% Set No Data, Min, Max, Offset and Scale for both extra byte descriptors
% We will use a scale of 1e-4 here, so we 'only' get 4 valid decimals
for i = 1:length(extrabytes.ExtrabyteNames)
    field_name = extrabytes.ExtrabyteNames{i};
    extrabytes.SetNoData(field_name, 0);
    extrabytes.SetMin(field_name, min(extrabytes.(field_name).decoded_data));
    extrabytes.SetMax(field_name, max(extrabytes.(field_name).decoded_data));
    extrabytes.SetOffset(field_name, 0);
    extrabytes.SetScale(field_name, 0.0001)
end
clear field_name

%% Set options for No Data, Min, Max, Offset and Scale
% We will not use the No Data and Offset field
% SetOptions supports to set options for multiple extra byte values at once
% SetOptions(names, no_data_bit, min_bit, max_bit, scale_bit, offset_bit)
extrabytes.SetOptions(extrabytes.ExtrabyteNames, false, true, true, true, false);

%% Set the data type
% We will choose the data type single (float) which takes up 4 byte per
% value.
extrabytes.SetDataType(extrabytes.ExtrabyteNames, 'single');

% Additionally to the name we can add a little description for our extra
% bytes
extrabytes.SetDescription(validExtraNames{1}, 'Difference to mean X Coordinate');
extrabytes.SetDescription(validExtraNames{2}, 'Difference to mean Y Coordinate');

%% Encode our extra bytes into pcloud structure
fprintf('     Encoding Extra Bytes...\n');
pcloud_modified = encode_extrabytes(pcloud, extrabytes, 'Sample Extra Bytes');

%% Write new cloud to modified_samples folder
targetDir = strcat(path, '\', 'modified_samples');
if ~exist(targetDir, 'dir')
    mkdir(targetDir)
end
outPath = fullfile(targetDir, 'sample_extrabytes.las');

% Write the new file
fprintf('     Writing File: %s\n', outPath);
writeLasFile(pcloud_modified, outPath, 1, 3, pcloud_modified.header.point_data_format);

% Finished. We added two extra byte values per point of data type single.
% Our Point Data Record Length has grown to 28 bytes per record (20 + 2*4)
fprintf('     Finished!\n');
