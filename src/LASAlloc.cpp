#include "LAS_IO.cpp"
#include <cstring>
#include <memory>

void LasDataReader::InitializeOutputStruct(mxArray* plhs[], std::ifstream& lasBin)
{
	try
	{
		/*struct variable name */
		const char* struct_field_names[] = { "header", "x", "y", "z","intensity", "bits", "bits2", "classification", "user_data", "scan_angle",
			"point_source_id", "gps_time", "red", "green", "blue", "nir", "extradata", "Xt", "Yt", "Zt", "wave_return_point", "wave_packet_descriptor",
			"wave_byte_offset", "wave_packet_size", "variablerecords", "extendedvariables", "wavedescriptors" };
		mwSize dims[2] = { 1, 27 };

		// Create structure for output var
		plhs[0] = mxCreateStructArray(1, dims, 27, struct_field_names);

		/* Allocate Header struct */
		const char* header_field_names[] = { "source_id", "global_encoding", "project_id_guid1", "project_id_guid2","project_id_guid3", "project_id_guid4", "version_major", "version_minor",
			"system_identifier", "generating_software", "file_creation_day_of_year", "file_creation_year", "header_size", "offset_to_point_data", "number_of_variable_records", "point_data_format",
			"point_data_record_length", "number_of_point_records", "number_of_points_by_return", "scale_factor_x", "scale_factor_y", "scale_factor_z",
			"x_offset", "y_offset", "z_offset", "max_x", "min_x", "max_y", "min_y", "max_z", "min_z" };
		mwSize dimsHeader[2] = { 1, 31 };

		m_mxStructPointer.pMXheader = mxCreateStructArray(1, dimsHeader, 31, header_field_names);
		mxSetField(plhs[0], 0, "header", m_mxStructPointer.pMXheader);

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
#if MX_HAS_INTERLEAVED_COMPLEX
		mxDouble* pGUID4 = mxGetDoubles(pMx);
#else
		mxDouble* pGUID4 = (mxDouble*)mxGetPr(pMx);;
#endif
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

		mxSetField(pMXheader, 0, "point_data_record_length", mxCreateDoubleScalar((double)m_header.PointDataRecordLength));

		// Differentiate between minorVersions 3 and below and 4 and above
		// This leads to messy condition checking but that has to be done to keep it consistent with the lasdata class structure
		// Preinitialize number of points here and overwrite if version minor is 4 or above
		uint_fast64_t numberOfPointRecordsToWrite = (uint_fast64_t)m_header.LegacyNumberOfPointRecords;

		// Add Fields which could be different in newer minor versions
		if (m_header.versionMajor == 1 && m_header.versionMinor < 4)
		{
			pMx = mxCreateDoubleMatrix(5, 1, mxREAL);
			mxSetField(pMXheader, 0, "number_of_points_by_return", pMx);
#if MX_HAS_INTERLEAVED_COMPLEX
			mxDouble* pNumPointsByReturn = mxGetDoubles(pMx);
#else
			mxDouble* pNumPointsByReturn = (mxDouble*)mxGetPr(pMx);;
#endif
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
#if MX_HAS_INTERLEAVED_COMPLEX
			mxDouble* pNumPointsByReturn = mxGetDoubles(pMx);
#else
			mxDouble* pNumPointsByReturn = (mxDouble*)mxGetPr(pMx);;
#endif
			for (int i = 0; i < 5; ++i) { *(pNumPointsByReturn + i) = (double)m_header.LegacyNumberOfPointByReturn[i]; }

			// Old Fields with new values
			numberOfPointRecordsToWrite = (uint_fast64_t)m_headerExt4.numberOfPointRecords;

			pMx = mxCreateDoubleMatrix(15, 1, mxREAL);
			mxSetField(pMXheader, 0, "number_of_points_by_return", pMx);
#if MX_HAS_INTERLEAVED_COMPLEX
			pNumPointsByReturn = mxGetDoubles(pMx);
#else
			pNumPointsByReturn = (mxDouble*)mxGetPr(pMx);;
#endif
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

void LasDataReader::AllocateOutputStruct(mxArray* plhs[], std::ifstream& lasBin) {

	try {
		// Pointer to the mxArray which is to be allocated right now, pointer shifts from field to field
		mxArray* pointerTocurrentMXArray;

		// Create empty matrices for point data, set fields to output struct and get pointers to underlying data
		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs[0], 0, "x", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pX = mxGetDoubles(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pX = (mxDouble*)mxGetPr(pointerTocurrentMXArray);
#endif

		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs[0], 0, "y", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pY = mxGetDoubles(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pY = (mxDouble*)mxGetPr(pointerTocurrentMXArray);
#endif
		
		pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
		mxSetField(plhs[0], 0, "z", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pZ = mxGetDoubles(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pZ = (mxDouble*)mxGetPr(pointerTocurrentMXArray);
#endif

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
		mxSetField(plhs[0], 0, "intensity", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pIntensity = mxGetUint16s(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pIntensity = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif
		
		// If unsafeRead is used then return because we only read xyz and intensity
		if (unsafeRead) { return; }

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs[0], 0, "bits", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pBits = mxGetUint8s(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pBits = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif
		
		// Second bit field only exists in format 5 and higher
		if (m_header.PointDataRecordFormat > 5)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "bits2", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pBits2 = mxGetUint8s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pBits2 = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif
		}

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs[0], 0, "classification", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pClassicfication = mxGetUint8s(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pClassicfication = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
		mxSetField(plhs[0], 0, "user_data", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pUserData = mxGetUint8s(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pUserData = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif

		// Scan Angle changes Datatype from Format 6 on
		if (m_header.PointDataRecordFormat < 6) {
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxINT8_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "scan_angle", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pScanAngle = mxGetInt8s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pScanAngle = (mxInt8*)mxGetPr(pointerTocurrentMXArray);
#endif
		}
		else
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxINT16_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "scan_angle", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pScanAngle_16Bit = mxGetInt16s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pScanAngle_16Bit = (mxInt16*)mxGetPr(pointerTocurrentMXArray);;
#endif
		}

		pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
		mxSetField(plhs[0], 0, "point_source_id", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
		m_mxStructPointer.pPointSourceID = mxGetUint16s(pointerTocurrentMXArray);
#else
		m_mxStructPointer.pPointSourceID = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif

		// Only allocate time, colors, wavepackets, nir and extrabytes in struct if file contains them
		if (m_containsTime)
		{
			pointerTocurrentMXArray = mxCreateDoubleMatrix((mwSize)m_numberOfPointsToRead, 1, mxREAL);
			mxSetField(plhs[0], 0, "gps_time", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pGPS_Time = mxGetDoubles(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pGPS_Time = (mxDouble*)mxGetPr(pointerTocurrentMXArray);
#endif
		}
		if (m_containsColors)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "red", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pRed = mxGetUint16s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pRed = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "green", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pGreen = mxGetUint16s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pGreen = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "blue", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pBlue = mxGetUint16s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pBlue = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif
		}

		if (m_containsWavepackets)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT8_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "wave_packet_descriptor", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWavePacketDescriptor = mxGetUint8s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWavePacketDescriptor = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT64_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "wave_byte_offset", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWaveByteOffset = mxGetUint64s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWaveByteOffset = (mxUint64*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT32_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "wave_packet_size", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWavePacketSize = mxGetUint32s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWavePacketSize = (mxUint32*)mxGetPr(pointerTocurrentMXArray);
#endif
			
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "wave_return_point", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWaveReturnPoint = mxGetSingles(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWaveReturnPoint = (mxSingle*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "Xt", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWaveXt = mxGetSingles(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWaveXt = (mxSingle*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "Yt", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWaveYt = mxGetSingles(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWaveYt = (mxSingle*)mxGetPr(pointerTocurrentMXArray);
#endif

			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxSINGLE_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "Zt", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pWaveZt = mxGetSingles(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pWaveZt = (mxSingle*)mxGetPr(pointerTocurrentMXArray);
#endif	
		}

		if (m_containsNIR)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, 1, mxUINT16_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "nir", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pNIR = mxGetUint16s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pNIR = (mxUint16*)mxGetPr(pointerTocurrentMXArray);
#endif
		}

		if (m_containsExtraBytes)
		{
			pointerTocurrentMXArray = mxCreateNumericMatrix((mwSize)m_numberOfPointsToRead, (mwSize)m_extraByteCount, mxUINT8_CLASS, mxREAL);
			mxSetField(plhs[0], 0, "extradata", pointerTocurrentMXArray);
#if MX_HAS_INTERLEAVED_COMPLEX
			m_mxStructPointer.pExtraBytes = mxGetUint8s(pointerTocurrentMXArray);
#else
			m_mxStructPointer.pExtraBytes = (mxUint8*)mxGetPr(pointerTocurrentMXArray);
#endif	
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