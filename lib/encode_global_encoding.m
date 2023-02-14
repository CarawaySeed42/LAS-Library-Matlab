function las = encode_global_encoding(las, globalEncoding)
%las = encode_global_encoding(las, globalEncoding)
%   Encodes a Global Encoding object into 2 bytes and writes it to header
%   of LAS structure
%
% Input:
%   las (struct)                   : Structure containing las data
%   globalEncoding (GlobalEncoding): Global Encoding Object
%
% Returns:
%   las [struct]        : Input LAS structure with updated global encoding
%
% For more information about the output class object type 'help GlobalEncoding'
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file

if ~isstruct(las)
    error('Argument has to be a LAS Struct')
end

if ~isa(globalEncoding, 'GlobalEncoding')
    error('Second argument has to an GlobalEncoding object')
end

if globalEncoding.waveform_data_packets_internal && globalEncoding.waveform_data_packets_external
    error('Waveform Data packets internal and external are mutually exclusive!')
end

%% las.header.global_encoding = uint16(0);
encoded_data = uint16(0);

encoded_data = bitor(encoded_data, bitand(globalEncoding.wkt, 1), 'uint16');
encoded_data  = bitshift(encoded_data, 1, 'uint16');  
encoded_data = bitor(encoded_data, bitand(globalEncoding.synthetic_return_numbers, 1), 'uint16');
encoded_data  = bitshift(encoded_data, 1, 'uint16'); 
encoded_data = bitor(encoded_data, bitand(globalEncoding.waveform_data_packets_external, 1), 'uint16');
encoded_data  = bitshift(encoded_data, 1, 'uint16');  
encoded_data = bitor(encoded_data, bitand(globalEncoding.waveform_data_packets_internal, 1), 'uint16');
encoded_data  = bitshift(encoded_data, 1, 'uint16');  
encoded_data = bitor(encoded_data, bitand(globalEncoding.gps_time_type, 1), 'uint16'); 

las.header.global_encoding = encoded_data;

%%
end

