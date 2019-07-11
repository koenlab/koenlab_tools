% participant_info_gui() - This function brings up an input dialog box to
%                          enter participant information that can be stored
%                          in a *_participants.tsv file for the BIDS
%                          formatting. 
%
% Usage:
%   >> info = participant_info_gui( id, fields)
%
% Required inputs:
%   id      - participant identifier (will be prepended with sub* if it is
%             not present.
%   fields  - cell array of strings for the particular fields to enter.
%             Prepends the field 'participant_id' to the fields list. 
%
% Outputs:
%   info    - data table object containing the participant information
%
% Created by: Joshua D. Koen, University of Notre Dame
% Created on: 2019/06/17

function info = participant_info_gui( id, fields )

% Define the input GUI parameters
prompt = ['participant_id' fields];
struct_fields = cellfun(@(x) strrep(x,' ','_'), prompt, 'UniformOutput', false);
dlg_title = 'Enter Participant Info:';
dimensions = [1 50];
def = [ id repmat({''}, size(fields)) ];

% Define gui options
options.Resize='on';
options.WindowStyle='normal';

% Display gui
info = inputdlg(prompt, dlg_title, dimensions, def, options);

% Covert output structure to data table
info = struct2table( cell2struct(info, struct_fields,1 ) );

end % of function