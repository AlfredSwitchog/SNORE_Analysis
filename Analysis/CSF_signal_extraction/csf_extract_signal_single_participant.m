%% Extract CSF signals from bottom slices for a single participant
clear; clc;

%% === User settings ===
spm_path   = '/scratch/c7201319/spm12_dev';
output_dir = '/scratch/c7201319/SNORE_CSF_Data/20260331_Raw_Signals';

mask_file_path = '/scratch/c7201319/SNORE_CSF_Masks/20260329_CSF_masks/6/CSF_mask_pruning/3_pruned_c3_in_func_space_bin_N4_brain_T1_MFRO01GG010724.nii.gz';
img_file       = '/scratch/c7201319/SNORE_MR_out/6/preprocessing/highpasshp_s3brain_a_rMFRO01GG010724.nii';
script_dir = '/scratch/c7201319/SNORE_Analysis/Analysis/CSF_signal_extraction';

num_slices = 4;

%% === Setup ===
addpath(spm_path);
fprintf('Using SPM from: %s\n', spm_path);

%% === Read volumes ===
disp(['Trying to read functional file: ', img_file]);
V_img = spm_vol(img_file);

disp(['Trying to read mask file: ', mask_file_path]);
V_mask = spm_vol(mask_file_path);

mask_data = spm_read_vols(V_mask);
n_timepoints = numel(V_img);

%% === Extract CSF signals ===
slice_data_struct = struct();
max_slices = size(mask_data, 3);
slices_to_extract = min(num_slices, max_slices);

for slice_idx = 1:slices_to_extract
    mask_slice = mask_data(:,:,slice_idx);
    csf_voxel_idx = find(mask_slice);

    if isempty(csf_voxel_idx)
        fprintf('Slice %d: No CSF voxels\n', slice_idx);
        slice_data_struct(slice_idx).signals = [];
        continue;
    end

    csf_signals = zeros(length(csf_voxel_idx), n_timepoints);

    for t = 1:n_timepoints
        volume_data = spm_read_vols(V_img(t));
        slice_data = volume_data(:,:,slice_idx);
        voxel_values = slice_data(csf_voxel_idx);
        csf_signals(:, t) = voxel_values;
    end

    slice_data_struct(slice_idx).signals = csf_signals;
end

%% === Save result ===
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

out_file = fullfile(output_dir, 'csf_signals_single_file.mat');
save(out_file, 'slice_data_struct');

fprintf('Saved CSF signals to %s\n', out_file);