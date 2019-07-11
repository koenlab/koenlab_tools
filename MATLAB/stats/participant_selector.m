% participant_selector() - Creates a list dialog selection box of participants
%                           in a given (BIDS) directory. Captures folders
%                           in the form sub*. 
%
% Usage:
%   >> selection = folder_listdlg(directory)
%
% Required inputs:
%   directory   - character array specifying a valid directory 
%
% Outputs:
%   selection   - cell array of strings with the selected items from the
%                 listdlg 
% See also:
%   DIR, LISTDLG
%
% Create by: Joshua D. Koen, University of Notre Dame

% LICENSE INFO

function selection = participant_selector( directory  )

% Check inputs
if ~ischar(directory) || ~isfolder(directory)
    error('directory inputs must be the ''char'' class and an existing folder.')
end

% List all files and folder meeting filter
dir_list = dir( fullfile(directory, 'sub-*') );

% Remove hidden directories and entries that are not a directory
dir_list( ismember({dir_list.name}, {'.' '..'}) ) = [];
dir_list( ~[dir_list.isdir] ) = [];

% Reduce to a cell array
dir_names = {dir_list.name};

% Create listdlg object to collect participants
[SELECTION,OK] = listdlg( ...
    'PromptString',     'Select participant(s) to process)', ...
    'SelectionMode',    'multiple', ...
    'ListString',       dir_names, ...
    'ListSize',         [200 500]);

% Return selection
if OK == 0
    selection = '';
else
    selection = dir_names(SELECTION);
end

end % of function


