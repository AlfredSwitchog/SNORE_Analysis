%% --- Step 1: Load functional volume and mask ---
mask_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/2/T1/MR t1_mprage_tra_p2_0.8mm_iso/rc3MFRO01GG010724-0005-00001-000001.nii';     % c3 mask image
path_func = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/preproc_out/brain_s3meanuaMFRO01GG010724-0011-00001-000001.nii';

% Load resliced func image
V_func_res = spm_vol(path_func);
Y_func_res = spm_read_vols(V_func_res);

% --- Load c3 CSF mask ---
V_c3 = spm_vol(mask_file);
Y_c3 = spm_read_vols(V_c3);  % Should match dimensions with Y_func_res

%% --- Step 2: Apply mask (e.g., threshold at 0.5) ---

% --- Extract bottom slice index ---
slice_idx = 3; %

% --- Extract functional and mask bottom slices ---
func_slice = squeeze(Y_func_res(:, :, slice_idx));  % X x Y --> results in a 2D matrix
mask_slice = squeeze(Y_c3(:, :, slice_idx));        % X x Y --> results in a 2D matrix (squeeze theoretically not necessary, removes 4th dimension)

% extract mean raw signal of certain slice
mean_signal_raw = mean(func_slice(:), 'omitnan');
disp(['mesn_signal for raw slice:', num2str(mean_signal_raw)])

% --- Binarize mask ---
mask_bin = mask_slice > 0.3;  % can be tweaked

% --- Extract mean signal from masked area ---
masked_values = func_slice(mask_bin);
mean_signal_csf = mean(masked_values, 'omitnan');
disp(['mean_signal for masked slice:', num2str(mean_signal_csf)])

% --- Create 95th vs. 5th percentile chart ---
p95 = prctile(masked_values, 95);
p5 = prctile(masked_values, 5);
contrast_ratio = p95 / p5;
disp(['95th/5th Percentile Ratio: ', num2str(contrast_ratio)]);

%% --- Create 95th to 5th percentile value for first 4 slice ---
% --- Define slice range explicitly ---
begin_slice = 2;
end_slice = 6;
slice_range = begin_slice:end_slice;
num_slices = length(slice_range);
contrast_ratio_per_slice = nan(num_slices, 1);  % Preallocate

% --- Loop over selected slices ---
for i = 1:num_slices
    slice_idx = slice_range(i);  % Actual slice index in the image

    % Extract 2D slices
    func_slice = squeeze(Y_func_res(:, :, slice_idx));
    mask_slice = squeeze(Y_c3(:, :, slice_idx));
    
    % Binarize mask
    mask_bin = mask_slice > 0.5;

    % Apply mask
    masked_values = func_slice(mask_bin);

    % Check there are enough values
    if numel(masked_values) > 10 && all(masked_values ~= 0)
        p95 = prctile(masked_values, 95);
        p5 = prctile(masked_values, 5);

        % Avoid division by zero
        if p5 ~= 0
            contrast_ratio_per_slice(i) = p95 / p5;
        end
    end
end

% --- Plotting ---
figure;
plot(slice_range, contrast_ratio_per_slice, '-o');
xlabel('Slice Index (Z)');
ylabel('95th / 5th Percentile Ratio');
title('Contrast Ratio per Selected Slices (CSF Masked)');
grid on;

%% --- Step 4: Create Visualization ---
%check the binary mask of the slice
%histogram(mask_slice(:), 50);

figure;
histogram(masked_values, 50);  % 50 bins

%% Step 5: Plot mean signal for each slice
% --- Initialize
num_slices = size(Y_func_res, 3);
%num_slices = 50
mean_signal_per_slice = nan(num_slices, 1);  % Preallocate

% --- Loop over slices ---
for slice_idx = 1:num_slices
    % Extract 2D slices
    func_slice = squeeze(Y_func_res(:, :, slice_idx));
    mask_slice = squeeze(Y_c3(:, :, slice_idx));
    
    % Binarize mask
    mask_bin = mask_slice > 0.5;

    % Apply mask
    masked_values = func_slice(mask_bin);

    % Compute mean (omit NaNs)
    mean_signal_per_slice(slice_idx) = mean(masked_values, 'omitnan');
end

% --- Plotting ---
figure;
plot(1:num_slices, mean_signal_per_slice, '-o');
xlabel('Slice Index (Z)');
ylabel('Mean Signal (CSF-masked)');
title('Mean Signal per Slice (CSF Masked)');
grid on;

