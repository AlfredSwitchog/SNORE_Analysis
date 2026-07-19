% Config
folderPath = '/Users/Richard/Masterabeit_local/EEG/SCORING';
outFile    = 'all_sleep_scores.mat';

% Find only CSV files with 'scores' in the name
csvFiles = dir(fullfile(folderPath, '*scores*.csv'));

% Initialize struct
scores = struct();

for i = 1:numel(csvFiles)
    % Full file path
    filePath = fullfile(csvFiles(i).folder, csvFiles(i).name);

    % Read table
    T = readtable(filePath);

    % Extract subject ID from filename, e.g. "P2"
    tokens = regexp(csvFiles(i).name, '(P\d+)', 'tokens');
    if ~isempty(tokens)
        subjID = tokens{1}{1};
    else
        subjID = sprintf('subj%d', i); % fallback if no match
    end

    % Store in struct
    scores.(subjID) = T;
end

% Save once
save(outFile, 'scores');
