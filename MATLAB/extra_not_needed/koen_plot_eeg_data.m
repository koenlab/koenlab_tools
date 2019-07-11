function koen_plot_eeg_data( EEG, chan_inds, varargin )

%% Default settings
bad_chans

for k = 1:2:length(varargin)
    this_setting = varargin{k};
    switch this_setting
        case 'bad_chans'
        case 'disp_opts'
    end
end

%% Show the plot
eegplot( ...
    EEG.data(opt.elec,:,:), ...
    'srate', EEG.srate, ...
    'title', 'Scroll component activities -- eegplot()', ...
    'limits', [EEG.xmin EEG.xmax]*1000, ...
    'color', chan_cols, ...
    'eloc_file', tmplocs, ...
    ');


%% Get the current artifact flags (if any), and make the format for eegplo()
% ------------------------------------
artEpochs = find(EEG.reject.rejmanual);
if ~isempty(artEpochs) % Make winrej structure
    winrej = trial2eegplot(EEG.reject.rejmanual,EEG.reject.rejmanualE(elecRange,:,:),EEG.pnts,[ 0.7 1 0.9]);
else
    winrej = [];
end

%% Plot the EEG data with eegplot()
% ------------------------------------
cmd = [ 'artEpochs = find(EEG.reject.rejmanual);' ...
    'EEG.reject.rejmanual = eegplot2trial( TMPREJ, EEG.pnts, EEG.trials);' ...
    ['EEG = update_erplab_flags(EEG,artEpochs,' num2str(artFlag) ');'] ];