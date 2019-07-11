% eeglab_add_table_to_events - This function adds selected columns of data
%                              table object to the EEG.events structure.
%                              This is only done for specific markers (in
%                              {EEG.event.type}). The number of rows in the
%                              data table must match the number of TRUE
%                              instances of EVENT_TYPES in
%                              {EEG.event.type}. 
% Usage:
%   >> EEG = eeglab_add_table_to_events( EEG, events_table, event_types, vars_to_add )
%
% Required inputs:
%   EEG          - EEGLAB EEG structure with EEG.events.
%   events_table - data table object containing information about a
%                  participant.
%   event_types  - cell array of strings corresponding to values in
%                  EEG.event.code to which events should be added.
%   vars_to_add  - cell array of strings for variables (columns) in
%                  events_table to add as fields in EEG.event.  
%
% Create by: Joshua D. Koen, University of Notre Dame
% Created on 2019/06/17

function EEG = eeglab_add_table_to_events( EEG, events_table, event_types, vars_to_add ) 

% Conduct some QC checks on inputs
try
    n_valid_markers = sum( ismember({EEG.event.type}, event_types) ); % will fail if numeric
catch
    n_valid_markers = sum( ismember([EEG.event.type], event_types) );
end
if height(events_table) ~= n_valid_markers
    error(['The number of rows in events_table input does not match the number of ' ...
           'valid markers (specified by event_types) in {EEG.event.type}.']);
end

% Check overlap in names (I do not want to debug overlapping names, so
% throw an error)
event_fields = fieldnames(EEG.event);
if any( ismember(event_fields, vars_to_add) )
    error(['At least one variable being added as the same name as a field in EEG.event. ' ...
           'This function does not handle duplicate variable/field names.']);
end

% Initialize events_counter for events_table
events_counter = 0;

for e = 1:length(EEG.event) % loop over EEG.event
    
    % Skip if EEG.event(e).type is not in event_type
    if ~ismember( EEG.event(e).type, event_types )
        continue;
    else % It is a member, so add vars_to_add
        
        % Incriment counter
        events_counter = events_counter + 1;          
        
        % Add data
        for v = string(vars_to_add)
            
            this_val = events_table.( char(v) )(events_counter);
            if iscell(this_val)
                this_val = this_val{1};
            end
            EEG.event(e).( char(v) ) = this_val;
            
        end
        
    end
    
end

end % of function