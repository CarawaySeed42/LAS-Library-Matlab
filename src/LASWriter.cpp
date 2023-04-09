#include "LAS_IO.hpp"
#include <cstring>
#include <memory>
#include <cmath>

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

constexpr auto size_char		= sizeof(char);
constexpr auto size_signedchar	= sizeof(int8_t);
constexpr auto size_uint8		= sizeof(uint8_t);
constexpr auto size_double		= sizeof(double);
constexpr auto size_float		= sizeof(float);
constexpr auto size_uint16		= sizeof(uint16_t);
constexpr auto size_int16		= sizeof(int16_t);
constexpr auto size_uint32		= sizeof(uint32_t);
constexpr auto size_int32		= sizeof(int32_t);
constexpr auto size_uint64		= sizeof(uint64_t);

constexpr auto size_3_int32		= 3 * sizeof(int32_t);
constexpr auto size_3_uint16	= 3 * sizeof(uint16_t);

void LASdataWriter::WriteLASheader(std::ofstream& lasBin)
{
	if (!lasBin.is_open()) { throw std::ofstream::failure("File is not open or not writable!"); }

	// Go to start of file
	lasBin.seekp(0, lasBin.beg);

	// Write every single header entry
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
		lasBin.write((char*)&m_headerExt4.numberOfPointsByReturn, 120);
	}

	
	auto currentStreampos = lasBin.tellp();

	if (static_cast<unsigned short>(currentStreampos) != m_header.headerSize)
	{
		mexWarnMsgIdAndTxt("MEX:WriteLASheader:invalid_streampos", "Streamposition after writing the header diverges from the reference!\n Error will be corrected!");
		lasBin.seekp(94, lasBin.beg);

		// Correct header size and offset to point data because it will be shifted as well
		long diffHeaderSizes = static_cast<long>(currentStreampos) - static_cast<long>(m_header.headerSize);
		m_header.headerSize = static_cast<unsigned short>(currentStreampos);
		m_header.offsetToPointData = static_cast<unsigned long>(static_cast<long>(m_header.offsetToPointData) + diffHeaderSizes);

		lasBin.write((char*)&m_header.headerSize, size_uint16);
		lasBin.write((char*)&m_header.offsetToPointData, size_uint32);
		lasBin.seekp(currentStreampos, lasBin.beg);
	}

	setInternalRecordFormatID();
}


void LASdataWriter::WriteLASdata(std::ofstream& lasBin)
{
	// Check if datatype sizes are correct during compilation
	static_assert(sizeof(float) == 4,			"Float should have a size of 8! But it is not on this machine!");
	static_assert(sizeof(double) == 8,			"Double should have a size of 8! But it is not on this machine!");

	// Initialilzations
	int writeBufferPointSize = 4096;	// How many Points are written per write call
	size_t pointOffset = 0;				// pointOffset is offset to the current cloud point to process
	size_t bufOffPointStart = 0;		// Offset to current position in write Buffer

	// Check if necessary Pointers are valid (Creates Matlab Error if not)
	isDataValid();

	// Get Interal record format and get all the byte offsets to LAS Fields
	setInternalRecordFormatID();

	if (m_internalPointDataRecordID == -1) 
	{
		mexWarnMsgIdAndTxt("MEX:WriteLASdata:InvalidPointDataRecordFormat", "Critical Error: Point Data Record Format not supported!\n");
		return;
	}

	const int record_length         = m_header.PointDataRecordLength;
	const int extradata_Byte		= m_record_lengths[m_internalPointDataRecordID];

	const int bits2_Byte			= m_bits2_Byte			[m_internalPointDataRecordID];
	const int classification_Byte	= m_classification_Byte	[m_internalPointDataRecordID];
	const int scanAngle_Byte		= m_scanAngle_Byte		[m_internalPointDataRecordID];
	const int userData_Byte			= m_userData_Byte		[m_internalPointDataRecordID];
	const int pointSourceID_Byte	= m_pointSourceID_Byte	[m_internalPointDataRecordID];
	const int time_Byte				= m_time_Byte			[m_internalPointDataRecordID];
	const int color_Byte			= m_color_Byte			[m_internalPointDataRecordID];
	const int NIR_Byte				= m_NIR_Byte			[m_internalPointDataRecordID];
	const int wavePackets_Byte		= m_wavePackets_Byte	[m_internalPointDataRecordID];

	const bool doWriteBits2			= bits2_Byte != 0;			// Is Bits2 field to be written
	const bool doWriteTime			= time_Byte  != 0;			// Is Time field to be written
	const bool doWriteColor			= color_Byte != 0;			// Is Color field to be written
	const bool doWriteNIR			= NIR_Byte   != 0;			// Is NIR field to be written
	const bool doWriteWavePackets	= wavePackets_Byte != 0;	// Is Wave Packets field to be written
	const bool isScanAngle16Bit		= scanAngle_Byte == 18;		// Is Scan Angle field a 16 bit / 2 byte value

	// Const copies of frequently accessed struct values
	const double xScale = m_header.xScaleFactor;
	const double yScale = m_header.yScaleFactor;
	const double zScale = m_header.zScaleFactor;
	const double xOff	= m_header.xOffset;
	const double yOff	= m_header.yOffset;
	const double zOff	= m_header.zOffset;

	// Set stream position before write as offset to point data
	setStreamPosAsDataOffset(lasBin);

	// Seek start of point data in file
	if (!lasBin.is_open()) { throw std::ofstream::failure("File is not open or not writable!"); }
	lasBin.seekp(m_header.offsetToPointData, lasBin.beg);

	// Arrays for three components fields
	int32_t XYZ_Coordinates[3] = { 0 };
	uint16_t colors[3] = { 0 };

	// Calculate number of full write blocks and the remaining points inside the last block
	const int fullChunksCount = static_cast<int>(m_numberOfPointsToWrite / writeBufferPointSize);
	const int pointsToWriteAtEnd = static_cast<int>(m_numberOfPointsToWrite - (static_cast<unsigned long long>(writeBufferPointSize) * fullChunksCount));

	// Create Write Buffer
	const int bufferLength = static_cast<int>(m_header.PointDataRecordLength) * writeBufferPointSize;
	std::unique_ptr<char[]>  uniqueBuffer(new char[bufferLength]);
	char* pBuffer = uniqueBuffer.get();

	// Set Buffer to Zero
	std::fill(pBuffer, pBuffer + bufferLength, static_cast<char>(0));

	// Don't check for file still good for every chunk
	const unsigned int fileCheckInterval = 30;

	/* Data write loop */
	for (size_t i = 0; i < (fullChunksCount + 1); ++i)
	{
		if ((i % fileCheckInterval == 0)) {

			if (!lasBin.good()) { throw std::ofstream::failure("Error during file write! Stream went bad!"); }
		}

		// Current Position in point array
		pointOffset = static_cast<size_t>(i) * writeBufferPointSize;

		// If last Iteration then we have to reduce buffer size
		if (i == fullChunksCount) { writeBufferPointSize = pointsToWriteAtEnd; }

		// Fill write buffer with all the fields which are supposed to be written
		for (size_t k = 0; k < writeBufferPointSize; ++k)
		{
			bufOffPointStart = k * m_header.PointDataRecordLength;

			// Create final values of static LAS fields which have to be written to file
			XYZ_Coordinates[0]	= std::lround((m_mxStructPointer.pX[pointOffset + k] - xOff) / xScale);
			XYZ_Coordinates[1]	= std::lround((m_mxStructPointer.pY[pointOffset + k] - yOff) / yScale);
			XYZ_Coordinates[2]	= std::lround((m_mxStructPointer.pZ[pointOffset + k] - zOff) / zScale);

			// Copy values to write buffer
			std::memcpy(pBuffer + bufOffPointStart,		 &XYZ_Coordinates[0], size_3_int32);
			std::memcpy(pBuffer + bufOffPointStart + 12, &m_mxStructPointer.pIntensity[pointOffset + k], size_uint16);
			std::memcpy(pBuffer + bufOffPointStart + 14, &m_mxStructPointer.pBits[pointOffset + k], size_uint16);

			// Write other fields according to point data record format
			if (doWriteBits2){	
				std::memcpy(pBuffer + bufOffPointStart + bits2_Byte, &m_mxStructPointer.pBits2[pointOffset + k], size_uint8); 
			}

			std::memcpy(pBuffer + bufOffPointStart + classification_Byte, &m_mxStructPointer.pClassicfication[pointOffset + k],	size_uint8);
			std::memcpy(pBuffer + bufOffPointStart + userData_Byte, &m_mxStructPointer.pUserData[pointOffset + k], size_uint8);

			if (isScanAngle16Bit) 
			{
				std::memcpy(pBuffer + bufOffPointStart + scanAngle_Byte, &m_mxStructPointer.pScanAngle_16Bit[pointOffset + k], size_int16);
			}
			else 
			{
				std::memcpy(pBuffer + bufOffPointStart + scanAngle_Byte, &m_mxStructPointer.pScanAngle[pointOffset + k], size_signedchar);
			}

			std::memcpy(pBuffer + bufOffPointStart + pointSourceID_Byte, &m_mxStructPointer.pPointSourceID[pointOffset + k], size_uint16);

			if (doWriteTime){	
				std::memcpy(pBuffer + bufOffPointStart + time_Byte,  &m_mxStructPointer.pGPS_Time[pointOffset + k], size_double); 
			}
			
			if (doWriteColor)
			{
				colors[0] = m_mxStructPointer.pRed[pointOffset + k];
				colors[1] = m_mxStructPointer.pGreen[pointOffset + k];
				colors[2] = m_mxStructPointer.pBlue[pointOffset + k];
				memcpy(pBuffer + bufOffPointStart + color_Byte, &colors[0], size_3_uint16);

			}

			if (doWriteNIR) 
			{
				std::memcpy(pBuffer + bufOffPointStart + NIR_Byte, &m_mxStructPointer.pNIR[pointOffset + k], size_uint16);
			}

			if (doWriteWavePackets)
			{
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte,		&m_mxStructPointer.pWavePacketDescriptor[pointOffset + k], size_uint8);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 1,	&m_mxStructPointer.pWaveByteOffset[pointOffset + k], size_uint64);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 9,	&m_mxStructPointer.pWavePacketSize[pointOffset + k], size_uint32);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 13, &m_mxStructPointer.pWaveReturnPoint[pointOffset + k], size_float);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 17, &m_mxStructPointer.pWaveXt[pointOffset + k], size_float);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 21, &m_mxStructPointer.pWaveYt[pointOffset + k], size_float);
				std::memcpy(pBuffer + bufOffPointStart + wavePackets_Byte + 25, &m_mxStructPointer.pWaveZt[pointOffset + k], size_float);
			}

			if (m_containsExtraBytes)
			{
				std::memcpy(pBuffer + bufOffPointStart + extradata_Byte, &m_mxStructPointer.pExtraBytes[(pointOffset + k)*m_extraByteCount], m_extraByteCount*size_uint8);
			}
		}

		// Finally write buffer to file
		lasBin.write(pBuffer, static_cast<std::streamsize>(writeBufferPointSize) * m_header.PointDataRecordLength);
	}
}

void LASdataWriter::GetHeader(const mxArray* prhs)
{
	mxDouble* pMXDouble;
	mxChar* pMXChar;

	mxArray* pMxHeader = mxGetField(prhs, 0, "header");
	m_mxStructPointer.pMXheader = pMxHeader;

	if (nullptr == pMxHeader) {
		mexErrMsgIdAndTxt("MEX:GetHeader:Nullptr", "Could not access header field of LAS structure!");
	}

	m_header.sourceID		  = static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "source_id")));
	m_header.globalEncoding   = static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "global_encoding")));
	m_header.projectID_GUID_1 = static_cast<unsigned long>(*GetDoubles(mxGetField(pMxHeader, 0, "project_id_guid1")));
	m_header.projectID_GUID_2 = static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "project_id_guid2")));
	m_header.projectID_GUID_3 = static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "project_id_guid3")));

	pMXDouble = GetDoubles(mxGetField(pMxHeader, 0, "project_id_guid4"));
	for (int i = 0; i < 8; ++i) { m_header.projectID_GUID_4[i] = static_cast<uint8_t>(pMXDouble[i]); }

	m_header.versionMajor = static_cast<unsigned char>(*GetDoubles(mxGetField(pMxHeader, 0, "version_major")));
	m_header.versionMinor = static_cast<unsigned char>(*GetDoubles(mxGetField(pMxHeader, 0, "version_minor")));

	m_header.fileCreationDayOfYear			= static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "file_creation_day_of_year")));
	m_header.fileCreationYear				= static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "file_creation_year")));
	m_header.headerSize						= static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "header_size")));
	m_header.offsetToPointData				= static_cast<unsigned long>(*GetDoubles(mxGetField(pMxHeader, 0, "offset_to_point_data")));
	m_header.numberOfVariableLengthRecords	= static_cast<unsigned long>(*GetDoubles(mxGetField(pMxHeader, 0, "number_of_variable_records")));
	m_header.LegacyNumberOfPointRecords		= 0;

	m_header.PointDataRecordFormat = static_cast<unsigned char>(*GetDoubles(mxGetField(pMxHeader, 0, "point_data_format")));
	m_header.PointDataRecordLength = static_cast<unsigned short>(*GetDoubles(mxGetField(pMxHeader, 0, "point_data_record_length")));
	m_header.xScaleFactor = *GetDoubles(mxGetField(pMxHeader, 0, "scale_factor_x"));
	m_header.yScaleFactor = *GetDoubles(mxGetField(pMxHeader, 0, "scale_factor_y"));
	m_header.zScaleFactor = *GetDoubles(mxGetField(pMxHeader, 0, "scale_factor_z"));
	m_header.xOffset = *GetDoubles(mxGetField(pMxHeader, 0, "x_offset"));
	m_header.yOffset = *GetDoubles(mxGetField(pMxHeader, 0, "y_offset"));
	m_header.zOffset = *GetDoubles(mxGetField(pMxHeader, 0, "z_offset"));
	m_header.maxX = *GetDoubles(mxGetField(pMxHeader, 0, "max_x"));
	m_header.minX = *GetDoubles(mxGetField(pMxHeader, 0, "min_x"));
	m_header.maxY = *GetDoubles(mxGetField(pMxHeader, 0, "max_y"));
	m_header.minY = *GetDoubles(mxGetField(pMxHeader, 0, "min_y"));
	m_header.maxZ = *GetDoubles(mxGetField(pMxHeader, 0, "max_z"));
	m_header.minZ = *GetDoubles(mxGetField(pMxHeader, 0, "min_z"));

	// Get number of point records
	m_numberOfPointsToWrite = static_cast<unsigned long long>(*GetDoubles(mxGetField(pMxHeader, 0, "number_of_point_records")));

	if (m_numberOfPointsToWrite < ULONG_MAX) // max is 4294967296
	{
		m_header.LegacyNumberOfPointRecords = static_cast<unsigned long>(m_numberOfPointsToWrite);
	}

	// Get version exclusive features
	if (m_header.versionMajor == 1 && m_header.versionMinor < 4)
	{
		pMXDouble = GetDoubles(mxGetField(pMxHeader, 0, "number_of_points_by_return"));
		for (int i = 0; i < 5; ++i) { m_header.LegacyNumberOfPointByReturn[i] = static_cast<unsigned long>(pMXDouble[i]); }
	}

	if (m_header.versionMajor == 1 && m_header.versionMinor > 2)
	{
		m_headerExt3.startOfWaveFormData = static_cast<unsigned long long>(*GetDoubles(mxGetField(pMxHeader, 0, "start_of_waveform_data")));
	}

	if (m_header.versionMajor == 1 && m_header.versionMinor > 3)
	{
		m_headerExt4.numberOfPointRecords = m_numberOfPointsToWrite;
		m_headerExt4.startOfFirstExtendedVariableLengthRecord	= static_cast<unsigned long long>(*GetDoubles(mxGetField(pMxHeader, 0, "start_of_extended_variable_length_record")));
		m_headerExt4.numberOfExtendedVariableLengthRecords		= static_cast<unsigned long>(*GetDoubles(mxGetField(pMxHeader, 0, "number_of_extended_variable_length_record")));

		pMXDouble = GetDoubles(mxGetField(pMxHeader, 0, "number_of_points_by_return"));
		for (int i = 0; i < 15; ++i) { m_headerExt4.numberOfPointsByReturn[i] = static_cast<unsigned long long>(pMXDouble[i]); }
	}

	// Copy system identifier and generating software char by char until null character or end of array is reached
	pMXChar = GetChars(mxGetField(pMxHeader, 0, "system_identifier"));
	copyMXCharToArray(&m_header.systemIdentifier[0], pMXChar, 32);

	pMXChar = GetChars(mxGetField(pMxHeader, 0, "generating_software"));
	copyMXCharToArray(&m_header.generatingSoftware[0], pMXChar, 32);

}

void LASdataWriter::GetData(const mxArray* prhs) {

	setContentFlags();

	m_mxStructPointer.pX		 = GetDoubles(mxGetField(prhs, 0, "x"));
	m_mxStructPointer.pY		 = GetDoubles(mxGetField(prhs, 0, "y"));
	m_mxStructPointer.pZ		 = GetDoubles(mxGetField(prhs, 0, "z"));
	m_mxStructPointer.pIntensity = GetUint16(mxGetField(prhs, 0, "intensity"));
	m_mxStructPointer.pBits		 = GetUint8(mxGetField(prhs, 0, "bits"));

	if (m_header.PointDataRecordFormat > 5)
	{
		m_mxStructPointer.pBits2 = GetUint8(mxGetField(prhs, 0, "bits2"));
	}

	m_mxStructPointer.pClassicfication	= GetUint8(mxGetField(prhs, 0, "classification"));
	m_mxStructPointer.pUserData			= GetUint8(mxGetField(prhs, 0, "user_data"));


	if (m_header.PointDataRecordFormat < 6)
	{
		m_mxStructPointer.pScanAngle = GetInt8(mxGetField(prhs, 0, "scan_angle"));
	}
	else
	{
		m_mxStructPointer.pScanAngle_16Bit = GetInt16(mxGetField(prhs, 0, "scan_angle"));
	}

	m_mxStructPointer.pPointSourceID = GetUint16(mxGetField(prhs, 0, "point_source_id"));

	if (m_containsTime) {
		m_mxStructPointer.pGPS_Time = GetDoubles(mxGetField(prhs, 0, "gps_time"));
	}

	if (m_containsColors)
	{
		m_mxStructPointer.pRed		= GetUint16(mxGetField(prhs, 0, "red"));
		m_mxStructPointer.pGreen	= GetUint16(mxGetField(prhs, 0, "green"));
		m_mxStructPointer.pBlue		= GetUint16(mxGetField(prhs, 0, "blue"));
	}

	if (m_containsWavepackets)
	{
		m_mxStructPointer.pWavePacketDescriptor = GetUint8(mxGetField(prhs, 0, "wave_packet_descriptor"));
		m_mxStructPointer.pWaveByteOffset		= GetUint64(mxGetField(prhs, 0, "wave_byte_offset"));
		m_mxStructPointer.pWavePacketSize		= GetUint32(mxGetField(prhs, 0, "wave_packet_size"));
		m_mxStructPointer.pWaveReturnPoint		= GetSingles(mxGetField(prhs, 0, "wave_return_point"));
		m_mxStructPointer.pWaveXt = GetSingles(mxGetField(prhs, 0, "Xt"));
		m_mxStructPointer.pWaveYt = GetSingles(mxGetField(prhs, 0, "Yt"));
		m_mxStructPointer.pWaveZt = GetSingles(mxGetField(prhs, 0, "Zt"));
	}

	if (m_containsNIR)
	{
		m_mxStructPointer.pNIR = GetUint16(mxGetField(prhs, 0, "nir"));
	}

	if (m_containsExtraBytes)
	{
		m_mxStructPointer.pExtraBytes = GetUint8(mxGetField(prhs, 0, "extradata"));
	}
}

void LASdataWriter::isDataValid()
{
	if (nullptr == m_mxStructPointer.pX) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to X invalid!");
	}
	if (nullptr == m_mxStructPointer.pY) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Y invalid!");
	}
	if (nullptr == m_mxStructPointer.pZ) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Z invalid!");
	}
	if (nullptr == m_mxStructPointer.pIntensity) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Intensity invalid!");
	}
	if (nullptr == m_mxStructPointer.pBits) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Bitfield invalid!");
	}
	if (m_header.PointDataRecordFormat > 5)
	{
		if (nullptr == m_mxStructPointer.pBits2) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to second Bitfield invalid!");
		}
	}
	if (nullptr == m_mxStructPointer.pClassicfication) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Classificaton invalid!");
	}
	if (nullptr == m_mxStructPointer.pUserData) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to User Data invalid!");
	}
	if (m_header.PointDataRecordFormat < 6)
	{
		if (nullptr == m_mxStructPointer.pScanAngle) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to 8bit Scan Angle invalid!");
		}
	}
	else
	{
		if (nullptr == m_mxStructPointer.pScanAngle_16Bit) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to 16bit Scan Angle invalid!");
		}
	}
	if (nullptr == m_mxStructPointer.pPointSourceID) {
		mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Point Source ID invalid!");
	}
	if (m_containsTime) {
		if (nullptr == m_mxStructPointer.pGPS_Time) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to GPS Time invalid!");
		}
	}
	if (m_containsColors)
	{
		if (nullptr == m_mxStructPointer.pRed) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Red Channel invalid!");
		}
		if (nullptr == m_mxStructPointer.pGreen) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Green Channel invalid!");
		}
		if (nullptr == m_mxStructPointer.pBlue) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Blue Channel invalid!");
		}
	}
	if (m_containsWavepackets)
	{
		if (nullptr == m_mxStructPointer.pWavePacketDescriptor) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Wave Packet Descriptor invalid!");
		}
		if (nullptr == m_mxStructPointer.pWaveByteOffset) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Wave Packet Byte Offset invalid!");
		}
		if (nullptr == m_mxStructPointer.pWavePacketSize) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Wave Packet Size invalid!");
		}
		if (nullptr == m_mxStructPointer.pWaveReturnPoint) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Wave Return Point invalid!");
		}
		if (nullptr == m_mxStructPointer.pWaveXt) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Parametric dX invalid!");
		}
		if (nullptr == m_mxStructPointer.pWaveYt) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Parametric dY invalid!");
		}
		if (nullptr == m_mxStructPointer.pWaveZt) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Parametric dZ invalid!");
		}
	}
	if (m_containsNIR)
	{
		if (nullptr == m_mxStructPointer.pNIR) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Near Infrared Channel invalid!");
		}
	}
	if (m_containsExtraBytes)
	{
		if (nullptr == m_mxStructPointer.pExtraBytes) {
			mexErrMsgIdAndTxt("MEX:LASWriter:isDataValid", "Pointer to Extrabytes invalid!");
		}
	}
}

void LASdataWriter::setStreamPosAsDataOffset(std::ofstream& lasBin)
{
	std::streampos currentStreampos = lasBin.tellp();

	if (static_cast<unsigned short>(currentStreampos) != m_header.offsetToPointData)
	{
		mexWarnMsgIdAndTxt("MEX:SetCurrentStreamPosAsOffset:new_streampos", "Offset to Point Data was Updated!");
		lasBin.seekp(96, lasBin.beg);
		m_header.offsetToPointData = static_cast<unsigned long>(currentStreampos);
		lasBin.write((char*)&m_header.offsetToPointData, sizeof(unsigned long));
		lasBin.seekp(currentStreampos, lasBin.beg);
	}
}
