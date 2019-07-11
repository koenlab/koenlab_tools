% bids_participants_tsv - This function takes  adata table input and 
%                         creates the participants.tsv file or appends the
%                         table to an existing participants.tsv file. 
%
% Usage:
%   >> bids_participants_tsv( dt, tsv_file)
%
% Required inputs:
%   dt       - data table object containing information about a
%              participant.
%   tsv_file - tab-separated (tsv) file to write dt to. If this file
%              exists, it is loaded and then the DT input is appended to
%              the table.   
%
% Create by: Joshua D. Koen, University of Notre Dame
% Created on 2019/06/17

function bids_participants_tsv( dt, tsv_file )

% Error check
if ~istable(dt), error('first input must be a data table object.'); end
if height(dt) ~= 1, error('dt must only have one row of data.'); end
if ~strcmpi(tsv_file(end-3:end), '.tsv'), error('tsv_file must have tab-separated extension (.tsv)'); end

% If file name exists, load it
if isfile(tsv_file)
    
    % Load file if necessary
    opts   = detectImportOptions(tsv_file, 'FileType', 'text');
    par_dt = readtable(tsv_file, opts);
    
    % Error check
    if ~isequal(par_dt.Properties.VariableNames, dt.Properties.VariableNames)
        error('fields for input data table and existing data table in tsv_file do not match.')
    end
    
    % Convert par_dt to cell array, then back (after appending)
    % This is a 'trick' to avoid some columns being interpreted as character
    % matrices.
    columns  = par_dt.Properties.VariableNames;
    par_cell = table2cell(par_dt);
    input_cell = table2cell(dt);
    par_col = strcmpi(columns,'participant_id');
    if ~ismember(par_cell(:,par_col), input_cell(:,par_col))
        par_cell = vertcat(par_cell,input_cell);
    end
    par_dt   = cell2table(par_cell, 'VariableNames', columns);

else % Otherwise, load dt as cell
    
    par_dt   = dt;
    par_cell = table2cell(par_dt);
    
end

% Write to file
writetable(par_dt,tsv_file,'FileType','text','Delimiter','\t');

end % of function