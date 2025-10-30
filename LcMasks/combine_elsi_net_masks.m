% Combine left and right LC masks into a single binary mask per participant
% using SPM's spm_imcalc_ui (union: i1>0 | i2>0)

% === Input/Output folders ===
in_dir  = '/Users/Richard/Masterabeit_local/SNORE_LC-Masks/segmenter_output_orig_space';
out_dir = '/Users/Richard/Masterabeit_local/SNORE_LC-Masks/combined_elsi_masks';
if ~exist(out_dir, 'dir'), mkdir(out_dir); end

% === Add SPM to path ===
addpath('/Users/Richard/MatLAB/spm12_dev'); % adjust if needed
spm('Defaults','fmri'); spm_jobman('initcfg');

% === Find all left/right pairs ===
files = dir(fullfile(in_dir, '*_0_elsi.nii*'));  % left masks (0)
for f = 1:numel(files)
    % Get participant ID (before first underscore)
    [~, fname] = fileparts(files(f).name);
    pid = strtok(fname, '_');
    
    % Build corresponding right-mask name (1_)
    left_mask  = fullfile(in_dir, sprintf('%s_0_elsi.nii.gz', pid));
    right_mask = fullfile(in_dir, sprintf('%s_1_elsi.nii.gz', pid));
    if ~isfile(right_mask)
        warning('Missing right mask for participant %s, skipping.', pid);
        continue
    end
    
    % Output filename
    out_mask = fullfile(out_dir, sprintf('%s_combined_LCmask.nii', pid));

    % Run SPM image calculator (binary union)
    spm_imcalc<({left_mask, right_mask}, out_mask, 'i1>0 | i2>0', struct('dtype',2));
    
    fprintf('Participant %s → %s\n', pid, out_mask);
end

disp('All masks combined successfully.');
