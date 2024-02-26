#include "LAS_IO.hpp"
#include <cstring>
#include <memory>


void LASdataReader::ReadLASheader(std::ifstream& lasBin)
{
	// Reads Las-File under the assumption that Header is 375 Bytes Long, which is the maximal size up to LAS 1.4
	const int headerReadBytes = 375;
	char headerBuf[headerReadBytes] = {}; // Buffer for stream read

	// Read specified amount of Bytes from file start to the header buffer, 512 Bytes is assumed but real size is not important at the moment
	lasBin.seekg(0, std::ios::beg);
	lasBin.read(headerBuf, headerReadBytes);

	/*Parse Header*/
	std::memcpy(m_header.fileSignature, headerBuf, 4);

	m_header.sourceID			= *reinterpret_cast<uint16_t*>(headerBuf + 4);
	m_header.globalEncoding		= *reinterpret_cast<uint16_t*>(headerBuf + 6);
	m_header.projectID_GUID_1	= *reinterpret_cast<uint32_t*>(headerBuf + 8);
	m_header.projectID_GUID_2	= *reinterpret_cast<uint16_t*>(headerBuf + 12);
	m_header.projectID_GUID_3	= *reinterpret_cast<uint16_t*>(headerBuf + 14);

	// Copy chars into projectID_GUID_4
	std::memcpy(m_header.projectID_GUID_4, headerBuf + 16, 8);

	m_header.versionMajor = *reinterpret_cast<uint8_t*>(headerBuf + 24);
	m_header.versionMinor = *reinterpret_cast<uint8_t*>(headerBuf + 25);

	// Copy chars into System identifier and Generating Software
	std::memcpy(m_header.systemIdentifier, headerBuf + 26, 32);
	std::memcpy(m_header.generatingSoftware, headerBuf + 58, 32);

	m_header.fileCreationDayOfYear			= *reinterpret_cast<uint16_t*>(headerBuf + 90);
	m_header.fileCreationYear				= *reinterpret_cast<uint16_t*>(headerBuf + 92);
	m_header.headerSize						= *reinterpret_cast<uint16_t*>(headerBuf + 94);
	m_header.offsetToPointData				= *reinterpret_cast<uint32_t*>(headerBuf + 96);
	m_header.numberOfVariableLengthRecords	= *reinterpret_cast<uint32_t*>(headerBuf + 100);
	m_header.PointDataRecordFormat			= *reinterpret_cast<uint8_t*> (headerBuf + 104);
	m_header.PointDataRecordLength			= *reinterpret_cast<uint16_t*>(headerBuf + 105);
	m_header.LegacyNumberOfPointRecords		= *reinterpret_cast<uint32_t*>(headerBuf + 107);

	std::memcpy(m_header.LegacyNumberOfPointByReturn, headerBuf + 111, 20);

	m_header.xScaleFactor	= *reinterpret_cast<double*>(headerBuf + 131);
	m_header.yScaleFactor	= *reinterpret_cast<double*>(headerBuf + 139);
	m_header.zScaleFactor	= *reinterpret_cast<double*>(headerBuf + 147);
	m_header.xOffset		= *reinterpret_cast<double*>(headerBuf + 155);
	m_header.yOffset		= *reinterpret_cast<double*>(headerBuf + 163);
	m_header.zOffset		= *reinterpret_cast<double*>(headerBuf + 171);
	m_header.maxX			= *reinterpret_cast<double*>(headerBuf + 179);
	m_header.minX			= *reinterpret_cast<double*>(headerBuf + 187);
	m_header.maxY			= *reinterpret_cast<double*>(headerBuf + 195);
	m_header.minY			= *reinterpret_cast<double*>(headerBuf + 203);
	m_header.maxZ			= *reinterpret_cast<double*>(headerBuf + 211);
	m_header.minZ			= *reinterpret_cast<double*>(headerBuf + 219);

	// Get number of points to read later from numberOfPointRecords, but differentiate if from legacy fields or new fields starting with LAS 1.4
	m_numberOfPointsToRead = (uint_fast64_t)m_header.LegacyNumberOfPointRecords;

	if (m_header.versionMinor > 2) 
	{
		m_headerExt3.startOfWaveFormData = *reinterpret_cast<uint64_t*>(headerBuf + 227);
	}
	if (m_header.versionMinor > 3)
	{
		m_headerExt4.startOfFirstExtendedVariableLengthRecord	= *reinterpret_cast<uint64_t*>(headerBuf + 235);
		m_headerExt4.numberOfExtendedVariableLengthRecords		= *reinterpret_cast<uint32_t*>(headerBuf + 243);
		m_headerExt4.numberOfPointRecords						= *reinterpret_cast<uint64_t*>(headerBuf + 247);
		std::memcpy(m_headerExt4.numberOfPointsByReturn, headerBuf + 255, 120);

		m_numberOfPointsToRead = (uint_fast64_t)m_headerExt4.numberOfPointRecords;
	}

	// Set internal record format id and Content Flags
	setContentFlags();

	// If end of file was reached during reading then clear bits to allow further reading and seeking
	if (lasBin.eof()) {
		lasBin.clear();
	}

}


void LASdataReader::ReadPointData(std::ifstream& lasBin)
{
	const int chunksize = 4096;																		// Blocksize of points for reading -> How many Points will be read at once. Bigger buffer yields diminishing returns
	int pointsToProcessInBuffer = chunksize;														// Used and manipulated in reading for-loop
	const size_t bufferSize = static_cast<size_t>(m_header.PointDataRecordLength) * chunksize;		// Buffer size in bytes

	// Data will be read in blocks. Determine Block count here
	uint_fast64_t fullChunksCount = m_numberOfPointsToRead / static_cast<uint_fast64_t>(chunksize);
	int pointsLeftToRead = (int)(m_numberOfPointsToRead - (static_cast<uint_fast64_t>(chunksize) * fullChunksCount));

	/* Check for Point Data Format and start reading*/
	// Create reading buffer
	std::unique_ptr<char[]>  uniqueBuffer(new char[bufferSize]);
	char* buffer = uniqueBuffer.get();

	// Set this external buffer to be used as internal buffer of ifstream to avoid copying from internal to external buffer
	lasBin.rdbuf()->pubsetbuf(buffer, bufferSize);

	// Seek begining of point data 
	lasBin.seekg(m_header.offsetToPointData, lasBin.beg);

	// If unsafe Read then read coordinates and intensities and return early
	if (m_XYZIntOnly) {

		// Since we only read XYZ and Intensities, we have to shift the pointer to the start of the next point. XYZInt are 14 Bytes (Example Record Length = 20 -> Shit pointer by 6 bytes to start of next point)
		int pointerShiftAfterIntensity = m_header.PointDataRecordLength - 14;

		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			// Read Buffer
			lasBin.read(buffer, bufferSize);

			// Pointer to start of Buffer
			char* pBuffer = buffer;

			//If last chunk is to be processed then change pointsToProcessInBuffer to pointsLeftToRead because last chunk is probably not full
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			//Process Buffer
			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				pBuffer += pointerShiftAfterIntensity;
			}
		}
		return;
	}

	// If everything is consistent up to here then try to read according to point data format
	// using switch case for 11 record formats. Not pretty but no additional branching in loop neccessary.
	switch ((unsigned short)m_header.PointDataRecordFormat)
	{
	case 0:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			// Read Buffer
			lasBin.read(buffer, bufferSize);

			// (Re)set Pointer to start of Buffer
			char* pBuffer = buffer;

			//If last chunk is to be processed then change pointsToProcessInBuffer to pointsLeftToRead because last chunk is probably not full
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			//Process Buffer
			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 1:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 2:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				readRGB(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 3:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i) {

				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readRGB(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 4:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readPointWavePacket(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 5:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readClassification(pBuffer);
				readScanAngle_8b(pBuffer);
				readUserData(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readRGB(pBuffer);
				readPointWavePacket(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 6:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readBits2(pBuffer);
				readClassification(pBuffer);
				readUserData(pBuffer);
				readScanAngle_16b(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 7:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readBits2(pBuffer);
				readClassification(pBuffer);
				readUserData(pBuffer);
				readScanAngle_16b(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readRGB(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 8:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readBits2(pBuffer);
				readClassification(pBuffer);
				readUserData(pBuffer);
				readScanAngle_16b(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readRGB(pBuffer);
				readNIR(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 9:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i) {

				readXYZInt(pBuffer);
				readBits(pBuffer);
				readBits2(pBuffer);
				readClassification(pBuffer);
				readUserData(pBuffer);
				readScanAngle_16b(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readPointWavePacket(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	case 10:
	{
		for (uint_fast64_t j = 0; j < (fullChunksCount + 1); ++j)
		{
			lasBin.read(buffer, bufferSize);
			char* pBuffer = buffer;
			if (j == fullChunksCount) { pointsToProcessInBuffer = pointsLeftToRead; }

			for (int i = 0; i < pointsToProcessInBuffer; ++i)
			{
				readXYZInt(pBuffer);
				readBits(pBuffer);
				readBits2(pBuffer);
				readClassification(pBuffer);
				readUserData(pBuffer);
				readScanAngle_16b(pBuffer);
				readPointSourceID(pBuffer);
				readGPSTime(pBuffer);
				readRGB(pBuffer);
				readNIR(pBuffer);
				readPointWavePacket(pBuffer);
				if (m_containsExtraBytes)
					readExtrabytes(pBuffer);
			}
		}
		break;
	}
	default:
	{
		char buffer[100];
		sprintf(buffer, "Point Data Format %d not supported!", m_header.PointDataRecordFormat);
		mexErrMsgIdAndTxt("MEX:ReadPointData::invalidformat", buffer);

	}
	}

	// Unbuffer stream, though this is implementation defined
	lasBin.rdbuf()->pubsetbuf(0, 0);
}


bool LASdataReader::CheckHeaderConsistency(std::ifstream& lasBin)
{
	bool isHeaderGood = true;

	if (m_internalPointDataRecordID == -1) {
		setInternalRecordFormatID();
	}

	char lasf[] = "LASF";
	if (strcmp(m_header.fileSignature, lasf) != 0)
	{
		mexErrMsgIdAndTxt("MEX:CheckHeaderConsistency:invalidheader", "File Signature of provided file is not LASF. This function is only to be used on LAS-Files containing LIDAR data!");
	}

	if (m_header.versionMinor > 4)
	{
		mexWarnMsgIdAndTxt("MEX:checkHeaderConsistency:notimplemented", "Version Minor bigger than 4 not actively supported!\n");
	}

	if (m_header.offsetToPointData < m_header.headerSize) {
		mexWarnMsgIdAndTxt("MEX:checkHeaderConsistency:invalidheader", "Critical Error: Offset to Point Data is smaller than header size!\n"); 
		isHeaderGood = false;
	}

	if (m_header.PointDataRecordFormat > 10)
	{
		m_XYZIntOnly = true;
		mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:notimplemented", "Point Data Format bigger than 10 is not officialy supported!\n\t\t Reading coordinates and intensities only! This might fail!");
	}

	if (m_header.PointDataRecordFormat > 127)
	{
		mexWarnMsgIdAndTxt("MEX:readLasFile:CheckHeaderConsistency:notimplemented", "File is LAZ (LASZip) File and is not supported by this function!"); 
		isHeaderGood = false;
	}

	if (m_header.versionMajor != 1)
	{
		mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:invalidheader", "Version Major other than 1 is not supported!\n"); 
		isHeaderGood = false;
	}

	// Check if point data length is longer than allowed min
	if (m_internalPointDataRecordID != -1)
	{
		if (m_header.PointDataRecordLength < m_minAllowedRecordLength) {
			char buffer[100];
			sprintf_s(buffer, "PointDataRecordLength is smaller than %d! LAS Reading will be cancelled!", m_minAllowedRecordLength);
			mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:invalidheader", buffer); 
			isHeaderGood = false;
		}
	}
	else {
		mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:notimplemented", "PointDataRecordFormat is unknown! Reading coordinates and intensities only! This might fail!");
		m_XYZIntOnly = true;
	}

	/* File consistency checks */
	// Check if enough bytes available in file to fill output arrays
	// Seek File End
	lasBin.seekg(0, lasBin.end);
	uint_fast64_t byteCountToEOF = lasBin.tellg();
	uint_fast64_t availableBytes = byteCountToEOF - m_header.offsetToPointData;

	// If the m_numberOfPointsToRead is bigger than the practically possible point count, then abort because header and file contents are definitely inconsistent
	if ((availableBytes / ((uint_fast64_t)m_header.PointDataRecordLength)) < m_numberOfPointsToRead) {
		mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:invalidheader", "According to header the file contains more Points than the filesize allows!\n");
		isHeaderGood = false;
	}

	if (m_numberOfPointsToRead < 1) {
		mexWarnMsgIdAndTxt("MEX:CheckHeaderConsistency:invalidheader", "Number of Point Records from Offset is zero according to parsed header. File apparently has no points!\n");
		isHeaderGood = false;
	}

	return isHeaderGood;
}

void LASdataReader::SetReadXYZIntOnly(bool m_XYZIntOnly_flag) {
	m_XYZIntOnly = m_XYZIntOnly_flag;
}

