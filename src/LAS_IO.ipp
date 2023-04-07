#if _MSC_VER > 1400
#pragma once
#endif

#ifndef LAS_IO_IMPL
#define LAS_IO_IMPL

// Assign the PDRF to an index to retrieve byte offsets for all fields
inline void LAS_IO::setInternalRecordFormatID()
{
	auto it = find(m_supported_record_formats.begin(), m_supported_record_formats.end(), m_header.PointDataRecordFormat);

	if (it != m_supported_record_formats.end())
	{
		m_internalPointDataRecordID = static_cast<size_t>(std::distance(m_supported_record_formats.begin(), it));
	}
	else
	{
		m_internalPointDataRecordID = 0;
	}
}

// Set Flags for colors, time, wave packets, NIR, VLR and extrabytes
inline void LAS_IO::setContentFlags()
{

	setInternalRecordFormatID();

	m_containsTime = false;
	if (m_time_Byte[m_internalPointDataRecordID] != 0) {
		m_containsTime = true;
	}

	m_containsColors = false;
	if (m_color_Byte[m_internalPointDataRecordID] != 0) {
		m_containsColors = true;
	}

	m_containsWavepackets = false;
	if (m_wavePackets_Byte[m_internalPointDataRecordID] != 0) {
		m_containsWavepackets = true;
	}

	m_containsNIR = false;
	if (m_NIR_Byte[m_internalPointDataRecordID] != 0) {
		m_containsNIR = true;
	}

	m_extraByteCount = 0;
	if (m_internalPointDataRecordID != -1 && m_internalPointDataRecordID < m_record_lengths.size())
	{
		if (m_header.PointDataRecordLength > m_record_lengths[m_internalPointDataRecordID])
		{
			m_containsExtraBytes = true;
			m_extraByteCount = m_header.PointDataRecordLength - m_record_lengths[m_internalPointDataRecordID];
		}
	}
}

/* Read methods for fields of the point data record*/
// Read XYZ Point Data,Intensities, advance the data and buffer pointer
inline void LASdataReader::readXYZInt(char*& pBuffer)
{
	*m_mxStructPointer.pX = ((double)*reinterpret_cast<int32_t*>(pBuffer) * m_header.xScaleFactor) + m_header.xOffset;
	m_mxStructPointer.pX++;

	*m_mxStructPointer.pY = ((double)*reinterpret_cast<int32_t*>(pBuffer + 4) * m_header.yScaleFactor) + m_header.yOffset;
	m_mxStructPointer.pY++;

	*m_mxStructPointer.pZ = ((double)*reinterpret_cast<int32_t*>(pBuffer + 8) * m_header.zScaleFactor) + m_header.zOffset;
	m_mxStructPointer.pZ++;

	*m_mxStructPointer.pIntensity = *reinterpret_cast<uint16_t*>(pBuffer + 12);
	m_mxStructPointer.pIntensity++;
	pBuffer += 14;
}

// Read byte which contains different bit sized fields, advance the data and buffer pointer
inline void LASdataReader::readBits(char*& pBuffer)
{
	*m_mxStructPointer.pBits = *reinterpret_cast<uint8_t*>(pBuffer);
	m_mxStructPointer.pBits++;
	pBuffer += 1;
}

// Read second byte which contains different bit sized fields, advance the data and buffer pointer
inline void LASdataReader::readBits2(char*& pBuffer)
{
	*m_mxStructPointer.pBits2 = *reinterpret_cast<uint8_t*>(pBuffer);
	m_mxStructPointer.pBits2++;
	pBuffer += 1;
}

// Read Classification, advance the data and buffer pointer
inline void LASdataReader::readClassification(char*& pBuffer)
{
	*m_mxStructPointer.pClassicfication = *reinterpret_cast<uint8_t*>(pBuffer);
	m_mxStructPointer.pClassicfication++;
	pBuffer += 1;
}

// Read 8Bit Scan Angle, advance the data and buffer pointer
inline void LASdataReader::readScanAngle_8b(char*& pBuffer)
{
	*m_mxStructPointer.pScanAngle = *reinterpret_cast<int8_t*>(pBuffer);
	m_mxStructPointer.pScanAngle++;
	pBuffer += 1;
}

// Read 16Bit Scan Angle, advance the data and buffer pointer
inline void LASdataReader::readScanAngle_16b(char*& pBuffer)
{
	*m_mxStructPointer.pScanAngle_16Bit = *reinterpret_cast<int16_t*>(pBuffer);
	m_mxStructPointer.pScanAngle_16Bit++;
	pBuffer += 2;
}

// Read User Data, advance the data and buffer pointer
inline void LASdataReader::readUserData(char*& pBuffer)
{
	*m_mxStructPointer.pUserData = *reinterpret_cast<uint8_t*>(pBuffer);
	m_mxStructPointer.pUserData++;
	pBuffer += 1;
}

// Read PointSourceID, advance the data and buffer pointer
inline void LASdataReader::readPointSourceID(char*& pBuffer)
{
	*m_mxStructPointer.pPointSourceID = *reinterpret_cast<uint16_t*>(pBuffer);
	m_mxStructPointer.pPointSourceID++;
	pBuffer += 2;
}

// Read GPS Time, advance the data and buffer pointer
inline void LASdataReader::readGPSTime(char*& pBuffer)
{
	*m_mxStructPointer.pGPS_Time = *reinterpret_cast<double*>(pBuffer);
	m_mxStructPointer.pGPS_Time++;
	pBuffer += 8;
}

// Read three RGB Color Values, advance the data and buffer pointer
inline void LASdataReader::readRGB(char*& pBuffer)
{
	*m_mxStructPointer.pRed = *reinterpret_cast<uint16_t*>(pBuffer);
	m_mxStructPointer.pRed++;

	*m_mxStructPointer.pGreen = *reinterpret_cast<uint16_t*>(pBuffer + 2);
	m_mxStructPointer.pGreen++;

	*m_mxStructPointer.pBlue = *reinterpret_cast<uint16_t*>(pBuffer + 4);
	m_mxStructPointer.pBlue++;
	pBuffer += 6;
}

// Read 7 Wave Packet components, advance the data and buffer pointer
inline void LASdataReader::readPointWavePacket(char*& pBuffer)
{
	*m_mxStructPointer.pWavePacketDescriptor = *reinterpret_cast<uint8_t*>(pBuffer);
	m_mxStructPointer.pWavePacketDescriptor++;

	*m_mxStructPointer.pWaveByteOffset = *reinterpret_cast<uint64_t*>(pBuffer + 1);
	m_mxStructPointer.pWaveByteOffset++;

	*m_mxStructPointer.pWavePacketSize = *reinterpret_cast<uint32_t*>(pBuffer + 9);
	m_mxStructPointer.pWavePacketSize++;

	*m_mxStructPointer.pWaveReturnPoint = *reinterpret_cast<float*>(pBuffer + 13);
	m_mxStructPointer.pWaveReturnPoint++;

	*m_mxStructPointer.pWaveXt = *reinterpret_cast<float*>(pBuffer + 17);
	m_mxStructPointer.pWaveXt++;

	*m_mxStructPointer.pWaveYt = *reinterpret_cast<float*>(pBuffer + 21);
	m_mxStructPointer.pWaveYt++;

	*m_mxStructPointer.pWaveZt = *reinterpret_cast<float*>(pBuffer + 25);
	m_mxStructPointer.pWaveZt++;
	pBuffer += 29;
}

// Read NIR Value, advance the data and buffer pointer
inline void LASdataReader::readNIR(char*& pBuffer)
{
	*m_mxStructPointer.pNIR = *reinterpret_cast<uint16_t*>(pBuffer);
	m_mxStructPointer.pNIR++;
	pBuffer += 2;
}

inline void LASdataReader::readExtrabytes(char*& pBuffer)
{
	for (int i = 0; i < m_extraByteCount; ++i)
	{
		*m_mxStructPointer.pExtraBytes = *reinterpret_cast<uint8_t*>(pBuffer);
		++m_mxStructPointer.pExtraBytes;
		++pBuffer;
	}
}

inline void LASdataWriter::copyMXCharToArray(char* pCharDestination, const mxChar* const pMXCharSource, size_t count)
{
	char copyChar;

	if (nullptr == pMXCharSource || nullptr == pCharDestination)
	{
		return;
	}

	for (size_t i = 0; i < count; ++i)
	{
		copyChar = static_cast<char>(pMXCharSource[i]);
		if (copyChar == 0) {
			break;
		}
		pCharDestination[i] = copyChar;
	}
}

#endif