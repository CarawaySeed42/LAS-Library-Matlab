function obj = writeLasFile_lasdata(obj, filename, majorversion, minorversion, pointformat)
% obj = writeLasFile(obj, filename, majorversion, minorversion, pointformat)
%
%   Writes lasdata style struct to a Las-File. This is a port of the
%   write_las method of the lasdata class modified to work with structs
%
%   Input:
%       obj [struct]        : Struct containing point cloud data
%       filename [string]   : Full Path to output file
%       majorversion [uint] : Major Version of LAS File
%       minorversion [uint] : Minor Verison of LAS File
%       pointformat [uint]  : Point Data Format of LAS File
%
%   Output:
%       obj [struct]        : Struct containing the written cloud data
%
% License:
%     Copyright (c) 2016, Teemu Kumpumäki
%     All rights reserved.
% 
%     Redistribution and use in source and binary forms, with or without
%     modification, are permitted provided that the following conditions are
%     met:
% 
%         * Redistributions of source code must retain the above copyright
%           notice, this list of conditions and the following disclaimer.
%         * Redistributions in binary form must reproduce the above copyright
%           notice, this list of conditions and the following disclaimer in
%           the documentation and/or other materials provided with the distribution
%         * Neither the name of the Tampere University of Technology nor the names
%           of its contributors may be used to endorse or promote products derived
%           from this software without specific prior written permission.
% 
%     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%     AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%     IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%     ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%     LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%     CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%     SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%     INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%     CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%     ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%     POSSIBILITY OF SUCH DAMAGE.
%
%   Modified by Patrick Kuemmerle (aka CarawaySeed42), 2022
%

MException = []; % Empty Matlab Exception
try
    %prevent overwriting
    %if you like to overwrite files, then disable check
    %         [pathtmp,filetmp,ext]=fileparts(obj.filename);
    %         if isempty(pathtmp); pathtmp = pwd; end
    %         orgfile = [pathtmp '/' filetmp ext];
    %         newfile = [pathtmp '/' filetmp ext];
    %
    %         if strcmpi(orgfile,newfile)
    %             error('Overwriting is not allowed.')
    %         end
    
    % Create output directory if doesn't exist (isdir for backwards comp)
    [pathtmp,~,ext]=fileparts(filename);
    if ~isdir(pathtmp) 
        mkdir(pathtmp);
    end 
    if ~strcmp(ext,'.las')
       error('writeStruct2las: Output File does not have extension .las !');
    end
    
    % Provide backwards compatibility to writeLas from lasdata
    if (isfield(obj.header, 'file_creation_daobj'))
        if (isfield(obj.header.file_creation_daobj, 'y') && ~isfield(obj.header, 'file_creation_day_of_year'))
            % Copy day of year from lasdata to new struct layout
            obj.header.file_creation_day_of_year = obj.header.file_creation_daobj.y;
        end
    end
    
    % Set variables and start writing
    newheader = obj.header;
    oldheader = obj.header;
    if ~exist('filename','var')
        error('Please input target filename.')
    end
    if exist('majorvarsion','var')
        newheader.version_major = majorversion;
    end
    if exist('minorversion','var')
        newheader.version_minor = minorversion;
    end
    if exist('pointformat','var')
        newheader.point_data_format = pointformat;
    end
    newheader.number_of_point_records = length(obj.x);
    newheader.max_x = max(obj.x);
    newheader.min_x = min(obj.x);
    newheader.max_y = max(obj.y);
    newheader.min_y = min(obj.y);
    newheader.max_z = max(obj.z);
    newheader.min_z = min(obj.z);
    newheader.filename = filename;
    newheader.number_of_variable_records = length(obj.variablerecords);
    
    fid = fopen(filename,'w');
    try
        obj.header = newheader;
        writeheader(obj, fid);
    catch err
        obj.header = oldheader;
        error(['Error writing las header: ' err.getReport]);
    end
    
    LEN = length(obj.x);
    
    if isempty(obj.intensity)
        warning('Adding zeros to intensity')
        obj.intensity = zeros(LEN,1,'uint16');
    end
    
    if isempty(obj.bits)
        warning('Adding zeros to bit values (return nr, scan dir. flag, edge of flight line)')
        obj.bits = zeros(LEN,1,'uint8');
    end
    
    if any(newheader.point_data_format == [6 7 8 9 10])
        if isempty(obj.bits2)
            obj.bits2 = zeros(LEN,1,'uint8');
        end
        %convert to new point formats
        if oldheader.point_data_format < 6
            obj.bits = bitor(get_return_number(obj), bitshift(get_number_of_returns(obj),4));
            obj.bits2 = bitor(bitshift(get_scan_direction_flag(obj),6), bitshift(get_edge_of_flight_line(obj),7));
        end
    end
    if any(oldheader.point_data_format > 5) && newheader.point_data_format < 6
        %convert to old point formats
        if oldheader.point_data_format > 5
            obj.bits = bitor(bitand(get_return_number(obj),7), bitand(bitshift(get_number_of_returns(obj),3),7));
            obj.bits = bitor(obj.bits, bitor(bitshift(get_scan_direction_flag(obj),6), bitshift(get_edge_of_flight_line(obj),7)));
        end
    end
    
    if isempty(obj.classification)
        warning('Adding zeros to classification')
        obj.classification = zeros(LEN,1,'uint8');
    end
    
    if isempty(obj.scan_angle)
        warning('Adding zeros to scan angle')
        obj.scan_angle = zeros(LEN,1,'uint8');
    end
    
    if isempty(obj.user_data)
        warning('Adding zeros to user data')
        obj.user_data = zeros(LEN,1,'uint8');
    end
    
    if isempty(obj.point_source_id)
        warning('Adding zeros to point source id')
        obj.point_source_id = zeros(LEN,1,'uint16');
    end
    
    if ~any(newheader.point_data_format == [0 2])
        if isempty(obj.gps_time)
            warning('Adding zeros to gps time')
            obj.gps_time = zeros(LEN,1,'double');
        end
    end
    
    if any(newheader.point_data_format == [3 5 7 8 10])
        if isempty(obj.red)
            warning('Adding zeros to RGB color')
            obj.red = zeros(LEN,1,'uint16');
            obj.green = zeros(LEN,1,'uint16');
            obj.blue = zeros(LEN,1,'uint16');
        end
        if any(newheader.point_data_format == [8 10])
            if isempty(obj.nir)
                warning('Adding zeros to nir color')
                obj.nir = zeros(LEN,1,'uint16');
            end
        end
    end
    
    if any(newheader.point_data_format == [4 5 9 10])
        if isempty(obj.wave_return_point)
            warning('Adding zeros to wave packet info')
            obj.wave_packet_descriptor = zeros(LEN,1,'uint8');
            obj.wave_byte_offset = zeros(LEN,1,'uint64');
            obj.wave_packet_size = zeros(LEN,1,'uint32');
            obj.wave_return_point = zeros(LEN,1,'single');
            obj.Xt = zeros(LEN,1,'single');
            obj.Yt = zeros(LEN,1,'single');
            obj.Zt = zeros(LEN,1,'single');
        end
    end
    
    obj.header = newheader;
    
    %%% variable length records
    try
        write_variable_records(obj,fid);
    catch err
        error(['Error writing variable length records: ' err.getReport]);
    end
    
    if obj.header.version_major==1 && obj.header.version_minor == 0
        tmp = char([hex2dec('DD') hex2dec('CC')]); %write las 1.0 variable record start
        fwrite(fid,tmp,'uint8');
    end
    
    %find offset to point data and write it to header in file
    tmppos = ftell(fid);
    obj.header.offset_to_point_data = tmppos;
    fseek(fid,96,-1);
    fwrite(fid,uint32(tmppos),'uint32');
    fseek(fid,tmppos,-1);
    
    %calculate point record length and write it to header in file
    record_lengths = [20 28 26 34 57 63 30 36 38 59 67 ];
    obj.header.point_data_record_length = ...
        record_lengths(obj.header.point_data_format+1) + size(obj.extradata,1);
    fseek(fid,105,-1);
    fwrite(fid,obj.header.point_data_record_length,'uint16');
    
    %update extendedvariable offset
    if newheader.version_minor > 3 %1.4
        obj.header.start_of_extended_variable_length_record = ...
            obj.header.offset_to_point_data + length(obj.x)*obj.header.point_data_record_length;
        fseek(fid,235,-1);
        fwrite(fid,obj.header.start_of_extended_variable_length_record,'uint64');
    end
    
    fclose(fid);
    
    try
        write_xyz(obj);
        write_intensity(obj);
        write_bits(obj);
        write_classification(obj);
        write_scan_angle(obj);
        write_user_data(obj);
        write_point_source_id(obj);
        write_gps_time(obj);
        write_color(obj);
        write_point_wave_info(obj);
        write_extradata(obj);
    catch err
        error(['Error writing point data: ' err.getReport]);
    end
    
    fid = fopen(filename,'r+');
    fseek(fid,double(obj.header.offset_to_point_data+length(obj.x)*obj.header.point_data_record_length),-1);
    
    try
        write_extended_variables(obj, fid);
    catch err
        error(['Error writing extended variable data: ' err.getReport]);
    end
    
    fclose(fid);
    
catch MException
end

% Close all opened file IDs because at least one is never closed
h_las=fopen('all');
for h=1:length(h_las)
    if strcmp(fopen(h_las(h)),filename)
        fclose(h_las(h));
    end
end

% If Exception was thrown then throw it again after all files are closed
if ~isempty(MException)
   rethrow(MException);
end

end
    
function obj = writeheader(obj,fid)
        fseek(fid,0,-1);
        fprintf(fid,'LASF');

        fwrite(fid, obj.header.source_id,'uint16');
        fwrite(fid, obj.header.global_encoding,'uint16');
        fwrite(fid, obj.header.project_id_guid1,'uint32');
        fwrite(fid, obj.header.project_id_guid2,'uint16');
        fwrite(fid, obj.header.project_id_guid3,'uint16');
        fwrite(fid, obj.header.project_id_guid4,'uint8');
        fwrite(fid, obj.header.version_major,'uint8');
        fwrite(fid, obj.header.version_minor,'uint8');
        tmp = obj.header.system_identifier;
        tmp = [tmp zeros(1,32-length(tmp),'uint8')];
        fprintf(fid, '%c',tmp);
        tmp = obj.header.generating_software;
        tmp = [tmp zeros(1,32-length(tmp),'uint8')];
        fprintf(fid, '%c', tmp);        
        fwrite(fid, obj.header.file_creation_day_of_year,'uint16');
        fwrite(fid, obj.header.file_creation_year,'uint16');
        fwrite(fid, obj.header.header_size,'uint16');
        fwrite(fid, obj.header.offset_to_point_data,'uint32');
        fwrite(fid, obj.header.number_of_variable_records,'uint32');
        fwrite(fid, obj.header.point_data_format,'uint8');
        fwrite(fid, obj.header.point_data_record_length,'uint16');
        if obj.header.number_of_point_records < 2^32 %if legacy compatible
            fwrite(fid, obj.header.number_of_point_records,'uint32');
        else
            fwrite(fid, 0,'uint32');
        end
        
        %add lecagy only if possible by pointcount limited by uint32
        if obj.header.number_of_point_records < 2^32 && ...
                (length(obj.header.number_of_points_by_return) == 15 && ...
                 all(obj.header.number_of_points_by_return(6:15)==0))
            tmpp = obj.header.number_of_points_by_return;
            if length(obj.header.number_of_points_by_return)==15
                tmpp = tmpp(1:5);
            end
                
            fwrite(fid, tmpp,'uint32');
        else
            fwrite(fid, zeros(5,1,'uint32'),'uint32');
        end
        fwrite(fid, obj.header.scale_factor_x,'double');         
        fwrite(fid, obj.header.scale_factor_y,'double');         
        fwrite(fid, obj.header.scale_factor_z,'double');         
        fwrite(fid, obj.header.x_offset,'double');         
        fwrite(fid, obj.header.y_offset,'double');         
        fwrite(fid, obj.header.z_offset,'double');
        fwrite(fid, obj.header.max_x,'double');          
        fwrite(fid, obj.header.min_x,'double');          
        fwrite(fid, obj.header.max_y,'double');          
        fwrite(fid, obj.header.min_y,'double');          
        fwrite(fid, obj.header.max_z,'double');          
        fwrite(fid, obj.header.min_z,'double');          
        if obj.header.version_minor > 2 %1.3
            if ~isfield(obj.header,'start_of_waveform_data')
                fwrite(fid, 0,'uint64');
            else
                fwrite(fid, obj.header.start_of_waveform_data,'uint64');
            end
        end
        if obj.header.version_minor > 3 %1.4
            if ~isfield(obj.header,'start_of_extended_variable_length_record')
                fwrite(fid, 0,'uint64');
            else            
                fwrite(fid, obj.header.start_of_extended_variable_length_record,'uint64');
            end
            
            if ~isfield(obj.header,'number_of_extended_variable_length_record')
                fwrite(fid, 0,'uint32');
            else            
                fwrite(fid, obj.header.number_of_extended_variable_length_record,'uint32');
            end  
            
            if ~isfield(obj.header,'number_of_point_records')
                fwrite(fid, 0,'uint64');
            else            
                fwrite(fid, obj.header.number_of_point_records,'uint64');
            end
            
            if ~isfield(obj.header,'number_of_points_by_return')
                fwrite(fid, 15,'uint64');
            else                  
                fwrite(fid, obj.header.number_of_points_by_return,'uint64');
            end
        end
        %write header length
        pos = ftell(fid);
        fseek(fid,94,-1);
        fwrite(fid,pos,'uint16');
        fseek(fid,pos,-1);
end
    
function obj = write_variable_records(obj,fid)
    for k=1:obj.header.number_of_variable_records
        if obj.header.version_major==1 && obj.header.version_minor == 0
            tmp = char([hex2dec('BB') hex2dec('AA')]); %write las 1.0 variable record start
            fwrite(fid,tmp,'uint8');
        end
        
        fwrite(fid,obj.variablerecords(k).reserved,'uint16');
        tmp = obj.variablerecords(k).user_id;
        tmp = [tmp zeros(1,16-length(tmp))];
        fprintf(fid,'%c',tmp);
        fwrite(fid,obj.variablerecords(k).record_id,'uint16');
        fwrite(fid,length(obj.variablerecords(k).data),'uint16');
        tmp = obj.variablerecords(k).description;
        tmp = [tmp zeros(1,32-length(tmp))];
        fprintf(fid,'%c',tmp);
        fwrite(fid,obj.variablerecords(k).data,'uint8');
    end
end

function obj = write_xyz(obj)
    fid = fopen(obj.header.filename,'r+');
    fseek(fid,double(obj.header.offset_to_point_data),-1);

    LEN = obj.header.point_data_record_length;
    OFFSET = 0;

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,toint32_xyz(obj),OFFSET,LEN);

    fclose(fid);
end

function obj = write_intensity(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;
    OFFSET = 12;
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.intensity,OFFSET,LEN);
    fclose(fid);
end

function obj = write_bits(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;
    OFFSET = 14;

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.bits,OFFSET,LEN);

    if obj.header.version_minor > 3 && obj.header.point_data_format > 5 %1.4 & pointformat >=6
        fseek(fid,double(obj.header.offset_to_point_data),-1);
        columndatafwrite(fid,obj.bits2,OFFSET+1,LEN);
    end
    fclose(fid);
end

function obj = write_classification(obj)
    fid = fopen(obj.header.filename,'r+');

    LEN = obj.header.point_data_record_length;
    offsettable = [15 15 15 15 15 15 16 16 16 16 16];
    OFFSET = offsettable(obj.header.point_data_format+1);

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.classification,OFFSET,LEN);
    fclose(fid);
end

function obj = write_scan_angle(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;

    offsettable = [16 16 16 16 16 16 18 18 18 18 18];
    OFFSET = offsettable(obj.header.point_data_format+1);
    datatypetable = {'int8', 'int8', 'int8', 'int8', 'int8', ...
        'int8', 'int16', 'int16', 'int16', 'int16', 'int16'};

    DATATYPE = datatypetable{obj.header.point_data_format+1};

    if ~isa(obj.scan_angle,DATATYPE)
        error(['Scan angle datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.scan_angle,OFFSET,LEN);
    fclose(fid);
end

function obj = write_user_data(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;
    DATATYPE ='uint8';
    offsettable = [17 17 17 17 17 17 17 17 17 17 17];
    OFFSET = offsettable(obj.header.point_data_format+1);

    if ~isa(obj.user_data,DATATYPE)
        error(['User data datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);

    columndatafwrite(fid,obj.user_data,OFFSET,LEN);
    fclose(fid);
end

function obj = write_point_source_id(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;
    offsettable = [18 18 18 18 18 18 20 20 20 20 20];
    OFFSET = offsettable(obj.header.point_data_format+1);
    DATATYPE = 'uint16';

    if ~isa(obj.point_source_id,DATATYPE)
        error(['Point source id datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.point_source_id,OFFSET,LEN);
    fclose(fid);
end

function obj = write_gps_time(obj)
    fid = fopen(obj.header.filename,'r+');
    %check if not in this point format
    if any(obj.header.point_data_format == [0 2])
        return;
    end

    LEN = obj.header.point_data_record_length;
    offsettable = [20 20 20 20 20 20 22 22 22 22 22];
    OFFSET = offsettable(obj.header.point_data_format+1);
    DATATYPE = 'double';

    if ~isa(obj.gps_time,DATATYPE)
        error(['GPS time datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,obj.gps_time,OFFSET,LEN);
    fclose(fid);
end

function obj = write_color(obj)
    fid = fopen(obj.header.filename,'r+');
    %check if not in this point format
    if any(obj.header.point_data_format == [0 1 2 4 6 9])
        return;
    end

    LEN = obj.header.point_data_record_length;
    offsettable = [20 20 20 28 28 28 30 30 30 30 30];
    OFFSET = offsettable(obj.header.point_data_format+1);
    DATATYPE = 'uint16';

    if ~isa(obj.red,DATATYPE)
        error(['Color datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    columndatafwrite(fid,[obj.red obj.green obj.blue],OFFSET,LEN);

    if any(obj.header.point_data_format == [8 10])
        fseek(fid,double(obj.header.offset_to_point_data),-1);
        columndatafwrite(fid,obj.nir,OFFSET+6,LEN);
    end

    fclose(fid);
end

function obj = write_point_wave_info(obj)
    fid = fopen(obj.header.filename,'r+');
    %check if not in this point format
    if any(obj.header.point_data_format == [0 1 2 3 6 7 8])
        return;
    end

    LEN = obj.header.point_data_record_length;

    offsettable = [28 28 28 28 28 28 28 28 28 30 38];

    DATATYPE = 'uint8';
    if ~isa(obj.wave_packet_descriptor,DATATYPE)
        error(['Wave packet descriptor datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1);
    columndatafwrite(fid,obj.wave_packet_descriptor,OFFSET,LEN);

    DATATYPE = 'uint64';
    if ~isa(obj.wave_byte_offset,DATATYPE)
        error(['Wave byte offset datatype is not: ' DATATYPE])
    end

    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+1;
    columndatafwrite(fid,obj.wave_byte_offset,OFFSET,LEN);

    DATATYPE = 'uint32';
    if ~isa(obj.wave_packet_size,DATATYPE)
        error(['Wave packet size datatype is not: ' DATATYPE])
    end
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+9;
    columndatafwrite(fid,obj.wave_packet_size,OFFSET,LEN);

    DATATYPE = 'single';
    if ~isa(obj.wave_return_point,DATATYPE)
        error(['Wave return point datatype is not: ' DATATYPE])
    end
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+13;
    columndatafwrite(fid,obj.wave_return_point,OFFSET,LEN);

    DATATYPE = 'single';
    if ~isa(obj.Xt,DATATYPE)
        error(['Xt datatype is not: ' DATATYPE])
    end
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+17;
    columndatafwrite(fid,obj.Xt,OFFSET,LEN);

    DATATYPE = 'single';
    if ~isa(obj.Yt,DATATYPE)
        error(['Yt datatype is not: ' DATATYPE])
    end
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+21;
    columndatafwrite(fid,obj.Yt,OFFSET,LEN);

    DATATYPE = 'single';
    if ~isa(obj.Zt,DATATYPE)
        error(['Zt datatype is not: ' DATATYPE])
    end
    fseek(fid,double(obj.header.offset_to_point_data),-1);
    OFFSET = offsettable(obj.header.point_data_format+1)+25;
    columndatafwrite(fid,obj.Zt,OFFSET,LEN);
    fclose(fid);
end

function obj = write_extradata(obj)
    fid = fopen(obj.header.filename,'r+');
    LEN = obj.header.point_data_record_length;
    offsettable = [20 28 26 34 57 63 30 36 38 59 67]; %magic numbers from point record byte lengths
    OFFSET = offsettable(obj.header.point_data_format+1);

    extralen = size(obj.extradata,1);
    if extralen %unknown extra data exists
        if ~isa(obj.extradata,'uint8')
            error(['Row extra data datatype is not: uint8'])
        end

        fseek(fid,double(obj.header.offset_to_point_data),-1);
        rowdatafwrite(fid,obj.extradata,OFFSET,LEN);
    end
    fclose(fid);
end

function obj = write_extended_variables(obj,fid)
    if ~isfield(obj.header,'number_of_extended_variable_length_record')
        obj.header.number_of_extended_variable_length_record = 0;
    end

    for k=1:obj.header.number_of_extended_variable_length_record
        fwrite(fid,obj.extendedvariables(k).reserved,'uint16');
        fwrite(fid,obj.extendedvariables(k).user_id,'int8');
        fwrite(fid,obj.extendedvariables(k).record_id,'uint16');
        fwrite(fid,length(obj.extendedvariables(k).data),'uint64');
        fwrite(fid,obj.extendedvariables(k).description,'int8');
        fwrite(fid,obj.extendedvariables(k).data,'uint8');
    end
end

function columndatafwrite(fid,data,columnpos,rowlength)
    %fwrite with block read/write to have faster column writes
    BLOCKROWS = 20000;

    insertdatalen = length(typecast(data(1,:),'uint8'));
    for k=1:BLOCKROWS:size(data,1)
        pos = ftell(fid);
        bend = k+BLOCKROWS-1;
        if bend > size(data,1)
            bend = size(data,1);
        end

        %find file size
        fseek(fid,0,1);
        filelen = ftell(fid);
        fseek(fid,pos,-1);
        %create empty space, because reading will fail otherwise
        %next column write will be faster
        if filelen < ftell(fid)+(bend-k+1)
            need_to_allocate = (bend-k+1)*rowlength - (filelen-pos);
            fwrite(fid,zeros(need_to_allocate,1,'uint8'));
        end
        fseek(fid,pos,-1);

        %read block to memory
        block = fread(fid,(bend-k+1)*rowlength,'*uint8');
        block = reshape(block,rowlength,[])';

        %add data in memory
        tmp = data(k:bend,:)';
        tmp = typecast(tmp(:),'uint8');
        tmp = reshape(tmp,insertdatalen,[])';
        block(:,columnpos+1:columnpos+insertdatalen) = tmp;
        block = block';
        %write block back to file
        fseek(fid,pos,-1);
        fwrite(fid,block(:));
    end
end

function rowdatafwrite(fid,data,rowpos,columnlength)
    %fwrite with block read/write to have faster column writes
    BLOCKROWS = 20000;

    insertdatalen = length(typecast(data(:,1),'uint8'));
    for k=1:BLOCKROWS:size(data,2)
        pos = ftell(fid);
        bend = k+BLOCKROWS-1;
        if bend > size(data,2)
            bend = size(data,2);
        end

        %find file size
        fseek(fid,0,1);
        filelen = ftell(fid);
        fseek(fid,pos,-1);
        %create empty space, because reading will fail otherwise
        %next column write will be faster
        if filelen < ftell(fid)+(bend-k+1)
            need_to_allocate = (bend-k+1)*columnlength - (filelen-pos);
            fwrite(fid,zeros(need_to_allocate,1,'uint8'));
        end
        fseek(fid,pos,-1);

        %read block to memory
        block = fread(fid,(bend-k+1)*columnlength,'*uint8');
        block = reshape(block,columnlength,[])';

        %add data in memory
        tmp = data(:, k:bend);
        tmp = typecast(tmp(:),'uint8');
        tmp = reshape(tmp,insertdatalen,[])';
        block(:,rowpos+1:rowpos+insertdatalen) = tmp;
        block = block';
        %write block back to file
        fseek(fid,pos,-1);
        fwrite(fid,block(:));
    end
end

function data = toint32_xyz( obj )
    if isempty(obj.x)
        warning('No data loaded.')
        return;
    end
    if isa(obj.x,'int32')
        return;
    end
    data(:,1) = obj.x - obj.header.x_offset;
    data(:,2) = obj.y - obj.header.y_offset;
    data(:,3) = obj.z - obj.header.z_offset;
    data(:,1) = round(data(:,1) / obj.header.scale_factor_x);
    data(:,2) = round(data(:,2) / obj.header.scale_factor_y);
    data(:,3) = round(data(:,3) / obj.header.scale_factor_z);
    data = int32(data);
end

function returns = get_return_number(obj)
    if obj.header.point_data_format < 6
        returns = bitand(obj.bits,7);
    else
        returns = bitand(obj.bits,15);
    end
end

function returns = get_number_of_returns(obj)
    if obj.header.point_data_format < 6
        returns = bitshift(bitand(obj.bits,56),-3);
    else
        returns = bitshift(bitand(obj.bits,240),-4);
    end
end

function returns = get_scan_direction_flag(obj)
    if obj.header.point_data_format < 6
        returns = bitand(obj.bits,64);
    else
        returns = bitand(obj.bits2,64);
    end
end

function returns = get_edge_of_flight_line(obj)
    if obj.header.point_data_format < 6
        returns = bitand(obj.bits,128);
    else
        returns = bitand(obj.bits2,128);
    end
end