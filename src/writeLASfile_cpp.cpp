/*%==========================================================
% writeLASfile_cpp.cpp
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
%
%========================================================*/
#include "mex.h"
#include <fstream>
#include "LAS_IO.hpp"


/* The gateway function. */
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

	/* Check for proper number of arguments */
	if (nrhs < 2) {
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:nargin", "Two input arguments required!");
	}
	if (nrhs > 3) {
		mexWarnMsgIdAndTxt("MEX:writeLASFile_mex:nargin", "More than three arguments provided! Extra arguments will be ignored!");
	}
	if (nlhs > 0) {
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:nargout", "This function does not return any output arguments");
	}

	if (!mxIsChar(prhs[1])) { // is not char array
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:typeargin", "Second argument has to be path to target LAS-File as char array!");
	}

	if (!mxIsStruct(prhs[0])) {
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:typeargin", "First argument has to be a LAS struture!");
	}

	// Get Path from input and open file
	char* filePath = mxArrayToString(prhs[1]);
	std::ofstream lasBin(filePath, std::ios::out | std::ios::binary);
	mxFree(filePath);										// Deallocate memory of path after opening file because it is not needed anymore

	if (lasBin.is_open()) {
		try {
			// Initialize instance of lasDataWriter class
			LASdataWriter lasWriter;

			lasWriter.GetHeader(prhs[0]);
			lasWriter.WriteLASheader(lasBin);

			if (lasWriter.HasVLR()) {
				lasWriter.WriteVLR(lasBin, prhs[0]);
			}
				
			lasWriter.GetData(prhs[0]);
			lasWriter.WriteLASdata(lasBin);

			if (lasWriter.HasExtVLR())
			{
				lasWriter.WriteExtVLR(lasBin, prhs[0]);
			}

			lasBin.close();
		}
		catch (const std::bad_alloc& ba) {
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:bad_alloc", ba.what());
		}
		catch (const std::ofstream::failure(&of)) {
			mexErrMsgIdAndTxt("MEX:writeLASFile_mex:ofstreamfailure", of.what());
		}
	}
	else
	{
		mexErrMsgIdAndTxt("MEX:writeLASFile_mex:invalidArgumentException", "File could not be opened for writing");
	}
};
