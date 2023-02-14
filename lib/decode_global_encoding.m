function globalEncoding = decode_global_encoding(lasStruct)
%globalEncoding = decode_global_encoding(lasStruct)
%   Decodes the 2 bytes of the global encoding header entry of a LAS file
%   into its components. Also provides the meaning of the gps time type bit
%   as char array
%
% Input:
%   lasStruct (struct)          : Structure containing las data with
%                                 header entry global_encoding
% Returns:
%   globalEncoding (GlobalEncoding) : GlobalEncoding object containing decoded data
%
% For more information about the output class object type 'help GlobalEncoding'
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file

if ~isstruct(lasStruct)
    error('Argument has to be a LAS Struct')
end
if ~isfield(lasStruct.header, 'global_encoding')
    error('Provided LAS structure has no header entry ''global_encoding''')
end

globalEncoding = GlobalEncoding();
lasEncoding = uint16(lasStruct.header.global_encoding);

globalEncoding.gps_time_type                  = bitand(lasEncoding, 1);
globalEncoding.waveform_data_packets_internal = bitand(bitshift(lasEncoding, -1, 'uint16'), 1);
globalEncoding.waveform_data_packets_external = bitand(bitshift(lasEncoding, -2, 'uint16'), 1);
globalEncoding.synthetic_return_numbers       = bitand(bitshift(lasEncoding, -3, 'uint16'), 1);
globalEncoding.wkt       = bitand(bitshift(lasEncoding, -4, 'uint16'), 1);
globalEncoding.reserved       = bitand(bitshift(lasEncoding, -5, 'uint16'), 2047);

if globalEncoding.waveform_data_packets_internal && globalEncoding.waveform_data_packets_external
    warning('Waveform Data packets internal and external are mutually exclusive!')
end
   
if globalEncoding.gps_time_type
    globalEncoding.gps_time_translation = 'Adjusted Standard GPS Time';
else
    globalEncoding.gps_time_translation = 'GPS Time of Week';
end

end

