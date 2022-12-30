classdef Bitfields < dynamicprops
    %Bitfields   : Class for LAS Point Data Bitfields
    %   Holds properties of bitfields. Four fields for LAS 1.0 to 1.3
    %   and six bitfields for LAS 1.4 (->extended)
    %   The properties of an instance of this class are dynamic
    %
    % Copyright (c) 2022, Patrick Kümmerle
    % Licence: see the included file    
    properties
        IsExtended
        return_number
        number_of_returns
    end
    
    methods
        function obj = Bitfields(useExtendedFields)
            %Bitfields Construct an instance of this class
            %   Creates members for bitfields. Four properties are created
            %   if useExtendedFields is false or no argument is provided.
            %   Six properties are created if useExtendedFields is true
            %   This refers to the different field count for different LAS
            %   version minors
            obj.IsExtended = false;
            if nargin > 0
                if useExtendedFields
                    obj.addprop('classification_flags');
                    obj.addprop('scanner_channel');
                    obj.IsExtended = true;
                end
            end
            
            obj.addprop('scan_direction_flag');
            obj.addprop('edge_of_flight_line');
        end
        
        function Extend(obj)
            %Extend Extends the Bitfield by the fields introduced in LAS 1.4
            %   Adds the two properties classification_flags and scanner_channel
            %   if they do not already exist
            if ~isprop(obj, 'classification_flags')
                obj.addprop('classification_flags');
            end
            if ~isprop(obj, 'scanner_channel')
                obj.addprop('scanner_channel');
            end
            obj.IsExtended = true;
        end
        
        function Shorten(obj)
            %Shorten Shortens the Bitfield to only contain fields relevant for
            %        LAS 1.0 to 1.3
            %   Removes the two properties classification_flags and scanner_channel
            %   if they exist
            if isprop(obj, 'classification_flags')
                delete(findprop(obj, 'classification_flags'));
            end
            if isprop(obj, 'scanner_channel')
                delete(findprop(obj, 'scanner_channel'));
            end
            obj.IsExtended = false;
        end
    end
end

