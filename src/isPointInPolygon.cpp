#include "mex.h"
#include <stdio.h> // standard input/output
#include <vector> // stl vector header
#include <thread>
#include <omp.h>

#if MX_HAS_INTERLEAVED_COMPLEX

#define GetLogicals	mxGetLogicals

#else

#define GetLogicals	(mxLogical*)mxGetPr

#endif

inline bool isPointInPolygon(const double* polyX, const double* polyY, const double& pointX, const double& pointY, const int& polyCount);

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {

	int i;
	const double* polyX, * polyY, * pointsX, * pointsY;
	polyX = polyY = pointsX = pointsY = nullptr;
	int numberOfThreads = 1;

	if (nrhs != 4 && nrhs != 5) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:nargin", "This function allows four or five input arguments!");
	}
	if (nlhs > 1) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:nargout", "This function allows exactly one output argument");
	}

	if (!mxIsNumeric(prhs[0]) || !mxIsNumeric(prhs[1]) || !mxIsNumeric(prhs[2]) || !mxIsNumeric(prhs[3])) { 
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:typeargin", "First four arguments have to be numeric!");
	}

	if (mxIsComplex(prhs[0]) || mxIsComplex(prhs[1]) || mxIsComplex(prhs[2]) || mxIsComplex(prhs[3])) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:typeargin", "Arguments are not allowed to be complex!");
	}

	// Set number if threads according to argument or available threads, depending on which is smaller
	if (nrhs == 5) {
		const int machine_num_threads	= std::thread::hardware_concurrency();
		numberOfThreads					= (numberOfThreads < machine_num_threads) ? static_cast<int>(mxGetScalar(prhs[4])) : machine_num_threads;
		numberOfThreads					= numberOfThreads < 1 ? machine_num_threads : numberOfThreads;
	}

	// Get data sizes and check them
	size_t size_polyX	= mxGetNumberOfElements(prhs[0]);
	size_t size_polyY	= mxGetNumberOfElements(prhs[1]);
	size_t size_pointsX = mxGetNumberOfElements(prhs[2]);
	size_t size_pointsY = mxGetNumberOfElements(prhs[3]);

	if (size_polyX != size_polyY || size_polyX < 1) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:sizeargin", "Input polygon has to be of same size and larger than a size of zero!");
	}
	if (size_pointsX != size_pointsY || size_pointsX < 1) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:sizeargin", "Input points have to be of same size and larger than a size of zero!");
	}

	// Get Data
	polyX	= mxGetPr(prhs[0]);
	polyY	= mxGetPr(prhs[1]);
	pointsX	= mxGetPr(prhs[2]);
	pointsY	= mxGetPr(prhs[3]);

	// Check for nullptr
	if (polyX == nullptr || polyY == nullptr || pointsX == nullptr || pointsY == nullptr) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:argin", "Can't get a valid pointer to all of the the input data!");
	}

	// Allocate Output
	plhs[0] = mxCreateLogicalMatrix(size_pointsX, 1);
	mxLogical* result = mxGetLogicals(plhs[0]);

	// Chunksize is chosen in a way that every thread gets 50 chunks, this might help to distribute the load a little bit
	const int threadChunksize = static_cast<int>((size_pointsX / (static_cast<size_t>(numberOfThreads)*50)) + 1); 
	omp_set_num_threads(numberOfThreads);

#pragma omp parallel for schedule(dynamic, threadChunksize) default(shared) if (size_pointsX > 10000 || size_polyX > 150)
	for (i = 0; i < size_pointsX; i++) 
	{
		result[i] = isPointInPolygon(polyX, polyY, pointsX[i], pointsY[i], size_polyX);
	}	
}


inline bool isPointInPolygon(const double* const polyX, const double* const polyY, const double& pointX, const double& pointY, const int& polyCount)
{
	bool inside = false;

	for (int i = 0, j = polyCount - 1; i < polyCount; i++) { 
		if (((polyY[i] > pointY) != (polyY[j] > pointY)) 
			&& (pointX < (polyX[j] - polyX[i]) * (pointY - polyY[i]) / (polyY[j] - polyY[i]) + polyX[i])) 
		{
			// Invert inside
			inside = !inside;
		}
		j = i;
	}

	return inside;
}