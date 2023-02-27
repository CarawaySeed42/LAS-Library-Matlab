% This script compiles the isPointInPolygon mex file
% Can be compiled with Microsoft Visual C++ 2019 (and likely newer)
% and latest MinGW-w64 Compiler. Tested on Windows 10 x64 platform!
% C++11 is minimum requirement! 
% If you use MinGW then you have to link the OpenMP library. See settings!
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
%       minGW_openMP_link  : Path to MinGW OpenMP lib on your PC 
%
% Advice: According to my testing MSVC should be preferred to MinGW.
%% ------------------------------------------------------------------------
% User Input
outdir = '../lib/mex';
debug = false;
UseInterleavedComplexAPI = false;
verbose = false;
parallel_computing = true;

minGW_openMP_link = 'C:\mingw64\lib\gcc\x86_64-w64-mingw32\12.2.0\libgomp.a';

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

% check compiler options for set compiler
CPPcompiler = mex.getCompilerConfigurations('C++','Selected');
compilerIsMinGW = strfind(lower(CPPcompiler.ShortName), lower('MinGW'));
if isempty(compilerIsMinGW)
    minGW_openMP_link = '';
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
fprintf(1, 'Compiler Input: %s\n', [minGW_openMP_link, ' ',interleaveOpts, ' ', verboseFlag, ' ', debugFlag, ' ', CFLAGS, ' ', ...
           'isPointInPolygon.cpp', ' ',' -outdir ',  outdir, ' -output ', outputname]);

% Compile File
mex(minGW_openMP_link, interleaveOpts, verboseFlag, debugFlag, CFLAGS, 'isPointInPolygon.cpp',...
    '-outdir', outdir, '-output', outputname)

fprintf('-------------------------------------------------------------\n');