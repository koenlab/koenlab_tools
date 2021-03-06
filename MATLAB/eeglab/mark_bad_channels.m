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
%                   2) 'badchans'   - vector of any bad channels indicies
%                                     from other approaches.
%                   3) 'plot_plot_freq_spect' - option to plot or not
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

% Handle fig_dir
if ~isfield(opts,'fig_dir')
    opts.fig_dir = '';
end

% handle plot_freq_spect
if ~isfield(opts, 'plot_freq_spect')
    opts.plot_freq_spect = 1:50;
end

% handle plot_EEG_scroll
if ~isfield(opts, 'plot_EEG_scroll')
    opts.plot_EEG_scroll = 'no';
end

%% Select channels for analysis (and the field in opts)
% Determine which channels to process
if ismember( 'chan_inds', input_fields ) % Determine by input indicies
    chan_field = 'chan_inds';
    chan_inds = opts.(chan_field);
elseif ismember( 'chan_type', input_fields ) % Determine by type
    chan_field = 'chan_type';
    chan_inds = find( ismember( {EEG.chanlocs.type}, opts.(chan_field) ) );
else
    error('chan_inds or chan_type have not been provided as input. This is required.');
end

% initialize badchans structure
badchans = struct();

% Copy from opts.badchans
badchans.given = opts.badchans;

%Find the bad channels
chan_inds = find( ismember( {EEG.chanlocs.type}, 'EEG' ) );
badchans.bad_inds = unique( [badchans.given] );
badchans.bad_labels = {EEG.chanlocs(badchans.bad_inds).labels};
fprintf('\t%d channels marked manually prior to this function\n', length(badchans.given));
pause( 3 ); % Pause for 3 seconds
    
%% Proceed with initialization and plot frequency spectrum, only if input is 'yes'
if strcmp(opts.plot_freq_spect, 'yes')
    
    % Plot the data
    % Plot channel properties
    spec_f = figure('Units','Normalized');
    spec_f.Position(1:2) = [.5 .5];
    EEG_spect = pop_select(EEG, 'channel',chan_inds);
    pop_spectopo(EEG_spect, 1, [EEG.xmin EEG.xmax]*EEG.srate, 'EEG' , ...
        'percent', 25, ...
        'freq', [3 10 15 25 40 55 80], ...
        'freqrange', [.1 100], ...
        'electrodes','off');
    
    % Save figure
    if ~isempty(opts.fig_dir)
        saveas(spec_f,fullfile(opts.fig_dir,'mark_bad_chans_plot_freq_spectrum.png'));
    end
    
    % Wait for user to close plot before continuing
    plot_f = gcf;
    waitfor( plot_f);
    
end %end of if loop to plot frequency spectrum

%% Plot channel scroll, only if input is 'yes'

if strcmp(opts.plot_EEG_scroll, 'yes')
    
    % Determine channel color (bad in red; good is black)
    colors = cell(1,length(chan_inds)); colors(:) = { 'k' };
    colors(EEG.etc.bad_channels.bad_inds) = { 'r' };
    
    % Show the plot
    eegplot(EEG.data(chan_inds,:,:), 'srate', EEG.srate, 'title', sprintf('%s: Look through data - Bad Channels Marked in Red', num2str(EEG.subject)), ...
        'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors, 'eloc_file', EEG.chanlocs(chan_inds), ...
        'events',EEG.event, 'command', []);
    
    % Wait for user to close plot before continuing
    plot_f = gcf;
    waitfor( plot_f);
    
end %end of if loop to plot EEG scroll to manually inspect channels

try close(spec_f); end

%% Ask if any channels you want to manually label as bad
man_rej = questdlg('Do you want (or need) to manually reject any channels?');
if strcmpi(man_rej,'yes')
    
    %Loop through the channel indices and make a cell array where the
    %format is 'channel # - channel name' to be input into listdlg
    for chani = 1:length(chan_inds)
        liststring{chani,:} = sprintf('%d-%s', chan_inds(chani), EEG.chanlocs(chan_inds(chani)).labels);
    end
    
    badchans.manual = listdlg( ...
        'ListString', liststring, ...
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

