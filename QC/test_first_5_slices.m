V = spm_vol('/Users/Richard/Documents/20250216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-00333-000333.nii');
Y = spm_read_vols(V);   % 3D matrix: X × Y × Z

size(Y)
