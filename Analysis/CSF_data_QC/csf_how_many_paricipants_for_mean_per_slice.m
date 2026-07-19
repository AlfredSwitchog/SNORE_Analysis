% Generate a QC plot that shows how many participants contribute to the
% calculation of the mean per slice across timepoints. This is relevant as
% the length of the runs varies across participants so at different
% timepoints it is possible that a different amount of participants
% contribute to the mean

clear; clc;

%% Path to merged result
input_file = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Group_Average/csf_group_mean_per_slice_cleaned.mat';

load(input_file, 'subject_count_per_slice', 'included_participants', 'exclude_participants');

fprintf('Loaded QC data from:\n%s\n\n', input_file);

fprintf('Included participants:\n');
disp(included_participants)

fprintf('Excluded participants:\n');
disp(exclude_participants)

%% Plot subject count for first 4 slices
figure;
hold on;

num_slices_to_plot = min(4, numel(subject_count_per_slice));
legend_entries = {};

max_y = 0;

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
    legend_entries{end+1} = sprintf('Slice %d', slice_idx);

    if max(counts) > max_y
        max_y = max(counts);
    end
end

title('Subject Count per Timepoint for First 4 Slices');
xlabel('Timepoint');
ylabel('Number of Subjects');
ylim([0 max_y + 1]);
legend(legend_entries, 'Location', 'best');
grid on;
hold off;