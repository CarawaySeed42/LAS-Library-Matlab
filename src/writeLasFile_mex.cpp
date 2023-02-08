/*%==========================================================
% readLas2Struct.mexw64 - MEX-File
% lasStruct = writeLASFile_mex(las, filename, majorversion, minorversion, pointformat)
% lasStruct = readLasFile(lasFilePath, optsString)
% 
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
% optsString:   'LoadOnlyHeader' - Fill only header struct
%				'VLR'			 - Get header and variable length records
%								   Does not include extended VLRs
%               'LoadAll'        - Loads all of the point data
%                                  (same as with only one given input)
% 
% Output:       lasStruct [struct]:         lasdata style struct
%			
%
% This function uses the extension .mexw64.
% Originally built in Matlab 2019b with Microsoft Visual C++ 2019
%
% Source: readLasFile.cpp LAS_IO.cpp LasReader.cpp VariableLengthRecords.cpp
% To rebuild this function run the provided script 'make_readLasFile.m'
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
% 
%========================================================*/


#include "mex.h"
#include <fstream>
#include <cstring>
#include "LAS_IO.cpp"


/* The gateway function. */
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

	/* Check for proper number of arguments */
	if (nrhs < 2) {
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:nargin", "Two or three input arguments required!");
	}
	if (nrhs > 3) {
		mexWarnMsgIdAndTxt("MEX:writeLASFile_mex:nargin", "More than three arguments provided! Extra arguments will be ignored!");
	}
	if (nlhs > 1) {
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:nargout", "One or no output argument required");
	}

	if (!mxIsChar(prhs[1])) { // is not char array
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:typeargin", "Second argument has to be path to target LAS-File as char array!");
	}

	/*
	if (nrhs > 2) {
		if (!mxIsLogical(prhs[2])) { // is not char array
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:typeargin", "Third argument has to be logical!");
		}

		autodetect = *mxGetLogicals(prhs[2]);
	}
	*/

	// Get Path from input and open file
	char* filePath = mxArrayToString(prhs[1]);
	std::ofstream lasBin(filePath, std::ios::out | std::ios::binary);
	mxFree(filePath);										// Deallocate memory of path after opening file because it is not needed anymore

	if (lasBin.is_open()) {
		try {
			// Initialize instance of lasDataWriter class
			LasDataWriter lasWriter;

			lasWriter.GetData(plhs);
			lasWriter.WriteLASheader(lasBin);

			// Read Write point cloud info to header
			//lasWriter.fillHeader_with_CloudInfo(pcPointer);

			/*if (enforceDataFormat) {
				lasWriter.PointDataRecordFormat = pointDataFormat;
			}
			else {
				pointDataFormat = lasWriter.determinePointDataFormat(pcPointer);
				lasWriter.PointDataRecordFormat = pointDataFormat;
			}

			RhinoApp().SetCommandPromptMessage(L"Write Point Cloud...");
			RhinoApp().Wait(0);

			lasWriter.writeLasHeader(lasBin);
			lasWriter.writePointData(lasBin, pcPointer, maxThreadCount);*/

			lasBin.close();
		}
		catch (const std::bad_alloc& ba) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:bad_alloc", ba.what());
		}
		catch (const std::exception& ex) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:Exception", ex.what());
		}
		catch (...) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:unhandledException", "Unhandled Exception occured");
		}
	}
	else
	{
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:invalidArgumentException", "File could not be opened for writing");
	}

	if (lasBin.is_open()) {
		lasBin.close();
	}

};
