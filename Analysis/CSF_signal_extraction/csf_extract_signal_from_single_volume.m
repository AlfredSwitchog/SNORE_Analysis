%% === SET PATHS ===
volume_file = '/Users/Richard/Documents/20260322_2_SNORE_QC/46/preprocessing/highpass_extracted/vol_001678_hp_s3brain_a_rMFHE00MS200225.nii';     % e.g. functional or anatomical volume
mask_file   = '/Users/Richard/Documents/20260322_2_SNORE_QC/46/CSF_mask_pruning/1_pruned_c3_in_func_space_bin_N4_brain_T1_MFHE00MS200225.nii.gz';       % binary mask

%% === LOAD NIFTI FILES ===
V = niftiread(volume_file);
M = niftiread(mask_file);

%% === IF VOLUME IS 4D, TAKE FIRST TIMEPOINT ===
if ndims(V) == 4
    V = V(:,:,:,1);
end

%% === MAKE SURE MASK IS LOGICAL ===
M = M > 0;

%% === FIND SLICES WHERE MASK EXISTS ===
mask_slices = find(squeeze(any(any(M,1),2)));

%% === TAKE FIRST 4 SLICES WITH MASK ===
num_slices = min(4, numel(mask_slices));
first4_slices = mask_slices(1:num_slices);

%% === EXTRACT SIGNAL FROM MASK FOR EACH SLICE ===
masked_signal = cell(num_slices,1);

for i = 1:num_slices
    z = first4_slices(i);

    vol_slice  = V(:,:,z);
    mask_slice = M(:,:,z);

    masked_signal{i} = vol_slice(mask_slice);
end

%% === DISPLAY RESULTS ===
disp('Slices used:')
disp(first4_slices)

for i = 1:num_slices
    fprintf('Slice %d: extracted %d voxels\n', first4_slices(i), numel(masked_signal{i}));
end