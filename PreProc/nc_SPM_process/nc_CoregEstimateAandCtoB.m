%%********************************%%
% CoregEstimateAandCtoB
% NC 14/12/17
%
% Functionality: This function uses estimate only, no reslicing
% Input:
%   A: source (structural)
%   B:ref (EPI) --> mean image
%   C: others
%
% Output: Structural image is changed during coregistration (header information changed)
%********************************%%


function nc_CoregEstimateAandCtoB(A,B,C)
matlabbatch{1}.spm.spatial.coreg.estimate.ref = {B}; %this is the mean image
matlabbatch{1}.spm.spatial.coreg.estimate.source = {A}; %this is the structural image
if nargin<3
matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
else
matlabbatch{1}.spm.spatial.coreg.estimate.other = {C};
end
%default options from spm
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

spm_jobman('run', matlabbatch);
clear matlabbatch

end