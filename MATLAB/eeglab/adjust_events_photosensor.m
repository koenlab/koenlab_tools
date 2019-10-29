% adjust_events_photosensor() -  Adjust event latencies given a (raw) photosensor channel. The algorithm first
%                                finds the maximum photosensor value, and takes a percentage of this as the
%                                threshold value for an event (e.g., if the threshold input is 80%, and the max value
%                                is 200, the threshold value is 160). In each segment around a marker, the
%                                alogirthm finds the first sample that exceeds the treshold value as the onset. If the 'delay' between the marker
%                                (original) and photosensor onsets is negative (original - photosensor) or it is
%                                below 1/2 of the frame rate (in milliseconds), then no correction is done.
%                                
% Usage:
% >> EEG = adjust_events_photosensor(EEG, events, channel, threshold, time_win, frame_rate, fig_dir, draw_trials ); 
%
% Inputs:
%   EEG           - Input dataset
%   events        - Cell array or string of event types to match to
%                   EEG.event.type. (defaults to all non-boundary events)
%   channel       - Channel number (numeric) or label (string/character)
%                   containing the photosensor data. (defaults to last
%                   channel in EEG.chanlocs)
%   threshold     - Proportion of the min-max difference as the cutoff for
%                   detecting an event. (default is .8)
%   time_win      - time window (in seconds) to extract signal from
%                   photosensor for processing. (defaults to [-.05 .05], or 50 ms before and after )
%   frame_rate    - frame rate of the monitor the photosensor is attached
%                   to. No onset correction for 'delays' less than 1/2 of a frame. 
%                   (defaults to 100Hz, or 5ms)
%   fig_dir       - directory to write a figure with a table summarizing
%                   the settings and adjustments. 
%   draw_trials   - draws a figure for each marker segment showing the
%                   correction. User must close each figure. (default false)
%
% Outputs:
%   EEG           - Input dataset with latencies shifted
%
% Authors: Joshua D. Koen

% Copyright (C) 2019  Joshua D. Koen
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

function [EEG, com] = adjust_events_photosensor( EEG, events, channel, threshold, time_win, frame_rate, fig_dir, draw_trials )

% Return help if needed
if nargin <1 
    help adjust_events_photosensor;
    return;
end

% Deal with empty or non-existent events
if ~exist('events','var') || isempty(events)
    events = {EEG.event.type};
    events( ismember(events,{'boundary'}) ) = [];
    events = unique(events);
end

% Deal with empty or non-existent channel
if ~exist('channel','var') || isempty(channel)
    if ~isfield(EEG,'chanlocs')
        error('chanlocs must be present to assume a default');
    else
        channel = EEG.chanlocs(end).labels; 
    end
end

% Deal with empty or non-existent threshold
if ~exist('threshold','var') || isempty(threshold)
    threshold = .85;
end

% Deal with empty or non-existent time_win
if ~exist('time_win','var') || isempty(time_win)
    time_win = [-0.05 0.05];
end

% Deal with empty or non-existent frame_rate
if ~exist('frame_rate','var') || isempty(frame_rate)
    frame_rate = 100; % Assume a 100Hz monitor
end

% Modify time window and convert to samples
time_win = time_win * EEG.srate;
samples_before = time_win(1);
if samples_before > 0, samples_before = samples_before * -1; end % Convert to negative
samples_after = time_win(2);

% Modify channel to convert to numeric
if ischar(channel)
    channel_name = channel;
    channel = find( ismember( {EEG.chanlocs.labels}, channel ) );
elseif isnumeric(channel)
    channel_name = EEG.chanlocs(channel).labels;
elseif ~isnumeric(channel)
    error('channel input is of wrong class (it is %s).', class(channel))
end

% Determine markers to adjust
try
    events_to_adjust = ismember({EEG.event.type}, events);
catch
    events_to_adjust = ismember([EEG.event.type], events);
end

% Handle fig_dir
if ~exist('fig_dir','var') || isempty(fig_dir)
    fig_dir = '';
end

% Handle draw_trials
if ~exist('draw_trials','var') || isempty(draw_trials)
    draw_trials = false;
end

% Get the threshold value. this is threshold % of the maximum value
threshold_value = round(max(EEG.data(channel,:,EEG.trials)) * threshold);    

% Go in and do the adjustment
delays = [];
for i = 1:length(events_to_adjust)
    
    
    if ~events_to_adjust(i) % skip if needed
        
        % Add stock information
        EEG.event(i).orig_latency = EEG.event(i).latency;
        EEG.event(i).photosensor_shift = false;
        EEG.event(i).latency_delay = 0;
        continue;
        
    else % Otherwise adjust marker
        
        % Get info on this event
        orig_latency = EEG.event(i).latency;
        EEG.event(i).orig_latency = orig_latency;
            
        % Latencies to grab (0 is samples before max value) 1 is added to
        % max 0 timepoitn of marker to samples_before value (in the
        % data_segment below)
        latencies = orig_latency + (samples_before+1:samples_after);
        
        % Extract the data segment        
        data_segment = EEG.data(channel, latencies);
        
        % Determine sample in data set where onset happened
        onset_sample = find(data_segment >= threshold_value, 1, 'first');
        
        % Determine corrected latency
        psensor_latency = latencies(onset_sample);
        delay = psensor_latency - orig_latency;
                
        % Draw figure
        if draw_trials
            f = figure;
            plot(latencies,data_segment);
            hold on;
            line(repmat(EEG.event(i).latency,2,1),get(gca,'YLim'),'Color','r');
            line(repmat(psensor_latency,2,1),get(gca,'YLim'),'Color','g');
            title(sprintf('Onset delay = %d samples (%1.3f ms)', ...
                (onset_sample - (samples_before*-1)), ...
                delay / EEG.srate) );
            hold off;
            waitfor(f);
        end
        
        % Update the event
        if delay < 0 || delay < frame_rate / 2
            EEG.event(i).latency = orig_latency;
            delay = 0;
            EEG.event(i).latency_delay = delay;
            EEG.event(i).photosensor_shift = false;
        else
            EEG.event(i).latency = new_latency;
            EEG.event(i).latency_delay = new_latency - orig_latency;
            EEG.event(i).photosensor_shift = false;
        end
        delays = [delays EEG.event(i).latency_delay];
        
    end
    
end

% Remove channel
EEG = pop_select( EEG, 'nochannel', channel );

% Print summary info
fprintf('\r\rSummary of Photosensor adjustments:\r')
fprintf('\tMean adjustment:\t\t%2.2f ms\n', (mean(delays) / EEG.srate) * 1000);
fprintf('\tMedian adjustment:\t\t%2.2f ms\n', (median(delays) / EEG.srate) * 1000);
fprintf('\tSmallest adjustment:\t%2.2f ms\n', (min(delays) / EEG.srate) * 1000);
fprintf('\tLargest adjustment:\t\t%2.2f ms\n', (max(delays) / EEG.srate) * 1000);
fprintf('\n')

% Make a table, and save as an image
if ~isempty(fig_dir)
    
    % Info to screen
    fprintf('Writing summary figure to file...');
    
    % Setup the figure
    f = figure('visible','off','Units','Normalized','Color','white');
        
    % Settings table data
    table = {
        sprintf('''%s'' ',events{:}); ...
        sprintf('%s (%d)', channel_name, channel); ...
        num2str(threshold); ...
        sprintf('[%s]',num2str(time_win)); ...
        };
    rownames = {'Event Types' 'Channel' 'Threshold' 'Time Window (ms)'};
    uitable('Parent',f,'Data',table,'Rowname',rownames,'Units','Normalized', ...
        'Position',[.1 .6 .8 .3],'ColumnName','Value','ColumnWidth',{max(cellfun(@length,table))*5});
    uicontrol('Parent',f,'Style','text','String','Photosensor Adjust Settings', ...
        'Units','Normalized','Position',[.3 .90 .4 .05], 'BackgroundColor','white', ...
        'FontWeight','bold');
    
    t2_pos = [.5 .25 .4 .5];
        
    % Data table
    table = { ...
        (mean(delays) / EEG.srate) * 1000; ...
        (median(delays) / EEG.srate) * 1000; ...
        (min(delays) / EEG.srate) * 1000; ...
        (max(delays) / EEG.srate) * 1000; ...
        };
    table = cellfun(@num2str,table,'UniformOutput',false);
    rownames = {'Mean' 'Median' 'Smallest' 'Largest'};
    uitable('Parent',f,'Data',table,'Rowname',rownames,'Units','Normalized', ...
        'Position',[.1 .1 .4 .3],'ColumnName','Value','ColumnWidth',{max(cellfun(@length,table))*8});
    uicontrol('Parent',f,'Style','text','String','Adjustment Results', ...
        'Units','Normalized','Position',[.15 .41 .3 .05], 'BackgroundColor','white', ...
        'FontWeight','bold');
    
    % Make a histogram
    subplot(2,2,4);
    hist((delays / EEG.srate) * 1000);
    title('Histogram of Delay Adjustments');
    
    % Save figure
    saveas(f,fullfile(fig_dir,'photosensor_adjust_summary.png'));
    close(f);
    fprintf('DONE\n\n');
    
end
    
% Update EEG.history
if isnumeric(events)
    com = sprintf('EEG = adjust_events_photosensor( EEG, {%s }', num2str(events));
else
    com = sprintf('EEG = adjust_events_photosensor( EEG, {%s }', sprintf('''%s'' ',events{:}));
end
com = sprintf('%s,  %d, %d, [%s] );', com, channel, threshold, num2str(time_win) );
EEG = eeg_hist(EEG, com);

end % of function