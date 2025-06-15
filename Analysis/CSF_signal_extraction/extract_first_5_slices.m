%% === Configuration ===
% Set environment: 'local' or 'leo5_prod'
    env = 'leo5_prod';  % <-- Change this to the appropriate environment
    
    if strcmpi(env, 'local')
        scriptpath  = '/Users/Richard/Masterabeit_local/Scripts/SNORE_PreProc';
        main_dir = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out';
        output_dir = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Data';
        spm_path    = '/Users/Richard/MatLAB/spm12_dev';
    
    elseif strcmpi(env, 'leo5_prod')
        scriptpath  = '/scratch/c7201319/SNORE_Analysis/Analysis/CSF_signal_extraction';
        main_dir = '/scratch/c7201319/SNORE_MR_out';
        output_dir  = '/scratch/c7201319/SNORE_Analysis/Data';
        spm_path    = '/scratch/c7201319/spm12_dev';
    
    else
        error('Unknown environment "%s". Choose from: local, leo5_prod.', env);
    end

% Testmode toggle and number of slice that are extracted    
test_mode = true;  % Set to false to run all participants
num_slices = 20;

if test_mode
    participant_ids = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10'}; % select individual participant dirs
else
    % Get all subfolders (excluding hidden/system dirs)
    dirs = dir(main_dir);
    participant_ids = {dirs([dirs.isdir] & ~startsWith({dirs.name}, '.')).name};
end

%% Add SPM and Script to Path
% Add SPM
addpath(spm_path)
fprintf('SPM used: %s\n', spm_path);

% Add scriptpath
addpath([scriptpath]);

%% === Extract signal for the first n Slices ===

% === Initialize result structure ===
csf_dataset = struct();

for i = 1:length(participant_ids)
    participant_id = participant_ids{i}; %index first value of participant ids
    participant_path = fullfile(main_dir, participant_id);

    try
        % === Identify and unzip functional file if necessary ===
        func_folder = fullfile(participant_path, 'func_merged');
        func_file = dir(fullfile(func_folder, 'merged_*.nii'));
        
        if isempty(func_file)
            % Check for .nii.gz
            gz_func_file = dir(fullfile(func_folder, 'merged_*.nii.gz'));
            
            if isempty(gz_func_file)
                fprintf('Skipping participant %s: No functional file found.\n', participant_id);
                continue;
            end
            
            % Unzip .nii.gz
            fprintf('Participant %s: Unzipping functional file %s...\n', participant_id, gz_func_file(1).name);
            gunzip(fullfile(func_folder, gz_func_file(1).name));  % Unzips in place
            
            % Retry finding the .nii file
            func_file = dir(fullfile(func_folder, 'merged_*.nii'));
            
            if isempty(func_file)
                fprintf('Participant %s: Unzipped functional file not found.\n', participant_id);
                continue;
            end
        end
        
        img_file = fullfile(func_folder, func_file(1).name);
        
        % === Identify and unzip CSF mask file if necessary ===
        mask_folder = fullfile(participant_path, 'CSF_mask');
        mask_file = dir(fullfile(mask_folder, '*pruned*.nii'));
        
        if isempty(mask_file)
            % Check for .nii.gz
            gz_mask_file = dir(fullfile(mask_folder, '*pruned*.nii.gz'));
            % Filter out files that start with a dot
            gz_mask_file = gz_mask_file(~startsWith({gz_mask_file.name}, '._'));

            
            if isempty(gz_mask_file)
                fprintf('Skipping participant %s: No CSF mask file found.\n', participant_id);
                continue;
            end
            
            % Unzip .nii.gz
            fprintf('Participant %s: Unzipping CSF mask file %s...\n', participant_id, gz_mask_file(1).name);
            gunzip(fullfile(mask_folder, gz_mask_file(1).name));
            
            % Retry finding the .nii file
            mask_file = dir(fullfile(mask_folder, '*pruned*.nii'));
            
            if isempty(mask_file)
                fprintf('Participant %s: Unzipped CSF mask file not found.\n', participant_id);
                continue;
            end
        end
        
        mask_file_path = fullfile(mask_folder, mask_file(1).name);


        % === Load image and mask ===
        V_img = spm_vol(img_file);
        V_mask = spm_vol(mask_file_path);
        mask_data = spm_read_vols(V_mask);
        n_timepoints = numel(V_img);

        % === Initialize slice struct ===
        slice_data_struct = struct();

        for slice_idx = 1:num_slices
            mask_slice = mask_data(:,:,slice_idx);
            csf_voxel_idx = find(mask_slice);

            if isempty(csf_voxel_idx)
                fprintf('Participant %s - Slice %d: No CSF voxels\n', participant_id, slice_idx);
                slice_data_struct(slice_idx).signals = [];
                continue;
            end

            % Extract signal across time
            csf_signals = zeros(length(csf_voxel_idx), n_timepoints);

            for t = 1:n_timepoints
                volume_data = spm_read_vols(V_img(t));
                slice_data = volume_data(:,:,slice_idx);
                voxel_values = slice_data(csf_voxel_idx);
                csf_signals(:,t) = voxel_values;
            end

            % Store per slice
            slice_data_struct(slice_idx).signals = csf_signals;
        end

        % === Store in result structure ===
        csf_dataset.(sprintf('p%s', participant_id)) = slice_data_struct;
        fprintf('Extracted CSF signals for participant %s\n', participant_id);

    catch ME
        fprintf('Error with participant %s: %s\n', participant_id, ME.message);
    end
end

%% ====== Save data ========
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

save(fullfile(output_dir, 'csf_first_20_slices.mat'), 'csf_dataset');


