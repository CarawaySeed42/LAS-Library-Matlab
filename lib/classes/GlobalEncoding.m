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
        function obj = GlobalEncoding()
            %GlobalEncoding Empty Contructor
        end
    end
end

