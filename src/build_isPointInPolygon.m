% This script compiles the isPointInPolygon mex file
% Can be compiled with Microsoft Visual C++ 2019 (and likely newer)
% and latest MinGW-w64 Compiler. Tested on Windows 10 x64 platform!
% C++11 is minimum requirement!
% Other compilers will probably work but have not been tested.
% For available compilers enter the folling into the matlab command window:
%   mex -setup cpp
%
% The following settings are available which the user is free to change
%
% Settings:
%       outdir    : Output directory of mex file (Default is lib/mex folder)
%       debug     : Set true if debug version should be compiled
%       UseInterleavedComplexAPI: Set true to compile with Interleaved Complex API
%       verbose            : Set true to show verbose compilation log
%       parallel_computing : Set OpenMP compiler flag for parfor?
%
%
%% ------------------------------------------------------------------------
% User Input
outdir = '../lib/mex';
debug = false;
UseInterleavedComplexAPI = false;
verbose = false;
parallel_computing = true;

%% -----------------------------------------------------------------------
fprintf('-------------------------------------------------------------\n');
% Name of the output file
outputname = 'isPointInPolygon_cpp';

% Translate user settings to compiler options
debugFlag = '';
if debug
    debugFlag = '-g';
end

verboseFlag = '';
if verbose
    verboseFlag = '-v';
end

interleaveOpts = '';
if UseInterleavedComplexAPI
    if ~verLessThan('matlab','9.4')
        interleaveOpts = '-R2018a';
    else
        disp(['Compiling without Interleaved Complex API due to ',...
              'Matlab Version being older than 9.4']);
    end
end

CFLAGS = '';
if parallel_computing
    if ismac
        % Flag to run on Mac platform
        fprintf(1,'Mac platform not supported for parallel processing!');
    elseif isunix
        % Flag to run on Linux platform
        CFLAGS='''$CFLAGS -fopenmp'' -LDFLAGS=''$LDFLAGS -fopenmp''';
    elseif ispc
        % Flag to run on Windows platform
        CFLAGS = 'COMPFLAGS="$COMPFLAGS /openmp"';
    else
        fprintf(1,'Platform not supported');
    end
end

% Print chosen options
fprintf(1, 'Compiler Input: %s\n', [interleaveOpts, ' ', verboseFlag, ' ', debugFlag, ' ', CFLAGS, ' ', 'isPointInPolygon.cpp', ' ',...
           ' -outdir ',  outdir, ' -output ', outputname]);

% Compile File
mex(interleaveOpts, verboseFlag, debugFlag, CFLAGS, 'isPointInPolygon.cpp',...
    '-outdir', outdir, '-output', outputname)

fprintf('-------------------------------------------------------------\n');