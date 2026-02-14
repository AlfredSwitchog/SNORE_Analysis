%%Function: The idea is to test the reallignment script so we prevent the
%%FOV clipping

%% Realign only

spm_path    = '/Users/Richard/MatLAB/spm12_dev';
scriptpath  = '/Users/Richard/Masterabeit_local/SNORE_Analysis/PreProc';

addpath([scriptpath '/nc_SPM_process']);
addpath(scriptpath);

% Add SPM
addpath(spm_path)
fprintf('SPM used: %s\n', spm_path);


OutDir = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/4/nifti_raw';

filesRealign = cellstr(spm_select('FPList', OutDir, '^MF.*\.nii$'));
nc_Realign_20260211(filesRealign);