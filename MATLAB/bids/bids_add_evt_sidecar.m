% ADD HELPER LATER
% ENTRIES not in 
function EEG = bids_add_evt_sidecar( EEG, events_table, event_types, vars_to_add ) 

% Add error checks for QC

% Make sure EEG.event(event_type) has same length as events_tsv...otherwise
% error

% Make sure all vars_to_add are in events_tsv (and don't overlap with EEG)


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