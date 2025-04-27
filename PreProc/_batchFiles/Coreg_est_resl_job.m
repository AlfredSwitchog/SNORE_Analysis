%-----------------------------------------------------------------------
% Job saved on 24-Apr-2025 07:38:32 by cfg_util (rev $Rev: 8183 $)
% spm SPM - SPM25 (00.00)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------

%ref --> func image
%source --> structural image

% SPM must be initialized
spm('Defaults','fMRI');
spm_jobman('initcfg');

matlabbatch{1}.spm.spatial.coreg.estwrite.ref = {'/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/preproc_out/brain_s3meanuaMFRO01GG010724-0011-00001-000001.nii,1'};
matlabbatch{1}.spm.spatial.coreg.estwrite.source = {'/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/2/T1/MR t1_mprage_tra_p2_0.8mm_iso/c3MFRO01GG010724-0005-00001-000001.nii,1'};
matlabbatch{1}.spm.spatial.coreg.estwrite.other = {''};
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estwrite.eoptions.fwhm = [7 7];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.interp = 4;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.mask = 0;
matlabbatch{1}.spm.spatial.coreg.estwrite.roptions.prefix = 'r';

% === Run the batch ===
spm_jobman('run', matlabbatch);
