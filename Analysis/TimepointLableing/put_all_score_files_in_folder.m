% Config
sourceFolder = '/Users/Richard/Masterabeit_local/EEG/SCORING';          % folder with all CSVs
targetFolder = fullfile(sourceFolder, 'scores_files'); % new folder inside

% Create target folder if it doesn’t exist
if ~exist(targetFolder, 'dir')
    mkdir(targetFolder);
end

% Find all files that contain "scores" in the name
csvFiles = dir(fullfile(sourceFolder, '*scores*.csv'));

% Move them into the target folder
for i = 1:numel(csvFiles)
    srcPath = fullfile(csvFiles(i).folder, csvFiles(i).name);
    destPath = fullfile(targetFolder, csvFiles(i).name);

    % movefile will relocate the file
    movefile(srcPath, destPath);
end

disp('All *scores*.csv files moved into scores_files folder.');
