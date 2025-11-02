%%********************************%%
% nc_RealignUnwarp
% NC 14/12/17
%
% EPI_files: EPI images to realig and unwarp
% VDM_file: Displacement vector file
%********************************%%

function nc_RealignUnwarp(EPI_files,VDM_file)

matlabbatch{1}.spm.spatial.realignunwarp.data.scans = EPI_files;
if nargin<2
matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = '';
else
matlabbatch{1}.spm.spatial.realignunwarp.data.pmscan = VDM_file;
end
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 2; %(Old value = 4) Suggestion by Alina: She used 2 for 1mm 7T Phillips runs 
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 3; %(Old value = 5) Suggestion by Alina: She used 3 for 1mm 7T Phillips runs 
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 4; %(Old value = 2) Suggestion by Alina: higher spline order can help us preserve the high-resolution details but I personally have not tested this extensively… Just with me eyes... However, from my experience with ANTs splines, anything over 4th-degree for 3T data feels like an overkill.
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

spm_jobman('run', matlabbatch);
clear matlabbatch

end