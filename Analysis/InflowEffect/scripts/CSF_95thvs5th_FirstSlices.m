% === File paths ===
img_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/filt_preproc_out/merged_s3uaMFAN99SC020724.nii';
mask_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/coreg_new/c3_pruned_MFAN99SC020724_in_func_space_bin.nii';

% === Load image and mask using SPM ===
V_img = spm_vol(img_file);       % Vector of volumes (1 per time point)
V_mask = spm_vol(mask_file);     % Single volume
mask_data = spm_read_vols(V_mask);  % 3D (x, y, z)
n_timepoints = numel(V_img);

% Store ratios for plotting
relative_ratios = nan(1, 7);  % NaN-filled in case some slices have no CSF

%% === Loop over the first 7 slices ===
for slice_idx = 1:7
    mask_slice = mask_data(:,:,slice_idx);
    csf_voxel_idx = find(mask_slice);

    if isempty(csf_voxel_idx)
        fprintf('Slice %d: No CSF voxels found. Skipping.\n', slice_idx);
        continue
    end

    % Initialize signal matrix
    csf_signals = zeros(numel(csf_voxel_idx), n_timepoints);

    % Extract signals over time
    for t = 1:n_timepoints
        volume_data = spm_read_vols(V_img(t));    % 3D image at time t
        slice_data = volume_data(:,:,slice_idx);  % Extract slice
        csf_signals(:,t) = slice_data(csf_voxel_idx);
    end

    % Replace zeros with NaNs
    csf_signals(csf_signals == 0) = NaN;

    % Compute mean time series
    mean_csf_timeseries = nanmean(csf_signals, 1);

    % Compute percentiles and ratio
    p95 = prctile(mean_csf_timeseries, 95);
    p5  = prctile(mean_csf_timeseries, 5);
    relative_ratio = p95 / p5;

    % Save result
    relative_ratios(slice_idx) = relative_ratio;

    % Display result
    fprintf('Slice %d: CSF 95th/5th percentile ratio = %.4f\n', slice_idx, relative_ratio);
end

%% === Plot the results ===
slices = 1:7;

figure;
plot(slices, relative_ratios, '-o', 'LineWidth', 2);
xlabel('Slice Number');
ylabel('95th / 5th Percentile Ratio');
title('CSF Signal Fluctuation Across First 7 Slices');
grid on;
