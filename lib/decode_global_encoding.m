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

lasEncoding = uint16(lasStruct.header.global_encoding);
globalEncoding = GlobalEncoding(lasEncoding);

if globalEncoding.waveform_data_packets_internal && globalEncoding.waveform_data_packets_external
    warning('Waveform Data packets internal and external are mutually exclusive!')
end

end

