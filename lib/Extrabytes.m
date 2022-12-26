classdef Extrabytes < dynamicprops
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        extrabytenames
    end
    
    methods
        function obj = Extrabytes(names)
            %Extrabytes Construct an instance of this class
            %   Add a property for every name specified in the cell array
            %   names. Constructs empty class if names not specified
            if ~nargin || ~iscell(names)
                return;
            end
            
            obj.extrabytenames = cell(length(names), 1);
            
            for i = 1:numel(names)
                extrabyte_name = names{i};
                field_name = strrep(strcat(extrabyte_name), ' ', '_');
                obj.extrabytenames(i) = {field_name};
                obj.addprop(field_name);
                
                obj.(field_name).vlr_record.reserved       = uint8([0;0]);             % 2 Bytes
                obj.(field_name).vlr_record.data_type.raw   = uint8(0);              % 1 Byte
                
                obj.(field_name).vlr_record.data_type.matlab_type = 'int64';
                obj.(field_name).vlr_record.data_type.size = 0;
                
                obj.(field_name).vlr_record.options.raw = uint8(zeros(1));       % 1 Byte
                obj.(field_name).vlr_record.name        = extrabyte_name;        % 32 Byte
                obj.(field_name).vlr_record.unused      = uint8(zeros(1,4));     % 4 Byte
                obj.(field_name).vlr_record.no_data     = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).vlr_record.deprecated1 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).vlr_record.min         = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).vlr_record.deprecated2 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).vlr_record.max         = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).vlr_record.deprecated3 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).vlr_record.scale       = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).vlr_record.deprecated4 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).vlr_record.offset      = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).vlr_record.deprecated5 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).vlr_record.description = char(zeros(1,32))';    % 32 Bytes
                
                % Decode options
                obj.(field_name).vlr_record.options.no_data_bit = uint8(zeros(1));
                obj.(field_name).vlr_record.options.min_bit     = uint8(zeros(1));
                obj.(field_name).vlr_record.options.max_bit     = uint8(zeros(1));
                obj.(field_name).vlr_record.options.scale_bit   = uint8(zeros(1));
                obj.(field_name).vlr_record.options.offset_bit  = uint8(zeros(1));
            end
        end
        
    end
    
    methods(Static)
        function datatypeLookup = GetDataTypeLUT()
            %GetDataTypeLUT Returns Look up table for the VLR byte that
            %               specifies the data type
            % Unused and undocumented types get the size of 0 bytes
            % Layout: [from_num, to_num, matlab_data_type, sizeof_type] 
            datatypeLookup = [...
                0,  0,  {'uint64'},  0;   ...  %  undocumented extra bytes specify value in options field
                1,  1,  {'uint8'},   1;   ...  %  unsigned char 1 byte
                2,  2,  {'char'},    1;   ...  %  char 1 byte
                3,  3,  {'uint16'},  2;   ...  %  unsigned short 2 bytes
                4,  4,  {'int16'},   2;   ...  %  short 2 bytes
                5,  5,  {'uint32'},  4;   ...  %  unsigned long 4 bytes
                6,  6,  {'int32'},   4;   ...  %  long 4 bytes
                7,  7,  {'uint64'},  8;   ...  %  unsigned long long 8 bytes
                8,  8,  {'int64'},   8;   ...  %  long long 8 bytes
                9,  9,  {'float'},   4;   ...  %  float 4 bytes
                10, 10, {'double'},  8;   ...  %  double 8 bytes
                11, 30, {'uint64'},  0;   ...  %  Deprecated deprecated
                31, 255,{'uint64'},  0;   ...  %  Reserved not assigned
                ];
        end
    end

end

