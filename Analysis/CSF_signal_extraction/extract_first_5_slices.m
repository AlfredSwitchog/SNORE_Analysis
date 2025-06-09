% === Setup ===
root_dir = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/';
%participant_dirs = dir(fullfile(root_dir, '*'));
%participant_dirs = participant_dirs([participant_dirs.isdir] & ~startsWith({participant_dirs.name}, '.'));

csf_dataset = struct();  % Final output

target_id = '7';
participant_dirs = dir(fullfile(root_dir, '*'));
participant_dirs = participant_dirs([participant_dirs.isdir] & strcmp({participant_dirs.name}, target_id));
%%
for i = 1:length(participant_dirs)
    participant_id = participant_dirs(i).name;

    try
        % === Construct file paths ===
        img_file  = fullfile(root_dir, participant_id, 'filt_preproc_out', 'merged_s3uaMFAN99SC020724.nii');
        mask_file = fullfile(root_dir, participant_id, 'coreg_new', 'c3_pruned_MFAN99SC020724_in_func_space_bin.nii');

        if ~exist(img_file, 'file') || ~exist(mask_file, 'file')
            fprintf('Skipping %s: Missing file(s)\n', participant_id);
            continue;
        end

        % === Load image and mask ===
        V_img = spm_vol(img_file);
        V_mask = spm_vol(mask_file);
        mask_data = spm_read_vols(V_mask);
        n_timepoints = numel(V_img);

        % === Initialize slice struct ===
        slice_data_struct = struct();

        for slice_idx = 1:5
            mask_slice = mask_data(:,:,slice_idx);
            csf_voxel_idx = find(mask_slice);

            if isempty(csf_voxel_idx)
                fprintf('Participant %s - Slice %d: No CSF voxels\n', participant_id, slice_idx);
                slice_data_struct(slice_idx).signals = [];  % Store empty matrix
                continue;
            end

            % Extract signal across time
            csf_signals = zeros(length(csf_voxel_idx), n_timepoints);

            for t = 1:n_timepoints
                volume_data = spm_read_vols(V_img(t));
                slice_data = volume_data(:,:,slice_idx);
                voxel_values = slice_data(csf_voxel_idx);
                voxel_values(voxel_values == 0) = NaN;
                csf_signals(:,t) = voxel_values;
            end

            % Store per slice
            slice_data_struct(slice_idx).signals = csf_signals;
        end

        % === Save participant's slice data ===
        csf_dataset.(participant_id) = slice_data_struct;
        fprintf('Extracted CSF signals for participant %s\n', participant_id);

    catch ME
        fprintf('Error with participant %s: %s\n', participant_id, ME.message);
    end
end

% === Save the full dataset ===
save('csf_raw_signals_by_slice.mat', 'csf_dataset');
