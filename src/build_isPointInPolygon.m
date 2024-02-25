% This script compiles the isPointInPolygon mex file
% Can be compiled with Microsoft Visual C++ 2017 (and likely newer)
% and latest MinGW-w64 Compiler Collection. 
% Tested on Windows 10 x64 platform! C++11 is minimum requirement! 
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
%       parallel_computing : Set OpenMP compiler flag for multithreading
%
%       minGW_openMP_link  : Path to MinGW OpenMP lib on your PC 
%
% Advice: According to my testing MSVC should be preferred to MinGW.
%% ------------------------------------------------------------------------
% User Input
outdir                   = '../lib/mex';
debug                    = false;
verbose                  = false;
UseInterleavedComplexAPI = true;
parallel_computing       = true;
useAddCompilerFlags      = false;
add_compiler_flags       = '-std=c++17';

minGW_openMP_link = 'C:\mingw64\lib\gcc\x86_64-w64-mingw32\12.2.0\libgomp.a';

%% -----------------------------------------------------------------------
fprintf('-------------------------------------------------------------\n');

% Name of the output file
outputname = 'isPointInPolygon_cpp';

% The compiler flags
flags = {};

% Translate user settings to compiler options
% check compiler options for set compiler
CPPcompiler     = mex.getCompilerConfigurations('C++','Selected');
compilerIsMinGW = strfind(lower(CPPcompiler.ShortName), lower('MinGW'));
if ~isempty(compilerIsMinGW)
    flags = cat(2, flags, minGW_openMP_link);
end

if parallel_computing
    if ispc
        % Flag to run on Windows platform
        flags = cat(2, flags, 'COMPFLAGS="$COMPFLAGS /openmp"');
    elseif isunix
        % Flag to run on Linux platform
        flags = cat(2, flags, '''$CFLAGS -fopenmp'' -LDFLAGS=''$LDFLAGS -fopenmp''');
    elseif ismac
        % Flag to run on Mac platform
        fprintf(1,'Mac platform not supported for parallel processing!');
    else
        fprintf(1,'Platform not supported');
    end
end

% Set interleaved complex
if UseInterleavedComplexAPI
    if ~verLessThan('matlab','9.4')
        flags = cat(2, flags, '-R2018a');
    else
        disp(['Compiling without Interleaved Complex API due to ',...
              'Matlab Version being older than 9.4']);
    end
end

if debug
    flags = cat(2, flags, '-g');
end

if verbose
    flags = cat(2, flags, '-v');
end

if useAddCompilerFlags
    flags = cat(2, flags, ['CXXFLAGS=$CXXFLAGS ' add_compiler_flags]);
end

% Add source files and output
flags = cat(2, flags, 'isPointInPolygon.cpp',...
            '-outdir',  outdir, '-output', outputname);

% Print chosen options (string joining was introduced with Matlab 2013b)
fprintf(1, 'Compiler Input: ');
fprintf('%s ', flags{:});
fprintf('\n');

% Compile File
mex(flags{:})

fprintf('-------------------------------------------------------------\n');