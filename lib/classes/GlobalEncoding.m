classdef GlobalEncoding
    %GlobalEncoding Class for global encoding of LAS file
    %   Holds decoded information of the global encoding header entry of a
    %   LAS file.
    %   Properties:
    %     gps_time_type: If set then 'adjusted Standard GPS Time' and if
    %                    not set then 'GPS Time of Week'
    %     waveform_data_packets_internal: Are waveform data packets located
    %                                     inside this file? (deprecated)
    %     waveform_data_packets_external: Are waveform data packets
    %                                     located outside of this file?
    %     synthetic_return_numbers: Are the return numbers synthetic?
    %     wkt: If set, the Coordinate Reference System (CRS) is WKT. 
    %          If not set, then CRS is GeoTIFF
    %     reserved: Reserved and must be zero
    %     gps_time_translation : GPS Time Bit description as char array
    
    properties
        gps_time_type
        waveform_data_packets_internal
        waveform_data_packets_external
        synthetic_return_numbers
        wkt
        reserved
        gps_time_translation
    end
    
    methods
        function obj = GlobalEncoding(lasEncoding)
            %GlobalEncoding Contructor If argument is given, decodes to properties
            %   Without arguments an empty object is returned
            if nargin < 1
                return;
            end
            
            obj = obj.Decode(lasEncoding);
        end
        
        function obj = Decode(obj, lasEncoding)
            reservedMask = 2047;
            
            obj.gps_time_type                  = bitand(lasEncoding, 1);
            obj.waveform_data_packets_internal = bitand(bitshift(lasEncoding, -1, 'uint16'), 1);
            obj.waveform_data_packets_external = bitand(bitshift(lasEncoding, -2, 'uint16'), 1);
            obj.synthetic_return_numbers       = bitand(bitshift(lasEncoding, -3, 'uint16'), 1);
            obj.wkt              = bitand(bitshift(lasEncoding, -4, 'uint16'), 1);
            obj.reserved         = bitand(bitshift(lasEncoding, -5, 'uint16'), reservedMask);
            
            if obj.gps_time_type
                obj.gps_time_translation = 'Adjusted Standard GPS Time';
            else
                obj.gps_time_translation = 'GPS Time of Week';
            end
        end
        
        function encoded_data = Encode(obj)
            encoded_data = uint16(0);
            reservedMask = 2047;
            
            encoded_data = bitor(encoded_data, bitand(obj.reserved, reservedMask), 'uint16');
            encoded_data = bitshift(encoded_data, 1, 'uint16');
            encoded_data = bitor(encoded_data, bitand(obj.wkt, 1), 'uint16');
            encoded_data = bitshift(encoded_data, 1, 'uint16');
            encoded_data = bitor(encoded_data, bitand(obj.synthetic_return_numbers, 1), 'uint16');
            encoded_data = bitshift(encoded_data, 1, 'uint16');
            encoded_data = bitor(encoded_data, bitand(obj.waveform_data_packets_external, 1), 'uint16');
            encoded_data = bitshift(encoded_data, 1, 'uint16');
            encoded_data = bitor(encoded_data, bitand(obj.waveform_data_packets_internal, 1), 'uint16');
            encoded_data = bitshift(encoded_data, 1, 'uint16');
            encoded_data = bitor(encoded_data, bitand(obj.gps_time_type, 1), 'uint16');
        end
    end
end

