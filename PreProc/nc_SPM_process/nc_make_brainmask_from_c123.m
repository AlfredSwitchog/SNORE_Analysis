function nc_make_brainmask_from_c123(t1_file, thr)
% make_brainmask_from_c123(t1_file, thr)
%
% t1_file : path to T1 that you want to skull-strip (bias-corrected or not)
% thr     : threshold for (c1+c2+c3); default = 0.2
%
% c1/c2/c3 are searched in the same folder via a pattern like:
%   ^c1MF.*\.nii$
% Adjust 'core_prefix' below if needed.
%
% Outputs:
%   brainmask_<T1>.nii  - binary brain mask
%   brain_<T1>.nii      - skull-stripped T1 using that mask

if nargin < 2 || isempty(thr)
    thr = 0.2;
end

if nargin < 1 || isempty(t1_file)
    error('Please provide the T1 file used for (or aligned to) the segmentation.');
end

[pth, nam, ext] = fileparts(t1_file);
if strcmp(ext, '.gz')
    error('Please unzip the T1 and c1/c2/c3 first (no .nii.gz).');
end

% Add SPM
spm_path = '/scratch/c7201319/spm12_dev';
addpath(spm_path)

% --- adjust this if your segmentations use another base prefix ---
core_prefix = 'MF';   % e.g. c1MFCR00TS... / c2MFCR00TS... / c3MFCR00TS...
% ---------------------------------------------------------------

% Build patterns for c1/c2/c3
pat_c1 = ['^c1' core_prefix '.*\.nii$'];
pat_c2 = ['^c2' core_prefix '.*\.nii$'];
pat_c3 = ['^c3' core_prefix '.*\.nii$'];

c1_list = spm_select('FPList', pth, pat_c1);
c2_list = spm_select('FPList', pth, pat_c2);
c3_list = spm_select('FPList', pth, pat_c3);

if isempty(c1_list) || isempty(c2_list) || isempty(c3_list)
    error('Could not find c1/c2/c3 files with patterns:\n  %s\n  %s\n  %s', ...
        pat_c1, pat_c2, pat_c3);
end

if size(c1_list,1) > 1 || size(c2_list,1) > 1 || size(c3_list,1) > 1
    error('More than one c1/c2/c3 file matched. Narrow the patterns.');
end

c1_file = strtrim(c1_list(1,:));
c2_file = strtrim(c2_list(1,:));
c3_file = strtrim(c3_list(1,:));

fprintf('Using:\n  %s\n  %s\n  %s\n', c1_file, c2_file, c3_file);

% Read volumes
V1 = spm_vol(c1_file);
V2 = spm_vol(c2_file);
V3 = spm_vol(c3_file);
VT = spm_vol(t1_file);

Y1 = spm_read_vols(V1);
Y2 = spm_read_vols(V2);
Y3 = spm_read_vols(V3);
YT = spm_read_vols(VT);

% Sum and threshold
Ysum = Y1 + Y2 + Y3;
mask = Ysum > thr;

% Write brain mask
Vmask       = VT;
Vmask.fname = fullfile(pth, ['brainmask_' nam ext]);
spm_write_vol(Vmask, mask);

% Apply mask to T1
YT_brain       = YT .* mask;
Vbrain         = VT;
Vbrain.fname   = fullfile(pth, ['brain_' nam ext]);
spm_write_vol(Vbrain, YT_brain);

fprintf('Created:\n  %s\n  %s\n', Vmask.fname, Vbrain.fname);
fprintf('Threshold used on (c1+c2+c3): %.3f\n', thr);
end
