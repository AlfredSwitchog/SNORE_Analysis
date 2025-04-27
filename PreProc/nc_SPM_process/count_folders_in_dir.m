
function num_dirs = count_folders_in_dir(directoryPath)

    % Specify the directory path
    directoryPath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev';
    
    % Get a list of items in the directory
    items = dir(directoryPath);
    
    % Filter out '.' and '..' (special entries for current and parent directories)
    items = items(~ismember({items.name}, {'.', '..'}));
    
    % Exclude hidden files (those starting with '.')
    items = items(~startsWith({items.name}, '.'));
    
    % Count the number of items
    num_dirs = numel(items);
end


% Display the count
%disp(['Number of items in the directory: ' num2str(numItems)]);
