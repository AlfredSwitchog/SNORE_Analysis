function gbold_average(participant_id)
% Average z-scored voxelwise gray-matter BOLD data for one participant
%
% Input file:
%   /scratch/c7201319/SNORE_GM_Data/z_score_corrected/gbold_p<id>_z_score_corrected.mat
%
% Expected variable inside:
%   voxelwise_z   [Nvox x T]
%
% Output file:
%   /scratch/c7201319/SNORE_GM_Data/average/gbold_p<id>_z_average.mat
%
% Output variable inside:
%   mean_signal   [1 x T]
%
% Example:
%   gbold_average(8)

if isnumeric(participant_id)
    participant_id = num2str(participant_id);
end

%% === Configuration ===
base_dir   = '/scratch/c7201319/SNORE_GM_Data';
%base_dir   = '/Users/Richard/Masterabeit_local/SNORE_GM_Data';
input_dir  = fullfile(base_dir, 'z_score_corrected');
output_dir = fullfile(base_dir, 'average');

%% === Build file paths from participant ID ===
in_file  = fullfile(input_dir,  sprintf('gbold_p%s_z_score_corrected.mat', participant_id));
out_file = fullfile(output_dir, sprintf('gbold_p%s_z_average.mat', participant_id));

try
    if ~exist(in_file, 'file')
        error('Input file not found: %s', in_file);
    end

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    %% === Load z-scored data ===
    S = load(in_file);

    if ~isfield(S, 'voxelwise_z')
        error('Variable "voxelwise_z" not found in %s', in_file);
    end

    voxelwise_z = S.voxelwise_z;

    if isempty(voxelwise_z)
        error('voxelwise_z is empty for participant %s', participant_id);
    end

    %% === Average across voxels ===
    mean_signal = mean(voxelwise_z, 1);

    %% === Save output ===
    save(out_file, 'mean_signal', '-v7.3');

    fprintf('Saved averaged global BOLD signal for participant %s to:\n%s\n', ...
        participant_id, out_file);

catch ME
    fprintf('Error with participant %s: %s\n', participant_id, ME.message);
end