%% ADD CHANNEL INFO %%
% This script adds channel info to the EEG set. This function requires
% EEGLAB as it needs to load in and write out the data.

% Usage:
% >> EEG = add_channel_info(EEG, participant)
%
% Inputs:
%   EEG           - Input dataset
%   ref           - The reference channel, as a string (i.e. "FCz")
%
% Outputs:
%   EEG           - EEG set with updated chanlocs
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

function EEG = add_channel_info(EEG, ref)

    % Update EEG.chanlocs and EEG.ref
    for c = 1:length(EEG.chanlocs)
        if strcmpi(EEG.chanlocs(c).labels, 'VEOG')
            EEG.chanlocs(c).ref = 'n/a';
            EEG.chanlocs(c).type = 'VEOG';
            EEG.chanlocs(c).unit = 'µV';
        elseif strcmpi(EEG.chanlocs(c).labels, 'HEOG')
            EEG.chanlocs(c).ref = 'n/a';
            EEG.chanlocs(c).type = 'HEOG';            
            EEG.chanlocs(c).unit = 'µV';
        elseif strcmpi(EEG.chanlocs(c).labels, 'Photosensor')
            EEG.chanlocs(c).ref = 'n/a';
            EEG.chanlocs(c).type = 'MISC';
            EEG.chanlocs(c).unit = 'mV';
        else
            EEG.chanlocs(c).ref = ref;
            EEG.chanlocs(c).type = 'EEG';
            EEG.chanlocs(c).unit = 'µV';
        end
    end
    
end

