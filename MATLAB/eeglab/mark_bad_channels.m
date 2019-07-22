% mark_bad_channels -  This function marks bad channels for later rejection. This function requires
%                          EEGLAB as it uses the pop_rejchan() function. It
%                          takes as input the EEG and EEG_ica structures and several options variables. It goes
%                          through the automatic rejection algorithm and
%                          then pulls up a GUI for manual inspection of the
%                          marked electrodes. The manually updated marks
%                          are then saved for later rejection.
%
% Usage:
% >> EEG = markbadchannels(EEG, badchans_opts )
%
% Inputs:
%   EEG           - Input dataset
%   badchans_opts - Options for determining bad channels via the pop_rejchan function. 
%                   Must contain the following fields:
%                   1) 'elec' - [n1 n2 ...] electrode number(s) to take into 
%                   consideration for rejection
%                   2) 'thresh' - [max] absolute threshold or activity probability 
%                   limit(s) (in std. dev.)
%                   3) 'freq_range' - range of frequencies in the spectral
%                   decomposision.
%                   4) 'badchans'   - vector of any bad channels indicies
%                                     from other approaches.
%
% Outputs:
%   EEG           - EEG set with new field (EEG.bad_channels). Contains
%                   indicies (inds) and names (names)
%
% Authors: Morgan L. Widhalm

% Copyright (C) 2019
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


function EEG = mark_bad_channels(EEG, opts)

%% Handle inputs
% Input fields
input_fields = fieldnames(opts);

% Make sure required fields are present
req_fields = {'thresh' 'freq_range'};
if ~all( ismember( req_fields, input_fields ) )
    error('options requires thresh and freq_range.')
end

% Make sure to have either chan_type or chan_inds
chan_fields = {'chan_type' 'chan_inds'};
if ~any( ismember( chan_fields, input_fields) )
    error('options requires one of the following: chan_type or chan_inds')
elseif all( ismember( chan_fields, input_fields) )
    warning('Both chan_type and chan_inds are present. Defaulting to chan_inds.')
end

% Check if bad chans is a field. If not, set it to empty
if ~isfield(opts, 'badchans')
    opts.badchans = [];
end

%% Select channels for analysis (and the field in opts)
% Determine which channels to process
if ismember( input_fields, 'chan_inds' ) % Determine by input indicies
    chan_field = 'chan_inds';
    chan_inds = opts.(chan_field);
else % Determine by type
    chan_field = 'chan_type';
    chan_inds = find( ismember( {EEG.chanlocs.type}, opts.(chan_field) ) );
end

%% Mark bad channels using pop_rejchan
% initialize badchans structure
badchans = struct();

% Copy from opts.badchans
badchans.given = opts.badchans;

% Run automated bad channel detection w/ probability and spectrum
[~, badchans.prob] = pop_rejchan(EEG, ...
    'elec', chan_inds, ...
    'threshold',opts.thresh, ...
    'norm','on', ...
    'measure','prob');
[~, badchans.spec] = pop_rejchan(EEG, ...
    'elec',chan_inds, ...
    'threshold',opts.thresh, ...
    'norm','on', ...
    'measure','spec', ...
    'freqrange', opts.freq_range);

%Find the bad channels
chan_inds = find( ismember( {EEG.chanlocs.type}, 'EEG' ) );
badchans.bad_inds = unique( struct2array( badchans ) );
badchans.bad_labels = {EEG.chanlocs(badchans.bad_inds).labels};
fprintf('\n\n%d channel(s) marked as bad from automated detection:\n', length(badchans.bad_inds) );
fprintf('\t%d channels marked manually prior to this function\n', length(badchans.given));
fprintf('\t%d channels marked as improbable (%d threshold)\n', length(badchans.prob), opts.thresh);
fprintf('\t%d channels marked based on bad spectrum (%d threshold)\n\n', length(badchans.spec), opts.thresh);
pause( 5 ); % Pause for 5 seconds
    
%% Plot the bad channels
% Determine channel color (bad in red; good is black)
colors = cell(1,length(chan_inds)); colors(:) = { 'k' };
colors(badchans.bad_inds) = { 'r' };

% Plot channel properties
spec_f = figure;
EEG_spect = pop_select(EEG, 'channel',chan_inds);
pop_spectopo(EEG_spect, 1, [EEG.xmin EEG.xmax]*EEG.srate, 'EEG' , ...
    'percent', 15, ...
    'freq', [3 10 15 25 40 55 80], ...
    'freqrange', opts.freq_range, ...
    'electrodes','off');

% Show the plot
eegplot(EEG.data(chan_inds,:,:), 'srate', EEG.srate, 'title', sprintf('%s: Look through data - Bad Channels Marked in Red', num2str(EEG.subject)), ...
    'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors, 'eloc_file', EEG.chanlocs(chan_inds), ...
    'events',EEG.event, 'command', []);
plot_f = gcf;
waitfor( plot_f);
try close(spec_f); end

%% Ask if any channels you want to manually label as bad
man_rej = questdlg('Do you want (or need) to manually reject any channels?');
if strcmpi(man_rej,'yes')
    
    badchans.manual = listdlg( ...
        'ListString', {EEG.chanlocs(chan_inds).labels}, ...
        'SelectionMode', 'multiple', ...
        'Name', sprintf('%s: Manual Channel Rejection', num2str(EEG.subject)), ...
        'PromptString', 'Select Channels for Manual Rejection (press cancel if none)', ...
        'ListSize', [300 600] );
    
else
    
    badchans.manual = [];
    
end

% Update badchans
badchans.bad_inds   =  unique(horzcat(badchans.bad_inds, badchans.manual));
badchans.bad_labels = {EEG.chanlocs(badchans.bad_inds).labels};

%% Ask if there are any channels you want to remove that are marked as bad
if ~isempty(badchans.bad_inds)

    clear_bads = questdlg('Do you want to unmark a channel labeled as bad (i.e., mark it as good)?');
    if strcmpi(clear_bads,'yes')
        bad_marked_good = listdlg( ...
            'ListString', badchans.bad_labels, ...
            'SelectionMode', 'multiple', ...
            'Name', sprintf('%s: Channels marked as bad', num2str(EEG.subject)), ...
            'PromptString', 'Select Bad Channels to set Status to Good (press cancel if all should be bad)', ...
            'ListSize', [600 300] );
    else
        bad_marked_good = [];
    end
    
    % Update
    badchans.bad_inds(bad_marked_good) = [];
    badchans.bad_marked_good = badchans.bad_labels(bad_marked_good);
    badchans.bad_labels = {EEG.chanlocs(badchans.bad_inds).labels};
    
end
    
%% Output info
if ~isempty(badchans.bad_inds)
    
    fprintf('These channels are marked as bad: \n')
    fprintf('\t%s\n',badchans.bad_labels{:});
    
else
    
    fprintf('No channels were marked as bad!!!\n');
    
end

%% Return EEG
EEG.etc.bad_channels = badchans;
com = sprintf('EEG = mark_bad_channels(EEG, cfg);');
EEG = eeg_hist(EEG,com);

end

