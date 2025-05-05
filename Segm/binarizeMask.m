%%%%%%% Binarize Segmentation Probability Maps %%%%%%%%%

pathToMask = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/8/T1/MR t1_mprage_tra_p2_0.8mm_iso/c3MFAN95NS090724-0005-00001-000001.nii';

% Load gray matter probability map
V = spm_vol(pathToMask);
Y = spm_read_vols(V);

% Threshold at 0.5
binary_mask = Y > 0.5;

% Prepare the header for the new file
V_mask = V;                      % Copy header information
V_mask.fname = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/8/T1/MR t1_mprage_tra_p2_0.8mm_iso/bin_c3T1_mask.nii';   % Set new filename

% Save the binary mask
spm_write_vol(V_mask, binary_mask);
