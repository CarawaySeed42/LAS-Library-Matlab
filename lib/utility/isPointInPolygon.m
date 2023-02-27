function isInside = isPointInPolygon(polyX, polyY, pointsX, pointsY, numThreads)
% isInside = isPointInPolygon(polyX, polyY, pointsX, pointsY, numThreads)
% 
% Finds 2D points inside and outside of a 2D polygon using the 
% Raycasting Algorithm.
% Supports multithreading that kicks in if more than 1e4 points or more
% than 150 polygon vertices are to be processed. The function has to be
% compiled with 'parallel_computing = true'. The number of threads can
% be specified, but they will automatically be limited to the number of
% available concurrent threads of the CPU, if the number is too big.
%
% Input:        polyX [nx1 double]  :	X-Coordinates of polygon vertices
%               polyY [nx1 double]  :	Y-Coordinates of polygon vertices
%               pointsX [nx1 double]:	X-Coordinates of query points
%               pointsY [nx1 double]:	Y-Coordinates of query points
%               numThreads [double] :   Max. number of threads used if
%                                       above threshold
% 
% Returns:      isInside [nx1 bool] :	true if point is inside,
%                                       false if point is outside poylgon
%			
% This file uses the extension .mexw64.
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
isInside = isPointInPolygon_cpp(polyX, polyY, pointsX, pointsY, numThreads);
end