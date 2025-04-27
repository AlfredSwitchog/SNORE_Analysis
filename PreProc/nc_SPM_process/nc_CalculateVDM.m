%%********************************%%
% CalculateVDM
% NC 14/12/17
%
% Phase_fm: Subtracted Phase B0 fieldmap file
% Mag_fm: One magnitude  B0 fieldmap file
% pm_file: file of parameters for fieldmap correction 
% EPI_file: one reference EPI file 
%********************************%%

function nc_CalculateVDM(Phase_fm,Mag_fm,pm_file,EPI_file)

%logic for empty arguments 
if nargin < 4
    EPI_file = [];
end 

if nargin < 3
    pm_file = [];
end

if nargin < 2
    Mag_fm = [];

matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = Phase_fm; % We have only this MR gre_field_mapping_mod_2mmiso
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = Mag_fm; % This one is not available in SNORE
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsfile = pm_file; %What is this?
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session.epi = EPI_file; %Which EPI file should I choose?
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'session';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0;
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = '';
matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;

spm_jobman('run', matlabbatch);
clear matlabbatch
end