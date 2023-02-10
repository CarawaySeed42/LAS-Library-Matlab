#include "mex.h"
#include <cstring>
#include <memory>
#include "LAS_IO.cpp"

#if MX_HAS_INTERLEAVED_COMPLEX

#define GetUint8	mxGetUint8s
#define GetUint16	mxGetUint16s
#define GetUint64	mxGetUint64s

#else

#define GetUint8	(mxUint8*)	mxGetPr
#define GetUint16	(mxUint16*) mxGetPr
#define GetUint64	(mxUint64*) mxGetPr

#endif

void LasDataReader::setStreamToVLRHeader(std::ifstream& lasBin)
{
	// If end of file was reached during reading then clear bits to allow further reading and seeking for small files
	if (lasBin.eof()) {
		lasBin.clear();
	}
	lasBin.seekg(m_header.headerSize, lasBin.beg);
}

void LasDataReader::setStreamToExtVLRHeader(std::ifstream& lasBin)
{
	// If end of file was reached during reading then clear bits to allow further reading and seeking for small files
	if (lasBin.eof()) {
		lasBin.clear();
	}
	lasBin.seekg(m_headerExt4.startOfFirstExtendedVariableLengthRecord, lasBin.beg);
}

bool LasDataReader::HasVLR() {
	return m_header.numberOfVariableLengthRecords > 0;
}

bool LasDataReader::HasExtVLR() {
	return m_headerExt4.numberOfExtendedVariableLengthRecords > 0;
}

void LasDataReader::readVLRHeader(std::ifstream& lasBin)
{
	char* pBuffer = &m_VLRHeader.vlrhBytes[0];
	lasBin.read(pBuffer, 54);

	m_VLRHeader.reserved				= *reinterpret_cast<unsigned short*>(pBuffer);
	m_VLRHeader.recordID				= *reinterpret_cast<unsigned short*>(pBuffer + 18);
	m_VLRHeader.recordLengthAfterHeader = *reinterpret_cast<unsigned short*>(pBuffer + 20);
	std::memcpy(m_VLRHeader.userID		, pBuffer + 2,  16 * sizeof(char));
	std::memcpy(m_VLRHeader.description	, pBuffer + 22, 32 * sizeof(char));
}

void LasDataReader::readExtVLRHeader(std::ifstream& lasBin)
{
	char* pBuffer = &m_ExtVLRHeader.extvlrhBytes[0];
	lasBin.read(pBuffer, 60);

	m_ExtVLRHeader.reserved					= *reinterpret_cast<unsigned short*>(pBuffer);
	m_ExtVLRHeader.recordID					= *reinterpret_cast<unsigned short*>(pBuffer + 18);
	m_ExtVLRHeader.recordLengthAfterHeader	= *reinterpret_cast<unsigned long long*>(pBuffer + 20);
	std::memcpy(m_ExtVLRHeader.userID		, pBuffer + 2,  16 * sizeof(char));
	std::memcpy(m_ExtVLRHeader.description	, pBuffer + 28, 32 * sizeof(char));
}

mxArray* LasDataReader::createMXVLRStruct(mxArray * plhs[])
{
	const char* field_names[] = { "reserved", "user_id", "record_id", "record_length","description", "data", "data_as_text" };
	mwSize dimsStruct[2] = { m_header.numberOfVariableLengthRecords, 7 };

	mxArray* vlrhStruct = mxCreateStructArray(1, dimsStruct, 7, field_names);

	mxSetField(plhs[0], 0, "variablerecords", vlrhStruct);
	return mxGetField(plhs[0], 0, "variablerecords");
}

mxArray* LasDataReader::createMXExtVLRStruct(mxArray* plhs[])
{
	const char* field_names[] = { "reserved", "user_id", "record_id", "record_length","description", "data", "data_as_text" };
	mwSize dimsStruct[2] = { m_headerExt4.numberOfExtendedVariableLengthRecords, 7 };

	mxArray* extvlrhStruct = mxCreateStructArray(1, dimsStruct, 7, field_names);

	mxSetField(plhs[0], 0, "extendedvariables", extvlrhStruct);
	return mxGetField(plhs[0], 0, "extendedvariables");
}

void LasDataReader::ReadVLR(mxArray* plhs[], std::ifstream& lasBin)
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
		std::memcpy(pUINT8, readBuffer, m_VLRHeader.recordLengthAfterHeader * sizeof(char));
		mxSetField(vlrhStruct, i, "data", pMXArray);

		mwSize dimsCharacters[2] = { 1, m_VLRHeader.recordLengthAfterHeader};
		dataText = mxCreateCharArray(2, dimsCharacters);
		mxChar* pDataText = mxGetChars(dataText);
		for (int j = 0; j < m_VLRHeader.recordLengthAfterHeader; ++j) { pDataText[j] = readBuffer[j]; }
		mxSetField(vlrhStruct, i, "data_as_text", dataText);
	}
}

void LasDataReader::ReadExtVLR(mxArray* plhs[], std::ifstream& lasBin)
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

void LasDataWriter::GetVLRData(mxArray* plhs[], size_t VLRindex) {

}