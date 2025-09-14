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

%% load data
csf_data = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject_cleaned.mat';
load(csf_data)

%% Calculate per slice mean at the group level
max_slices = max(cellfun(@numel, all_subjects));
group_mean_csf_data = cell(max_slices, 1);

for slice_idx = 1:max_slices
    slice_ts_list = {};
    time_lengths = [];

    for subj = 1:numel(all_subjects)
        subj_slices = all_subjects{subj};
        
        if numel(subj_slices) >= slice_idx
            ts = subj_slices{slice_idx};
            if ~isempty(ts)
                slice_ts_list{end+1} = ts;
                time_lengths(end+1) = numel(ts);  % save the TR length
            end
        end
    end

    if ~isempty(slice_ts_list)
        max_len = max(time_lengths);
        n_subjects = numel(slice_ts_list);
        
        % Initialize with NaNs and fill in valid data
        padded_matrix = NaN(n_subjects, max_len);
        for i = 1:n_subjects
            T = numel(slice_ts_list{i});
            padded_matrix(i, 1:T) = slice_ts_list{i};
        end

        % Compute mean across subjects per timepoint (ignoring NaNs)
        group_mean_csf_data{slice_idx} = mean(padded_matrix, 1, 'omitnan'); % This means the mean is calculated only including subjects that have data
        subject_count_per_slice{slice_idx} = sum(~isnan(padded_matrix), 1);

    else
        group_mean_csf_data{slice_idx} = [];
    end
end

%% Determine how many participants contributed
%subject_count_per_slice{slice_idx} = sum(~isnan(padded_matrix), 1);

%% Save combined data
output_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data';
output_path = fullfile(output_folder, 'csf_group_mean_per_slice_cleaned.mat');
save(output_path, 'group_mean_csf_data', '-v7.3');  % v7.3 handles large files

%% Overlay subject count plots for the first 4 slices
figure;
hold on;

num_slices_to_plot = min(4, numel(subject_count_per_slice));
legend_entries = cell(1, num_slices_to_plot);

for slice_idx = 1:num_slices_to_plot
    counts = subject_count_per_slice{slice_idx};

    if isempty(counts)
        fprintf('Slice %d: No data\n', slice_idx);
        continue;
    end

    fprintf('Slice %d:\n', slice_idx);
    fprintf('  - Timepoints: %d\n', numel(counts));
    fprintf('  - Max subjects contributing: %d\n', max(counts));
    fprintf('  - Min subjects contributing: %d\n', min(counts));
    fprintf('  - Mean subject coverage: %.2f\n\n', mean(counts));

    plot(counts, 'LineWidth', 1.5);
    legend_entries{slice_idx} = sprintf('Slice %d', slice_idx);
end

title('Subject Count per Timepoint for First 4 Slices');
xlabel('Timepoint');
ylabel('Number of Subjects');
ylim([0, max(cellfun(@max, subject_count_per_slice(1:num_slices_to_plot))) + 1]);
legend(legend_entries, 'Location', 'best');
grid on;
hold off;

