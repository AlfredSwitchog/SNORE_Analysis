function gm_extract_signals(participant_id)
% Extract voxelwise gray-matter BOLD signal for one participant
% Output: gbold_data{subj}.voxelwise = [Nvox x T]

% Convert numeric input to string if necessary
if isnumeric(participant_id)
    participant_id_num = participant_id;
    participant_id = num2str(participant_id);
else
    participant_id_num = str2double(participant_id);
end

%% === Configuration ===

main_dir   = '/scratch/c7201319/SNORE_MR_out';
spm_path   = '/scratch/c7201319/spm12_dev';
output_dir = '/scratch/c7201319/SNORE_GM_Data/Raw_Signals';

addpath(spm_path);
fprintf('Using SPM from: %s\n', spm_path);

participant_path = fullfile(main_dir, participant_id);

try
    %% === Load functional file ===
    func_folder = fullfile(participant_path, 'preprocessing', 'highpass');
    func_file = dir(fullfile(func_folder, 'hp_s3brain_a_r*.nii'));

    if isempty(func_file)
        gz_func_file = dir(fullfile(func_folder, 'hp_s3brain_a_r*.nii.gz'));
        if isempty(gz_func_file)
            error('No functional file found for participant %s.', participant_id);
        end
        fprintf('Unzipping functional file: %s\n', gz_func_file(1).name);
        gunzip(fullfile(func_folder, gz_func_file(1).name));
        func_file = dir(fullfile(func_folder, 'hp_s3brain_a_r*.nii'));
    end

    img_file = fullfile(func_folder, func_file(1).name);

    %% === Load GM mask in EPI space ===
    mask_folder = fullfile(participant_path, 'GM_mask');
    mask_file = dir(fullfile(mask_folder, 'c1_in_func_space_bin_*.nii'));

    if isempty(mask_file)
        gz_mask_file = dir(fullfile(mask_folder, 'c1_in_func_space_bin_*.nii.gz'));
        if isempty(gz_mask_file)
            error('No GM mask file found for participant %s.', participant_id);
        end
        fprintf('Unzipping GM mask file: %s\n', gz_mask_file(1).name);
        gunzip(fullfile(mask_folder, gz_mask_file(1).name));
        mask_file = dir(fullfile(mask_folder, 'c1_in_func_space_bin_*.nii'));
    end

    mask_file_path = fullfile(mask_folder, mask_file(1).name);

    %% === Read volumes ===
    disp(['Trying to read functional file: ', img_file])
    V_img = spm_vol(img_file);

    disp(['Trying to read mask file: ', mask_file_path])
    V_mask = spm_vol(mask_file_path);
    mask_data = spm_read_vols(V_mask);

    n_timepoints = numel(V_img);

    %% === Get all GM voxel indices ===
    gm_voxel_idx = find(mask_data > 0);

    if isempty(gm_voxel_idx)
        error('GM mask is empty for participant %s.', participant_id);
    end

    n_voxels = numel(gm_voxel_idx);
    fprintf('Found %d GM voxels for participant %s\n', n_voxels, participant_id);

    %% === Extract voxelwise signals ===
    voxelwise_signals = zeros(n_voxels, n_timepoints);

    for t = 1:n_timepoints
        volume_data = spm_read_vols(V_img(t));
        voxelwise_signals(:, t) = volume_data(gm_voxel_idx);
    end

    %% === Store output ===
    gbold_data = cell(1,1);
    gbold_data{1}.participant_id = participant_id;
    gbold_data{1}.voxelwise_signal = voxelwise_signals;

    %% === Save results ===
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    out_file = fullfile(output_dir, sprintf('gbold_p%s.mat', participant_id));
    save(out_file, 'gbold_data', '-v7.3');

    fprintf('Saved global BOLD voxelwise signals for participant %s to %s\n', participant_id, out_file);

catch ME
    fprintf('Error with participant %s: %s\n', participant_id, ME.message);
end