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

% --- Realign (Est.) options ---
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 2; %(Old value = 4) Suggestion by Alina: She used 2 for 1mm 7T Phillips runs 
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 3; %(Old value = 5) Suggestion by Alina: She used 3 for 1mm 7T Phillips runs 
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 1; % <-- register-to-mean (better for 3.6k vols)
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 2;  % <-- trilinear (avoid blockiness with huge N)
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';

% --- Unwarp model (estimation) ---
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 150000; % 1e5–2e5; bump slightly for long-run stability
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4; % try 6 if you see wavy patches
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';

% --- Write (reslicing) ---
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 2;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

spm_jobman('run', matlabbatch);
clear matlabbatch

end