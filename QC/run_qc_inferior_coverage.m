spm_path    = '/Users/Richard/MatLAB/spm12_dev';
scriptpath  = '/Users/Richard/Masterabeit_local/SNORE_Analysis/QC';

addpath(scriptpath);

% Add SPM
addpath(spm_path)
fprintf('SPM used: %s\n', spm_path);

folder = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/29/nifti_raw';
files  = spm_select('FPList', folder, '^MF.*\.nii$');

qc_inferior_coverage_spm(files, 12, 'nonzero');

