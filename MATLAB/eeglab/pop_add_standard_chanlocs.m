%  pop_add_standard_chanlocs() -  This function adds the channel locations
%                                 from the standard BESA .loc file in the
%                                 dipfit plugin. The cartesian XYZ
%                                 coordinates are also centered once the
%                                 locations are imported. 
% Usage:
%   >>  pop_add_standard_chanlocs( EEG )
%
% Inputs:
%   EEG        - current dataset structure or structure array
%    
% Outputs:
%   EEG            - current dataset structure or structure array with
%                    standard channel locations added
%   com            - string for the function call
%
% See also:
%    POP_CHANEDIT, POP_CHANCENTER

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

function [EEG, com] = pop_add_standard_chanlocs( EEG )

% Define channel location file
chan_loc_file = fullfile( fileparts(which('eegplugin_dipfit')),'standard_BESA', 'standard-10-5-cap385.elp');
if ~isfile(chan_loc_file)
    warning('The dipfit BESA standard-10-5-cap385.elp file does not exist. Is the dipfit plugin installed?')
    return;
end

% Make the call to the function
evalcmd = 'chans = pop_chancenter( chans, [],[]);';
EEG = pop_chanedit(EEG, 'lookup', chan_loc_file, 'eval', evalcmd);

% Update com
com = sprintf('EEG = pop_chanedit( EEG, ''lookup'', ''%s'', ''eval'', ''%s'')', chan_loc_file, evalcmd);
EEG = eeg_hist(EEG, com);

end % of function

