#include "mex.h"
#include <thread>
#include <omp.h>

#if MX_HAS_INTERLEAVED_COMPLEX

#define GetLogicals	mxGetLogicals

#else

#define GetLogicals	(mxLogical*)mxGetPr

#endif

inline bool raycast(const double* __restrict  polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount);
inline bool windingNumber(const double* __restrict polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount);
inline bool windingNumberIncludeBorder(const double* __restrict polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount);
inline void windingNumberIncludeBordersss(const double *polyX, const double *polyY, const double *pointX, const double *pointY, const size_t polyCount, const size_t pointCount, const size_t threadCount, mxLogical*& result);

template<typename T>
inline T isLeft(const T polyX_1, const T polyY_1, const T polyX_2, const T polyY_2, const T queryX, const T queryY);

enum searchAlgorithm { WindingNumber, WindingNumberWithBorders, Raycast };

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) 
{

	const double* __restrict polyX, * polyY, * pointsX, * pointsY;	// Pointer to input data
	polyX = polyY = pointsX = pointsY = nullptr;					
	int numberOfThreads = 1;										// Number of processing threads
	int algorithmInput = WindingNumber;								// Standard algorithm is winding number without including borders
	
	if (nrhs < 4 || nrhs > 6) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:nargin", "This function allows four to six input arguments!");
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
	if (nrhs > 4) {
		const int machine_num_threads	= std::thread::hardware_concurrency();
		numberOfThreads					= (numberOfThreads < machine_num_threads) ? static_cast<int>(mxGetScalar(prhs[4])) : machine_num_threads;
		numberOfThreads					= numberOfThreads < 1 ? machine_num_threads : numberOfThreads;
	}

	if (nrhs > 5) {
		algorithmInput = static_cast<int>(mxGetScalar(prhs[5]));
	}

	// Get data sizes and check them
	const size_t size_polyX	= mxGetNumberOfElements(prhs[0]);	// Number of Polygon X - Coordinates
	const size_t size_polyY	= mxGetNumberOfElements(prhs[1]);	// Number of Polygon Y - Coordinates
	const size_t size_pointsX = mxGetNumberOfElements(prhs[2]);	// Number of Point Data X - Coordinates
	const size_t size_pointsY = mxGetNumberOfElements(prhs[3]); // Number of Point Data Y- Coordinates

	if (size_polyX != size_polyY || size_polyX < 1) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:sizeargin", "Input polygon has to be of same size and larger than a size of zero!");
	}
	if (size_pointsX != size_pointsY || size_pointsX < 1) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:sizeargin", "Input points have to be of same size and larger than a size of zero!");
	}

	// If input cloud or polygon has more than INT32_MAX points then cancel, because not implemented
	if (size_pointsX > INT32_MAX || size_polyX > INT32_MAX) {
		mexErrMsgIdAndTxt("MEX:isPointInPolygon:sizeargin", "Input with more elements than %d not implemented!", INT32_MAX);
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

	/*Run Point in Poly algorithm*/ 
	const int threadChunksize = static_cast<int>((size_pointsX / (numberOfThreads * 50)) + 1);
	omp_set_num_threads(static_cast<int>(numberOfThreads));

	if (algorithmInput == WindingNumberWithBorders)
	{
#pragma omp parallel for schedule(dynamic, threadChunksize) default(shared) if (size_pointsX > 10000 || size_polyX > 150)
		for (int i = 0; i < size_pointsX; ++i) {
			result[i] = windingNumberIncludeBorder(polyX, polyY, pointsX[i], pointsY[i], size_polyX);
		}
	}
	else if (algorithmInput == Raycast)
	{
#pragma omp parallel for schedule(dynamic, threadChunksize) default(shared) if (size_pointsX > 10000 || size_polyX > 150)
		for (int i = 0; i < size_pointsX; ++i) {
			result[i] = raycast(polyX, polyY, pointsX[i], pointsY[i], size_polyX);
		}
	}
	else
	{
#pragma omp parallel for schedule(dynamic, threadChunksize) default(shared) if (size_pointsX > 10000 || size_polyX > 150)
		for (int i = 0; i < size_pointsX; ++i) {
			result[i] = windingNumber(polyX, polyY, pointsX[i], pointsY[i], size_polyX);
		}
	}
	
}

// Tests if point is in polygon using the raycast algorithm
//	Returns: true if point inside polygon, false if otherwise
inline bool raycast(const double* __restrict polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount)
{
	bool inside = false;

	for (int i = 0, j = polyCount - 1; i < polyCount; j = i++) {
		if (((polyY[i] > pointY) != (polyY[j] > pointY)) 
			&& (pointX < (polyX[j] - polyX[i]) * (pointY - polyY[i]) / (polyY[j] - polyY[i]) + polyX[i])) 
		{
			// Invert inside
			inside = !inside;
		}
	}

	return inside;
}

// Tests if the winding number for a query point and a polygon is unequal to zero. 
// If so then the point is fully inside the polygon
//	Returns: true if point inside polygon, false if otherwise
inline bool windingNumber(const double* __restrict polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount)
{
	int winding_num = 0;  // the  winding number counter

	for (int i = 0, j = polyCount - 1; i < polyCount; j = i++)
	{
		if (polyY[j] <= pointY) {

			if (pointY < polyY[i]) {
				if (isLeft(polyX[j], polyY[j], polyX[i], polyY[i], pointX, pointY) > 0)
				{
					// If point on the right then increase winding number
					++winding_num;
				}
			}
		}
		else { // Ray crosses an downwards line
			if (polyY[i] <= pointY) {
				if (isLeft(polyX[j], polyY[j], polyX[i], polyY[i], pointX, pointY) < 0)
				{
					// If point on the right then decrease winding number
					--winding_num;
				}
			}
		}
	}
	return winding_num != 0;  // Only if winding_num is 0 then point is outside polygon
};

// Tests if the winding number for a query point and a polygon is unequal to zero or if point is on border
// If so then the point is fully inside the polygon
//	Returns: true if point inside polygon or on border, false if otherwise
inline bool windingNumberIncludeBorder(const double* __restrict polyX, const double* __restrict polyY, const double& pointX, const double& pointY, const int& polyCount)
{
	int winding_num = 0;  // the  winding number counter

	for (int i = 0, j = polyCount - 1; i < polyCount; j = i++)
	{
		if (polyX[i] == pointX && polyY[i] == pointY)
		{
			winding_num = 1;
			break;
		}

		// Early continue if ray does not intersect the segment
		if (!((polyY[i] > pointY) != (polyY[j] > pointY)))
			continue;

		const double& sideOfLine = isLeft(polyX[j], polyY[j], polyX[i], polyY[i], pointX, pointY);

		// Check if the point lies on the polygon.
		if (sideOfLine == 0)
		{
			winding_num = 1;
			break;
		}

		if (polyY[j] <= pointY) {

			if (pointY < polyY[i]) {
				if (sideOfLine > 0)
				{
					// If point on the right then increase winding number
					++winding_num;
				}
			}
		}
		else { // Ray crosses an downwards line
			if (polyY[i] <= pointY) {
				if (sideOfLine < 0)
				{
					// If point on the right then decrease winding number
					--winding_num;
				}
			}
		}
	}
	return winding_num != 0;  // Only if winding_num is 0 then point is outside polygon
};

// Tests if a point is Left, Right or On a line
//    Input:  X and Y of first and second point of line, X and Y of query point
//    Returns: >0 if query point is left of the line
//             =0 if query point is on the line
//             <0 if query point is right of the line
template<typename T>
inline T isLeft(const T polyX_1, const T polyY_1, const T polyX_2, const T polyY_2, const T queryX, const T queryY)
{
	return (queryY - polyY_1) * (polyX_2 - polyX_1) - (queryX - polyX_1) * (polyY_2 - polyY_1);
};