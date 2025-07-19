% --- Settings ---
merged_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/merged_func.nii';     % Your 4D merged data
filtered_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/s3ua_hp_add_mean_func.nii';     % Your 4D filtered data
TR = 2.5;

%% --- Load 4D data ---
V_orig = spm_vol(merged_file);
Y_orig = spm_read_vols(V_orig);  % Y: [X, Y, Z, Time]

V_filt = spm_vol(filtered_file);
Y_filt = spm_read_vols(V_filt);  % Y: [X, Y, Z, Time]

%% Reshape to [nVoxels x nTimePoints]
orig_ts = reshape(Y_orig, [], size(Y_orig, 4));
filt_ts = reshape(Y_filt, [], size(Y_filt, 4));

% Mask out background (optional: only non-zero voxels)
mask = any(orig_ts, 2);
mean_orig = mean(orig_ts(mask, :), 1);
mean_filt = mean(filt_ts(mask, :), 1);

%% Create Plot

t = (0:length(mean_orig)-1) * TR;

figure;
plot(t, mean_orig, 'b-', 'DisplayName', 'Original'); hold on;
plot(t, mean_filt, 'r-', 'DisplayName', 'Filtered');
xlabel('Time (s)');
ylabel('Mean Signal Intensity');
legend;
title('Mean Time Series Before and After High-Pass Filtering (SPM)');


