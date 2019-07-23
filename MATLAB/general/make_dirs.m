function make_dirs(directory_list)

% Make directories
fprintf('MAKING DIRECTORIES:\n')
for directory = string(directory_list)
    if ~isfolder(directory) 
        mkdir(directory);
        fprintf('\tCREATED:  %s\n', directory); 
    else
        fprintf('\tEXISTS:   %s\n', directory);
    end
end

end % of function