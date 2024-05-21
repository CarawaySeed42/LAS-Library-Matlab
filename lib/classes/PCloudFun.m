classdef PCloudFun
    %PCloudFun : Contains static methods regarding point cloud manipulation
    %   Is meant to function as a container for point cloud methods
    %
    % Copyright (c) 2022, Patrick Kümmerle
    % Licence: see the included file
    
    properties (Constant)
        % Supported record formats and their record lengths
        supported_record_formats = [ 0,   1,  2,  3,  4,  5,  6,  7,  8,  9, 10 ];
        record_lengths           = [ 20, 28, 26, 34, 57, 63, 30, 36, 38, 59, 67 ];
        
        % Specifies record formats that contain certain fields
        LASContainsColor         = [ 2, 3, 5, 7, 8, 10 ];
        LASContainsTime          = [ 1, 3:10 ];
        LASContains16bitAngle    = [ 6, 7, 8, 9, 10 ];
        LASContainsBits2         = [ 6, 7, 8, 9, 10 ];
        LASContainsNIR           = [ 8, 10 ];
        LASContainsWavePackets   = [ 4, 5, 9, 10 ];
    end
    
    methods(Static)
        function las = newPointCloud(versionMinor)
            % las = newPointCloud(versionMinor)
            %
            %   Creates a empty point cloud structure that can be populated and then
            %   written with the corresponding writer function
            %
            %   Arguments:
            %       versionMinor (numeric) : Optionally create header fields
            %                                for this version
            %                                Default: 4
            %
            %   Returns:
            %       las (struct)           : LAS Point Cloud structure
            %
            if nargin < 1
                versionMinor = 4;
            end
            
			% Header sizes for version minor 0-4
            headerSizes = [227, 227, 227, 235, 375];
            
            % Header
            las.header.source_id                      =   0;
            las.header.global_encoding                =   0;
            las.header.project_id_guid1               =   0;
            las.header.project_id_guid2               =   0;
            las.header.project_id_guid3               =   0;
            las.header.project_id_guid4               =   zeros( 8,1);
            las.header.version_major                  =   1;
            las.header.version_minor                  =   versionMinor;
            las.header.system_identifier              =   repmat(' ', 1, 32);
            las.header.generating_software            =   repmat(' ', 1, 32);
            
            % Today's date
            date_now                                  =   datetime(now,'ConvertFrom','datenum');
            
            las.header.file_creation_day_of_year      =   day(date_now,'dayofyear');
            las.header.file_creation_year             =   date_now.Year;
            las.header.header_size                    =   headerSizes(versionMinor+1);
            las.header.offset_to_point_data           =   headerSizes(versionMinor+1);
            las.header.number_of_variable_records     =   0;
            las.header.point_data_format              =   0;
            las.header.point_data_record_length       =   20;
            las.header.number_of_point_records        =   0;
            
            if versionMinor > 3
                las.header.number_of_points_by_return =   zeros(15,1);
            else
                las.header.number_of_points_by_return =   zeros(5,1);
            end
            
            las.header.scale_factor_x                 =   0.0001;
            las.header.scale_factor_y                 =   0.0001;
            las.header.scale_factor_z                 =   0.0001;
            las.header.x_offset                       =   0;
            las.header.y_offset                       =   0;
            las.header.z_offset                       =   0;
            
            las.header.max_x                          =   0;
            las.header.min_x                          =   0;
            las.header.max_y                          =   0;
            las.header.min_y                          =   0;
            las.header.max_z                          =   0;
            las.header.min_z                          =   0;
            
            if versionMinor > 2
                las.header.start_of_waveform_data     =   0;
            end
            if versionMinor > 3
                las.header.start_of_extended_variable_length_record  = 0;
                las.header.number_of_extended_variable_length_record = 0;
            end
            
            % Data fields
            las.x                      =   [];
            las.y                      =   [];
            las.z                      =   [];
            las.intensity              =   [];
            las.bits                   =   [];
            las.bits2                  =   [];
            las.classification         =   [];
            las.user_data              =   [];
            las.scan_angle             =   [];
            las.point_source_id        =   [];
            las.gps_time               =   [];
            las.red                    =   [];
            las.green                  =   [];
            las.blue                   =   [];
            las.nir                    =   [];
            las.extradata              =   [];
            las.Xt                     =   [];
            las.Yt                     =   [];
            las.Zt                     =   [];
            las.wave_return_point      =   [];
            las.wave_packet_descriptor =   [];
            las.wave_byte_offset       =   [];
            las.wave_packet_size       =   [];
            las.variablerecords        =   [];
            las.extendedvariables      =   [];
            las.wavedescriptors        =   [];
        end

        function las = Allocate(pointCount, versionMinor, recordFormat)
            % las = Allocate(count, versionMinor, recordFormat)
            %
            %   Creates and allocates a new point count with pointCount points,
            %   the specified versionMinor and recordFormat. All values
            %   will be initialized to zeros
            %
            %   Arguments:
            %       pointCount (numeric)   : Number of points to allocate
            %       versionMinor (numeric) : Target version minor 
            %                                Default: 4
            %       recordFormat (numeric) : Target point record format
            %                                Default: 6
            %
            %   Returns:
            %       las (struct)           : LAS Point Cloud structure
            %
            if nargin < 2
                versionMinor = 4;
            end
            if nargin < 3
                recordFormat = 6;
            end
            
            las              = PCloudFun.newPointCloud(versionMinor);
            recordFormatInfo = PCloudFun.RecordFormatInfo(recordFormat);
            
            las.header.point_data_format = recordFormat;
            las.header.version_minor     = versionMinor;
            las.header.point_data_record_length = recordFormatInfo.record_length;
            
            % Fields that are always present
            las.x         = zeros(pointCount, 1, 'double');
            las.y         = zeros(pointCount, 1, 'double');
            las.z         = zeros(pointCount, 1, 'double');
            las.intensity = zeros(pointCount, 1, 'uint16');
            las.bits      = zeros(pointCount, 1, 'uint8');
            las.classification  = zeros(pointCount, 1, 'uint8');
            las.user_data       = zeros(pointCount, 1, 'uint8');
            las.point_source_id = zeros(pointCount, 1, 'uint16');
            
            % Fields depending on Record Format
            if recordFormatInfo.has16bitAngle
                las.scan_angle  = zeros(pointCount, 1, 'int16');
            else
                las.scan_angle  = zeros(pointCount, 1, 'int8');
            end
            if recordFormatInfo.hasBit2Field
                las.bits2       = zeros(pointCount, 1, 'uint8');
            end
            if recordFormatInfo.hasTime
                las.gps_time    = zeros(pointCount, 1, 'double');
            end
            if recordFormatInfo.hasColor
                las.red      = zeros(pointCount, 1, 'uint16');
                las.green    = zeros(pointCount, 1, 'uint16');
                las.blue     = zeros(pointCount, 1, 'uint16');
            end
            if recordFormatInfo.hasNIR
                las.nir = zeros(pointCount, 1, 'uint16');
            end
            
            if recordFormatInfo.hasWavepackets
                las.wave_packet_descriptor = zeros(pointCount, 1,  'uint8');
                las.wave_byte_offset  = zeros(pointCount, 1, 'uint64');
                las.wave_packet_size  = zeros(pointCount, 1, 'uint32');
                las.wave_return_point = zeros(pointCount, 1, 'single');
                las.Xt = zeros(pointCount, 1, 'single');
                las.Yt = zeros(pointCount, 1, 'single');
                las.Zt = zeros(pointCount, 1, 'single');
            end
            
            las.header.number_of_point_records       = length(las.x);
        end
        
        function las = Subset(las, indices)
            % las = Subset(las, indices)
            %   Creates subset of las. The indices can be integers or a
            %   logical vector of the size of point count
            %
            %   Arguments:
            %       las (struct)           : LAS Point Cloud structure
            %       indices (numeric array): array with point indices
            %
            %   Returns:
            %       las (struct)           : LAS Point Cloud structure
            %
            
            % Get fields except header, VLRs and extradata
            % extradata has different data layout
            lasFields = fieldnames(las);
            lasFields = lasFields(~ismember(lasFields, ...
                                 {'header', 'variablerecords', ...
                                 'extendedvariables', 'extradata'}));
            
            % Iterate through fields to get subset
            for fieldID = 1:length(lasFields)
                field = lasFields{fieldID};
                
                if isempty(las.(field))
                    continue;
                end
                
                % Get subset for indices
                las.(field) = las.(field)(indices);
            end
            
            % Extrabytes
            if ~isempty(las.extradata)
                las.extradata = las.extradata(:, indices);
            end
            
            % Change count in header to new count of x
            las.header.number_of_point_records = length(las.x);
        end
        
        function las = SetAtIndex(las, lasToSet, startIndex)
            % las = SetAtIndex(las, lasToSet, startIndex)
            %
            %   Inserts and overwrites(!) points from one cloud into 
            %   another cloud beginning at index. No type checking is done! 
            %   Point count of lasInsert is derived from length(lasInsert.x). 
            %   All las fields need to have the same length or be empty!
            %
            %   Arguments:
            %       las (struct)           : LAS Point Cloud structure
            %       lasToInsert (struct)   : LAS Point Cloud structure to
            %                                insert
            %       index (numeric)        : index from where on the data
            %                                will be inserted
            %
            %   Returns:
            %       las (struct)           : LAS Point Cloud structure
            %
            insertCount = numel(lasToSet.x);
            indexArray  = startIndex:startIndex+insertCount-1;
            
            % Get fields except header, VLRs and extradata
            lasFields = fieldnames(las);
            lasFields = lasFields(~ismember(lasFields, ...
                                 {'header', 'variablerecords', ...
                                 'extendedvariables', 'extradata'}));
            
            % Iterate through fields and set
            for fieldID = 1:length(lasFields)
                field = lasFields{fieldID};
                
                if isempty(lasToSet.(field))
                    continue;
                end
                
                % Set to indexArray
                las.(field)(indexArray) = lasToSet.(field);
                
            end
            
            % Extrabytes
            if ~isempty(lasToSet.extradata)
                las.extradata(:, startIndex:startIndex+insertCount) = lasToSet.extradata;
            end
            
            % Change count in header to new count of x
            las.header.number_of_point_records = length(las.x);
            
        end
        
        function recordFormatInfo = RecordFormatInfo(recordFormat)
            % recordFormatInfo = RecordFormatInfo(recordFormat)
            %
            %   Returns a struct containing info about a LAS record format
            %   
            %   Arguments:
            %       recordFormat (numeric) : The record format to check
            %
            %   Returns:
            %       recordFormatInfo (struct): struct with fields
            %                                  recordFormatInfo.hasTime
            %                                  recordFormatInfo.hasColor
            %                                  recordFormatInfo.has16bitAngle
            %                                  recordFormatInfo.hasBit2Field
            %                                  recordFormatInfo.hasNIR
            %                                  recordFormatInfo.hasWavepackets
            %                                  recordFormatInfo.record_length
            
            recordFormatInfo         = struct();
            
            if numel(recordFormat) > 1
                warning('RecordFormatInfo: RecordFormat must be one numeric value!');
                return;
            end
            
            if ~ismember(recordFormat, PCloudFun.supported_record_formats)
                warning('RecordFormatInfo: Point Data Record Format %d not supported!', recordFormat);
                return;
            end
            
            % Check which information is in the cloud
            recordFormatInfo.hasTime         = ismember(recordFormat, PCloudFun.LASContainsTime);
            recordFormatInfo.hasColor        = ismember(recordFormat, PCloudFun.LASContainsColor);
            recordFormatInfo.has16bitAngle   = ismember(recordFormat, PCloudFun.LASContains16bitAngle);
            recordFormatInfo.hasBit2Field    = ismember(recordFormat, PCloudFun.LASContainsBits2);
            recordFormatInfo.hasNIR          = ismember(recordFormat, PCloudFun.LASContainsNIR);
            recordFormatInfo.hasWavepackets  = ismember(recordFormat, PCloudFun.LASContainsWavePackets);
            
            record_index                     = PCloudFun.supported_record_formats == recordFormat;
            recordFormatInfo.record_length   = PCloudFun.record_lengths(record_index);
        end
        
        function optimal_format = GetOptimalRecordFormat(las)
            % optimal_format = GetOptimalRecordFormat(las)
            %
            %   Determines the optimal record format for a point cloud, by
            %   analyzing what fields of the las structure are occupied and
            %   what datatype they are
            %
            %   Arguments:
            %       las (struct)             : LAS Point Cloud structure
            %
            %   Returns:
            %       optimal_format (numeric) : The lowest record format
            %                                  that covers all data fields    
            %
            
            available_formats = PCloudFun.supported_record_formats;
            if ~isempty(las.gps_time)
                available_formats = intersect(available_formats, PCloudFun.LASContainsTime);
            end
            if ~isempty(las.red) && ~isempty(las.green) && ~isempty(las.blue)
                available_formats = intersect(available_formats, PCloudFun.LASContainsColor);
            end
            if ~isa(las.scan_angle, 'int8') 
                available_formats = intersect(available_formats, PCloudFun.LASContains16bitAngle);
            end
            if ~isempty(las.bits2)
                available_formats = intersect(available_formats, PCloudFun.LASContainsBits2);
            end
            if ~isempty(las.nir)
                available_formats = intersect(available_formats, PCloudFun.LASContainsNIR);
            end
            
            hasWavepackets  = ~isempty(las.wave_packet_descriptor) && ...
                  ~isempty(las.wave_byte_offset) && ...
                  ~isempty(las.wave_packet_size) && ...
                  ~isempty(las.Xt) && ~isempty(las.Yt) && ~isempty(las.Zt);
            
            if hasWavepackets
                available_formats = intersect(available_formats, PCloudFun.LASContainsWavePackets);
            end
            
            optimal_format = min(available_formats);
        end
    end
end

