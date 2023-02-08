%% sample_GetExtrabytes
% This is a sample script to demonstrate how to get and decode extra bytes
% included in a LAS-File
% Before one executes this script they should first execute
% 'sample_AddExtrabytes' to create a sample LAS-File containing extra bytes
fprintf('\nRun: sample_GetExtrabytes\n');

%% Add required paths
addpath('../lib')
addLASLibPaths()

%% Load File containing extra bytes
mpath = mfilename('fullpath');
[path,~,~] = fileparts(mpath);
lasDir = strcat(path, '\', 'modified_samples');
lasFilePath = fullfile(lasDir, 'sample_extrabytes.las');
fprintf('     Reading File: %s\n', lasFilePath);

% In this example we read the header and VLRs first to check if Extrabytes
% are present. Extrabytes have the record_id 4 assigned to them.
pcloud = readLasFile(lasFilePath, 'VLR');

if sum([pcloud.variablerecords.record_id] == 4) > 0
    fprintf('       File contains ExtraBytes confirmed!\n');
end

% Then we read the whole file
pcloud = readLasFile(lasFilePath);

% The check for Extrabytes was just a demonstration and is not neccessary.
% The decoding would fail anyway if Extrabytes are missing

%% Decode extra bytes
fprintf('     Decoding Extra Bytes...\n');
try
    extrabytes = decode_extrabytes(pcloud);
catch ME
    fprintf('\nIf decoding fails, then an exception will be thrown!\n');
    rethrow(ME);
end

%% Print some information
fprintf('\n     Printing extracted information....\n');
fprintf('     Found named Extra Byte(s):\n');
for i = 1:length(extrabytes.ExtrabyteNames)
    fprintf('      %s : %s\n', strcat(extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.name), ...
                               strcat(extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.description));
end

fprintf('\n     Datatype    Min      Max      Scale   Offset:\n');
for i = 1:length(extrabytes.ExtrabyteNames)
    fprintf('      %s   %.4f   %.4f   %.4f   %.4f\n', ...
            extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.data_type.matlab_type, ...            
            extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.min, ...
            extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.max, ...
            extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.scale, ...
            extrabytes.(extrabytes.ExtrabyteNames{i}).descriptor.offset);
end