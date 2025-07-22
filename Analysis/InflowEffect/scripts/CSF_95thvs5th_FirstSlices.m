% === Load group-averaged CSF signal ===
data_file = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_group_mean_per_slice.mat';
load(data_file, 'group_mean_csf_data');  % Assumes variable is called group_mean_csf_data

% === Initialize result array ===
relative_ratios = nan(1, 7);

% === Loop over the first 7 slices ===
for slice_idx = 1:7
    if slice_idx > numel(group_mean_csf_data) || isempty(group_mean_csf_data{slice_idx})
        fprintf('Slice %d: No data found. Skipping.\n', slice_idx);
        continue
    end

    % Extract group-averaged time series for this slice
    mean_csf_timeseries = group_mean_csf_data{slice_idx};

    % Replace zeros with NaNs (optional)
    mean_csf_timeseries(mean_csf_timeseries == 0) = NaN;

    % Compute percentiles and ratio
    p95 = prctile(mean_csf_timeseries, 95);
    p5  = prctile(mean_csf_timeseries, 5);
    relative_ratio = p95 / p5;

    % Save result
    relative_ratios(slice_idx) = relative_ratio;

    % Display result
    fprintf('Slice %d: Group mean CSF 95th/5th percentile ratio = %.4f\n', slice_idx, relative_ratio);
end

%% === Plot the results ===
slices = 1:7;

figure;
plot(slices, relative_ratios, '-o', 'LineWidth', 2);
xlabel('Slice Number');
ylabel('95th / 5th Percentile Ratio');
title('Group Mean CSF Signal Fluctuation Across First 7 Slices');
grid on;
