function lasStruct = encode_bit_fields(lasStruct, bitfields)
%[bitfields] = decode_bit_fields(lasStruct, optsReturnType)
%   Encode LAS fields 'bits' and, if provided, 'bits2'.
%   'bits' will be encoded if only Return Number, Number of Returns, Scan
%   Direction Flag and Edge of Flight Line are provided
%
%   'bits2' will be encoded if Classification Flags and Scanner Channel are
%   additionally provided.
%   
%   If 'bits2' is encoded then LAS version minor will be set to 4 if it was
%   smaller than 4 in the first place
%
%   Only LAS Versions up to 1.4 are supported for encoding because how the
%   fields look for 1.5 is unknown at this point in time
%
% Input:
%   lasStruct (struct)  : Structure containing las data and a field
%                                 called 'bits' and 'bits2'
%   bitfields (varies)  : nx4 matrix or nx6 matrix or Bitfields class with
%                         following properties
%
%                          4 field input:
%                              return_number
%                              number_of_returns
%                              scan_direction_flag
%                              edge_of_flight_line
%
%                          6 field input:
%                              return_number
%                              number_of_returns
%                              classification_flags
%                              scanner_channel
%                              scan_direction_flag
%                              edge_of_flight_line
%
% Returns:
%   lasStruct (struct)  : Modified Input struct with encoded bitfields
%
%
% Copyright (c) 2022, Patrick Kümmerle
% Licence: see the included file
%
%-------------------------------------------------------------------------
% Bit fields according to LAS 1.4 Revision 15 specification:
%
% LAS 1.0 - 1.3:
%   Return Number 3 bits (bits 0-2)
%   Number of Returns (Given Pulse) 3 bits (bits 3-5)
%   Scan Direction Flag 1 bit (bit 6)
%   Edge of Flight Line 1 bit (bit 7)
%
% LAS 1.4:
%   Return Number 4 bits (bits 0-3)
%   Number of Returns (Given Pulse) 4 bits (bits 4-7)
%   Classification Flags 4 bits (bits 0-3
%   Scanner Channel 2 bits (bits 4-5)
%   Scan Direction Flag 1 bit (bit 6)
%   Edge of Flight Line 1 bit (bit 7) 
%% 

encodeBits2 = false;        % Are two bit bytes to be encoded? (LAS 1.4)
pointCount = 0;             % How many data points are there?


%% Input checks
% Check if Bitfields input and turn it into matrix
if isa(bitfields, 'Bitfields')

    % Check if minimal input is present
    if ~isprop(bitfields, 'return_number')
        error('Input Bitfields instance is missing the field: return_number')
    end
    if ~isprop(bitfields, 'number_of_returns')
        error('Input Bitfields instance is missing the field: number_of_returns')
    end
    if ~isprop(bitfields, 'scan_direction_flag')
        error('Input Bitfields instance is missing the field: scan_direction_flag')
    end
    if ~isprop(bitfields, 'edge_of_flight_line')
        error('Input Bitfields instance is missing the field: edge_of_flight_line')
    end
    
    if ~isequal(numel(bitfields.return_number), numel(bitfields.number_of_returns),...
            numel(bitfields.scan_direction_flag) , numel(bitfields.edge_of_flight_line))
        error('Input bitfields need to have the same number of entries')
    end
    
    % Number of points
    pointCount = numel(bitfields.return_number);
    
    % Check for additional input
    if isprop(bitfields, 'classification_flags') && isprop(bitfields, 'scanner_channel')
        encodeBits2 = true;
        
        if ~isequal(pointCount, numel(bitfields.classification_flags) , numel(bitfields.scanner_channel))
            error('Input bitfields classification_flags and scanner_channel need to have the same number of entries as the rest')
        end
    end
    
    % Check if isExtended flag is set in Bitfields class instance
    if isprop(bitfields, 'IsExtended')
        encodeBits2 = bitfields.IsExtended && encodeBits2;
    end
    
    % Create Matrix
    if ~encodeBits2
        bitfields = [bitfields.return_number, bitfields.number_of_returns,...
                     bitfields.scan_direction_flag, bitfields.edge_of_flight_line];
    else
        bitfields = [bitfields.return_number, bitfields.number_of_returns, bitfields.classification_flags...
                     bitfields.scanner_channel, bitfields.scan_direction_flag, bitfields.edge_of_flight_line];
    end
    
else % Check for correct matrix size 
    
    inputSize = size(bitfields);
    if inputSize(2) == 6
        encodeBits2 = true;
    elseif inputSize(2) ~= 4
        error('Input bitfields matrix has a column size of neither 4 nor 6')
    end
    
    % Number of Points
    pointCount = inputSize(1);
end

if ~isstruct(lasStruct)
    error('First argument has to be a LAS Struct')
end

% Correct version minor if necessary
if encodeBits2
    if ~isfield(lasStruct.header, 'version_minor') || lasStruct.header.version_minor < 4
        lasStruct.header.version_minor = 4;
    end
end

% check data type of input
if ~isa(bitfields, 'uint8')
    bitfields = uint8(bitfields);
end

%% Differentiate between LAS Minor Versions and extract bit fields

if encodeBits2
    
    if ~isfield(lasStruct, 'bits2')
        error('Input struct is missing the field bits2')
    end
    
    % Allocate result matrix and assign extracted fields
    lasStruct.bits  = zeros(pointCount, 1, 'uint8');
    lasStruct.bits2 = zeros(pointCount, 1, 'uint8');
    
    lasStruct.bits  = bitfields(:,1);                                                % Return Number (4 bits)
    lasStruct.bits  = bitshift(lasStruct.bits, 4, 'uint8');                          %   Shift to next
    lasStruct.bits  = bitor(lasStruct.bits, bitand(bitfields(:,2), 15), 'uint8');    % Number of Returns (Given Pulse) (4 bits)
    
    lasStruct.bits2  = bitfields(:,3);                                               % Classification Flags (4 bits)
    lasStruct.bits2  = bitshift(lasStruct.bits2, 2, 'uint8');                        %   Shift to next
    lasStruct.bits2  = bitor(lasStruct.bits2, bitand(bitfields(:,4), 3), 'uint8');   % Scanner Channel (2 bits)
    lasStruct.bits2  = bitshift(lasStruct.bits2, 1, 'uint8');                        %   Shift to next
    lasStruct.bits2  = bitor(lasStruct.bits2, bitand(bitfields(:,5), 1), 'uint8');   % Scan Direction Flag (1 bits)
    lasStruct.bits2  = bitshift(lasStruct.bits2, 1, 'uint8');                        %   Shift to next
    lasStruct.bits2  = bitor(lasStruct.bits2, bitand(bitfields(:,6), 1), 'uint8');   % Edge of Flight Line (1 bits)
    
else
    % Allocate result matrix and assign extracted fields
    lasStruct.bits  = zeros(pointCount, 1, 'uint8');
    
    lasStruct.bits  = bitfields(:,1);                                               % Return Number (4 bits)
    lasStruct.bits  = bitshift(lasStruct.bits, 3, 'uint8');                         %   Shift to next
    lasStruct.bits  = bitor(lasStruct.bits, bitand(bitfields(:,2), 7), 'uint8');    % Number of Returns (Given Pulse) (2 bits)
    lasStruct.bits  = bitshift(lasStruct.bits, 1, 'uint8');                         %   Shift to next
    lasStruct.bits  = bitor(lasStruct.bits, bitand(bitfields(:,3), 1), 'uint8');    % Scan Direction Flag (1 bits)
    lasStruct.bits  = bitshift(lasStruct.bits, 1, 'uint8');                         %   Shift to next
    lasStruct.bits  = bitor(lasStruct.bits, bitand(bitfields(:,4), 1), 'uint8');    % Edge of Flight Line (1 bits)
    
end

end