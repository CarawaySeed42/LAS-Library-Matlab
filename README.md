# LAS-Library-Matlab
This aims to be a library for reading, writing and extracting LAS files (LIDAR data) in Matlab

### Features 
- Read LAS-Files containing LIDAR data into a [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) style structure
- Supports LAS-Files up to minor version 4 ([LAS Specification 1.4 - R15](https://www.asprs.org/wp-content/uploads/2019/07/LAS_1_4_r15.pdf) to be specific)
- Supports Point Data Record Formats 1 to 10
- Supports Variable Length Records and extended Variable Length Records
- Read LAS-File header, header and VLRs or all of the data
- Write manipulated point cloud data to LAS-File
- LAS Reader and Writer implemented in C++ and compiled to mex for faster processing of big files
- De- and encoding of bit fields within header
- De- and encoding of bit fields within point data records
- Special emphasis on de- and encoding and manipulation of extra bytes attached to point data records
- Coded with emphasis on avoiding newer built-in matlab functions to maximize compatibility with older revisions
- Contains example scripts and data to show how the library is to be used

---
### How to Build
All Matlab scripts can be used as is.<br>
This repository already contains compiled LAS-File reader and writer.<br>
To compile them yourself for your platform and matlab version use the provided build scripts:<br>
```
 ...src/build_readLasFile.m
 ...src/build_writeLasFile.m
 ```
<br>
If you lack support of the Interleaved Complex API then set 'UseInterleavedComplexAPI' to 'false'.<br>
The mex-function should be compiled to .../lib/mex<br>
For more information on mex-functions follow this link (https://www.mathworks.com/help/matlab/ref/mex.html)

---
### Credits
The alternative LAS-File writer contained in this library is a port of the writer present within the [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) <br>class by Teemu Kumpumäki with minor adjustments<br>
To keep compatibility with the LAS-Writer the imported data is kept in line with the lasdata properties. <br>
Big thanks to Teemu Kumpumäki for providing a great tool for reading and writing LAS files<br>
License is included next and within file

---
### License
This library is released under the MIT license with exception of the alternative LAS-Writer function

---
### Plans for the Future
- ~~Create a fast C++ LAS-Writer~~ Done
- Support decoding of all variable length records predefined within LAS Specification 1.4 R15
- Support external waveform data
