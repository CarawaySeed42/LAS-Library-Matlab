#include "LAS_IO.cpp"
#include <cstring>
#include <memory>

// Preprocessor directives to get field data

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

#define GetDoubles	(mxDouble*)	mxGetPr
#define GetSingles	(mxSingle*)	mxGetPr
#define GetChars	(mxChar*)	mxGetPr
#define GetUint8	(mxUint8*)	mxGetPr
#define GetInt8		(mxInt8*)	mxGetPr
#define GetUint16	(mxUint16*) mxGetPr
#define GetInt16	(mxInt16*)	mxGetPr
#define GetUint32	(mxUint32*) mxGetPr
#define GetInt32	(mxInt32*)	mxGetPr
#define GetUint64	(mxUint64*) mxGetPr
#define GetInt64	(mxInt64*)	mxGetPr

#endif


bool LasDataWriter::WriteLASheader(std::ofstream& lasBin)
{
	if (!lasBin.is_open()) { throw std::ofstream::failure("File is not open or not writable!"); }

	// Go to start of file
	lasBin.seekp(0, lasBin.beg);

	// Get current year and day of year for write
	/*time_t theTime = time(NULL);
	struct tm aTime;
	localtime_s(&aTime, &theTime);
	FileCreationYear = (unsigned short)aTime.tm_year + 1900; // Year is # years since 1900
	FileCreationDayOfYear = (unsigned short)aTime.tm_yday;
	*/

	char FileSignature[] = "LASF";
	std::strcpy(m_header.fileSignature, FileSignature);

	lasBin.write((char*)&FileSignature, 4);
	lasBin.write((char*)&m_header.sourceID, 2);

	lasBin.write((char*)&m_header.globalEncoding, 2);
	lasBin.write((char*)&m_header.projectID_GUID_1, 4);
	lasBin.write((char*)&m_header.projectID_GUID_2, 2);
	lasBin.write((char*)&m_header.projectID_GUID_3, 2);
	lasBin.write((char*)&m_header.projectID_GUID_4, 8);
	lasBin.write((char*)&m_header.versionMajor, 1);
	lasBin.write((char*)&m_header.versionMinor, 1);
	lasBin.write((char*)&m_header.systemIdentifier, 32);
	lasBin.write((char*)&m_header.generatingSoftware, 32);
	lasBin.write((char*)&m_header.fileCreationDayOfYear, 2);
	lasBin.write((char*)&m_header.fileCreationYear, 2);
	lasBin.write((char*)&m_header.headerSize, 2);

	lasBin.write((char*)&m_header.offsetToPointData, 4);
	lasBin.write((char*)&m_header.numberOfVariableLengthRecords, 4);

	lasBin.write((char*)&m_header.PointDataRecordFormat, 1);
	lasBin.write((char*)&m_header.PointDataRecordLength, 2);
	lasBin.write((char*)&m_header.LegacyNumberOfPointRecords, 4);
	lasBin.write((char*)&m_header.LegacyNumberOfPointByReturn[0], 4);
	lasBin.write((char*)&m_header.LegacyNumberOfPointByReturn[1], 4);
	lasBin.write((char*)&m_header.LegacyNumberOfPointByReturn[2], 4);
	lasBin.write((char*)&m_header.LegacyNumberOfPointByReturn[3], 4);
	lasBin.write((char*)&m_header.LegacyNumberOfPointByReturn[4], 4);
	lasBin.write((char*)&m_header.xScaleFactor, 8);
	lasBin.write((char*)&m_header.yScaleFactor, 8);
	lasBin.write((char*)&m_header.zScaleFactor, 8);
	lasBin.write((char*)&m_header.xOffset, 8);
	lasBin.write((char*)&m_header.yOffset, 8);
	lasBin.write((char*)&m_header.zOffset, 8);
	lasBin.write((char*)&m_header.maxX, 8);
	lasBin.write((char*)&m_header.minX, 8);
	lasBin.write((char*)&m_header.maxY, 8);
	lasBin.write((char*)&m_header.minY, 8);
	lasBin.write((char*)&m_header.maxZ, 8);
	lasBin.write((char*)&m_header.minZ, 8);

	if (m_header.versionMajor == 1 && m_header.versionMinor > 2)
	{
		lasBin.write((char*)&m_headerExt3.startOfWaveFormData, 8);
	}
	
	if (m_header.versionMajor == 1 && m_header.versionMinor > 3)
	{
		lasBin.write((char*)&m_headerExt4.startOfFirstExtendedVariableLengthRecord, 8);
		lasBin.write((char*)&m_headerExt4.numberOfExtendedVariableLengthRecords, 4);
		lasBin.write((char*)&m_headerExt4.numberOfPointRecords, 8);
		lasBin.write((char*)&m_headerExt4.numberOfPointsByReturn, 8*15);
	}

	
	std::streampos currentStreampos = lasBin.tellp();

	if (static_cast<unsigned short>(currentStreampos) != m_header.headerSize)
	{
		mexWarnMsgIdAndTxt("MEX:WriteLASheader:invalid_streampos", "Streamposition after writing the header diverges from the reference!\n Error will be corrected!");
		lasBin.seekp(94, lasBin.beg);
		m_header.headerSize = static_cast<unsigned short>(currentStreampos);
		lasBin.write((char*)&m_header.headerSize, 2);
		lasBin.seekp(currentStreampos, lasBin.beg);
		return false;
	}

	return true;
}


bool LasDataWriter::WriteLASdata(std::ofstream& lasBin)
{

	return true;
}

bool LasDataWriter::GetHeader(mxArray* prhs[])
{
	mxDouble* pMXDouble;
	mxChar* pMXChar;

	m_header.sourceID = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "source_id")));
	m_header.globalEncoding = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "global_encoding")));
	m_header.projectID_GUID_1 = static_cast<uint32_t>(*GetDoubles(mxGetField(prhs[0], 0, "project_id_guid1")));
	m_header.projectID_GUID_2 = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "project_id_guid2")));
	m_header.projectID_GUID_3 = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "project_id_guid3")));

	pMXDouble = GetDoubles(mxGetField(prhs[0], 0, "project_id_guid4"));
	for (int i = 0; i < 8; ++i) { m_header.projectID_GUID_4[i] = static_cast<uint8_t>(pMXDouble[i]); }

	m_header.versionMajor = static_cast<uint8_t>(*GetDoubles(mxGetField(prhs[0], 0, "version_major")));
	m_header.versionMinor = static_cast<uint8_t>(*GetDoubles(mxGetField(prhs[0], 0, "version_minor")));

	m_header.fileCreationDayOfYear = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "file_creation_day_of_year")));
	m_header.fileCreationYear = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "file_creation_year")));
	m_header.headerSize = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "header_size")));
	m_header.offsetToPointData = static_cast<uint32_t>(*GetDoubles(mxGetField(prhs[0], 0, "offset_to_point_data")));
	m_header.numberOfVariableLengthRecords = static_cast<uint32_t>(*GetDoubles(mxGetField(prhs[0], 0, "number_of_variable_records")));
	m_header.LegacyNumberOfPointRecords = 0;

	m_header.PointDataRecordFormat = static_cast<uint8_t>(*GetDoubles(mxGetField(prhs[0], 0, "point_data_format")));
	m_header.PointDataRecordLength = static_cast<uint16_t>(*GetDoubles(mxGetField(prhs[0], 0, "point_data_record_length")));
	m_header.xScaleFactor = *GetDoubles(mxGetField(prhs[0], 0, "scale_factor_x"));
	m_header.yScaleFactor = *GetDoubles(mxGetField(prhs[0], 0, "scale_factor_y"));
	m_header.zScaleFactor = *GetDoubles(mxGetField(prhs[0], 0, "scale_factor_z"));
	m_header.xOffset = *GetDoubles(mxGetField(prhs[0], 0, "x_offset"));
	m_header.yOffset = *GetDoubles(mxGetField(prhs[0], 0, "y_offset"));
	m_header.zOffset = *GetDoubles(mxGetField(prhs[0], 0, "z_offset"));
	m_header.maxX = *GetDoubles(mxGetField(prhs[0], 0, "max_x"));
	m_header.minX = *GetDoubles(mxGetField(prhs[0], 0, "min_x"));
	m_header.maxY = *GetDoubles(mxGetField(prhs[0], 0, "max_y"));
	m_header.minY = *GetDoubles(mxGetField(prhs[0], 0, "min_y"));
	m_header.maxZ = *GetDoubles(mxGetField(prhs[0], 0, "max_z"));
	m_header.minZ = *GetDoubles(mxGetField(prhs[0], 0, "min_z"));

	// Get number of point records
	m_numberOfPointsToWrite = static_cast<unsigned long long>(*GetDoubles(mxGetField(prhs[0], 0, "number_of_point_records")));

	if (m_numberOfPointsToWrite < ULONG_MAX) // max is 4294967296
	{
		m_header.LegacyNumberOfPointRecords = static_cast<unsigned long>(m_numberOfPointsToWrite);
	}

	// Get version exclusive features
	if (m_header.versionMajor == 1 && m_header.versionMinor < 4)
	{
		pMXDouble = GetDoubles(mxGetField(prhs[0], 0, "number_of_points_by_return"));
		for (int i = 0; i < 5; ++i) { m_header.LegacyNumberOfPointByReturn[i] = static_cast<uint32_t>(pMXDouble[i]); }
	}

	if (m_header.versionMajor == 1 && m_header.versionMinor > 2)
	{
		m_headerExt3.startOfWaveFormData = static_cast<uint64_t>(*GetDoubles(mxGetField(prhs[0], 0, "start_of_waveform_data")));
	}

	if (m_header.versionMajor == 1 && m_header.versionMinor > 3)
	{
		m_headerExt4.numberOfPointRecords = m_numberOfPointsToWrite;
		m_headerExt4.startOfFirstExtendedVariableLengthRecord = static_cast<uint64_t>(*GetDoubles(mxGetField(prhs[0], 0, "start_of_extended_variable_length_record")));
		m_headerExt4.startOfFirstExtendedVariableLengthRecord = static_cast<uint64_t>(*GetDoubles(mxGetField(prhs[0], 0, "number_of_extended_variable_length_record")));

		pMXDouble = GetDoubles(mxGetField(prhs[0], 0, "number_of_points_by_return"));
		for (int i = 0; i < 15; ++i) { m_headerExt4.numberOfPointsByReturn[i] = static_cast<uint64_t>(pMXDouble[i]); }
	}

	// Copy system identifier and generating software char by char until null character or end of array is reached
	pMXChar = GetChars(mxGetField(prhs[0], 0, "system_identifier"));
	for (int i = 0; i < 32; ++i) {
		char copyChar = static_cast<char>(pMXChar[i]);
		m_header.systemIdentifier[i] = static_cast<char>(copyChar);

		if (copyChar == '/0') {
			break;
		}
	}

	pMXChar = GetChars(mxGetField(prhs[0], 0, "generating_software"));
	for (int i = 0; i < 32; ++i) {
		char copyChar = static_cast<char>(pMXChar[i]);
		m_header.generatingSoftware[i] = static_cast<char>(copyChar);

		if (copyChar == '/0') {
			break;
		}
	}

	return true;
}

bool LasDataWriter::GetData(mxArray* prhs[]) {

	m_mxStructPointer.pX = GetDoubles(mxGetField(prhs[0], 0, "x"));
	m_mxStructPointer.pY = GetDoubles(mxGetField(prhs[0], 0, "y"));
	m_mxStructPointer.pZ = GetDoubles(mxGetField(prhs[0], 0, "z"));
	m_mxStructPointer.pIntensity = GetUint16(mxGetField(prhs[0], 0, "intensity"));
	m_mxStructPointer.pBits = GetUint8(mxGetField(prhs[0], 0, "bits"));

	if (m_header.PointDataRecordFormat > 5)
	{
		m_mxStructPointer.pBits2 = GetUint8(mxGetField(prhs[0], 0, "bits"));
	}

	m_mxStructPointer.pClassicfication = GetUint8(mxGetField(prhs[0], 0, "classification"));
	m_mxStructPointer.pUserData = GetUint8(mxGetField(prhs[0], 0, "user_data"));


	if (m_header.PointDataRecordFormat < 6)
	{
		m_mxStructPointer.pScanAngle = GetInt8(mxGetField(prhs[0], 0, "scan_angle"));
	}
	else
	{
		m_mxStructPointer.pScanAngle_16Bit = GetInt16(mxGetField(prhs[0], 0, "scan_angle"));
	}

	m_mxStructPointer.pPointSourceID = GetUint16(mxGetField(prhs[0], 0, "point_source_id"));

	if (m_containsTime) {
		m_mxStructPointer.pGPS_Time = GetDoubles(mxGetField(prhs[0], 0, "gps_time"));
	}

	if (m_containsColors)
	{
		m_mxStructPointer.pRed = GetUint16(mxGetField(prhs[0], 0, "red"));
		m_mxStructPointer.pGreen = GetUint16(mxGetField(prhs[0], 0, "green"));
		m_mxStructPointer.pBlue = GetUint16(mxGetField(prhs[0], 0, "blue"));
	}

	if (m_containsWavepackets)
	{
		m_mxStructPointer.pWavePacketDescriptor = GetUint8(mxGetField(prhs[0], 0, "wave_packet_descriptor"));
		m_mxStructPointer.pWaveByteOffset = GetUint64(mxGetField(prhs[0], 0, "wave_byte_offset"));
		m_mxStructPointer.pWavePacketSize = GetUint32(mxGetField(prhs[0], 0, "wave_packet_size"));
		m_mxStructPointer.pWaveReturnPoint = GetSingles(mxGetField(prhs[0], 0, "wave_return_point"));
		m_mxStructPointer.pWaveXt = GetSingles(mxGetField(prhs[0], 0, "Xt"));
		m_mxStructPointer.pWaveYt = GetSingles(mxGetField(prhs[0], 0, "Yt"));
		m_mxStructPointer.pWaveZt = GetSingles(mxGetField(prhs[0], 0, "Zt"));
	}

	if (m_containsNIR)
	{
		m_mxStructPointer.pNIR = GetUint16(mxGetField(prhs[0], 0, "nir"));
	}

	if (m_containsExtraBytes)
	{
		m_mxStructPointer.pExtraBytes = GetUint8(mxGetField(prhs[0], 0, "extradata"));
	}

	return true;
}