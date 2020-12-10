% bids_artifacts_to_tsv - This function takes an EEG data structure as input,
%                      and writes inofrmation in EEG.reject to a
%                      *artifacts.tsv sidecar file.
%
% Usage:
%   >> bids_artifacts_to_tsv( EEG )
%   >> bids_artifacts_to_tsv( EEG, tsv_file ) 
%
% Required inputs:
%   EEG      - EEG data structure with EEG.reject field
%   
% 
% Optional inputs:
%   tsv_file      - file name of data file to write *artifacts.tsv. Defaults
%                   to reading EEG.filepath and EEG.filename. 
%
% Create by: Joshua D. Koen and Morgan Widhalm Munsen, University of Notre Dame
% Created on 2019/06/17

function bids_artifacts_to_tsv( EEG, tsv_file, vars_to_write )

% %% Just convert EEG.reject to cell table to start off with
% % This is useful for extracting data later on
% if length( EEG.reject ) > 1
%     in_dt = struct2table( EEG.reject );
% else % Handle a single trial or marker
%     reject_cell = struct2cell( EEG.reject );
%     reject_cell( cellfun(@isempty,reject_cell) ) = {'n/a'};
%     if ~isrow( reject_cell )
%         reject_cell = reject_cell';
%     end
%     artifact_fields = fieldnames( EEG.reject );
%     in_dt = cell2table( reject_cell, 'VariableNames', artifact_fields );
% end

%% Extract information of interest
rejmanual   = EEG.reject.rejmanual';
%rejmanualE = EEG.reject.rejmanualE;

%% create output dt (out_dt)
out_dt = table(rejmanual);

%% Add additional columns if need be
% if isvarname('vars_to_write') && ~isempty(vars_to_write)
%     
%     % Error check vars_to_write
%     if ~all( ismember(vars_to_write, in_dt.Properties.VariableNames) )
%         error('All VARS_TO_WRITE input values must exist as a field in EEG.event.');
%     end
%     
%     % Update out_dt
%     for vari = 1:length(vars_to_write)
%         this_field = vars_to_write{vari};
%         out_dt.( this_field ) = in_dt.( this_field );
%     end
% 
% end

%% If file name is supplied, use it to make _artifacts.tsv sidecar
if isvarname('filename') && ~isempty(tsv_file)
    [path, file, ext] = fileparts(tsv_file);
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
    file = strrep( file, '_eeg', '_artifacts.tsv' );
end

%% Write to file
artifacts_tsv_name = fullfile( path, file );
writetable(out_dt,artifacts_tsv_name,'FileType','text','Delimiter','\t');

end % of function