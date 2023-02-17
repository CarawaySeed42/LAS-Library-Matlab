function las = newPointCloud(versionMinor)
% las = newPointCloud(versionMinor)
%
%   Creates a empty point cloud structure that can be populated and then
%   written with the corresponding writer function
%
%   Input:  
%       versionMinor (numeric) : Optionally create header fields 
%                                for this version
%                                Default: 3
%
%   Output: 
%       las [struct]           : Structure that is writable to LAS file
%
%   The default Version Minor, if function is called with no arguments, is
%   four. This has the most versatility but is overkill for most
%   applications

if nargin == 0
    versionMinor = 4;
end

headerSizes = [227, 227, 227, 235, 375];

% Header
las.header.source_id                            =        0;        
las.header.global_encoding                      =        0;        
las.header.project_id_guid1                     =        0;        
las.header.project_id_guid2                     =        0;        
las.header.project_id_guid3                     =        0;        
las.header.project_id_guid4                     =        zeros( 8,1);        
las.header.version_major                        =        1;        
las.header.version_minor                        =        versionMinor;        
las.header.system_identifier                    =        '                                ';   
las.header.generating_software                  =        '                                ';

% Today's date
date_now=datestr(now,26);

las.header.file_creation_day_of_year            =        day(datetime(now,'ConvertFrom','datenum'),'dayofyear');        
las.header.file_creation_year                   =        str2double(date_now(1:4));
las.header.header_size                          =        headerSizes(versionMinor+1);
las.header.offset_to_point_data                 =        headerSizes(versionMinor+1);        
las.header.number_of_variable_records           =        0;        
las.header.point_data_format                    =        0;        
las.header.point_data_record_length             =        20;        
las.header.number_of_point_records              =        0;

if versionMinor > 3
    las.header.number_of_points_by_return       =   zeros(15,1);
else
    las.header.number_of_points_by_return           =   zeros(5,1);
end

las.header.scale_factor_x                       =        0.0001;        
las.header.scale_factor_y                       =        0.0001;        
las.header.scale_factor_z                       =        0.0001;        
las.header.x_offset                             =        0;        
las.header.y_offset                             =        0;        
las.header.z_offset                             =        0;        

las.header.max_x                                =        0;
las.header.min_x                                =        0;
las.header.max_y                                =        0;
las.header.min_y                                =        0;
las.header.max_z                                =        0;
las.header.min_z                                =        0;

if versionMinor > 2
    las.header.start_of_waveform_data           =        0;
end
if versionMinor > 3
    las.header.start_of_extended_variable_length_record  = 0;
    las.header.number_of_extended_variable_length_record = 0;
end

% Data fields
las.x                         =   [];
las.y                         =   [];
las.z                         =   [];
las.intensity                 =   [];
las.bits                      =   [];
las.bits2                     =   [];
las.classification            =   [];
las.user_data                 =   [];
las.scan_angle                =   [];
las.point_source_id           =   [];
las.gps_time                  =   [];
las.red                       =   [];
las.green                     =   [];
las.blue                      =   [];
las.nir                       =   [];
las.extradata                 =   [];
las.Xt                        =   [];
las.Yt                        =   [];
las.Zt                        =   [];
las.wave_return_point         =   [];
las.wave_packet_descriptor    =   [];
las.wave_byte_offset          =   [];
las.wave_packet_size          =   [];
las.variablerecords           =   [];
las.extendedvariables         =   [];
las.wavedescriptors           =   [];

end


