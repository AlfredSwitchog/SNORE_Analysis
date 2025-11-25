function csf_extract_signals(participant_id)
% Extract CSF signal from the bottom slices for one participant
% Convert numeric input to string if necessary
if isnumeric(participant_id)
    participant_id = num2str(participant_id);
end
%% === Configuration ===
env = 'local';  % change to 'local' if testing locally
num_slices = 4;

switch lower(env)
    case 'local'
        main_dir   = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out';
        spm_path   = '/Users/Richard/MatLAB/spm12_dev';
        output_dir = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Data';
        script_dir = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/CSF_signal_extraction';
    case 'leo5_prod'
        main_dir   = '/scratch/c7201319/SNORE_MR_out';
        spm_path   = '/scratch/c7201319/spm12_dev';
        output_dir = '/scratch/c7201319/SNORE_CSF_Data/20251125_Raw_Signal';
        script_dir = '/scratch/c7201319/SNORE_Analysis/Analysis/CSF_signal_extraction';
    otherwise
        error('Unknown environment "%s".', env);
end

addpath(spm_path);
addpath(script_dir);
fprintf('Using SPM from: %s\n', spm_path);

participant_path = fullfile(main_dir, participant_id);


%% === Extract signal for the first n Slices ===

try
    %% === Load functional file ===
    func_folder = fullfile(participant_path, 'preprocessing/highpass');
    func_file = dir(fullfile(func_folder, 'hp_s3a_brain_r*.nii'));

    if isempty(func_file)
        gz_func_file = dir(fullfile(func_folder, 'hp_s3a_brain_r*.nii.gz'));
        if isempty(gz_func_file)
            error('No functional file found for participant %s.', participant_id);
        end
        fprintf('Unzipping functional file: %s\n', gz_func_file(1).name);
        gunzip(fullfile(func_folder, gz_func_file(1).name));
        func_file = dir(fullfile(func_folder, 'hp_s3a_brain_r*.nii'));
    end

    img_file = fullfile(func_folder, func_file(1).name);

    %% === Load CSF mask ===
    mask_folder = fullfile(participant_path, 'CSF_mask');
    all_files = dir(fullfile(mask_folder, '*pruned*.nii'));
    % Filter out files that start with '.' --> necessary bc macOS creates
    % metadat files (anoying)
    mask_file = all_files(~startsWith({all_files.name}, '.'));

    if isempty(mask_file)
        gz_mask_file = dir(fullfile(mask_folder, '*pruned*.nii.gz'));
        gz_mask_file = gz_mask_file(~startsWith({gz_mask_file.name}, '._'));
        if isempty(gz_mask_file)
            error('No CSF mask file found for participant %s.', participant_id);
        end
        fprintf('Unzipping CSF mask file: %s\n', gz_mask_file(1).name);
        gunzip(fullfile(mask_folder, gz_mask_file(1).name));
        mask_file = dir(fullfile(mask_folder, '*pruned*.nii'));
    end

    mask_file_path = fullfile(mask_folder, mask_file(1).name);

    %% === Read volumes ===
    disp(['Trying to read: ', img_file])
    V_img = spm_vol(img_file);
    disp(['Trying to read: ', mask_file_path])
    V_mask = spm_vol(mask_file_path);
    mask_data = spm_read_vols(V_mask);
    n_timepoints = numel(V_img);

    %% === Extract CSF signals ===
    slice_data_struct = struct();
    max_slices = size(mask_data, 3);
    slices_to_extract = min(num_slices, max_slices);

    for slice_idx = 1:slices_to_extract
        mask_slice = mask_data(:,:,slice_idx);
        csf_voxel_idx = find(mask_slice);

        if isempty(csf_voxel_idx)
            fprintf('Slice %d: No CSF voxels\n', slice_idx);
            slice_data_struct(slice_idx).signals = [];
            continue;
        end

        csf_signals = zeros(length(csf_voxel_idx), n_timepoints);

        for t = 1:n_timepoints
            volume_data = spm_read_vols(V_img(t));
            slice_data = volume_data(:,:,slice_idx);
            voxel_values = slice_data(csf_voxel_idx);
            csf_signals(:,t) = voxel_values;
        end

        slice_data_struct(slice_idx).signals = csf_signals;
    end

    %% === Save results ===
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    out_file = fullfile(output_dir, sprintf('csf_p%s.mat', participant_id));
    save(out_file, 'slice_data_struct');
    fprintf('Saved CSF signals for participant %s to %s\n', participant_id, out_file);

catch ME
    fprintf('Error with participant %s: %s\n', participant_id, ME.message);
end



