/*%==========================================================
% readLas2Struct.mexw64 - MEX-File
% lasStruct = readLasFile(lasFilePath)
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
#include "LAS_IO.hpp"

/* The gateway function. */
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

	/* Check for proper number of arguments */
	if (nrhs != 1 && nrhs != 2) {
		mexErrMsgIdAndTxt("MEX:readLasFile:nargin", "This function allows one or two input arguments!");
	}
	if (nlhs != 1) {
		mexErrMsgIdAndTxt("MEX:readLasFile:nargout", "This function allows exactly one output argument");
	}

	/* Check if the input is of proper type and determine input options if given */
	// Flag if reading of the file should stop after header or Variable Length Records
	bool loadOnlyHeader = false;
	bool returnAfterVLR = false;
	bool XYZIntOnly = false;

	if (!mxIsChar(prhs[0])) { // is not char array
		mexErrMsgIdAndTxt("MEX:readLasFile:typeargin", "Argument has to be path to LAS-File as char array!");
	}

	if (nrhs == 2) { // if second argument given

		if (mxIsChar(prhs[1])) { // If second argument is char array

			char* optionalArgument = mxArrayToString(prhs[1]);

			if (std::strcmp(optionalArgument, "LoadOnlyHeader") == 0)
			{
				loadOnlyHeader = true;
			}
			else if (std::strcmp(optionalArgument, "XYZInt") == 0)
			{
				XYZIntOnly = true;
			}
			else if (std::strcmp(optionalArgument, "VLR") == 0)
			{
				returnAfterVLR = true;
			}
			else if (std::strcmp(optionalArgument, "LoadAll") != 0)
			{
				mxFree(optionalArgument);
				mexErrMsgIdAndTxt("MEX:readLasFile:valueargin", "The entered second argument is not a valid option/command!");
			}

			mxFree(optionalArgument);
		}
		else
		{
			mexErrMsgIdAndTxt("MEX:readLasFile:typeargin", "If second Argument is given then it has to be a char array!");
		}
	}

	// Get Path from input and open file
	char* filePath = mxArrayToString(prhs[0]);

	std::ios_base::sync_with_stdio(false);
	std::ifstream lasBin;
	lasBin.rdbuf()->pubsetbuf(0, 0);						
	lasBin.open(filePath, std::ios::in | std::ios::binary);	// Open File
	mxFree(filePath);										// Deallocate memory of path after opening file because it is not needed anymore

	if (lasBin.is_open()) {
		try {
			// Initialize instance of lasDataReader class
			LASdataReader lasReader;

			// Read Header and then check it
			lasReader.ReadLASheader(lasBin);
			bool headerGood = lasReader.CheckHeaderConsistency(lasBin);

			// Create Output Structure
			lasReader.InitializeOutputStructure(plhs[0], lasBin);

			// Fill Header of output Structure
			lasReader.PopulateStructureHeader(lasBin);

			// If load only header chosen or header is bad then return
			if (loadOnlyHeader || !headerGood) {
				if (lasBin.is_open()) { lasBin.close(); }
				return; 
			} 

			// Read Variable Length Records if they are present
			if (lasReader.HasVLR())
			{
				lasReader.ReadVLR(plhs[0], lasBin);
			}

			// If specified then return after loading VLRs
			if (returnAfterVLR) {
				if (lasBin.is_open()) { lasBin.close(); }
				return;
			}

			// Allocate and read XYZ and intensity only, if specified
			if (XYZIntOnly) {
				lasReader.SetReadXYZIntOnly(XYZIntOnly);
			}

			// Allocate Rest of the Point Data if load only header is not chosen
			lasReader.AllocateOutputStructure(plhs[0], lasBin);

			// Read Las Data
			lasReader.ReadPointData(lasBin);

			// Read Extended Variable Length Records if they are present
			if (lasReader.HasExtVLR())
			{
				lasReader.ReadExtVLR(plhs[0], lasBin);
			}
		}
		catch (const std::bad_alloc& ba) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:readLasFile:bad_alloc", ba.what());
		}
		catch (const std::exception& ex) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:readLasFile:Exception", ex.what());
		}
		catch (...) {
			if (lasBin.is_open()) { lasBin.close(); }
			mexErrMsgIdAndTxt("MEX:readLasFile:unhandledException", "Unhandled Exception occured");
		}
	}
	else
	{
		mexErrMsgIdAndTxt("MEX:readLasFile:invalidArgumentException", "File could not be opened!");
	}

	// Close file
	if (lasBin.is_open()) 
	{ 
		lasBin.close();
	}
};
