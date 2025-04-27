function deleteAllFilesInSubfolders(parentFolder)
    % Check if folder exists
    if ~isfolder(parentFolder)
        error('The specified folder does not exist.');
    end

    % Get list of all files in subfolders
    fileList = dir(fullfile(parentFolder, '**', '*')); % '**' means recursive
    for k = 1:length(fileList)
        file = fileList(k);
        % Skip directories
        if ~file.isdir
            filePath = fullfile(file.folder, file.name);
            try
                delete(filePath);
                fprintf('Deleted: %s\n', filePath);
            catch ME
                warning('Could not delete: %s\nReason: %s', filePath, ME.message);
            end
        end
    end

    fprintf('Finished deleting files in subfolders of:\n%s\n', parentFolder);
end
