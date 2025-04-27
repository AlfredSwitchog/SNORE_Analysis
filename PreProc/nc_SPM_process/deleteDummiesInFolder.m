function deleteFirst5Entries(numToDelete, dirPath)

    % Check if the input is a valid directory
    if ~isfolder(dirPath)
        error('The specified path is not a valid directory.');
    end
    
    % Get all entries in the directory
    files = dir(dirPath);

    % Filter out directories from the list of files
    files = files(~[files.isdir]);

    % Filter out files that start with '.'
    files = files(~startsWith({files.name}, '.'));
    
    % Sort the entries alphabetically (default behavior of dir)
    [~, sortIdx] = sort({files.name});
    files = files(sortIdx);
    
    % Determine the number of entries to delete (5 or fewer if less exist)
    numToDeleteDetermined = min(numToDelete, length(files));

    %check if the first file is the first volume or if the dummy scans have
    %already been removed
    firstFile = files(1).name;
    firstFile_name = files(1).name;
    firstFile = extractBefore(firstFile, '.');
    firstFile = extractAfter(firstFile, strlength(firstFile) - 6);
    firstFile = str2double(firstFile);

    if firstFile ~= 1
       fprintf('Dummies have already been deleted! \n');
       fprintf('First file is detected as: %s\n', firstFile_name)
       return;
    end
    
    % Loop through and delete the first numToDelete entries
    for i = 1:numToDeleteDetermined
        entryPath = fullfile(dirPath, files(i).name);
        if files(i).isdir
            % If the entry is a directory, delete it and its contents
            fprintf('Deleting directory: %s\n', entryPath);
            rmdir(entryPath, 's'); % 's' flag removes the directory and its contents
        else
            % If the entry is a file, delete it
            fprintf('Deleting file: %s\n', entryPath);
            delete(entryPath);
        end
    end
        
    fprintf('Deleted the first %d entries in the directory: %s\n',dirPath);
end