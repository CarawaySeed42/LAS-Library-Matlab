% This script compiles the writeLasFile mex file
% Can be compiled with Microsoft Visual C++ 2017 (and likely newer)
% and latest MinGW-w64 Compiler Collection. 
% Tested on Windows 10 x64 platform! C++11 is minimum requirement!
% Other compilers will probably work but have not been tested.
% For available compilers enter the folling into the matlab command window:
%   mex -setup cpp
%
% Compiling with Interleaved Complex API is recommended but is only
% supported from Matlab 2018a onwards
% To compile without IC API, remove the -R2018a compiler option or use the
% provided option when using this script
%
% The following settings are available which the user is free to change
%
% Settings:
%       outdir    : Output directory of mex file (Default is lib/mex folder)
%       debug     : Set true if debug version should be compiled
%       UseInterleavedComplexAPI: Set true to compile with Interleaved Complex API
%       verbose            : Set true to show verbose compilation log
%       compiler_flags     : Additional compiler flags
%       useAddCompilerFlags : Set true to use the set compiler_flags
%
% Compilation example:
% mex -R2018a writeLASfile_cpp.cpp LASWriter.cpp
% VariableLengthRecords.cpp -outdir ../lib/mex
%
%% ------------------------------------------------------------------------
% User Input
outdir                   = '../lib/mex';
debug                    = false;
UseInterleavedComplexAPI = true;
verbose                  = false;
useAddCompilerFlags      = false;
compiler_flags           = '-std=c++17';

%% -----------------------------------------------------------------------
fprintf('-------------------------------------------------------------\n');

% include folder without and with path separator
includeFolder = 'include';
relIncPath    = [includeFolder filesep];

% Name of the output file
outputname = 'writeLASfile_cpp';

% The compiler flags
flags = {};

% Translate user settings to compiler options
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

includePath = sprintf('-I"%s"', includeFolder);
flags = cat(2, flags, includePath);

if useAddCompilerFlags
    flags = cat(2, flags, ['CXXFLAGS=$CXXFLAGS ' compiler_flags]);
end

flags = cat(2, flags, 'writeLASfile_cpp.cpp', [relIncPath, 'LASWriter.cpp'],  ...
    [relIncPath, 'VariableLengthRecords.cpp'], '-outdir',  outdir, '-output', outputname);

% Print chosen options (string joining was introduced with Matlab 2013b)
fprintf(1, 'Compiler Input: ');
fprintf('%s ', flags{:});
fprintf('\n');

% Compile File
mex(flags{:})

fprintf('-------------------------------------------------------------\n');