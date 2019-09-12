% pop_manual_mark_artifacts() -  This function plots the data with the currently
%                      marked artifacts (in EEG.reject.rejmanual), and
%                      allows the user to manually mark artifacts. The
%                      script pauses the program until the window is closed
%                      and artifacts are marked. 
% Usage:
%   >>  [EEG, marked_epochs, com] = pop_manual_mark_artifacts( EEG, chans ) 
%
% Inputs:
%   EEG        - current dataset structure or structure array
%   chans   - electrodes/channels to test for linear drift. Must be a
%                 numeric vector or cell array of strings with labels
%   artFlag     - (optional) the artifact flag to assign epochs with linear
%                 drift (requires ERPLAB)
%    
% Outputs:
%   EEG            - current dataset structure or structure array
%   marked_epochs  - epoch indices marked for removal (includes those 
%                    marked prior to function call). 
%   com            - string for the function call
%
% See also:
%    POP_EEGPLOT, EEGPLOT

% Copyright (C) 2015  Joshua D. Koen
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [EEG, com] = pop_manual_mark_artifacts( EEG, chan_inds ) 

%% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_manual_artifact_flag;
	return;
end

%% pop up window
% -------------
if nargin < 2
    
    % Set up the options and default values
    commandchans = [ 'tmpchans = get(gcbf, ''userdata'');' ... % Get figure hangle containing an object with a currently executing callback
        'tmpchans = tmpchans{1};' ... % Get the first cell from the input returned by the above)
        'set(findobj(gcbf, ''tag'', ''chantype''), ''string'', int2str(pop_chansel( tmpchans )));' ... % Find indices of selcted channels, and return as a string
        'clear tmpchans;' ];
    
    % Define the prompts
    promptstr    = { ...
        { 'style' 'text' 'string' 'Channels to show (default=''all'')' }, ...
        { 'style' 'edit' 'string' 'all' 'tag' 'chantype' }, ...
        { 'style' 'pushbutton' 'string' 'Channel List' 'callback' commandchans }, ...
        };
    
    % Define geomery
    geometry = { [2 2 2] };
    
    % channel labels
    % --------------
    if ~isempty(EEG.chanlocs)
        tmpchanlocs = EEG(1).chanlocs;
        alllabels = { tmpchanlocs.labels };
    else
        for index = 1:EEG(1).nbchan
            alllabels{index} = int2str(index);
        end
    end
    
    % Make GUI
    result = inputgui('geometry',geometry,'uilist',promptstr, ...
        'helpcom', 'pophelp(''pop_manual_mark_artifacts'')', ...
        'title', 'Manual Artifact Detection == manual_mark_artifacts()', ...
        'userdata', { alllabels } );
    
    % Sort the results into the appropriate variables, and check input for
    % errors
    % Electrodes
    if isempty(result)
        error('No channels were selected.')
    else
        chan_inds = str2num(result{1});
        if isempty(chan_inds)
            if strcmpi(result{1},'all')
                chan_inds = 1:EEG.nbchan;
            end
        end
    end
    
else % When chan inds are provided, run some checks
    
   % If numeric indicies are supplied for channels, make sure they are in
   % range
   if isnumeric(chans)
       chans_inds = chans;
       if any( ~ismember(chans_inds, 1:EEG.nbchan ) )
           error('A specified channel index is out of range.')
       end
   end
   
   % If a cell array of string, convert to chans
   if iscellstr(chans)
       chans_inds = find( ismember(chans, {EEG.chanlocs.labels}) );
       if any( ~ismember(chans, {EEG.chanlocs.labels}) )
           warning('At least one channel label was not found. Omitting the channel(s) from plotting.')
       end
   end
    
end
    
% Specify window color
win_color = ([255,182,193] / 255);

%% Initialize EEG.reject.rejmanual if it is empty. This is to avoid errors
% ------------------------------------
% INITIALIZE EEG>REJECT>REJMANUAL FOR INSTANCES WHEN IT IS EMPTY (SET TO
% zeros(1,size(EEG.data,3)); Same for EEG.reject.rejmanualE
if isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = zeros(1,EEG.trials);
    EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);
elseif length(EEG.reject.rejmanual) ~= EEG.trials || size(EEG.reject.rejmanualE,2) ~= EEG.trials
    warning('Mismatch between EEG.trials and length of EEG.reject.rejmanual. Clearing EEG.reject.rejmanual.')
    EEG.reject.rejmanual = zeros(1,EEG.trials);
    EEG.reject.rejmanualE = zeros(EEG.nbchan,EEG.trials);
end

% Get the marked epochs
marked_epochs = find(EEG.reject.rejmanual); %#ok<EFIND>
if ~isempty(marked_epochs) % Make winrej structure
    winrej = trial2eegplot( EEG.reject.rejmanual, EEG.reject.rejmanualE(chan_inds,:,:), EEG.pnts, win_color );
else
    winrej = [];
end

%% Plot the EEG data with eegplot()
% ------------------------------------
cmd = [ 'marked_epochs = find(EEG.reject.rejmanual);' ...
    'EEG.reject.rejmanual = eegplot2trial( TMPREJ, EEG.pnts, EEG.trials);'  ];
butlabel = 'MARK EPOCHS';
if ~isempty(EEG.chanlocs)
    eegplot(EEG.data(chan_inds,:,:), 'eloc_file',EEG.chanlocs(chan_inds), 'srate',EEG.srate, ...
        'command',cmd, 'butlabel',butlabel, 'wincolor',win_color, ...
        'winrej',winrej, 'events',EEG.event);
else
    eegplot(EEG.data(chan_inds,:,:), 'srate',EEG.srate, ...
        'command',cmd, 'butlabel',butlabel, 'wincolor',win_color, ...
        'winrej',winrej, 'events',EEG.event);
end
waitfor( findobj('parent', gcf, 'string', butlabel), 'userdata');

%% return the string command for detect drift
% -------------------------
if nargin == 2
    com = sprintf('%s = pop_manual_mark_artifacts(%s,%s);', inputname(1),inputname(2));
else
    com = sprintf('%s = pop_manual_mark_artifacts(%s,%s);', inputname(1), num2str(chan_inds));
end
EEG = eeg_hist(EEG, com);

end
