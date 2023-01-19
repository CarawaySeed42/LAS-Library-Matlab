% Benchmark the LAS-File Reader function
% Set a target directory from which every .las-File will be imported. 
% The more files the better. tictoc is used as a timer which is not very
% accurate but should provide a satisfying result as long as the file sizes
% aren't too small.
% If no valid target directory is set, then the directory of this script
% will be used
%% Choose the target directory containing LAS-Files

targetDirectory = 'D:\SampleFolderPlaceholder';

if isempty(targetDirectory) || ~exist(targetDirectory, 'dir')
    [targetDirectory, ~, ~] = fileparts(mfilename('fullpath'));
end

%%
lasFiles = dir(fullfile(targetDirectory, '*.las'));
currentMegabytes = 0;
totalTime = 0;
bytesInMB = 1024^2;

fprintf('\nDirectory: %s\n', targetDirectory);
fprintf('Start Benchmarking...\n');
tic;
for i = 1:size(lasFiles, 1)
    
    t1 = toc;
    test = readLasFile(fullfile(lasFiles(i).folder, lasFiles(i).name));
    t2 = toc;
    
    fileSize = lasFiles(i).bytes/bytesInMB;
    dt = t2-t1; 
    fprintf('Finished cloud number %d : Average Speed  %.3f MB/s | File Size  %.1fMB  |  Elapsed Time  %.3fs\n',...
             i, fileSize/dt, fileSize, dt);
    currentMegabytes = currentMegabytes + lasFiles(i).bytes/bytesInMB;
    totalTime = totalTime +(t2-t1);
    
end

fprintf('\nTotal File Size: %.3f MB\n', sum([lasFiles.bytes])/bytesInMB);
fprintf('Total Elapsed Time spent Reading: %.3f s\n', totalTime);
fprintf('Average Total Read Speed: %.3f MB/s\n', currentMegabytes/totalTime);
