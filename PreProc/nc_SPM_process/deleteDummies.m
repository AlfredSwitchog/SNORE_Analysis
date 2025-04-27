%%********************************%%
% deleteDummies
% Richard Lohr 16/01/24
%
% Assumes folder structure like ./parent/>numOfParticipants</nifti_raw
% --> numberOfParticipnats is accessed dynamically
% --> nifti_raw is hardcoded
% 
%********************************%%


function deleteDummies(nFilesToDelete, parentDir)

% Get a list of all subdirectories
subDirs = dir(parentDir);

% Loop through the subdirectories
for i = 1:length(subDirs)
    % Skip non-directory entries and hidden directories (., ..)
    if subDirs(i).isdir && ~startsWith(subDirs(i).name, '.')

        % Get the full path of the current subdirectory
        currentDir = fullfile(parentDir, subDirs(i).name);
        
        %select files from /nifti_raw folder
        currentDir = [currentDir '/nifti_raw']
        
        % Get a list of all files in the current subdirectory
        files = dir(currentDir);
        
        % Filter out directories from the list of files
        files = files(~[files.isdir]);

        % Filter out files that start with '.'
        files = files(~startsWith({files.name}, '.'));
        
        % Sort the files alphabetically (default behavior of dir)
        % To ensure consistent deletion order
        [~, sortIdx] = sort({files.name});
        files = files(sortIdx);
        
        % Determine how many files to delete --> if num of files is smaller
        % then then num to Delete then then all files are deleted in folder
        numFilesToDelete = min(nFilesToDelete, length(files));
        
        % Delete the first `numFilesToDelete` files
        for j = 1:numFilesToDelete
            fileToDelete = fullfile(currentDir, files(j).name);
            fprintf('Deleting: %s\n', fileToDelete); % Optional: For confirmation
            delete(fileToDelete);
        end
    end
end
