% bids_events_to_tsv - This function takes an EEG data structure as input,
%                      and writes inofrmation in EEG.events to a
%                      *events.tsv sidecar file.
%
% Usage:
%   >> bids_events_to_tsv( EEG )
%   >> bids_events_to_tsv( EEG, tsv_file )
%   >> bids_events_to_tsv( EEG, tsv_file, vars_to_write )   
%
% Required inputs:
%   EEG      - EEG data structure with EEG.event field
%   
% 
% Optional inputs:
%   tsv_file      - file name of data file to write *channels.tsv. Defaults
%                   to reading EEG.filepath and EEG.filename. 
%   vars_to_write - cell array of strings for fields in EEG.event to write
%                   to the sidecar. These are ADDITIONAL fields. Defaults
%                   are onset, duration, sample, and value (following BIDS
%                   specification). 
%
% Create by: Joshua D. Koen, University of Notre Dame
% Created on 2019/06/17

function bids_events_to_tsv( EEG, tsv_file, vars_to_write )

% Just convert EEG.event to cell table to start off with
% This is useful for extracting data later on
if length( EEG.event ) > 1
    in_dt = struct2table( EEG.event );
else % Handle a single trial or marker
    event_cell = struct2cell( EEG.event );
    event_cell( cellfun(@isempty,event_cell) ) = {'n/a'};
    if ~isrow( event_cell )
        event_cell = event_cell';
    end
    event_fields = fieldnames( EEG.event );
    in_dt = cell2table( event_cell, 'VariableNames', event_fields );
end

% Extract onsets, samples, and durations
onset    = (in_dt.latency / EEG.srate) - (1 / EEG.srate);
sample   = in_dt.latency;
duration = in_dt.duration;
value    = in_dt.type;

% create output dt (out_dt)
out_dt = table(onset,sample,duration,value);

% Add additional columns if need be
if isvarname('vars_to_write') && ~isempty(vars_to_write)
    
    % Error check vars_to_write
    if ~all( ismember(vars_to_write, in_dt.Properties.VariableNames) )
        error('All VARS_TO_WRITE input values must exist as a field in EEG.event.');
    end
    
    % Update out_dt
    for vari = 1:length(vars_to_write)
        this_field = vars_to_write{vari};
        out_dt.( this_field ) = in_dt.( this_field );
    end

end

% If file name is supplied, use it to make _events.tsv sidecar
if isvarname('filename') && ~isempty(tsv_file)
    [path, file] = fileparts(tsv_file);
else
    if isempty(EEG.filepath)
        path = pwd;
    else
        path = EEG.filepath;
    end
    if isempty(EEG.filename)
        file = '';
    else
        [~,file] = fileparts(EEG.filename);
    end
end
file = strrep( file, '_eeg', '_events.tsv' );

% Write to file
events_tsv_name = fullfile( path, file );
writetable(out_dt,events_tsv_name,'FileType','text','Delimiter','\t');

end % of function