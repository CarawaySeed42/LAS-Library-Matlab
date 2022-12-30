classdef Extrabytes < dynamicprops
    %Extrabytes   Class for Extra Bytes appended to point data of LAS file
    %   Holds the names, descriptors and decoded data of extra byte data
    %   The properties of an instance of this class are dynamic
    %
    % Copyright (c) 2022, Patrick Kümmerle
    % Licence: see the included file
    
    properties
        extrabytenames = {}
    end
    
    methods
        function obj = Extrabytes(names)
            %obj = Extrabytes(names) Construct an instance of this class
            %   Add a property for every name specified in the cell array
            %   names. Constructs empty class if names not specified
            if ~nargin || ~iscell(names)
                return;
            end
            
            obj.AddExtrabytes(names);
        end
        
        function AddExtrabytes(obj, names)
            %AddExtrabytes(names) Add a new extrabyte to this object. Adds 
            %   a property for every specified name in argument names.
            %   Argument is a cell array containing char arrays specifying
            %   the names of the extrabytes
            if ~nargin || ~iscell(names)
                warning('AddExtraBytes: No valid extrabyte names provided! Object remains unchanged')
                return;
            end
            
            for i = 1:numel(names)
                extrabyte_name = names{i};
                field_name = VariableNames.MakeValid(extrabyte_name);
                obj.extrabytenames(end+1) = {field_name};
                obj.addprop(field_name);
                
                obj.(field_name).descriptor.reserved       = uint8([0;0]);             % 2 Bytes
                obj.(field_name).descriptor.data_type.raw   = uint8(0);              % 1 Byte
                
                obj.(field_name).descriptor.data_type.matlab_type = 'int64';
                obj.(field_name).descriptor.data_type.size = 0;
                
                obj.(field_name).descriptor.options.raw = uint8(zeros(1));       % 1 Byte
                obj.(field_name).descriptor.name        = extrabyte_name;        % 32 Byte
                obj.(field_name).descriptor.unused      = uint8(zeros(1,4));     % 4 Byte
                obj.(field_name).descriptor.no_data     = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).descriptor.deprecated1 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.min         = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).descriptor.deprecated2 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.max         = int64(zeros(1,8));     % 8 Bytes any type
                obj.(field_name).descriptor.deprecated3 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.scale       = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).descriptor.deprecated4 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.offset      = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).descriptor.deprecated5 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.description = char(zeros(1,32))';    % 32 Bytes
                
                % Decode options
                obj.(field_name).descriptor.options.no_data_bit = uint8(zeros(1));
                obj.(field_name).descriptor.options.min_bit     = uint8(zeros(1));
                obj.(field_name).descriptor.options.max_bit     = uint8(zeros(1));
                obj.(field_name).descriptor.options.scale_bit   = uint8(zeros(1));
                obj.(field_name).descriptor.options.offset_bit  = uint8(zeros(1));
            end
        end

    end
    
    methods(Static)
        function datatypeLookup = GetDataTypeLUT()
            %GetDataTypeLUT Returns Look up table for the VLR byte that
            %               specifies the data type to find out which
            %               datatype was specified in VLR
            % Unused and undocumented types get the initial size of 0 bytes
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
                11, 30, {'uint64'},  0;   ...  %  Deprecated
                31, 255,{'uint64'},  0;   ...  %  Reserved not assigned
                ];
        end
        
        function datatypeIndices = GetDataTypeIndices()
            %GetDataTypeIndices Returns which row of data type lookup table
            %                   contains unsigned, signed, floating point
            %                   or undocumented datatypes 
            datatypeIndices = struct('unsigned', [0,1,3,5,7], 'signed', [2,4,6,8],...
                                     'float', [9,10]);
        end
        
    end

end

