% This script compiles the readLasFile mex file
% Can be compiled with Microsoft Visual C++ 2019 (and likely newer)
% and latest MinGW-w64 Compiler. Tested on Windows 10 x64 platform!
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
%       outdir    : Output directory of mex file (Default is lib folder)
%       debug     : Set true if debug version should be compiled
%       UseInterleavedComplexAPI: Set true to compile with Interleaved Complex API
%       verbose            : Set true to show verbose compilation log
%       compiler_flags     : Additional compiler flags
%       useCompilerOptions : Set true to use the set compiler_flags
%
% Compilation example:
% mex -R2018a readLasFile.cpp LAS_IO.cpp LasReader.cpp
% VariableLengthRecords.cpp LASAlloc.cpp -outdir ../lib
%
%% ------------------------------------------------------------------------
% User Input
outdir = '../lib';
debug = false;
UseInterleavedComplexAPI = true;
verbose = false;
compiler_flags = '-std=c++17';
useCompilerFlags = false;

%% -----------------------------------------------------------------------
fprintf('-------------------------------------------------------------\n');
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

combinedFlag = '';
if useCompilerFlags
    combinedFlag = ['CXXFLAGS=$CXXFLAGS ' compiler_flags];
end

% Print chosen options
fprintf(1, 'Compiler Input: %s\n', [interleaveOpts, ' ', verboseFlag, ' ', debugFlag, ' ', combinedFlag, ' ', 'readLasFile.cpp', ' ',...
           'LAS_IO.cpp', ' ', 'LasReader.cpp', ' ',  'VariableLengthRecords.cpp', ' ', 'LASAlloc.cpp', ' ',  '-outdir', ' ',  outdir]);

% Compile File
mex(interleaveOpts, verboseFlag, debugFlag, combinedFlag, 'readLasFile.cpp', 'LAS_IO.cpp',...
    'LasReader.cpp', 'VariableLengthRecords.cpp', 'LASAlloc.cpp', '-outdir', outdir)

fprintf('-------------------------------------------------------------\n');