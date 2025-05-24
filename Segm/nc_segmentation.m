%%********************************%%
% Segmentation
% NC 250323
%
% Function: Segment a structural image
% 
% 
%********************************%%

function nc_segmentation(structfile, spm_path, biasfwmh)

if nargin<3
    biasfwmh=60; % Spm default but Martina (Switch Task) and Daniel Huber proposed 30 or even 20 (SNORE: Use biasfwmh = 30) 
end

matlabbatch{1}.spm.spatial.preproc.channel.vols = {structfile};
matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.0001; %Daniel mentioned that this could be tweaked
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = biasfwmh;
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,1'));
matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,2'));
matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,3'));
matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,4'));
matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,5'));
matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = cellstr(fullfile(spm_path, 'tpm/TPM.nii,6'));
matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0 0.1 0.01 0.04];%different in Switch task pipline 
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1]; % [1 1] = Inverse + forward
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1]; % creates bias corrected image: to check if bias correction is working fine (-> this creates an image with file name prefix ‘m’). 
%matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN; %doesn't exist in switchtask pipe
%matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN NaN NaN NaN]; %doesn't exist in switchtask pipe

spm_jobman('run', matlabbatch);
clear matlabbatch
end

%Tip from Daniel: change the numbers of Gaussians of the tissue classes of interest and 
%their neighboring tissues (I previously used something like 2-2-2-3-4-2 for the 6 tissue types) 
% SPM default:1-1-2-3-4-2


% Options for segmentation field
% matlabbatch{1}.spm.spatial.preproc.warp.write = [1 0]; --> Inverse
% matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1]; --> Forward
% matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1]; --> Inverse +
% Forward (needed for normalizing to MNI space on the individual level) 

