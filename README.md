# LAS-Library-Matlab
This aims to be a library for reading, writing and extracting LAS files (LIDAR data) in Matlab

### Features 
- Read LAS-Files containing LIDAR data into a [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) style structure
- Supports LAS-Files up to minor version 4 ([LAS Specification 1.4 - R15](https://www.asprs.org/wp-content/uploads/2019/07/LAS_1_4_r15.pdf) to be specific)
- Supports Point Data Record Formats 0 to 10
- Supports (extended) Variable Length Records
- Flexible options to read LAS-File header, header and VLRs, only point coordinates and intensities, or all of the data
- LAS Reader and Writer implemented in C++ and compiled to mex for faster processing of big files (extremely fast on SSDs)
- De- and encoding of bit fields within header
- De- and encoding of bit fields within point data records
- Special emphasis on de- and encoding and manipulation of extra bytes attached to point data records
- Coded with emphasis on avoiding newer built-in matlab functions to maximize compatibility with older revisions
- Contains example scripts and data to show how the library can be used
- Contains utility functions, like a fast multithreaded point in polygon function

---
### How to Build
All Matlab scripts can be used as is.<br>
This repository already contains compiled LAS-File reader and writer, as well as the compiled point in polygon function.<br>
To compile them yourself for your platform and matlab version use the provided build scripts:<br>
```
 ...src/build_readLasFile.m
 ...src/build_writeLasFile.m
 ...src/build_isPointInPolygon.m
 ```
<br>
If you lack support of the Interleaved Complex API then set 'UseInterleavedComplexAPI' to 'false'.<br>
The mex-function should be compiled to .../lib/mex<br>
Tested and working C++ compilers are MSVC 2019 and latest MinGW-w64 
For more information on mex-functions follow this link (https://www.mathworks.com/help/matlab/ref/mex.html)

---
### Credits
The general structure and handling of the LAS data within Matlab follows the [lasdata](https://www.mathworks.com/matlabcentral/fileexchange/48073-lasdata) <br>class by Teemu Kumpumäki.<br>
This started out as an extension of the lasdata utility but became its own thing in the process.<br>
At this point this library does not use any code from said lasdata class but instead was created from scratch.<br>
The writer is compatible with lasdata objects because they are so similar.<br>
Thanks to Teemu Kumpumäki for being an inspiration and for providing a great tool for reading and writing LAS files.<br>

---
### License
This library is released under the MIT license

---
### Plans for the Future
- ~~Create a fast C++ LAS-Writer~~: Finished
- ~~Support decoding of all variable length records predefined within LAS Specification 1.4 R15~~: Unlikely, due to how dynamic some VLRs are
- Support external waveform data
