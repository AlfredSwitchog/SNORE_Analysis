%%********************************%%
% nc_Realign
% NC 20250711
%
% RL 20260211: Das ist das neue realign script mit optimierten parametern,
% sodass wir hoffentlich keine bounding box issues mehr bekommen.
%
% EPI_files: EPI images to realig and unwarp
%********************************%%

function nc_Realign_20260211(EPI_files)

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
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix  = 'r_new_';

spm_jobman('run', matlabbatch);
clear matlabbatch

end
