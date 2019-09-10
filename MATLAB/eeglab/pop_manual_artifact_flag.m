% pop_manual_artifact_flag() -  This function plots the data with the currently
%                      marked artifacts, and allows the user to manually
%                      mark artifacts. Before plotting, a prompt asks for a
%                      artifact flag to mark the ERPLAB EVENTLIST.
% Usage:
%   >>  [EEG, com] = pop_manual_artifact_flag( EEG, elecRange, artFlag ) 
%
% Inputs:
%   EEG        - current dataset structure or structure array
%   elecRange   - electrodes/channels to test for linear drift
%   artFlag     - (optional) the artifact flag to assign epochs with linear
%                 drift (requires ERPLAB)
%    
% Outputs:
%   EEG        - current dataset structure or structure array
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

function [EEG, com] = pop_manual_artifact_flag( EEG, elecRange, artFlag ) 

% the command output is a hidden output that does not have to
% be described in the header

com = ''; % this initialization ensure that the function will return something
          % if the user press the cancel button            

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
    commandchans = [ 'tmpchans = get(gcbf, ''userdata'');' ...
                     'tmpchans = tmpchans{1};' ...
                     'set(findobj(gcbf, ''tag'', ''chantype''), ''string'', ' ...
                     '       int2str(pop_chansel( tmpchans )));' ...
                     'clear tmpchans;' ];
    commandtype = ['tmptype = get(gcbf, ''userdata'');' ...
                   'tmptype = tmptype{2};' ...
                   'if ~isempty(tmptype),' ...
                   '    [tmps,tmpv, tmpstr] = listdlg2(''PromptString'',''Select type(s)'', ''ListString'', tmptype);' ...
				   '    if tmpv' ...
				   '        set(findobj(''parent'', gcbf, ''tag'', ''chantype''), ''string'', tmpstr);' ...
				   '    end;' ...
                   'else,' ...
                   '    warndlg2(''No channel type'', ''No channel type'');' ...
                   'end;' ...
				   'clear tmps tmpv tmpstr tmptype tmpchans;' ];
               
    % Define the prompts
	promptstr    = { ...
        { 'style' 'text' 'string' 'Channel type(s) or indices' }, ...
        { 'style' 'edit' 'string' '' 'tag' 'chantype' }, ...
        { 'style' 'pushbutton' 'string' '... types' 'callback' commandtype } ...
        { 'style' 'pushbutton' 'string' '... channels' 'callback' commandchans }, ...
        { 'style' 'text' 'string' 'Artifact Flag (for ERPLAB; 2 to 8)' }, ...
        { 'style' 'edit' 'string' '2' }, ...
        };
    
    % Define geomery
    geometry = { [2 1 1 1] [2 1.5] };
    
    % channel types
    % -------------
    if isfield(EEG.chanlocs, 'type')
        tmpchanlocs = EEG(1).chanlocs;
        alltypes = { tmpchanlocs.type };
        indempty = cellfun('isempty', alltypes);
        alltypes(indempty) = '';
        try
            alltypes = unique_bc(alltypes);
        catch
            alltypes = '';
        end
    else
        alltypes = '';
    end
    
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
        'helpcom', 'pophelp(''pop_detectdrift'')', ...
        'title', 'Manual Artifact Detection == pop_manual_artifact_flag()', ...
        'userdata', { alllabels alltypes } );
    
    % Sort the results into the appropriate variables, and check input for
    % errors
    % Electrodes
    if ~isempty(result{1})
        if ~isempty(str2num(result{1})), elecRange = str2num(result{1});
        else                             elecRange = parsetxt(result{1}); 
        end
    end
    
% elseif nargin == 3
%     
%     error('Must provide all inputs.')
    
end
    
%% Chech if ERPLAB installed and EVENTLIST created
% ------------------------------------
if exist(which('eegplugin_erplab'),'file')
   if ~isfield(EEG,'EVENTLIST')
       error('Must create EVENTLIST structure.')
   end
else
    error('Must have the ERPLAB plugin installed.')
end

%% Get the current artifact flags (if any), and make the format for eegplot()
% ------------------------------------
% INITIALIZE EEG>REJECT>REJMANUAL FOR INSTANCES WHEN IT IS EMPTY (SET TO
% zeros(1,size(EEG.data,3)); Same for EEG.reject.rejmanualE
if isempty(EEG.reject.rejmanual)
    EEG.reject.rejmanual = zeros(1,size(EEG.data,3));
end
if isempty(EEG.reject.rejmanualE)
    EEG.reject.rejmanualE = zeros(1,size(EEG.data,3));
end

artEpochs = find(EEG.reject.rejmanual);
if ~isempty(artEpochs) % Make winrej structure
    winrej = trial2eegplot(EEG.reject.rejmanual,EEG.reject.rejmanualE(elecRange,:,:),EEG.pnts,[ 0.7 1 0.9]);
else
    winrej = [];
end

%% Plot the EEG data with eegplot()
% ------------------------------------
cmd = [ 'artEpochs = find(EEG.reject.rejmanual);' ...
    'EEG.reject.rejmanual = eegplot2trial( TMPREJ, EEG.pnts, EEG.trials);'  ];
butlabel = 'UPDATE MARKS';
eegplot(EEG.data(elecRange,:,:),'eloc_file',EEG.chanlocs(elecRange),'srate',EEG.srate, ...
    'command',cmd,'butlabel',butlabel,'wincolor',[ 0.7 1 0.9], ...
    'winrej',winrej,'events',EEG.event);
waitfor( findobj('parent', gcf, 'string', butlabel), 'userdata');

%% return the string command for detect drift
% -------------------------
com = [ com sprintf('%s = pop_manual_artifact_flag(%s);', inputname(1), ...
		inputname(1))]; 

end
