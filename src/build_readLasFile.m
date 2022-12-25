% This script compiles the readLasFile mex file
% Can be compiled with Microsoft Visual C++ 2019 (and likely newer)
% and latest MinGW-w64 Compiler. Tested on Windows 10 x64 platform!
%
% Compiling with Interleaved Complex API is recommended but is only
% supported from Matlab 2018a onwards
% To compile without IC API, remove the -R2018a compiler option or use the
% provided option in this script
%
% The following settings are available which the user is free to change
%
% Settings:
%       outdir    : Output directory of mex file (Default is lib folder)
%       debug     : Set true if debug version should be compiled
%       UseInterleavedComplexAPI: Compile with Interleaved Complex API?
%       verbose            : Set true to show verbose compilation log
%       compiler_flags     : Additional compiler flags
%       useCompilerOptions : Should the set compiler flags be used?
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
    interleaveOpts = '-R2018a';  
end

combinedFlag = '';
if useCompilerFlags
    combinedFlag = ['COMPFLAGS=''$COMPFLAGS ' compiler_flags ''''];
end

% Print chosen options
fprintf(1, 'Compiler Input: %s\n', [interleaveOpts, ' ', verboseFlag, ' ', debugFlag, ' ', combinedFlag, ' ', 'readLasFile.cpp', ' ',...
           'LAS_IO.cpp', ' ', 'LasReader.cpp', ' ',  'VariableLengthRecords.cpp', ' ', 'LASAlloc.cpp', ' ',  '-outdir', ' ',  outdir]);

% Compile File
mex(interleaveOpts, verboseFlag, debugFlag, combinedFlag, 'readLasFile.cpp', 'LAS_IO.cpp',...
    'LasReader.cpp', 'VariableLengthRecords.cpp', 'LASAlloc.cpp', '-outdir', outdir)
