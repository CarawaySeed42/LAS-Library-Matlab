function lasStruct = readLASfile(lasFilePath, optsString)
% function lasStruct = readLasFile(lasFilePath)
% or       lasStruct = readLasFile(lasFilePath, optsString)
% 
% Supports Versions LAS 1.1 - 1.4
% Supports Point Data Record Format 0 to 10. Partially supports other PDRF.
%
% Reads LAS-File data with the help of a C++ Mex-File into a lasdata style
% struct. The resulting struct has the similar layout as the lasdata fields
% with some exceptions. E.g. The creation day of year is not a struct anymore.
% Extended Variable Length Records' size after header keeps the same
% field name as the field for the not extended VLRs, ...
%
% For info on lasdata see the matlab class lasdata by Teemu Kumpumäki
%
% Some informations still have to be decoded (like extra bytes)
% which is not the purpose of this reader. So they are read but not decoded
%
% Input:        lasFilePath [char array]:	Full Path to LAS-File
% (optional)    optsString  [char array]:   Optional input option string
%
% optsString:   'LoadOnlyHeader' - Fill header struct only
%               'VLR'			 - Get header and variable length records
%                                  Does not include extended VLRs
%               'XYZInt'         - Loads header, VLR, X, Y, Z and intensities
%               'LoadAll'        - Loads all of the point data
%                                  (same as with only one given input)
% 
% Output:       lasStruct [struct]:         lasdata style struct
%			
%
% This function uses the extension .mexw64.
% Originally built in Matlab 2019b with Microsoft Visual C++ 2019
%
% Source: readLasFile.cpp LAS_IO.cpp LasReader.cpp
%         VariableLengthRecords.cpp  LASAlloc.cpp
% To rebuild this function run the provided script 'build_readLasFile.m'
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
% 
%========================================================
if nargin == 1
    optsString = 'LoadAll'; 
end
lasStruct = readLASfile_cpp(char(lasFilePath), optsString);