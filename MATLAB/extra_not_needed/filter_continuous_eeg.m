% filter_continuous_eeg -  This function filters the continuous EEG data
%                          for the koenlab pipeline. This function requires
%                          ERPLAB as it uses the pop_basicfilter()
%                          function. It takes as input structures
%                          (configurations) for two filters: EEG and EOG
%                          Channel types. Note that a third filter settings
%                          is applied that uses the LPF from the EEG
%                          filter, and a hard-coded HPF of 1Hz. EOG
%                          filtering is done first, and then passed to
%                          other filters.
%
% Usage:
% >> [EEG, com] = filter_continuous_eeg(EEG, filter, highpass)
%
% Inputs:
%   EEG           - Input dataset
%   eeg_opts      - Filter options for EEG. Must contain the following
%                   fields:
%                   1) filter ('bandpass' or 'highpass' is preferred)
%                   2) design ('butter' is preferred)
%                   3) eeg_cutoff (for eeg, typically .1 - 100 Hz if bandpass,
%                      or .1 if HPF only)
%                   4) remove_dc (prefer 'on')
%                   5) order (prefer 4)
%                   6) boundary_id (typically -99)
%                   7) ica_cutoff (optional; typicaly same as eeg_cutoff but with 1Hz
%                      HPF)
%                   8) eog_cutoff (optional; filter applied to EOG type channels)
%
% Outputs:
%   EEG_filt      - Filtered EEG set 
%   EEG_filt_ica  - Filtered EEG set using ica_cutoff. If this option is
%                   not given, then this output will be empty. 
%
% Authors: Joshua D. Koen

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

function [EEG_filt, EEG_filt_ica] = filter_continuous_eeg(EEG, filt_opts)

%% Error Check
% Return help if needed
if nargin < 2 
    help filer_continuous_eeg
    return;
end

% Check for required fields
req_fields   = {'filter' 'design' 'eeg_cutoff' 'remove_dc' 'order' 'boundary_id'};
input_fields = fieldnames(filt_opts);
if ~all( ismember(req_fields, input_fields) )
    error('At least one required field is missing in filter options input.');
end

% Find EEG channels
eeg_chans = find( ismember({EEG.chanlocs.type}, {'EEG'}) );
if isempty(eeg_chans)
    error('Could not find channels in EEG that have the EEG type. Check inputs.')
end

%% Initialize outputs
EEG_filt = struct();
EEG_filt_ica = struct();

%% Run EOG Filter
if ismember('eog_cutoff', input_fields)
    
    % Find eog channels
    eog_chans = find( ismember({EEG.chanlocs.type}, {'VEOG', 'HEOG' 'EOG'}) );
    if isempty(eog_chans)
        
        warning('Could not detect channels with the VEOG, HEOG, or EOG type.')
        warning('Skipping filter applied to EOG channels.')
        
    else % apply filter
        
        fprintf('\n\nAPPLYING FILTER TO EOG CHANNELS...\n\n')
        EEG = pop_basicfilter( ...
            EEG, eog_chans, ...
            'Cutoff',   filt_opts.eog_cutoff, ...
            'Design',   filt_opts.design, ...
            'Filter',   filt_opts.filter, ...
            'Order',    filt_opts.order, ...
            'RemoveDC', filt_opts.remove_dc, ...
            'Boundary', filt_opts.boundary_id );
        EEG = eeg_checkset(EEG);
        
    end
    
end

%% RUN ICA Filter
if ismember('ica_cutoff', input_fields)
           
        fprintf('\n\nAPPLYING ICA FILTER SETTINGS...\n\n')
        EEG_filt_ica = pop_basicfilter( ...
            EEG, eeg_chans, ...
            'Cutoff',   filt_opts.ica_cutoff, ...
            'Design',   filt_opts.design, ...
            'Filter',   filt_opts.filter, ...
            'Order',    filt_opts.order, ...
            'RemoveDC', filt_opts.remove_dc, ...
            'Boundary', filt_opts.boundary_id );
        EEG_filt_ica = eeg_checkset(EEG_filt_ica);
        
end

%% Apply filter to EEG data
fprintf('\n\nAPPLYING EEG FILTER SETTINGS...\n\n')
EEG_filt = pop_basicfilter( ...
    EEG, eeg_chans, ...
    'Cutoff',   filt_opts.eeg_cutoff, ...
    'Design',   filt_opts.design, ...
    'Filter',   filt_opts.filter, ...
    'Order',    filt_opts.order, ...
    'RemoveDC', filt_opts.remove_dc, ...
    'Boundary', filt_opts.boundary_id );
EEG_filt = eeg_checkset(EEG_filt);
    
    
end % of function