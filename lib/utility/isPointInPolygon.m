function isInside = isPointInPolygon(polyX, polyY, pointsX, pointsY, numThreads, algorithm)
% isInside = isPointInPolygon(polyX, polyY, pointsX, pointsY, numThreads, algorithm)
% 
% Finds 2D points inside and outside of a 2D polygon. 
% Maximum point count for query points and polygon is 2^31-1.
%
% Different algorithms can be chosen. Standard is the winding number
% algorithm. Points on the border do not count as inside but there is an
% option to treat points on the border as inside (see Input)
%
% Supports multithreading that kicks in if more than 1e4 points or more
% than 150 polygon vertices are to be processed. The function has to be
% compiled with 'parallel_computing = true'. The number of threads can
% be specified, but they will automatically be limited to the number of
% available concurrent threads of the CPU, if the number is too big.
% Number of threads will be set to max available threads if input is zero
%
% Input:        polyX [nx1 float]  :	X-Coordinates of polygon vertices
%               polyY [nx1 float]  :	Y-Coordinates of polygon vertices
%               pointsX [nx1 float]:	X-Coordinates of query points
%               pointsY [nx1 float]:	Y-Coordinates of query points
%               numThreads [double] :   Max. number of threads used if
%                                       above threshold (default is 1)
%               algorithm [int]     :   0 == Winding Number (default)
%                                       1 == WN but edges count inside
%                                       2 == Ray Casting
% 
% Returns:      isInside [nx1 bool] :	true if point is inside,
%                                       false if point is outside poylgon
%			
% This called mex file uses the extension .mexw64.
% Originally built in Matlab 2019b with MSVC 2019
%
% Source:		 isPointInPolygon.cpp
%
% Created by Patrick Kuemmerle
% 
% Hint: The specified number of threads are only used if there are more
% than 10000 points or more than 150 vertices. Those are hardcoded
% thresholds to avoid searching in a tiny polygon and with only a few points
% with multiple threads. The thread creating and thread scheduling makes
% this a lot slower than single threaded. The selected thresholds are
% semi-arbitrary because there is no select number of points or vertices
% where multi-threading is faster than single threaded. But it is chosen in
% a way, that if both are below the threshold then single-threaded will
% basically always be faster. 
if nargin < 5
    numThreads = 1;
end
if nargin < 6
    algorithm = 0;
end

% If input is neither fully double or single then cast to double
isNotFloatingPoint = ...
    ~(all([isa(polyX, 'double'), isa(polyY, 'double'),...
           isa(pointsX, 'double'), isa(pointsY, 'double')]) |...
      all([isa(polyX, 'single'), isa(polyY, 'single'),...
           isa(pointsX, 'single'), isa(pointsY, 'single')]));
       
if isNotFloatingPoint
    polyX   = double(polyX);
    polyY   = double(polyY);
    pointsX = double(pointsX);
    pointsY = double(pointsY);
end

isInside = isPointInPolygon_cpp(polyX, polyY, pointsX, pointsY, numThreads, algorithm);
end