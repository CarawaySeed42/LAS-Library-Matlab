#include "mex.h"
#include <algorithm>
#include <array>
#include <fstream>
#include <vector>

// Ths is the header f�le for LAS_IO and LASDataReader 
// File Extension is cpp due to matlab compiler not recognizing .h / .hpp files

class LAS_IO 
{
protected:

	// Las Header struct according to LAS 1.2 Specs (char arrays are null terminated)
	struct LasHeader
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
	struct LasHeaderExt3
	{
		unsigned long long startOfWaveFormData = 0;
	} m_headerExt3;

	// LAS Header Extension introduced with LAS 1.4
	struct LasHeaderExt4
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
		char				extvlrhBytes[55] = { '\0' };	// 60 Raw Bytes from of variable length record header
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
	size_t m_internalPointDataRecordID	= -1;

	// Constants
	const std::vector<unsigned char> m_supported_record_formats	{ 0,   1,  2,  3,  4,  5,  6,  7,  8,  9, 10 };
	const std::vector<unsigned char> m_record_lengths			{ 20, 28, 26, 34, 57, 63, 30, 36, 38, 59, 67 };

	void SetInternalRecordFormatID() 
	{
		auto it = find(m_supported_record_formats.begin(), m_supported_record_formats.end(), m_header.PointDataRecordFormat);

		if (it != m_supported_record_formats.end())
		{
			m_internalPointDataRecordID = static_cast<size_t>(std::distance(m_supported_record_formats.begin(), it));
		}
		else
		{
			m_internalPointDataRecordID = -1;
		}
	}
};


class LasDataReader : public LAS_IO
{

// Private members to only allow modifcation from inside class
private:

	// How many points to read? Header info is ambigous due to legacy and LAS 1.4 field
	uint_fast64_t m_numberOfPointsToRead = 0;

	/* Record lengths of Point Data Formats according to specifications */ 
	const size_t m_record_lengths_size = m_record_lengths.size();
	const unsigned short m_minAllowedRecordLength    = 20;

	//Flag for unsafe reading if point data record format is not supported or point data record length is smaller than specification for pdrf
	bool unsafeRead = false;

	// Moves the stream position to the beginning of the variable length record header
	void setStreamToVLRHeader(std::ifstream& lasBin);

	// Moves the stream position to the beginning of the extended variable length record header
	void setStreamToExtVLRHeader(std::ifstream& lasBin);

	/// <summary>
	/// Reads one Variable Length Record Header from file to class member m_VLRHeader. The ifstream position has to point to the beginning of a variable length record header!
	/// </summary>
	/// <param name="lasBin"></param>
	void readVLRHeader(std::ifstream& lasBin);

	/// <summary>
	/// Reads one Extended Variable Length Record Header from file to class member m_ExtVLRHeader. The ifstream position has to point to the beginning of a extended variable length record header!
	/// </summary>
	/// <param name="lasBin"></param>
	void readExtVLRHeader(std::ifstream& lasBin);

	/// <summary>
	/// Creates the Variable Length Record structure field for the matlab output struct
	/// </summary>
	/// <param name="plhs"></param>
	/// <returns>mxArray*: Pointer to created struct mxArray</returns>
	mxArray* createMXVLRStruct(mxArray* plhs[]);

	/// <summary>
	/// Creates the Extended Variable Length Record field structure for the matlab output struct
	/// </summary>
	/// <param name="plhs"></param>
	/// <returns>mxArray*: Pointer to created struct mxArray</returns>
	mxArray* createMXExtVLRStruct(mxArray* plhs[]);

public:

	/// <summary>
	/// Read Las-File header to class member struct m_header
	/// </summary>
	/// <param name="lasBin"></param>
	void ReadLasHeader(std::ifstream& lasBin);

	/// <summary>
	/// Read Point Data from LAS-File stream using header information and write them to output struct
	/// </summary>
	/// <param name="lasBin"></param>
	/// <returns></returns>
	void ReadPointData(std::ifstream& lasBin);

	/// <summary>
	/// Checks header consistency. The file stream is used to determine the file size and how many bytes could be reserved for points.
	/// If an header error is not too severe then return headerGood = false. This will indicate that the header contents should be saved to output struct for the error to be analysed by the user. 
	/// </summary>
	/// <param name="lasBin"></param>
	/// <returns>isHeaderGood:   True if header and file are consistent, false otherwise</returns>
	bool CheckHeaderConsistency(std::ifstream& lasBin);

	/// <summary>
	/// Sets up the output matlab struct and creates all its necessary fields
	/// </summary>
	/// <param name="plhs"></param>
	/// <param name="lasBin"></param>
	void InitializeOutputStruct(mxArray* plhs[], std::ifstream& lasBin);

	/// <summary>
	/// Allocate point data fields of output struct according to header information and save data pointer to m_mxStructPointer
	/// </summary>
	/// <param name="plhs"></param>
	/// <param name="lasBin"></param>
	void AllocateOutputStruct(mxArray* plhs[], std::ifstream& lasBin);

	/// <summary>
	/// Allocates matlab header struct and sets values from class member m_header to it
	/// </summary>
	/// <param name="lasBin"></param>
	void FillStructHeader(std::ifstream& lasBin);

	/// <summary>
	/// Returns true if LAS-File has variable length records and false if not
	/// </summary>
	/// <returns>hasVLR: Does the LAS-File have VLR?</returns>
	bool HasVLR();

	/// <summary>
	/// Returns true if LAS-File has extended variable length records and false if not
	/// </summary>
	/// <returns>hasVLR: Does the LAS-File have ExtVLR?</returns>
	bool HasExtVLR();

	/// <summary>
	/// Reads every Variable Length Record from file and writes it to matlab output struct
	/// </summary>
	/// <param name="lasBin"></param>
	void ReadVLR(mxArray* plhs[], std::ifstream& lasBin);

	/// <summary>
	/// Reads every Extended Variable Length Record from file and writes it to matlab output struct
	/// </summary>
	/// <param name="lasBin"></param>
	void ReadExtVLR(mxArray* plhs[], std::ifstream& lasBin);
	
private:
	/* --- Inline Functions for reading individual point data fields --- */

	// Read XYZ Point Data,Intensities, advance the data and buffer pointer
	inline void readXYZInt(char*& pBuffer) 
	{
		*m_mxStructPointer.pX = ((double)*reinterpret_cast<int32_t*>(pBuffer) * m_header.xScaleFactor) + m_header.xOffset;
		m_mxStructPointer.pX++;
		pBuffer += 4;

		*m_mxStructPointer.pY = ((double)*reinterpret_cast<int32_t*>(pBuffer) * m_header.yScaleFactor) + m_header.yOffset;
		m_mxStructPointer.pY++;
		pBuffer += 4;

		*m_mxStructPointer.pZ = ((double)*reinterpret_cast<int32_t*>(pBuffer) * m_header.zScaleFactor) + m_header.zOffset;
		m_mxStructPointer.pZ++;
		pBuffer += 4;

		*m_mxStructPointer.pIntensity = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pIntensity++;
		pBuffer += 2;
	}

	// Read byte which contains different bit sized fields, advance the data and buffer pointer
	inline void readBits(char*& pBuffer) 
	{
		*m_mxStructPointer.pBits = *reinterpret_cast<uint8_t*>(pBuffer);
		m_mxStructPointer.pBits++;
		pBuffer += 1;
	}

	// Read second byte which contains different bit sized fields, advance the data and buffer pointer
	inline void readBits2(char*& pBuffer) 
	{
		*m_mxStructPointer.pBits2 = *reinterpret_cast<uint8_t*>(pBuffer);
		m_mxStructPointer.pBits2++;
		pBuffer += 1;
	}

	// Read Classification, advance the data and buffer pointer
	inline void readClassification(char*& pBuffer) 
	{
		*m_mxStructPointer.pClassicfication = *reinterpret_cast<uint8_t*>(pBuffer);
		m_mxStructPointer.pClassicfication++;
		pBuffer += 1;
	}

	// Read 8Bit Scan Angle, advance the data and buffer pointer
	inline void readScanAngle_8b(char*& pBuffer)
	{
		*m_mxStructPointer.pScanAngle = *reinterpret_cast<int8_t*>(pBuffer);
		m_mxStructPointer.pScanAngle++;
		pBuffer += 1;
	}

	// Read 16Bit Scan Angle, advance the data and buffer pointer
	inline void readScanAngle_16b(char*& pBuffer) 
	{
		*m_mxStructPointer.pScanAngle_16Bit = *reinterpret_cast<int16_t*>(pBuffer);
		m_mxStructPointer.pScanAngle_16Bit++;
		pBuffer += 2;
	}

	// Read User Data, advance the data and buffer pointer
	inline void readUserData(char*& pBuffer) 
	{
		*m_mxStructPointer.pUserData = *reinterpret_cast<uint8_t*>(pBuffer);
		m_mxStructPointer.pUserData++;
		pBuffer += 1;
	}

	// Read PointSourceID, advance the data and buffer pointer
	inline void readPointSourceID(char*& pBuffer) 
	{
		*m_mxStructPointer.pPointSourceID = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pPointSourceID++;
		pBuffer += 2;
	}

	// Read GPS Time, advance the data and buffer pointer
	inline void readGPSTime(char*& pBuffer) 
	{
		*m_mxStructPointer.pGPS_Time = *reinterpret_cast<double*>(pBuffer);
		m_mxStructPointer.pGPS_Time++;
		pBuffer += 8;
	}

	// Read three RGB Color Values, advance the data and buffer pointer
	inline void readRGB(char*& pBuffer) 
	{
		*m_mxStructPointer.pRed = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pRed++;
		pBuffer += 2;

		*m_mxStructPointer.pGreen = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pGreen++;
		pBuffer += 2;

		*m_mxStructPointer.pBlue = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pBlue++;
		pBuffer += 2;
	}

	// Read 7 Wave Packet components, advance the data and buffer pointer
	inline void readPointWavePacket(char*& pBuffer) 
	{
		*m_mxStructPointer.pWavePacketDescriptor = *reinterpret_cast<uint8_t*>(pBuffer);
		m_mxStructPointer.pWavePacketDescriptor++;
		pBuffer += 1;

		*m_mxStructPointer.pWaveByteOffset = *reinterpret_cast<uint64_t*>(pBuffer);
		m_mxStructPointer.pWaveByteOffset++;
		pBuffer += 8;

		*m_mxStructPointer.pWavePacketSize = *reinterpret_cast<uint32_t*>(pBuffer);
		m_mxStructPointer.pWavePacketSize++;
		pBuffer += 4;

		*m_mxStructPointer.pWaveReturnPoint = *reinterpret_cast<float*>(pBuffer);
		m_mxStructPointer.pWaveReturnPoint++;
		pBuffer += 4;

		*m_mxStructPointer.pWaveXt = *reinterpret_cast<float*>(pBuffer);
		m_mxStructPointer.pWaveXt++;
		pBuffer += 4;

		*m_mxStructPointer.pWaveYt = *reinterpret_cast<float*>(pBuffer);
		m_mxStructPointer.pWaveYt++;
		pBuffer += 4;

		*m_mxStructPointer.pWaveZt = *reinterpret_cast<float*>(pBuffer);
		m_mxStructPointer.pWaveZt++;
		pBuffer += 4;
	}

	// Read NIR Value, advance the data and buffer pointer
	inline void readNIR(char*& pBuffer) 
	{
		*m_mxStructPointer.pNIR = *reinterpret_cast<uint16_t*>(pBuffer);
		m_mxStructPointer.pNIR++;
		pBuffer += 2;
	}
	
	// Read Extrabytes, advance the data and buffer pointer
	inline void readExtrabytes(char*& pBuffer)
	{
		for (int i = 0; i < m_extraByteCount; ++i)
		{
			*m_mxStructPointer.pExtraBytes = *reinterpret_cast<uint8_t*>(pBuffer);
			m_mxStructPointer.pExtraBytes += m_numberOfPointsToRead;
			++pBuffer;
		}

		// Revert the memory adress jumps and go to the first byte of the next point's extrabyte
		//	- The jumps represent moving to the next matrix column because matlab uses column major ordering
		m_mxStructPointer.pExtraBytes += 1 - m_extraByteCount * m_numberOfPointsToRead;
	}

};