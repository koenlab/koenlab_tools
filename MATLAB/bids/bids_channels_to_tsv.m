% bids_channels_to_tsv() - This function takes the information in
%                          EEG.chanlocs and converts it to a *channels.tsv
%                          sidecar. It defaults all channels to good status. 
% Usage:
%   >> bids_channels_to_tsv( EEG )
%   >> bids_channels_to_tsv( EEG, tsv_file )
% 
% Required inputs:
%   EEG        - EEG data structure with EEG.chanlocs field
%
% Optional inputs:
%   tsv_file   - file name of data file to write *channels.tsv. Defaults to
%                reading EEG.filepath and EEG.filename.
%
% Created by: Joshua D. Koen, University of Notre Dame
% Created on: 2019/06/17

function bids_channels_to_tsv( EEG, filename )

% Convert EEG.chanlocs to a datatable
chanlocs = EEG.chanlocs;
fields_present = fieldnames(chanlocs);
fields_to_keep = {'labels' 'type' 'unit' 'ref'}; 
chanlocs_trimmed = rmfield( chanlocs, fields_present( ~ismember(fields_present, fields_to_keep) ) );
dt = struct2table( chanlocs_trimmed );

% Update variable names
new_vars = {'name' 'type' 'reference' 'units'};
dt.Properties.VariableNames = new_vars;
dt = movevars(dt,'units','Before','reference');

% Add sampling frequency
data_add_size = [size(dt,1), 1];
dt.sampling_frequency = repmat( EEG.srate, data_add_size);
%dt.status = repmat( {'good'}, data_add_size ); 

% If file name is supplied, use it to make _events.tsv sidecar
if isvarname('filename') && ~isempty(filename)
    [path, file, ext] = fileparts(filename);
    file = [file ext];
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
    file = strrep( file, '_eeg', '_channels.tsv' );
end

% Write to file
chans_tsv_name = fullfile( path, file );
writetable(dt, chans_tsv_name,'FileType','text','Delimiter','\t');

end