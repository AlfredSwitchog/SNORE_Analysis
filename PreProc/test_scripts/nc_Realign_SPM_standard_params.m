%%********************************%%
% nc_Realign_standard_params
%
% This is realignment with SPM standard Parameters that you get from
% creating a ascript in the SPM UI
%
% RL: Important that we set roptions.mask = 0 --> otherwise FOV clipping
%********************************%%

function nc_Realign_SPM_standard_params(EPI_files)

matlabbatch{1}.spm.spatial.realign.estwrite.data = {EPI_files};
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.95; %changed
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep     = 1.5; %changed
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm    = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm     = 1; % register to mean
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp  = 2; % trilinear
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap    = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight  = '';

matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which   = [2 1]; % write all & mean
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp  = 4;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap    = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask    = 0; % This is the only thing that I will change compared to SPM standard: 1 = mask so only voxels that are present in all timepoint volumes are taken
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix  = 'r';

spm_jobman('run', matlabbatch);
clear matlabbatch

end