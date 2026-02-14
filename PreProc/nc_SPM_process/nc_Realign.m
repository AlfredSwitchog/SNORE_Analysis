%%********************************%%
% nc_Realign
% NC 20250711
%
% EPI_files: EPI images to realig and unwarp
% RL: Important that we set roptions.mask = 0 --> otherwise FOV clipping
%********************************%%

function nc_Realign(EPI_files)

matlabbatch{1}.spm.spatial.realign.estwrite.data = {EPI_files};
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep     = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm    = 5;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm     = 1; % register to mean
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp  = 2; % trilinear
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap    = [0 1 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight  = '';

matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which   = [2 1]; % write all & mean
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp  = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap    = [0 1 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask    = 0; % 1 = mask so only voxels that are present in all timepoint volumes are taken
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix  = 'r';

spm_jobman('run', matlabbatch);
clear matlabbatch

end