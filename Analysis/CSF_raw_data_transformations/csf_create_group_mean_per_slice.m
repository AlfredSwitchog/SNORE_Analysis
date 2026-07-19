% Explanation of mean calculation: 
% This script computes the group-level mean CSF time series for each slice
% across multiple subjects. Each subject's data is structured as a cell
% array of slices, where each slice contains a 1 × T time series vector,
% with T being the number of timepoints for that subject (equal across slices
% but variable across subjects).

% To handle differences in time series length between subjects, each slice's
% data across subjects is aligned in a padded matrix where shorter time series
% are filled with NaNs at the end. The group mean is then computed across
% subjects for each timepoint using 'mean(..., 'omitnan')', which ensures
% that only available data points contribute to the mean at each timepoint.

% As a result, early timepoints (which most subjects have) are averaged across
% more participants, while later timepoints may include fewer contributions.
% This preserves all available data without interpolation or truncation,
% and provides a per-slice group mean time series of maximal length.

% Participants that don't have data for slice 1 are manually excluded below
% by setting the list exclude_participants

% Each subject is stored in an individual .mat file, for example:
%   csf_p5_averaged.mat
%
% Each file is expected to contain:
%   averaged_csf_data

clear; clc;

%% Paths
data_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
output_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Group_Average';

if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

%% Participants to exclude
exclude_participants = [5 9];   % example: [5 12 33]

%% Find files
files = dir(fullfile(data_folder, 'csf_p*_averaged.mat'));

all_subjects = {};
included_participants = [];

for i = 1:length(files)
    file_name = files(i).name;
    file_path = fullfile(data_folder, file_name);

    % Extract participant number from filename, e.g. csf_p5_averaged.mat -> 5
    tokens = regexp(file_name, 'csf_p(\d+)_averaged\.mat', 'tokens');

    if isempty(tokens)
        fprintf('Skipping file with unexpected name: %s\n', file_name);
        continue;
    end

    participant_id = str2double(tokens{1}{1});

    if ismember(participant_id, exclude_participants)
        fprintf('Excluding participant %d\n', participant_id);
        continue;
    end

    S = load(file_path);

    if ~isfield(S, 'averaged_csf_data')
        fprintf('Skipping %s (no averaged_csf_data found)\n', file_name);
        continue;
    end

    all_subjects{end+1} = S.averaged_csf_data;
    included_participants(end+1) = participant_id;

    fprintf('Loaded participant %d\n', participant_id);
end

fprintf('\nTotal included participants: %d\n', numel(all_subjects));
disp('Included participant IDs:')
disp(included_participants)

%% Calculate per-slice group mean
max_slices = max(cellfun(@numel, all_subjects));
group_mean_csf_data = cell(max_slices, 1);
subject_count_per_slice = cell(max_slices, 1);

for slice_idx = 1:max_slices
    slice_ts_list = {};
    time_lengths = [];

    for subj = 1:numel(all_subjects)
        subj_slices = all_subjects{subj};

        if numel(subj_slices) >= slice_idx
            ts = subj_slices{slice_idx};

            if ~isempty(ts)
                slice_ts_list{end+1} = ts;
                time_lengths(end+1) = numel(ts);
            end
        end
    end

    if ~isempty(slice_ts_list)
        max_len = max(time_lengths);
        n_subjects = numel(slice_ts_list);

        padded_matrix = NaN(n_subjects, max_len);

        for j = 1:n_subjects
            T = numel(slice_ts_list{j});
            padded_matrix(j, 1:T) = slice_ts_list{j};
        end

        group_mean_csf_data{slice_idx} = mean(padded_matrix, 1, 'omitnan');
        subject_count_per_slice{slice_idx} = sum(~isnan(padded_matrix), 1);
    else
        group_mean_csf_data{slice_idx} = [];
        subject_count_per_slice{slice_idx} = [];
    end
end

%% Save results
output_path = fullfile(output_folder, 'csf_group_mean_per_slice_cleaned.mat');
save(output_path, ...
    'group_mean_csf_data', ...
    'subject_count_per_slice', ...
    'included_participants', ...
    'exclude_participants', ...
    '-v7.3');

fprintf('\nSaved group mean data to:\n%s\n', output_path);

