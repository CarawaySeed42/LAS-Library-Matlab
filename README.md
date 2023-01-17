# LAS-Library-Matlab
This aims to be a library for reading, writing and extracting LAS files (LIDAR data) in Matlab

### Features 
- Read LAS-Files containing LIDAR data into a [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) style struct
- Supports LAS-Files up to minor version 4 ([LAS Specification 1.4 - R15](https://www.asprs.org/wp-content/uploads/2019/07/LAS_1_4_r15.pdf) to be specific)
- Supports Point Data Record Formats 1 to 10
- Read LAS-File header only or read all of the content including Variable Length Records and Waveform Data
- LAS Reader implemented in C++ and compiled to mex for fast reading of huge files
- De- and encoding of bit fields within header
- De- and encoding of bit fields within point data records
- Special emphasis on de- and encoding and manipulation of extra bytes attached to point data records
- Write LAS data from matlab to LAS-File (please see credits)
- Coded with emphasis on avoiding built-in matlab functions available on in Matlab versions newer than R2010 to maximize compatibility
- Matlab script to easily compile/build the C++ code yourself (MSVC2019 and latest MinGW64-C++ compilers have been tested and work)
- Contains examples to show how the library is to be used

---
### How to Build
All Matlab scripts can be used as is.<br>
This repository already contains the compiled LAS-File reader (readLasFile.mexw64) which should work with MatlabR2018b and newer.<br>
If you need to build the file reader yourself then you can use the provided build script or compile it yourself from the command window.

Needless to say, you need to have the means to compile mex files with matlab<br>
(Type 'help mex' in matlab command window for more information)  

To build without build script, change current path to .../src and execute:
<br>
<br>
```mex -R2018a readLasFile.cpp LAS_IO.cpp LasReader.cpp VariableLengthRecords.cpp LASAlloc.cpp -outdir ../lib```
<br>
<br>
If your matlab version does not support the Interleaved Complex API then omit `-R2018a`.<br>
The mex-function should be compiled to .../lib<br>
For more information on mex-functions see [here](https://www.mathworks.com/help/matlab/ref/mex.html)

---
### Credits
The LAS-File writer contained in this library is a port of the writer present within the [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) <br>class by Teemu Kumpumäki with minor adjustments 

`Copyright (c) 2016, Teemu Kumpumäki. 
All rights reserved.`

To keep compatibility with the LAS-Writer the imported data is kept in line with the lasdata properties but how the data is read is completely<br>
independend of the lasdata class.

---
### License
This library is released under the MIT license with exception of the LAS-Writer function

---
### Plans for the Future
- Write a C++ LAS-Writer
- Support decoding of all variable length records predefined within LAS Specifications
- Support external waveform data
