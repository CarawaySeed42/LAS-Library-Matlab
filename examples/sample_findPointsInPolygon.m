% sample_findPointsInPolygon.m
% This is a sample script to demonstrate how to use the isPointInPolygon
% function to find all points of a sample that are inside a search polygon.
% The function also supports multithreading.
% We will learn a few lessons here:
%   - Multi-Threaded execution does not linearly cut down the time.
%     And if there is too little work then the multi-threaded approach
%     is even slower than single threaded. ( Just like teamwork )
%   - Matlab has a built-in inpolygon function which is slow, but
%     operates on a different principle which is not shown here
%   - The more points or the more vertices a polygon has, the longer the
%     execution time. Which you can test yourself.

close all; clc; clear;
fprintf('-------------------------------------------------------------\n');

% Initializations
numberOfThreads = 4;
numberOfVertices = 3960;

%% Add required paths
addpath('../lib')
addLASLibPaths();
close all

%% Read LAS-File for query points
mpath = mfilename('fullpath');
[path,~,~] = fileparts(mpath);
lasFilePath = fullfile(path, 'sample.las');
fprintf('     Reading File: %s\n', lasFilePath);

% Read the sample file
pcloud = readLASfile(lasFilePath);

%% Create query polygon by approximating a circle
fprintf('     Create Polygon...\n');
vertexNumberToCircleScale = numberOfVertices/360;
polyX = mean(pcloud.x) + (sind((1:numberOfVertices)/11) * 0.2)';
polyY = mean(pcloud.y) + (cosd((1:numberOfVertices)/11) * 0.2)';

%% Find points in polygon
fprintf('     Find points in circle approximating polygon...\n');
tic;
isInside = isPointInPolygon(polyX, polyY, pcloud.x, pcloud.y, 1);
t1 = toc;

fprintf('     Number of vertices of polygon: %d points\n', length(polyX));
fprintf('     Number of points in polygon: %d of %d points\n', sum(isInside), length(isInside));

figure; 
plot(polyX, polyY, '-b'), hold on
plot(pcloud.x(~isInside), pcloud.y(~isInside), '.r');
plot(pcloud.x(isInside), pcloud.y(isInside), '.g');
axis equal
title('Find points in circle approximating Polygon')
xlabel('X-Coordinate [m]')
xlabel('Y-Coordinate [m]')
legend('Search Polygon', 'Points outside Polygon', 'Points inside Polygon')

%% Multi-threaded point search
fprintf('     Find points in polygon with multithreading and %d threads...\n\n', numberOfThreads);
t2 = toc;
isInside = isPointInPolygon(polyX, polyY, pcloud.x, pcloud.y, numberOfThreads);
t3 = toc-t2;

fprintf('     Execution Time (Single Threaded)\t\t\t: %6.1fms\n', t1*1000);
fprintf('     Execution Time (Multi Threaded) \t\t\t: %6.1fms\n', t3*1000);

%% Comparison to built-in matlab function
t4 = toc;
isInside = inpolygon(pcloud.x, pcloud.y, polyX, polyY);
t5 = toc-t4;

fprintf('     Execution Time (Built-In Matlab Function) \t: %6.1fms\n', t5*1000);
fprintf('-------------------------------------------------------------\n');