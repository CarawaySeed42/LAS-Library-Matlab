classdef Extrabytes < dynamicprops
    %Extrabytes   Class for Extra Bytes appended to point data of LAS file
    %   Holds the names, descriptors and decoded data of extra byte data
    %   The properties of an instance of this class are dynamic
    %
    % Copyright (c) 2022, Patrick Kümmerle
    % Licence: see the included file
    
    properties
        ExtrabyteNames = {}
    end
    
    methods
        function obj = Extrabytes(names)
            %Extrabytes    Construct an instance of this class
            %   obj = Extrabytes(names)
            %   Add a property for every name specified in the cell array
            %   names. Constructs empty class if names not specified
            
            if ~nargin 
                return;
            end
            if ischar(names)
                names = {names};
            end
            if ~iscell(names)
                error('Argin is no valid extrabyte name(s)');
            end
            
            obj.AddExtrabytes(names);
        end
        
        function AddExtrabytes(obj, names)
            %AddExtrabytes Add a new extrabyte to this object.  
            %   AddExtrabytes(names)
            %   Adds a property for every specified name in argument names.
            %   Argument is a cell array containing char arrays specifying
            %   the names of the extrabytes
            if ~nargin || ~iscell(names)
                warning('AddExtraBytes: No valid extrabyte names provided! Object remains unchanged')
                return;
            end
            
            for i = 1:numel(names)
                extrabyte_name = names{i};
                field_name = VariableNames.MakeValid(extrabyte_name);
                obj.ExtrabyteNames(end+1) = {field_name};
                obj.addprop(field_name);
                
                obj.(field_name).descriptor.reserved       = uint8([0;0]);             % 2 Bytes
                obj.(field_name).descriptor.data_type.raw   = uint8(0);              % 1 Byte
                
                obj.(field_name).descriptor.data_type.matlab_type = 'int64';
                obj.(field_name).descriptor.data_type.size = uint8(0);
                
                obj.(field_name).descriptor.options.raw = uint8(0);              % 1 Byte
                obj.(field_name).descriptor.name        = extrabyte_name;        % 32 Byte
                obj.(field_name).descriptor.unused      = uint8(zeros(1,4));     % 4 Byte
                obj.(field_name).descriptor.no_data     = uint64(0);             % 8 Bytes any type
                obj.(field_name).descriptor.deprecated1 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.min         = uint64(0);             % 8 Bytes any type
                obj.(field_name).descriptor.deprecated2 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.max         = uint64(0);             % 8 Bytes any type
                obj.(field_name).descriptor.deprecated3 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.scale       = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).descriptor.deprecated4 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.offset      = double(zeros(1,8));    % 8 Bytes
                obj.(field_name).descriptor.deprecated5 = uint8(zeros(1,16));    % 16 Bytes
                obj.(field_name).descriptor.description = char(zeros(1,32));     % 32 Bytes
                
                obj.(field_name).descriptor.options.no_data_bit = uint8(0);
                obj.(field_name).descriptor.options.min_bit     = uint8(0);
                obj.(field_name).descriptor.options.max_bit     = uint8(0);
                obj.(field_name).descriptor.options.scale_bit   = uint8(0);
                obj.(field_name).descriptor.options.offset_bit  = uint8(0);
            end
        end
        
        function RemoveExtrabytes(obj, names)
            % RemoveExtrabytes  Remove extrabytes from object
            %   RemoveExtrabytes(names)
            %   Removes the extrabytes with called names
            if ischar(names)
                names = {names};
            end
            if ~iscell(names)
                error('Argin is no valid extrabyte name(s)');
            end
            for i = 1: length(names)
                rmprops(obj, names{i});
                obj.ExtrabyteNames(strcmp(obj.ExtrabyteNames, names{i})) = [];
            end
        end
        
        function SetExtrabyteData(obj, name, data)
            %SetExtrabyteData  Set the data values of the extra byte values per point record
            %  SetExtrabyteData(data) 
            %  Set the extrabyte data for the extra byte specified by name
            %  data should be a [n x 1] vector with n being the number of
            %  point records and thus extra byte values in the point cloud
            %  which the extra bytes should be encoded into
            if size(data,2) > size(data,1)
                data = data';
            end
            if size(data,2) ~= 1
                error('Extrabyte data has to be a vector');
            end
            obj.(name).decoded_data = data;
        end
        
        function data = GetExtrabyteData(obj, name)
            %GetExtrabyteData  Get the data values of the extra byte values per point record
            %  data = GetExtrabyteData(name)
            %  Get the extrabyte data for the extra byte specified by name
            data = obj.(name).decoded_data;
        end
        
        function SetDataType(obj, names, datatype)
            %SetDataType Set the data type of the extrabytes
            %   SetDataType(names, datatype)
            %   Sets the datatype of the extrabytes 
            %   Input can be matlab datatype as char array or index from
            %   data type lookup table
            if nargin < 3
                error('Not enough input arguments')
            end
            if ~iscell(names)
                names = {names};
            end
            
            LUT_Row = -1;
            datatypeLookup = Extrabytes.GetDataTypeLUT();
            
            if isnumeric(datatype)
                LUT_Row    = datatype;
            elseif ischar(datatype)
                LUT_Row    = find(strcmp(datatype,datatypeLookup(:,3)));
                LUT_Row    = LUT_Row(cell2mat(datatypeLookup(LUT_Row, 4)) ~= 0);
            end
            
            if LUT_Row == -1 || isempty(LUT_Row)
                error('Data type argument could not be assigned to matlab data type!')
            end
            
            for i = 1:length(names)
                field_name = names{i};
                obj.(field_name).descriptor.data_type.matlab_type = datatypeLookup{LUT_Row, 3};
                obj.(field_name).descriptor.data_type.raw         = uint8(datatypeLookup{LUT_Row, 1});
                obj.(field_name).descriptor.data_type.size        = uint8(datatypeLookup{LUT_Row, 4});
            end
        end
        
        function datatype = GetDataType(obj, name)
            %GetDataType Get the data type of the extrabytes
            %   datatype = SetDataType(names)
            %   Gets the datatype of the extrabytes as struct
            %   containing raw value, matlab type and size of type
            datatype.raw         = obj.(name).descriptor.data_type.raw;
            datatype.matlab_type = obj.(name).descriptor.data_type.matlab_type;
            datatype.size        = obj.(name).descriptor.data_type.size;
        end
        
        function SetOptions(obj, names, no_data, min, max, scale, offset)
            %SetOptions Specify if options fields are relevant or not
            %   SetOptions(names, no_data, min, max, scale, offset)
            %   Encodes the chosen settings into a single value.
            %   Input no_data, min, max, scale and offset will be converted
            %   to logical. If true then the bit will be set to specify
            %   that this field is relevant for de- and encoding
            if nargin < 7
                error('Not enough input arguments')
            end
            if ~iscell(names)
                names = {names};
            end
            
            for i = 1:length(names)
                field_name = names{i};
                optionsTmp = logical(no_data)*1 + logical(min)*2 + logical(max)*4 + logical(scale)*8 + logical(offset)*16;
                obj.(field_name).descriptor.options.raw = uint8(optionsTmp);
                obj.(field_name).descriptor.options.no_data_bit = logical(no_data);
                obj.(field_name).descriptor.options.min_bit     = logical(min);
                obj.(field_name).descriptor.options.max_bit     = logical(max);
                obj.(field_name).descriptor.options.scale_bit   = logical(scale);
                obj.(field_name).descriptor.options.offset_bit  = logical(offset);
            end
        end
               
        function options = GetOptions(obj, name)
            %GetOptions Get extra byte options regarding no_data, min, max, scale and offset
            %   GetOptions(name)
            %   Returns options regarding raw value, no_data, min, max, scale and offset 
            %   as a struct
            options.raw     = obj.(name).descriptor.options.raw;
            options.no_data = obj.(name).descriptor.options.no_data_bit;
            options.min     = obj.(name).descriptor.options.min_bit;
            options.max     = obj.(name).descriptor.options.max_bit;
            options.scale   = obj.(name).descriptor.options.scale_bit;
            options.offset  = obj.(name).descriptor.options.offset_bit;
        end
        
        function SetNoData(obj, name, noDataValue)
            %SetNoData  Sets the value which indicates no data of extra byte
            %   SetNoData(name, noDataValue)
            %   Writes NoData value to descriptor of extra byte called name
            obj.(name).descriptor.no_data = noDataValue;
        end
        
        function noDataValue = GetNoData(obj, name)
            %GetNoData  Gets the value which indicates no data of extra byte
            %   GetNoData(name)
            %   Gets NoData value from descriptor of extra byte called name
            noDataValue = obj.(name).descriptor.no_data;
        end
        
        function SetMin(obj, name, minValue)
            %SetMin  Sets the minimum value of extrabytes
            %   SetMin(name, minValue)
            %   Writes minimum value to descriptor of extra byte called name
            obj.(name).descriptor.min = minValue;
        end
        
        function minValue = GetMin(obj, name)
            %GetMin  Gets the minimum value of extrabytes
            %   GetMin(name)
            %   Gets min value from descriptor of extra byte called name
            minValue = obj.(name).descriptor.min;
        end
        
        function SetMax(obj, name, maxValue)
            %SetMax  Sets the maximum value of extrabytes
            %   SetMax(name, maxValue)
            %   Writes maximum value to descriptor of extra byte called name
            obj.(name).descriptor.max = maxValue;
        end
        
        function maxValue = GetMax(obj, name)
            %GetMax  Gets the maximum value of extrabytes
            %   GetMax(name)
            %   Gets max value from descriptor of extra byte called name
            maxValue = obj.(name).descriptor.max;
        end
        
        function SetScale(obj, name, scale)
            %SetScale  Sets the scale value of extrabytes
            %   SetScale(name, scale)
            %   Writes scale value to descriptor of extra byte called name
            obj.(name).descriptor.scale = scale;
        end
        
        function scale = GetScale(obj, name)
            %GetScale  Gets the scale value of extrabytes
            %   GetScale(name)
            %   Gets scale value from descriptor of extra byte called name
            scale = obj.(name).descriptor.scale;
        end
        
        function SetOffset(obj, name, offset)
            %SetOffset  Sets the offset value of extrabytes
            %   SetOffset(name, offset)
            %   Writes offset value to descriptor of extra byte called name
            obj.(name).descriptor.offset = offset;
        end
        
        function offset = GetOffset(obj, name)
            %GetOffset  Gets the offset value of extrabytes
            %   GetOffset(name)
            %   Gets offset value from descriptor of extra byte called name
            offset = obj.(name).descriptor.offset;
        end
        
        function SetDescription(obj, name, description)
            %SetDescription  Sets the minimum value in extrabytes
            %   SetDescription(name, description)
            %   Writes description to descriptor of extra byte called name
            %   Description is a [1x32] char array
            if ~ischar(description)
                error('Extrabyte description has to be char array')
            end
            if size(description,1) ~= 1 && size(description,2) ~= 1
                error('Extrabyte description has to be [1xn] char array')
            end
            
            descriptionEnd = length(description);
            if length(description) > 32
                descriptionEnd = 32;
            end
            
            obj.(name).descriptor.description = char(zeros(1,32));
            obj.(name).descriptor.description(1:descriptionEnd) = description(1:descriptionEnd);
        end
    end
    
    methods(Static)
        function datatypeLookup = GetDataTypeLUT()
            %GetDataTypeLUT Returns Look up table for the VLR data type byte
            %   datatypeLookup = GetDataTypeLUT()
            %   Returns Look up table for the VLR data type byte
            %   to find out which datatype was specified in VLR
            %   Unused and undocumented types get the initial size of 0 bytes
            %   Layout: [from_num, to_num, matlab_data_type, sizeof_type] 
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
            %GetDataTypeIndices Get general data types of LUT entries
            %   datatypeIndices = GetDataTypeIndices()
            %   Returns which row of data type lookup table
            %   Contains unsigned, signed, floating point
            %   or undocumented datatypes 
            datatypeIndices = struct('unsigned', [0,1,3,5,7], 'signed', [2,4,6,8],...
                                     'float', [9,10]);
        end
        
    end

end

