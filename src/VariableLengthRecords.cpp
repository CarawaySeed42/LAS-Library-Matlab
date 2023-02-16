#include "mex.h"
#include <cstring>
#include <memory>
#include "LAS_IO.cpp"

#if MX_HAS_INTERLEAVED_COMPLEX

#define GetChars	mxGetChars
#define GetUint8	mxGetUint8s
#define GetUint16	mxGetUint16s
#define GetUint64	mxGetUint64s

#else

#define GetChars	(mxChar*)	mxGetPr
#define GetUint8	(mxUint8*)	mxGetPr
#define GetUint16	(mxUint16*) mxGetPr
#define GetUint64	(mxUint64*) mxGetPr

#endif

void LAS_IO::setStreamToVLRHeader(std::ifstream& lasBin)
{
	// If end of file was reached during reading then clear bits to allow further reading and seeking for small files
	if (lasBin.eof()) {
		lasBin.clear();
	}
	lasBin.seekg(m_header.headerSize, lasBin.beg);
}

void LAS_IO::setStreamToExtVLRHeader(std::ifstream& lasBin)
{
	// If end of file was reached during reading then clear bits to allow further reading and seeking for small files
	if (lasBin.eof()) {
		lasBin.clear();
	}
	lasBin.seekg(m_headerExt4.startOfFirstExtendedVariableLengthRecord, lasBin.beg);
}

bool LAS_IO::HasVLR() {
	return m_header.numberOfVariableLengthRecords > 0;
}

bool LAS_IO::HasExtVLR() {
	return m_headerExt4.numberOfExtendedVariableLengthRecords > 0;
}

void LasDataReader::readVLRHeader(std::ifstream& lasBin)
{
	char* pBuffer = &m_VLRHeader.vlrhBytes[0];
	lasBin.read(pBuffer, 54);

	m_VLRHeader.reserved				= *reinterpret_cast<uint16_t*>(pBuffer);
	m_VLRHeader.recordID				= *reinterpret_cast<uint16_t*>(pBuffer + 18);
	m_VLRHeader.recordLengthAfterHeader = *reinterpret_cast<uint16_t*>(pBuffer + 20);
	std::memcpy(m_VLRHeader.userID		, pBuffer + 2,  16);
	std::memcpy(m_VLRHeader.description	, pBuffer + 22, 32);
}

void LasDataReader::readExtVLRHeader(std::ifstream& lasBin)
{
	char* pBuffer = &m_ExtVLRHeader.extvlrhBytes[0];
	lasBin.read(pBuffer, 60);

	m_ExtVLRHeader.reserved					= *reinterpret_cast<uint16_t*>(pBuffer);
	m_ExtVLRHeader.recordID					= *reinterpret_cast<uint16_t*>(pBuffer + 18);
	m_ExtVLRHeader.recordLengthAfterHeader	= *reinterpret_cast<uint64_t*>(pBuffer + 20);
	std::memcpy(m_ExtVLRHeader.userID		, pBuffer + 2,  16);
	std::memcpy(m_ExtVLRHeader.description	, pBuffer + 28, 32);
}

mxArray* LasDataReader::createMXVLRStruct(mxArray*& plhs)
{
	const char* field_names[] = { "reserved", "user_id", "record_id", "record_length","description", "data", "data_as_text" };
	mwSize dimsStruct[2] = { m_header.numberOfVariableLengthRecords, 7 };

	mxArray* vlrhStruct = mxCreateStructArray(1, dimsStruct, 7, field_names);

	mxSetField(plhs, 0, "variablerecords", vlrhStruct);
	return mxGetField(plhs, 0, "variablerecords");
}

mxArray* LasDataReader::createMXExtVLRStruct(mxArray*& plhs)
{
	const char* field_names[] = { "reserved", "user_id", "record_id", "record_length","description", "data", "data_as_text" };
	mwSize dimsStruct[2] = { m_headerExt4.numberOfExtendedVariableLengthRecords, 7 };

	mxArray* extvlrhStruct = mxCreateStructArray(1, dimsStruct, 7, field_names);

	mxSetField(plhs, 0, "extendedvariables", extvlrhStruct);
	return mxGetField(plhs, 0, "extendedvariables");
}

void LasDataReader::ReadVLR(mxArray*& plhs, std::ifstream& lasBin)
{
	mxArray*  pMXArray;
	mxArray*  tempMXString;
	mxUint16* pUINT16;
	mxUint8*  pUINT8;
	mxArray*  dataText;

	setStreamToVLRHeader(lasBin);
	mxArray* vlrhStruct = createMXVLRStruct(plhs);

	for (unsigned long i = 0; i < m_header.numberOfVariableLengthRecords; ++i) 
	{
		// Read VLR Header and write contents to plhs
		readVLRHeader(lasBin);	
		
		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
		pUINT16 = GetUint16(pMXArray);
		*pUINT16 = m_VLRHeader.reserved;
		mxSetField(vlrhStruct, i, "reserved", pMXArray);

		tempMXString = mxCreateString(m_VLRHeader.userID);
		mxSetField(vlrhStruct, i, "user_id", tempMXString);

		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
		pUINT16 = GetUint16(pMXArray);
		*pUINT16 = m_VLRHeader.recordID;
		mxSetField(vlrhStruct, i, "record_id", pMXArray);

		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
		pUINT16 = GetUint16(pMXArray);
		*pUINT16 = m_VLRHeader.recordLengthAfterHeader;
		mxSetField(vlrhStruct, i, "record_length", pMXArray);

		tempMXString = mxCreateString(m_VLRHeader.description);
		mxSetField(vlrhStruct, i, "description", tempMXString);

		// Read VLR Data and write contents to plhs
		std::unique_ptr<char[]>  uniqueBuffer(new char[m_VLRHeader.recordLengthAfterHeader]);
		char* readBuffer = uniqueBuffer.get();
		lasBin.read(readBuffer, m_VLRHeader.recordLengthAfterHeader);

		pMXArray = mxCreateNumericMatrix(m_VLRHeader.recordLengthAfterHeader, 1,  mxUINT8_CLASS, mxREAL);
		pUINT8 = GetUint8(pMXArray);
		std::memcpy(pUINT8, readBuffer, m_VLRHeader.recordLengthAfterHeader);
		mxSetField(vlrhStruct, i, "data", pMXArray);

		mwSize dimsCharacters[2] = { 1, m_VLRHeader.recordLengthAfterHeader};
		dataText = mxCreateCharArray(2, dimsCharacters);
		mxChar* pDataText = mxGetChars(dataText);
		for (int j = 0; j < m_VLRHeader.recordLengthAfterHeader; ++j) { pDataText[j] = readBuffer[j]; }
		mxSetField(vlrhStruct, i, "data_as_text", dataText);
	}
}

void LasDataReader::ReadExtVLR(mxArray*& plhs, std::ifstream& lasBin)
{
	mxArray*	pMXArray;
	mxArray*	tempMXString;
	mxUint16*	pUINT16;
	mxUint64*	pUINT64;
	mxUint8*	pUINT8;
	mxArray*	dataText;

	setStreamToExtVLRHeader(lasBin);
	mxArray* extvlrhStruct = createMXExtVLRStruct(plhs);

	for (unsigned long i = 0; i < m_headerExt4.numberOfExtendedVariableLengthRecords; ++i)
	{
		// Read VLR Header and write contents to plhs
		readExtVLRHeader(lasBin);

		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
		pUINT16 = GetUint16(pMXArray);
		*pUINT16 = m_ExtVLRHeader.reserved;
		mxSetField(extvlrhStruct, i, "reserved", pMXArray);

		tempMXString = mxCreateString(m_ExtVLRHeader.userID);
		mxSetField(extvlrhStruct, i, "user_id", tempMXString);

		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT16_CLASS, mxREAL);
		pUINT16 = GetUint16(pMXArray);
		*pUINT16 = m_ExtVLRHeader.recordID;
		mxSetField(extvlrhStruct, i, "record_id", pMXArray);

		pMXArray = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
		pUINT64 = GetUint64(pMXArray);
		*pUINT64 = m_ExtVLRHeader.recordLengthAfterHeader;
		mxSetField(extvlrhStruct, i, "record_length", pMXArray);

		tempMXString = mxCreateString(m_ExtVLRHeader.description);
		mxSetField(extvlrhStruct, i, "description", tempMXString);

		// Read VLR Data and write contents to plhs
		std::unique_ptr<char[]>  uniqueBuffer(new char[m_ExtVLRHeader.recordLengthAfterHeader]);
		char* readBuffer = uniqueBuffer.get();
		lasBin.read(readBuffer, m_ExtVLRHeader.recordLengthAfterHeader);

		pMXArray = mxCreateNumericMatrix(m_ExtVLRHeader.recordLengthAfterHeader, 1,  mxUINT8_CLASS, mxREAL);
		pUINT8 = GetUint8(pMXArray);
		std::memcpy(pUINT8, readBuffer, m_ExtVLRHeader.recordLengthAfterHeader);
		mxSetField(extvlrhStruct, i, "data", pMXArray);

		mwSize dimsCharacters[2] = { 1, m_ExtVLRHeader.recordLengthAfterHeader };
		dataText = mxCreateCharArray(2, dimsCharacters);
		mxChar* pDataText = mxGetChars(dataText);
		for (int j = 0; j < m_ExtVLRHeader.recordLengthAfterHeader; ++j) { pDataText[j] = readBuffer[j]; }
		mxSetField(extvlrhStruct, i, "data_as_text", dataText);
	}
}


void LasDataWriter::GetVLRHeader(mxArray* pVLRfield, size_t VLRindex) {

	mxChar* pMXChar;

	m_VLRHeader.reserved = static_cast<unsigned short>(*GetUint16(mxGetField(pVLRfield, VLRindex, "reserved")));
	m_VLRHeader.recordID = static_cast<unsigned short>(*GetUint16(mxGetField(pVLRfield, VLRindex, "record_id")));
	m_VLRHeader.recordLengthAfterHeader = static_cast<unsigned short>(*GetUint16(mxGetField(pVLRfield, (mwIndex)VLRindex, "record_length")));

	// User_id and Description are char arrays
	pMXChar = GetChars(mxGetField(pVLRfield, (mwIndex)VLRindex, "user_id"));
	if (nullptr != pMXChar) {
		for (int i = 0; i < 16; ++i) {
			char copyChar = static_cast<char>(pMXChar[i]);
			if (copyChar == 0) {
				break;
			}

			m_VLRHeader.userID[i] = copyChar;
		}
	}

	pMXChar = GetChars(mxGetField(pVLRfield, (mwIndex)VLRindex, "description"));
	if (nullptr != pMXChar) {
		for (int i = 0; i < 32; ++i) {
			char copyChar = static_cast<char>(pMXChar[i]);
			if (copyChar == 0) {
				break;
			}

			m_VLRHeader.description[i] = copyChar;
		}
	}

	// Get header in single char array as it will be written
	std::memcpy(m_VLRHeader.vlrhBytes,      &m_VLRHeader.reserved,  2);
	std::memcpy(m_VLRHeader.vlrhBytes +  2, &m_VLRHeader.userID,   16);
	std::memcpy(m_VLRHeader.vlrhBytes + 18, &m_VLRHeader.recordID,  2);
	std::memcpy(m_VLRHeader.vlrhBytes + 20, &m_VLRHeader.recordLengthAfterHeader, 2);
	std::memcpy(m_VLRHeader.vlrhBytes + 22, &m_VLRHeader.description, 32);
}

bool LasDataWriter::WriteVLR(std::ofstream& lasBin, const mxArray* matlabInput)
{
	mxArray* pVLRfield = mxGetField(matlabInput, 0, "variablerecords");

	for (size_t i = 0; i < m_header.numberOfVariableLengthRecords; ++i) {

		// Get header, write header, then write data
		GetVLRHeader(pVLRfield, i);
		lasBin.write(m_VLRHeader.vlrhBytes, 54);

		// Get and write data
		if (m_VLRHeader.recordLengthAfterHeader > 0) {
			mxUint8* dataPointer = GetUint8(mxGetField(pVLRfield, i, "data"));
			lasBin.write((char*)dataPointer, m_VLRHeader.recordLengthAfterHeader);
		}
	}

	return true;
}

void LasDataWriter::GetExtVLRHeader(mxArray* pVLRfield, size_t VLRindex) {

	mxChar* pMXChar;

	m_ExtVLRHeader.reserved = static_cast<unsigned short>(*GetUint16(mxGetField(pVLRfield, VLRindex, "reserved")));
	m_ExtVLRHeader.recordID = static_cast<unsigned short>(*GetUint16(mxGetField(pVLRfield, VLRindex, "record_id")));
	m_ExtVLRHeader.recordLengthAfterHeader = static_cast<unsigned long long>(*GetUint64(mxGetField(pVLRfield, (mwIndex)VLRindex, "record_length")));

	// User_id and Description are char arrays
	pMXChar = GetChars(mxGetField(pVLRfield, (mwIndex)VLRindex, "user_id"));
	if (nullptr != pMXChar) {
		for (int i = 0; i < 16; ++i) {
			char copyChar = static_cast<char>(pMXChar[i]);
			if (copyChar == 0) {
				break;
			}

			m_ExtVLRHeader.userID[i] = copyChar;
		}
	}

	pMXChar = GetChars(mxGetField(pVLRfield, (mwIndex)VLRindex, "description"));
	if (nullptr != pMXChar) {
		for (int i = 0; i < 32; ++i) {
			char copyChar = static_cast<char>(pMXChar[i]);
			if (copyChar == 0) {
				break;
			}

			m_ExtVLRHeader.description[i] = copyChar;
		}
	}

	// Get header in single char array as it will be written
	std::memcpy(m_ExtVLRHeader.extvlrhBytes, &m_ExtVLRHeader.reserved, 2);
	std::memcpy(m_ExtVLRHeader.extvlrhBytes + 2, &m_ExtVLRHeader.userID, 16);
	std::memcpy(m_ExtVLRHeader.extvlrhBytes + 18, &m_ExtVLRHeader.recordID, 2);
	std::memcpy(m_ExtVLRHeader.extvlrhBytes + 20, &m_ExtVLRHeader.recordLengthAfterHeader, 8);
	std::memcpy(m_ExtVLRHeader.extvlrhBytes + 28, &m_ExtVLRHeader.description, 32);
}

bool LasDataWriter::WriteExtVLR(std::ofstream& lasBin, const mxArray* matlabInput)
{
	mxArray* pExtVLRfield = mxGetField(matlabInput, 0, "extendedvariables");

	for (size_t i = 0; i < m_header.numberOfVariableLengthRecords; ++i) {

		// Get header, write header, then write data
		GetExtVLRHeader(pExtVLRfield, i);
		lasBin.write(m_ExtVLRHeader.extvlrhBytes, 54);

		// Get and write data
		if (m_ExtVLRHeader.recordLengthAfterHeader > 0) {
			mxUint8* dataPointer = GetUint8(mxGetField(pExtVLRfield, i, "data"));
			lasBin.write((char*)dataPointer, m_ExtVLRHeader.recordLengthAfterHeader);
		}
	}

	return true;
}
