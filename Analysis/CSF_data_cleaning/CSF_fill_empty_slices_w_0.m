% === CONFIG ===
data_dir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260329_Averaged_Signal';

% === Find all .mat files ===
files = dir(fullfile(data_dir, '*.mat'));

for f = 1:length(files)
    file_path = fullfile(data_dir, files(f).name);
    fprintf('Processing %s\n', files(f).name);

    % Load file
    S = load(file_path);

    % Check if averaged_csf_data exists
    if ~isfield(S, 'averaged_csf_data')
        warning('Skipping %s (no averaged_csf_data found)', files(f).name);
        continue;
    end

    averaged_slices = S.averaged_slices;

    % Replace NaNs in averaged_slices with 0
    averaged_slices(isnan(averaged_slices)) = 0;

    % Save back
    save(file_path, 'averaged_csf_data');
end

disp('Done replacing NaNs with 0 in averaged_slices.');