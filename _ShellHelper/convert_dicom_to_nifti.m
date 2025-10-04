function convert_nm_to_nii(participants)
% Minimal DICOM -> NIfTI per participant using SPM
if nargin==0, participants=1; end

base_in  = '/scratch/c7201319/SNORE_MR';
rel_dir  = 'Day/MR gre3d_MTC_TR45_fast_BW130_try_ND';
base_out = '/scratch/c7201319/SNORE_MRI_data_dev_out';
out_sub  = 'T1_slab';  out_name = 't1slab_orig';

addpath('/scratch/c7201319/spm12_dev'); spm('Defaults','fmri'); spm_jobman('initcfg');

for pid = participants(:)'
    in_dir  = fullfile(base_in, num2str(pid), rel_dir);
    out_dir = fullfile(base_out, num2str(pid), out_sub); if ~exist(out_dir,'dir'), mkdir(out_dir); end
    files   = cellstr(spm_select('FPList', in_dir, '.*\.dcm$'));  % pick DICOMs (assume present)
    hdr     = spm_dicom_headers(files);
    c       = spm_dicom_convert(hdr,'all','flat','nii',out_dir);  % write NIfTI(s)
    src     = c.files{1};                                        % assume first is the slab
    dest    = fullfile(out_dir,[out_name '.nii']);
    if exist(dest,'file'), delete(dest); end, movefile(src,dest,'f'); gzip(dest); delete(dest);
    fprintf('ID %d -> %s\n', pid, fullfile(out_dir,[out_name '.nii.gz']));
end
end