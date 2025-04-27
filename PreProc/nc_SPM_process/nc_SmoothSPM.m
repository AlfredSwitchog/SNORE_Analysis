%%********************************%%
% Smooth
% NC 14/12/17
% DH 18/04/19
%
% files: files to smooth
% fwmh: fwmh vector of the 3D gaussian filter 
%********************************%%

function nc_SmoothSPM(files,fwhm)
matlabbatch{1}.spm.spatial.smooth.data = files;
matlabbatch{1}.spm.spatial.smooth.fwhm = fwhm; %Q: Is the smoothing kernel correctly placed?
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = ['s' num2str(fwhm(1))];% add smoothing kernel to name 
spm_jobman('run', matlabbatch);
clear matlabbatch
end

