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
    warning('Waveform Data packets internal and external are mutually exclusive!')
end

encoded_data                = globalEncoding.Encode();
las.header.global_encoding  = encoded_data;

%%
end

