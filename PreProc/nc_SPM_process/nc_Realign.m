%%********************************%%
% nc_Realign
% NC 20250711
%
% EPI_files: EPI images to realig and unwarp
%********************************%%

function nc_Realign(EPI_files)

matlabbatch{1}.spm.spatial.realign.estwrite.data = {EPI_files};
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep     = 2;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm    = 3;
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm     = 1; % register to mean
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp  = 2; % trilinear
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap    = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight  = '';

matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which   = [2 1]; % write all & mean
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp  = 2;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap    = [0 0 0];
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask    = 1;
matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix  = 'r';

spm_jobman('run', matlabbatch);
clear matlabbatch

end
