function gbold_z_score_correct(participant_id)
% Z-score correct voxelwise gray-matter BOLD data for one participant
%
% Input file:
%   /scratch/c7201319/SNORE_GM_Data/Raw_Signals/gbold_p<id>.mat
%
% Expected variable inside:
%   gbold_data{1}.participant_id
%   gbold_data{1}.voxelwise_signal   [Nvox x T]
%
% Output file:
%   /scratch/c7201319/SNORE_GM_Data/z_score_corrected/gbold_p<id>_z_score_corrected.mat
%
% Output variable inside:
%   gbold_data{1}.participant_id
%   gbold_data{1}.voxelwise_z        [Nvox x T]
%
% Example:
%   gbold_z_score_correct(8)

% Convert numeric input to string if necessary
if isnumeric(participant_id)
    participant_id = num2str(participant_id);
end

%% === Configuration ===
base_dir   = '/scratch/c7201319/SNORE_GM_Data';
input_dir  = fullfile(base_dir, 'Raw_Signals');
output_dir = fullfile(base_dir, 'z_score_corrected');

%% === Build file paths from participant ID ===
in_file  = fullfile(input_dir,  sprintf('gbold_p%s.mat', participant_id));
out_file = fullfile(output_dir, sprintf('gbold_p%s_z_score_corrected.mat', participant_id));

try
    %% === Check input ===
    if ~exist(in_file, 'file')
        error('Input file not found: %s', in_file);
    end

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    %% === Load raw data ===
    S = load(in_file);

    if isempty(S.gbold_data) || numel(S.gbold_data) < 1 || isempty(S.gbold_data{1})
        error('gbold_data{1} is missing or empty in %s', in_file);
    end

    voxelwise_signal = S.gbold_data{1}.voxelwise_signal;

    if isempty(voxelwise_signal)
        error('voxelwise_signal is empty for participant %s', participant_id);
    end

    %% === Z-score across time for each voxel ===
    % Matrix format is [Nvox x T]
    % Therefore z-score must be calculated along dimension 2
    voxelwise_z = zscore(voxelwise_signal, 0, 2);

    % Flat voxels (std = 0) become NaN -> set to 0
    voxelwise_z(isnan(voxelwise_z)) = 0;

    %% === Save output ===
    save(out_file, 'voxelwise_z', '-v7.3');

    fprintf('Saved z-score corrected data for participant %s to:\n%s\n', ...
        participant_id, out_file);

catch ME
    fprintf('Error with participant %s: %s\n', participant_id, ME.message);
end