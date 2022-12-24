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
%       compiler_flags: Additional compiler flags
%       useCompilerOptions: Should the set compiler flags be used?
%
% Alternative compilation call example:
% mex -R2018a readLasFile.cpp LAS_IO.cpp LasReader.cpp
% VariableLengthRecords.cpp LASAlloc.cpp -outdir ../lib
%
%%------------------------------------------------------------------------

outdir = '../lib';
debug = false;
UseInterleavedComplexAPI = true;
compiler_flags = '-std=c++17';
useCompilerFlags = false;

%% -----------------------------------------------------------------------

debugFlag = '';
if debug
    debugFlag = '-g';
end

interleaveOpts = '';
if UseInterleavedComplexAPI
    interleaveOpts = '-R2018a';  
end

combinedFlag = '';
if useCompilerFlags
    combinedFlag = ['COMPFLAGS=''$COMPFLAGS ' compiler_flags ''''];
end

fprintf(1, 'Compiler Input: %s\n', [interleaveOpts, ' ', debugFlag, ' ', combinedFlag, ' ', 'readLasFile.cpp', ' ',...
           'LAS_IO.cpp', ' ', 'LasReader.cpp', ' ',  'VariableLengthRecords.cpp', ' ', 'LASAlloc.cpp', ' ',  '-outdir', ' ',  outdir]);

% Compile File
mex(interleaveOpts, debugFlag, combinedFlag, 'readLasFile.cpp', 'LAS_IO.cpp',...
    'LasReader.cpp', 'VariableLengthRecords.cpp', 'LASAlloc.cpp', '-outdir', outdir)
