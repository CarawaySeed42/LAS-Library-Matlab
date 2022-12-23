function bitfields = unpack_bit_fields(lasStruct, optsReturnType)
%[bitfields] = unpack_bit_fields(lasStruct, optsReturnType)
%   Unpacks LAS fields 'bits' and if applicable 'bits2'
%   The resulting data depends on if the LAS Minor Version is four or lower
%   than four (LAS 1.0 - LAS 1.3 or LAS 1.4)
%
% Input:
%   lasStruct (struct)          : Structure containing las data and a field
%                                 called 'bits' and 'bits2'
%   optsReturnType (char array) : Optional char array specifying return type
%
% Returns:
%   bitfields (varies)          : Matrix or Struct containing unpacked values
%
% Optional return types:
%   'matrix'    : Returns bit fields as a [nxm] double matrix (Standard)
%   'struct'    : Returns bit fields in a struct having one field for every
%                 data member
%
%   n:  Number of LAS points
%   m:  Number of bitfields. Is 4 if LAS Version Minor is smaller than four
%                            Is 6 if LAS Minor Version is exactly four
%
supportedReturnTypes = {'matrix', 'struct'};
returnType = 'matrix';

%% Input checks
if nargin == 2
    if ~any(strcmp(optsReturnType, supportedReturnTypes))
        error('unpack_bit_fields: Selected Return Type is not supported')
    end
    returnType = optsReturnType;
end

if ~isstruct(lasStruct)
    error('unpack_bit_fields: First argument has to be a LAS Struct')
end

if ~isfield(lasStruct.header, 'version_minor')
    error('unpack_bit_fields: Input struct is missing the field las.header.version_minor') 
end

if lasStruct.header.version_minor > 4 
   error('unpack_bit_fields: LAS Minor Versions bigger than 4 not implemented') 
end

if lasStruct.header.version_minor < 0
   error('unpack_bit_fields: LAS Minor Version is smaller than zero') 
end

%% Differentiate between LAS Minor Versions and extract bit fields

if lasStruct.header.version_minor == 4
    % Allocate result matrix and assign extracted fields
    bitfields       = zeros(numel(lasStruct.bits), 6);
    
    bitfields(:,1)  = bitshift(lasStruct.bits, -4, 'uint8');             % Return Number
    bitfields(:,2)  = bitand(lasStruct.bits, 15);                        % Number of Returns (Given Pulse)
    
    bitfields(:,3)  = bitshift(lasStruct.bits2, -4, 'uint8');            % Classification Flags
    bitfields(:,4)  = bitand(bitshift(lasStruct.bits2, -2, 'uint8'), 3); % Scanner Channel
    bitfields(:,5)  = bitand(bitshift(lasStruct.bits2, -1, 'uint8'), 1); % Scan Direction Flag
    bitfields(:,6)  = bitand(lasStruct.bits2, 1);                        % Edge of Flight Line
    
    % Change return type to struct if so chosen
    if strcmp(returnType, 'struct')
        tmpStruct = struct;
        tmpStruct.return_number         = bitfields(:,1);
        tmpStruct.number_of_returns     = bitfields(:,2);
        tmpStruct.classification_flags  = bitfields(:,3);
        tmpStruct.scanner_channel       = bitfields(:,4);
        tmpStruct.scan_direction_flag   = bitfields(:,5);
        tmpStruct.edge_of_flight_line   = bitfields(:,6);
        
        bitfields = tmpStruct;
    end
else
    % Allocate result matrix and assign extracted fields
    bitfields       = zeros(numel(lasStruct.bits), 4);
    
    bitfields(:,1)  = bitshift(lasStruct.bits, -5, 'uint8');            % Return Number
    bitfields(:,2)  = bitand(bitshift(lasStruct.bits, -2, 'uint8'), 7); % Number of Returns (Given Pulse)
    bitfields(:,3)  = bitand(bitshift(lasStruct.bits, -1, 'uint8'), 1); % Scan Direction Flag
    bitfields(:,4)  = bitand(lasStruct.bits, 1);                        % Edge of Flight Line
    
    % Change return type to struct if so chosen
    if strcmp(returnType, 'struct')
        tmpStruct = struct;
        tmpStruct.return_number         = bitfields(:,1);
        tmpStruct.number_of_returns     = bitfields(:,2);
        tmpStruct.scan_direction_flag   = bitfields(:,3);
        tmpStruct.edge_of_flight_line   = bitfields(:,4);
        
        bitfields = tmpStruct;
    end
end

%% Educational Information about code parts
% Explanantion of "Magical" logical And numbers:
% First of all: In this case we read from right to left
% We try to extract certain bits from a value. So we shift the bits to the
% right until the start of the bits we want is the rightmost
% Then we mask the bits to the left we don't want. 
% So if we do a logical and operation with the number 3 then we only
% get 2 bits because 3 = 0b00000011
% 7 would be 0b00000111 and thus 3 bits
end