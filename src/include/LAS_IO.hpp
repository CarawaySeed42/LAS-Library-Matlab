#if _MSC_VER > 1400
#pragma once
#endif

#ifndef LAS_IO_H
#define LAS_IO_H

#include "mex.h"
#include <array>
#include <fstream>

// Ths is the header f�le for base class LAS_IO and derived classes LASDataReader and LASDataWriter
// Info: private and protected methods start with lower case letter. Publc methods start with upper case letter.

// Check if datatype sizes are LAS conform during compilation. 
static_assert(sizeof(char) == 1, "Type Char should have a size of 1 byte! But is not on this machine!");
static_assert(sizeof(unsigned char) == 1, "Type Unsigned Char should have a size of 1 byte! But is not on this machine!");
static_assert(sizeof(unsigned short) == 2, "Type Unsigned Short should have a size of 2 bytes! But is not on this machine!");
static_assert(sizeof(unsigned long) == 4, "Type Unsigned Long should have a size of 4 bytes! But is not on this machine!");
static_assert(sizeof(unsigned long long) == 8, "Type Unsigned Long Long should have a size of 8 bytes! But is not on this machine!");
static_assert(sizeof(long) == 4, "Type Long should have a size of 4 bytes! But is not on this machine!");
static_assert(sizeof(float) == 4, "Type Float should have a size of 4 bytes! But is not on this machine!");
static_assert(sizeof(double) == 8, "Type Double should have a size of 8 bytes! But is not on this machine!");

static_assert(sizeof(uint8_t) == 1, "Type uint8_t should have a size of 1 byte! But is not on this machine!");
static_assert(sizeof(uint16_t) == 2, "Type uint16_t should have a size of 2 bytes! But is not on this machine!");
static_assert(sizeof(uint32_t) == 4, "Type uint32_t should have a size of 4 bytes! But is not on this machine!");
static_assert(sizeof(uint64_t) == 8, "Type uint64_t should have a size of 8 bytes! But is not on this machine!");
static_assert(sizeof(int8_t) == 1, "Type int8_t should have a size of 1 byte! But is not on this machine!");
static_assert(sizeof(int16_t) == 2, "Type int16_t should have a size of 2 bytes! But is not on this machine!");
static_assert(sizeof(int32_t) == 4, "Type int32_t should have a size of 4 bytes! But is not on this machine!");
static_assert(sizeof(int64_t) == 8, "Type int64_t should have a size of 8 bytes! But is not on this machine!");

// Compile Time Constants
constexpr size_t RecordFormatCount = 11;


class LAS_IO 
{
protected:

	// Las Header struct according to LAS 1.2 Specs (char arrays are null terminated)
	struct LASheader
	{
		char			fileSignature[5]		= { '\0' };
		unsigned short	sourceID				= 0;
		unsigned short	globalEncoding			= 0;
		unsigned long	projectID_GUID_1		= 0;
		unsigned short	projectID_GUID_2		= 0;
		unsigned short	projectID_GUID_3		= 0;
		unsigned char	projectID_GUID_4[8]		= {};
		unsigned char	versionMajor			= 0;
		unsigned char	versionMinor			= 0;
		char			systemIdentifier[33]	= { '\0' };
		char			generatingSoftware[33]	= { '\0' };
		unsigned short	fileCreationDayOfYear	= 0;
		unsigned short	fileCreationYear		= 0;
		unsigned short	headerSize				= 0;
		unsigned long	offsetToPointData		= 0;

		unsigned long	numberOfVariableLengthRecords	=  0;
		unsigned char	PointDataRecordFormat			= -1;
		unsigned short	PointDataRecordLength			=  0;
		unsigned long	LegacyNumberOfPointRecords		=  0;
		unsigned long	LegacyNumberOfPointByReturn[5]	= { 0, 0, 0, 0, 0 };

		double xScaleFactor = 0;
		double yScaleFactor = 0;
		double zScaleFactor = 0;
		double xOffset		= 0;
		double yOffset		= 0;
		double zOffset		= 0;
		double maxX			= 0;
		double maxY			= 0;
		double maxZ			= 0;
		double minX			= 0;
		double minY			= 0;
		double minZ			= 0;

	} m_header;

	// LAS Header Extension introduced with LAS 1.3
	struct LASheaderExt3
	{
		unsigned long long startOfWaveFormData = 0;
	} m_headerExt3;

	// LAS Header Extension introduced with LAS 1.4
	struct LASheaderExt4
	{
		unsigned long long	startOfFirstExtendedVariableLengthRecord = 0;
		unsigned long		numberOfExtendedVariableLengthRecords	 = 0;
		unsigned long long	numberOfPointRecords					 = 0;
		unsigned long long	numberOfPointsByReturn[15] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
	} m_headerExt4;

	struct VLRHeader 
	{
		char			vlrhBytes[55] = { '\0' };			// 54 Raw Bytes from of variable length record header
		unsigned short	reserved;							// 2 bytes
		char			userID[17] = { '\0' };				// 16 bytes
		unsigned short	recordID;							// 2 bytes
		unsigned short	recordLengthAfterHeader;			// 2 bytes
		char			description[33] = { '\0' }; ;		// 32 bytes
	} m_VLRHeader;

	struct ExtVLRHeader
	{
		char				extvlrhBytes[61] = { '\0' };	// 60 Raw Bytes from of variable length record header
		unsigned short		reserved;						// 2 bytes
		char				userID[17] = { '\0' };			// 16 bytes
		unsigned short		recordID;						// 2 bytes
		unsigned long long	recordLengthAfterHeader;		// 8 bytes
		char				description[33] = { '\0' }; ;	// 32 bytes
	} m_ExtVLRHeader;

	// Pointer to point data fields of matlab struct
	struct mxStructPointer {
		mxDouble* pX					= nullptr;
		mxDouble* pY					= nullptr;
		mxDouble* pZ					= nullptr;
		mxUint16* pIntensity			= nullptr;
		mxDouble* pGPS_Time				= nullptr;
		mxUint8*  pBits					= nullptr;		// Pointer to the 8 bits containing return number, scan direction,...
		mxUint8*  pBits2				= nullptr;		// Pointer to the 8 bits added in PDF 6 to 10 to have more bits for return number, ... and added classification flags, ...
		mxUint8*  pClassicfication		= nullptr;
		mxUint8*  pUserData				= nullptr;
		mxInt8*   pScanAngle			= nullptr;
		mxInt16*  pScanAngle_16Bit		= nullptr;
		mxUint16* pPointSourceID		= nullptr;
		mxUint16* pRed					= nullptr;
		mxUint16* pGreen				= nullptr;
		mxUint16* pBlue					= nullptr;
		mxUint8*  pWavePacketDescriptor = nullptr;
		mxUint64* pWaveByteOffset		= nullptr;
		mxUint32* pWavePacketSize		= nullptr;
		mxSingle* pWaveReturnPoint		= nullptr;
		mxSingle* pWaveXt				= nullptr;
		mxSingle* pWaveYt				= nullptr;
		mxSingle* pWaveZt				= nullptr;
		mxUint16* pNIR					= nullptr;
		mxUint8*  pExtraBytes			= nullptr;
		mxArray*  pMXheader				= nullptr;

	} m_mxStructPointer;

	// Additional information
	bool	m_containsTime				= false;
	bool	m_containsColors			= false;
	bool	m_containsWavepackets		= false;
	bool	m_containsNIR				= false;
	bool	m_containsExtraBytes		= false;
	size_t	m_extraByteCount			= 0;

	// Internal Point Data ID because index in PDRF list does not have to coincide with PDRF itself
	int m_internalPointDataRecordID	= -1;

	// Constants and byte offsets
	const std::array<unsigned char, RecordFormatCount> m_supported_record_formats	{ 0,   1,  2,  3,  4,  5,  6,  7,  8,  9, 10 };
	const std::array<unsigned char, RecordFormatCount> m_record_lengths				{ 20, 28, 26, 34, 57, 63, 30, 36, 38, 59, 67 };

	const std::array<unsigned char, RecordFormatCount> m_bits2_Byte					{  0,  0,  0,  0,  0,  0, 15, 15, 15, 15, 15 };	// Byte offset to second bit field
	const std::array<unsigned char, RecordFormatCount> m_classification_Byte		{ 15, 15, 15, 15, 15, 15, 16, 16, 16, 16, 16 };	// Byte offset to classification
	const std::array<unsigned char, RecordFormatCount> m_scanAngle_Byte				{ 16, 16, 16, 16, 16, 16, 18, 18, 18, 18, 18 };	// Byte offset to scan angle rank
	const std::array<unsigned char, RecordFormatCount> m_userData_Byte				{ 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17 };	// Byte offset to user data
	const std::array<unsigned char, RecordFormatCount> m_pointSourceID_Byte			{ 18, 18, 18, 18, 18, 18, 20, 20, 20, 20, 20 };	// Byte offset to point source id
	const std::array<unsigned char, RecordFormatCount> m_time_Byte					{  0, 20,  0, 20, 20, 20, 22, 22, 22, 22, 22 };	// Byte offset to time
	const std::array<unsigned char, RecordFormatCount> m_color_Byte					{  0,  0, 20, 28,  0, 28,  0, 30, 30,  0, 30 };	// Byte offset from point start to red color
	const std::array<unsigned char, RecordFormatCount> m_NIR_Byte					{  0,  0,  0,  0,  0,  0,  0,  0, 36,  0, 36 };	// Byte offset to near infrared channel
	const std::array<unsigned char, RecordFormatCount> m_wavePackets_Byte			{  0,  0,  0,  0, 28, 34,  0,  0,  0, 30, 38 };	// Byte offset to wave packets
	
	// Moves the stream position to the beginning of the variable length record header
	void setStreamToVLRHeader(std::ifstream& lasBin)  const;

	// Moves the stream position to the beginning of the extended variable length record header
	void setStreamToExtVLRHeader(std::ifstream& lasBin)  const;

	// Assign the PDRF to an index to retrieve byte offsets for all fields
	inline void setInternalRecordFormatID();

	// Set Flags for colors, time, wave packets, NIR, VLR and extrabytes
	inline void setContentFlags();

public:
	/// <summary>
	/// Returns true if LAS-File has variable length records and false if not
	/// </summary>
	/// <returns>hasVLR: Does the LAS-File have VLR?</returns>
	bool HasVLR()  const;

	/// <summary>
	/// Returns true if LAS-File has extended variable length records and false if not
	/// </summary>
	/// <returns>hasVLR: Does the LAS-File have ExtVLR?</returns>
	bool HasExtVLR()  const;

};


class LASdataReader : public LAS_IO
{

// Private members to only allow modifcation from inside class
private:

	// How many points to read? Header info is ambigous due to legacy and LAS 1.4 field
	uint_fast64_t m_numberOfPointsToRead = 0;

	/* Record lengths of Point Data Formats according to specifications */ 
	const size_t m_record_lengths_size = m_record_lengths.size();
	const unsigned short m_minAllowedRecordLength    = 20;

	//Flag for reading of XYZ and intensity only, if specified by user, point data record format is not supported or point data record length is smaller than specification for pdrf
	bool m_XYZIntOnly = false;

	// Reads one Variable Length Record Header from file to class member m_VLRHeader. The ifstream position has to point to the beginning of a variable length record header!
	void readVLRHeader(std::ifstream& lasBin);

	// Reads one Extended Variable Length Record Header from file to class member m_ExtVLRHeader. The ifstream position has to point to the beginning of a extended variable length record header!
	void readExtVLRHeader(std::ifstream& lasBin);

	// Creates the Variable Length Record structure field for the matlab output struct
	// Returns: 
	//    mxArray* : Pointer to created struct mxArray
	mxArray* createMXVLRStruct(mxArray*& plhs);

	// Creates the Extended Variable Length Record field structure for the matlab output struct
	///Returns:
	//    mxArray* : Pointer to created struct mxArray
	mxArray* createMXExtVLRStruct(mxArray*& plhs);

public:

	// Set Flag if only XYZ coordinates and intensity are to be read
	void SetReadXYZIntOnly(bool m_XYZIntOnly_flag);

	// Read Las-File header to class member struct m_header
	void ReadLASheader(std::ifstream& lasBin);

	// Read Point Data from LAS-File stream using header information and write them to output struct
	void ReadPointData(std::ifstream& lasBin);

	// Checks header consistency. 
	// The file stream is used to determine the file size and how many bytes could be reserved for points.
	// If an header error is not too severe then return headerGood = false. 
	// This will indicate that the header contents should be saved to output struct for the error to be analysed by the caller. 
	// Returns:
	//    isHeaderGood : True if header and file are consistent, false otherwise
	bool CheckHeaderConsistency(std::ifstream& lasBin);

	// Sets up the matlab output structure and initializes all its necessary fields
	void InitializeOutputStructure(mxArray*& plhs, std::ifstream& lasBin);

	// Allocate point data fields of output struct according to header information and save data pointer to m_mxStructPointer
	void AllocateOutputStructure(mxArray*& plhs, std::ifstream& lasBin);

	// Allocates matlab header struct and sets values from class member m_header to it
	void PopulateStructureHeader(std::ifstream& lasBin);

	// Reads every Variable Length Record from file and writes it to matlab output struct
	void ReadVLR(mxArray*& plhs, std::ifstream& lasBin);

	// Reads every Extended Variable Length Record from file and writes it to matlab output struct
	void ReadExtVLR(mxArray*& plhs, std::ifstream& lasBin);
	
private:
	/* --- Inline Functions for reading individual point data fields --- */

	// Read XYZ Point Data,Intensities, advance the data and buffer pointer
	inline void readXYZInt(char*& pBuffer);

	// Read byte which contains different bit sized fields, advance the data and buffer pointer
	inline void readBits(char*& pBuffer);

	// Read second byte which contains different bit sized fields, advance the data and buffer pointer
	inline void readBits2(char*& pBuffer);

	// Read Classification, advance the data and buffer pointer
	inline void readClassification(char*& pBuffer);

	// Read 8Bit Scan Angle, advance the data and buffer pointer
	inline void readScanAngle_8b(char*& pBuffer);

	// Read 16Bit Scan Angle, advance the data and buffer pointer
	inline void readScanAngle_16b(char*& pBuffer);

	// Read User Data, advance the data and buffer pointer
	inline void readUserData(char*& pBuffer);

	// Read PointSourceID, advance the data and buffer pointer
	inline void readPointSourceID(char*& pBuffer);

	// Read GPS Time, advance the data and buffer pointer
	inline void readGPSTime(char*& pBuffer);

	// Read three RGB Color Values, advance the data and buffer pointer
	inline void readRGB(char*& pBuffer);

	// Read 7 Wave Packet components, advance the data and buffer pointer
	inline void readPointWavePacket(char*& pBuffer);

	// Read NIR Value, advance the data and buffer pointer
	inline void readNIR(char*& pBuffer);
	
	// Read Extrabytes, advance the data and buffer pointer
	inline void readExtrabytes(char*& pBuffer);

};

class LASdataWriter : public LAS_IO
{
private:
	// How many points to read? Header info is ambigous due to legacy and LAS 1.4 field
	unsigned long long m_numberOfPointsToWrite = 0;

	// Record lengths of Point Data Formats according to specifications
	const size_t m_record_lengths_size = m_record_lengths.size();

	// Copies count characters from mxChar array to char array. Stops if a null character is encountered
	inline void copyMXCharToArray(char* pCharDestination, const mxChar* const pMXCharSource, size_t count);

	// Are the Pointers to the neccessary Matlab data valid (Throws Matlab Error if not)
	void isDataValid() const;

	// Writes current stream position as offset to point data into LAS file
	void setStreamPosAsDataOffset(std::ofstream& lasBin);

	// Copy one VLR header entry from matlab structure at VLRindex to VLRHeader structure
	void getVLRHeader(mxArray* pVLRfield, size_t VLRindex);

	// Copy one Extended VLR header entry from matlab structure at VLRindex to ExtVLRHeader structure
	void getExtVLRHeader(mxArray* pVLRfield, size_t VLRindex);

public:
	// Copy LAS header content from matlab structure to m_header and its extended forms if applicable
	void GetHeader(const mxArray* lasStructure);

	// Point the pointers in m_mxStructPointer to the respective data fields of the matlab LAS structure
	void GetData(const mxArray* lasStructure);

	// Write contents of m_header and extended header to file/stream
	void WriteLASheader(std::ofstream& lasBin);

	// Write point data, that m_mxStructPointer points to, to file/stream
	void WriteLASdata(std::ofstream& lasBin);

	// Write VLR data in m_VLRHeader to file/stream
	void WriteVLR(std::ofstream& lasBin, const mxArray* lasStructure);

	// Write extended VLR data in m_ExtVLRHeader to file/stream
	void WriteExtVLR(std::ofstream& lasBin, const mxArray* lasStructure);

};

#include "LAS_IO.ipp"

#endif