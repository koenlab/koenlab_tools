function EEG = reref_eeg_set(EEG, formulas, add_chanlocs, new_ref)

EEG = pop_eegchanoperator(EEG, formulas);
if add_chanlocs
    path = fileparts(which('pop_dipfit_batch'));
    loc_file = fullfile(path, 'standard_BESA', 'standard-10-5-cap385.elp');
    EEG = pop_chanedit(EEG, 'lookup', loc_file);
end
EEG.ref = new_ref;

end % of function