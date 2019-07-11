% mark_bad_channels -  This function marks bad channels for later rejection. This function requires
%                          EEGLAB as it uses the pop_rejchan() function. It
%                          takes as input the EEG and EEG_ica structures and several options variables. It goes
%                          through the automatic rejection algorithm and
%                          then pulls up a GUI for manual inspection of the
%                          marked electrodes. The manually updated marks
%                          are then saved for later rejection.
%
% Usage:
% >> [bad_channels] = markbadchannels(EEG, badchans_opts )
%
% Inputs:
%   EEG           - Input dataset
%   badchans_opts - Options for determining bad channels via the pop_rejchan function. 
%                   Must contain the following fields:
%                   1) 'elec' - [n1 n2 ...] electrode number(s) to take into 
%                   consideration for rejection
%                   2) 'thresh' - [max] absolute thresold or activity probability 
%                   limit(s) (in std. dev.)
%                   UPDATE ASW NEEDED
%
%
% Outputs:
%   bad_channels  - cell array of strings with bad channel labels
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


function [EEG_badchans, EEG_ica_badchans] = markbadchannels(INEEG1,INEEG2,badchans_opts,filter_opts,ica)

%% Handle inputs

for l = 1:2
    
    if l == 1
        filt_type = filter_opts.eeg_cutoff;
        EEG = INEEG1;
    elseif l == 2
        filt_type = filter_opts.ica_cutoff;
        EEG = INEEG2;
    end
    
    badchans.prob = [];
    badchans.spec = [];
    badchans.all = [];
    badchans.manual = [];
    indelec = [];
    
    % Run automated bad channel detection w/ probability and spectrum
    [~, badchans.prob] = pop_rejchan(EEG, 'elec',badchans_opts.elec,'threshold',badchans_opts.thresh,'norm','on','measure','prob');   
    [~, badchans.spec] = pop_rejchan(EEG, 'elec',badchans_opts.elec,'threshold',badchans_opts.thresh,'norm','on','measure','spec', 'freqrange', [filt_type]);
    
    % Determine all bad channels
    badchans.all = unique([badchans.prob(:) badchans.spec(:)]);
    indelec = zeros(63,1); %change this hardcoded option to all the electrodes in .chanloc that are type == 'EEG'
    for j = 1:length(badchans.all)
        indelec(badchans.all(j)) = 1;
    end
    
    % Manually inspect the automatically marked bad channels
    opt.elec = length(find(ismember({EEG.chanlocs.type}, {'EEG'}))); %change this hardcoded option to all the electrodes in .chanloc that are type == 'EEG'
    colors = cell(1,length(opt.elec)); colors(:) = { 'k' };
    colors(find(indelec)) = { 'r' }; colors = colors(end:-1:1);
    fprintf('%d electrodes labeled for rejection\n', length(find(indelec)));
    tmplocs = EEG.chanlocs(opt.elec);
    
    eegplot(EEG.data(opt.elec,:,:), 'srate', EEG.srate, 'title', 'Scroll component activities -- eegplot()', ...
        'limits', [EEG.xmin EEG.xmax]*1000, 'color', colors(end:-1:1), 'eloc_file', tmplocs);
    
    % HERE WE NEED TO UPDATE THE BADCHANS.MANUAL VARIABLE BASED ON KEYBOARD INPUT
    for k = 1:length(badchans.all)
        pause_script(k) = input(strcat('Do you want to reject channel ', num2str(badchans.all(k)), '? Press y for Yes and n for No: '), 's');
    end
    
    tot = 1;
    for k = 1:length(badchans.all)
        if strcmp(pause_script(k),'n')
            badchans.manual(tot) = badchans.all(k);
            tot = tot+1;
        end
    end
    
    % Record the bad channels that have been manually inspected for rejection in rejmanualE
    EEG_badchans = EEG;
    if l == 1  
        EEG_badchans.reject.rejmanualE = badchans.manual;
    elseif l == 2
        EEG_ica_badchans.reject.rejmanualE = badchans.manual;
    end
end
end

