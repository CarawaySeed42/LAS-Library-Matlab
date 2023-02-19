#include "LAS_IO.cpp"
#include <cstring>
#include <memory>

#if MX_HAS_INTERLEAVED_COMPLEX

#define GetDoubles	mxGetDoubles
#define GetSingles	mxGetSingles
#define GetChars	mxGetChars
#define GetUint8	mxGetUint8s
#define GetInt8		mxGetInt8s
#define GetUint16	mxGetUint16s
#define GetInt16	mxGetInt16s
#define GetUint32	mxGetUint32s
#define GetInt32	mxGetInt32s
#define GetUint64	mxGetUint64s
#define GetInt64	mxGetInt64s

#else

#define GetDoubles	(mxDouble*) mxGetPr
#define GetSingles	(mxSingle*) mxGetPr
#define GetChars	(mxChar*)   mxGetPr
#define GetUint8	(mxUint8*)  mxGetPr
#define GetInt8		(mxInt8*)	mxGetPr
#define GetUint16	(mxUint16*) mxGetPr
#define GetInt16	(mxInt16*)	mxGetPr
#define GetUint32	(mxUint32*) mxGetPr
#define GetInt32	(mxInt32*)	mxGetPr
#define GetUint64	(mxUint64*) mxGetPr
#define GetInt64	(mxInt64*)	mxGetPr

#endif

void LasDataReader::InitializeOutputStruct(mxArray*& plhs, std::ifstream& lasBin)
{
	try
	{
		/*struct variable name */
		const char* struct_field_names[] = { "header", "x", "y", "z","intensity", "bits", "bits2", "classification", "user_data", "scan_angle",
			"point_source_id", "gps_time", "red", "green", "blue", "nir", "extradata", "Xt", "Yt", "Zt", "wave_return_point", "wave_packet_descriptor",
			"wave_byte_offset", "wave_packet_size", "variablerecords", "extendedvariables", "wavedescriptors" };
		mwSize dims[2] = { 1, 27 };

		// Create structure for output var
		plhs = mxCreateStructArray(1, dims, 27, struct_field_names);

		/* Allocate Header struct */
		const char* header_field_names[] = { "source_id", "global_encoding", "project_id_guid1", "project_id_guid2","project_id_guid3", "project_id_guid4", "version_major", "version_minor",
			"system_identifier", "generating_software", "file_creation_day_of_year", "file_creation_year", "header_size", "offset_to_point_data", "number_of_variable_records", "point_data_format",
			"point_data_record_length", "number_of_point_records", "number_of_points_by_return", "scale_factor_x", "scale_factor_y", "scale_factor_z",
			"x_offset", "y_offset", "z_offset", "max_x", "min_x", "max_y", "min_y", "max_z", "min_z" };
		mwSize dimsHeader[2] = { 1, 31 };

		m_mxStructPointer.pMXheader = mxCreateStructArray(1, dimsHeader, 31, header_field_names);
		mxSetField(plhs, 0, "header", m_mxStructPointer.pMXheader);

	}
	catch (const std::bad_alloc& ba) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:InitializeOutputStruct:bad_alloc", ba.what());
	}
	catch (const std::exception& ex) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:InitializeOutputStruct:Exception", ex.what());
	}
	catch (...) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:InitializeOutputStruct:UnhandledException", "Unhandled Exception occured");
	}
}

void LasDataReader::FillStructHeader(std::ifstream& lasBin)
{
	try {
		mxArray* pMXheader = m_mxStructPointer.pMXheader;	// pointer to matlab header struct
		mxArray* pMx;										// temporary pointer for data copy

		// Every Output will be double because ladata does the same, wastes memory but only for header entries
		mxSetField(pMXheader, 0, "source_id", mxCreateDoubleScalar((double)m_header.sourceID));
		mxSetField(pMXheader, 0, "global_encoding", mxCreateDoubleScalar((double)m_header.globalEncoding));
		mxSetField(pMXheader, 0, "project_id_guid1", mxCreateDoubleScalar((double)m_header.projectID_GUID_1));
		mxSetField(pMXheader, 0, "project_id_guid2", mxCreateDoubleScalar((double)m_header.projectID_GUID_2));
		mxSetField(pMXheader, 0, "project_id_guid3", mxCreateDoubleScalar((double)m_header.projectID_GUID_3));

		// Copy GUID4 to output as double array
		pMx = mxCreateDoubleMatrix(8, 1, mxREAL);
		mxSetField(pMXheader, 0, "project_id_guid4", pMx);
		mxDouble* pGUID4 = GetDoubles(pMx);
		for (int i = 0; i < 8; ++i) { *(pGUID4 + i) = (double)m_header.projectID_GUID_4[i]; }

		mxSetField(pMXheader, 0, "version_major", mxCreateDoubleScalar((double)m_header.versionMajor));
		mxSetField(pMXheader, 0, "version_minor", mxCreateDoubleScalar((double)m_header.versionMinor));

		// Copy system identifier and generating software to output char array
		pMx = mxCreateString(m_header.systemIdentifier);
		mxSetField(pMXheader, 0, "system_identifier", pMx);
		pMx = mxCreateString(m_header.generatingSoftware);
		mxSetField(pMXheader, 0, "generating_software", pMx);

		mxSetField(pMXheader, 0, "file_creation_day_of_year", mxCreateDoubleScalar((double)m_header.fileCreationDayOfYear));
		mxSetField(pMXheader, 0, "file_creation_year", mxCreateDoubleScalar((double)m_header.fileCreationYear));
		mxSetField(pMXheader, 0, "header_size", mxCreateDoubleScalar((double)m_header.headerSize));
		mxSetField(pMXheader, 0, "offset_to_point_data", mxCreateDoubleScalar((double)m_header.offsetToPointData));
		mxSetField(pMXheader, 0, "number_of_variable_records", mxCreateDoubleScalar((double)m_header.numberOfVariableLengthRecords));
		mxSetField(pMXheader, 0, "point_data_format", mxCreateDoubleScalar((double)m_header.PointDataRecordFormat));
		mxSetField(pMXheader, 0, "point_data_record_length", mxCreateDoubleScalar((double)m_header.PointDataRecordLength));

		// Number of Point records and points by return will be treated separately down below

		mxSetField(pMXheader, 0, "scale_factor_x", mxCreateDoubleScalar((double)m_header.xScaleFactor));
		mxSetField(pMXheader, 0, "scale_factor_y", mxCreateDoubleScalar((double)m_header.yScaleFactor));
		mxSetField(pMXheader, 0, "scale_factor_z", mxCreateDoubleScalar((double)m_header.zScaleFactor));
		mxSetField(pMXheader, 0, "x_offset", mxCreateDoubleScalar((double)m_header.xOffset));
		mxSetField(pMXheader, 0, "y_offset", mxCreateDoubleScalar((double)m_header.yOffset));
		mxSetField(pMXheader, 0, "z_offset", mxCreateDoubleScalar((double)m_header.zOffset));
		mxSetField(pMXheader, 0, "max_x", mxCreateDoubleScalar((double)m_header.maxX));
		mxSetField(pMXheader, 0, "min_x", mxCreateDoubleScalar((double)m_header.minX));
		mxSetField(pMXheader, 0, "max_y", mxCreateDoubleScalar((double)m_header.maxY));
		mxSetField(pMXheader, 0, "min_y", mxCreateDoubleScalar((double)m_header.minY));
		mxSetField(pMXheader, 0, "max_z", mxCreateDoubleScalar((double)m_header.maxZ));
		mxSetField(pMXheader, 0, "min_z", mxCreateDoubleScalar((double)m_header.minZ));

		// Differentiate between minorVersions 3 and below and 4 and above
		// This leads to messy condition checking but that has to be done to keep it consistent with the lasdata class structure
		// Preinitialize number of points here and overwrite if version minor is 4 or above
		uint_fast64_t numberOfPointRecordsToWrite = (uint_fast64_t)m_header.LegacyNumberOfPointRecords;

		// Add Fields which could be different in newer minor versions
		if (m_header.versionMajor == 1 && m_header.versionMinor < 4)
		{
			pMx = mxCreateDoubleMatrix(5, 1, mxREAL);
			mxSetField(pMXheader, 0, "number_of_points_by_return", pMx);
			mxDouble* pNumPointsByReturn = GetDoubles(pMx);
			for (int i = 0; i < 5; ++i) { *(pNumPointsByReturn + i) = (double)m_header.LegacyNumberOfPointByReturn[i]; }
		}

		if (m_header.versionMajor == 1 && m_header.versionMinor > 2)
		{
			int success = mxAddField(pMXheader, "start_of_waveform_data");
			mxSetField(pMXheader, 0, "start_of_waveform_data", mxCreateDoubleScalar((double)m_headerExt3.startOfWaveFormData));
		}

		if (m_header.versionMajor == 1 && m_header.versionMinor > 3)
		{
			int success = mxAddField(pMXheader, "start_of_extended_variable_length_record");
			mxSetField(pMXheader, 0, "start_of_extended_variable_length_record", mxCreateDoubleScalar((double)m_headerExt4.startOfFirstExtendedVariableLengthRecord));
			success = mxAddField(pMXheader, "number_of_extended_variable_length_record");
			mxSetField(pMXheader, 0, "number_of_extended_variable_length_record", mxCreateDoubleScalar((double)m_headerExt4.numberOfExtendedVariableLengthRecords));

			// Legacy Fields
			success = mxAddField(pMXheader, "legacy_number_of_point_records_READ_ONLY");
			mxSetField(pMXheader, 0, "legacy_number_of_point_records_READ_ONLY", mxCreateDoubleScalar((double)m_header.LegacyNumberOfPointRecords));

			success = mxAddField(pMXheader, "legacy_number_of_points_by_return_READ_ONLY");
			pMx = mxCreateDoubleMatrix(5, 1, mxREAL);
			mxSetField(pMXheader, 0, "legacy_number_of_points_by_return_READ_ONLY", pMx);
			mxDouble* pNumPointsByReturn = GetDoubles(pMx);
			for (int i = 0; i < 5; ++i) { *(pNumPointsByReturn + i) = (double)m_header.LegacyNumberOfPointByReturn[i]; }

			// Old Fields with new values
			numberOfPointRecordsToWrite = (uint_fast64_t)m_headerExt4.numberOfPointRecords;

			pMx = mxCreateDoubleMatrix(15, 1, mxREAL);
			mxSetField(pMXheader, 0, "number_of_points_by_return", pMx);
			pNumPointsByReturn = GetDoubles(pMx);
			for (int i = 0; i < 15; ++i) { *(pNumPointsByReturn + i) = (double)m_headerExt4.numberOfPointsByReturn[i]; }
		}

		// Finally write the number of Point Records here which could have been "overwritten" by LAS 1.4
		mxSetField(pMXheader, 0, "number_of_point_records", mxCreateDoubleScalar((double)numberOfPointRecordsToWrite));
		// Number of Points by return could not be written the same way because the array size is different

	}
	catch (const std::bad_alloc& ba) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:FillStructHeader:bad_alloc", ba.what());
	}
	catch (const std::exception& ex) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:FillStructHeader:Exception", ex.what());
	}
	catch (...) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:FillStructHeader:UnhandledException", "Unhandled Exception occured");
	}
}

void LasDataReader::AllocateOutputStruct(mxArray*& plhs, std::ifstream& lasBin) {

	try {
		// Pointer to the mxArray which is to be allocated right now, pointer shifts from field to field
		mxArray* pointerTocurrentMXArray;

		// Create empty matrices for point data, set fields to output struct and get pointers to underlying data
		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs, 0, "x", pointerTocurrentMXArray);
		m_mxStructPointer.pX = GetDoubles(pointerTocurrentMXArray);

		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs, 0, "y", pointerTocurrentMXArray);
		m_mxStructPointer.pY = GetDoubles(pointerTocurrentMXArray);
		
		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs, 0, "z", pointerTocurrentMXArray);
		m_mxStructPointer.pZ = GetDoubles(pointerTocurrentMXArray);

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
		mxSetField(plhs, 0, "intensity", pointerTocurrentMXArray);
		m_mxStructPointer.pIntensity = GetUint16(pointerTocurrentMXArray);
		
		// If m_XYZIntOnly is used then return because we only read xyz and intensity
		if (m_XYZIntOnly) { return; }

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs, 0, "bits", pointerTocurrentMXArray);
		m_mxStructPointer.pBits = GetUint8(pointerTocurrentMXArray);
		
		// Second bit field only exists in format 5 and higher
		if (m_header.PointDataRecordFormat > 5)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
			mxSetField(plhs, 0, "bits2", pointerTocurrentMXArray);
			m_mxStructPointer.pBits2 = GetUint8(pointerTocurrentMXArray);
		}

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs, 0, "classification", pointerTocurrentMXArray);
		m_mxStructPointer.pClassicfication = GetUint8(pointerTocurrentMXArray);

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs, 0, "user_data", pointerTocurrentMXArray);
		m_mxStructPointer.pUserData = GetUint8(pointerTocurrentMXArray);

		// Scan Angle changes Datatype from Format 6 on
		if (m_header.PointDataRecordFormat < 6) {
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxINT8_CLASS, mxREAL);
			mxSetField(plhs, 0, "scan_angle", pointerTocurrentMXArray);
			m_mxStructPointer.pScanAngle = GetInt8(pointerTocurrentMXArray);
		}
		else
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxINT16_CLASS, mxREAL);
			mxSetField(plhs, 0, "scan_angle", pointerTocurrentMXArray);
			m_mxStructPointer.pScanAngle_16Bit = GetInt16(pointerTocurrentMXArray);
		}

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
		mxSetField(plhs, 0, "point_source_id", pointerTocurrentMXArray);
		m_mxStructPointer.pPointSourceID = GetUint16(pointerTocurrentMXArray);

		// Only allocate time, colors, wavepackets, nir and extrabytes in struct if file contains them
		if (m_containsTime)
		{
			pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
			mxSetField(plhs, 0, "gps_time", pointerTocurrentMXArray);
			m_mxStructPointer.pGPS_Time = GetDoubles(pointerTocurrentMXArray);
		}
		if (m_containsColors)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs, 0, "red", pointerTocurrentMXArray);
			m_mxStructPointer.pRed = GetUint16(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs, 0, "green", pointerTocurrentMXArray);
			m_mxStructPointer.pGreen = GetUint16(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs, 0, "blue", pointerTocurrentMXArray);
			m_mxStructPointer.pBlue = GetUint16(pointerTocurrentMXArray);
		}

		if (m_containsWavepackets)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
			mxSetField(plhs, 0, "wave_packet_descriptor", pointerTocurrentMXArray);
			m_mxStructPointer.pWavePacketDescriptor = GetUint8(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT64_CLASS, mxREAL);
			mxSetField(plhs, 0, "wave_byte_offset", pointerTocurrentMXArray);
			m_mxStructPointer.pWaveByteOffset = GetUint64(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT32_CLASS, mxREAL);
			mxSetField(plhs, 0, "wave_packet_size", pointerTocurrentMXArray);
			m_mxStructPointer.pWavePacketSize = GetUint32(pointerTocurrentMXArray);
			
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs, 0, "wave_return_point", pointerTocurrentMXArray);
			m_mxStructPointer.pWaveReturnPoint = GetSingles(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs, 0, "Xt", pointerTocurrentMXArray);
			m_mxStructPointer.pWaveXt = GetSingles(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs, 0, "Yt", pointerTocurrentMXArray);
			m_mxStructPointer.pWaveYt = GetSingles(pointerTocurrentMXArray);

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs, 0, "Zt", pointerTocurrentMXArray);
			m_mxStructPointer.pWaveZt = GetSingles(pointerTocurrentMXArray);
		}

		if (m_containsNIR)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs, 0, "nir", pointerTocurrentMXArray);
			m_mxStructPointer.pNIR = GetUint16(pointerTocurrentMXArray);
		}

		if (m_containsExtraBytes)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_extraByteCount, (mwSize)m_numberOfPointsToRead,  mxUINT8_CLASS, mxREAL);
			mxSetField(plhs, 0, "extradata", pointerTocurrentMXArray);
			m_mxStructPointer.pExtraBytes = GetUint8(pointerTocurrentMXArray);
		}

	}
	catch (const std::bad_alloc& ba) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:AllocateOutputStruct:bad_alloc", ba.what());
	}
	catch (const std::exception& ex) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:AllocateOutputStruct:Exception", ex.what());
	}
	catch (...) {
		lasBin.close();
		mexErrMsgIdAndTxt("MEX:AllocateOutputStruct:UnhandledException", "Unhandled Exception occured");
	}
}