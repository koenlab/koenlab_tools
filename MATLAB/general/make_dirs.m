function make_dirs(directory_list)

% Make directories
fprintf('MAKING DIRECTORIES:\n')
for directory = string(directory_list)
    if ~isfolder(directory), mkdir(directory); end
    fprintf('\tCREATED:  %s\r', directory)
end

end % of function