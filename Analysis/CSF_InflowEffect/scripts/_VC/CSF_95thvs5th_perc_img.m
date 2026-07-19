% === File paths ===
img_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/filt_preproc_out/merged_s3uaMFAN99SC020724.nii';     % 4D image (e.g., fMRI)
mask_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/coreg_new/c3_pruned_MFAN99SC020724_in_func_space_bin.nii';  % 3D binary CSF mask

% === Load image and mask using SPM ===
V_img = spm_vol(img_file);       % Returns vector of volumes (1 per time point)
V_mask = spm_vol(mask_file);     % Single volume

 
%% Read mask data
mask_data = spm_read_vols(V_mask);  % 3D (x, y, z)

% Identify the 2nd slice
slice_idx = 2;
mask_slice = mask_data(:,:,slice_idx);
csf_voxel_idx = find(mask_slice);   % Indices of CSF voxels in this slice (these are the voxels containing the CSF signal)

% Sanity check
if isempty(csf_voxel_idx)
    error('No CSF voxels found in slice %d of the mask.', slice_idx);
end

%% Extract CSF signal for a specific slice
%extract time points from 4d vector
n_timepoints = numel(V_img);

%Initialize signal matrix with rows as voxels and columns as time points (all zero values)
csf_signals = zeros(numel(csf_voxel_idx), n_timepoints);

% Loop through time points and extract signal at CSF voxels in slice 2
for t = 1:n_timepoints
    volume_data = spm_read_vols(V_img(t));    % 3D image at time t
    slice_data = volume_data(:,:,slice_idx);  % Extract 2nd slice
    csf_signals(:,t) = slice_data(csf_voxel_idx);
end
%% Compute mean time series over CSF voxels
% Replace zeros with NaNs
csf_signals(csf_signals == 0) = NaN;

% Compute mean while ignoring NaNs
mean_csf_timeseries = nanmean(csf_signals, 1); % 1 x time ((csf_signals, 1) means we average accross rows along the columns, 2 would give averga accross columns over time per row)

% Compute 95th and 5th percentiles
p95 = prctile(mean_csf_timeseries, 95);
p5  = prctile(mean_csf_timeseries, 5);

% Compute signal magnitude ratio
relative_ratio = p95 / p5;

% Display result
fprintf('Slice %d CSF mean signal 95th/5th percentile ratio: %.4f\n', slice_idx, relative_ratio);
