function gbold_average_raw(participant_id)
% Average RAW (non z-scored) voxelwise gray-matter BOLD data for one participant
%
% This is the counterpart of gbold_average.m. That script averages the
% z-scored voxel time series; this one averages the raw voxel time series
% and therefore skips the z-scoring step entirely, taking its input
% directly from Raw_Signals instead of z_score_corrected.
%
% Input file:
%   /scratch/c7201319/SNORE_GM_Data/Raw_Signals/gbold_p<id>.mat
%
% Expected variable inside:
%   gbold_data{1}.voxelwise_signal   [Nvox x T]
%
% Output file:
%   /scratch/c7201319/SNORE_GM_Data/average_raw/gbold_p<id>_raw_average.mat
%
% Output variable inside:
%   mean_signal   [1 x T]
%
% Example:
%   gbold_average_raw(8)

if isnumeric(participant_id)
    participant_id = num2str(participant_id);
end

%% === Configuration ===
base_dir   = '/scratch/c7201319/SNORE_GM_Data';
input_dir  = fullfile(base_dir, 'Raw_Signals');
output_dir = fullfile(base_dir, 'average_raw');

%% === Build file paths from participant ID ===
in_file  = fullfile(input_dir,  sprintf('gbold_p%s.mat', participant_id));
out_file = fullfile(output_dir, sprintf('gbold_p%s_raw_average.mat', participant_id));

try
    if ~exist(in_file, 'file')
        error('Input file not found: %s', in_file);
    end

    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    %% === Load raw data ===
    S = load(in_file);

    if ~isfield(S, 'gbold_data') || isempty(S.gbold_data) || ...
       numel(S.gbold_data) < 1 || isempty(S.gbold_data{1})
        error('gbold_data{1} is missing or empty in %s', in_file);
    end

    if ~isfield(S.gbold_data{1}, 'voxelwise_signal')
        error('Field "voxelwise_signal" not found in gbold_data{1} of %s', in_file);
    end

    voxelwise_signal = S.gbold_data{1}.voxelwise_signal;

    if isempty(voxelwise_signal)
        error('voxelwise_signal is empty for participant %s', participant_id);
    end

    %% === Average across voxels (no z-scoring) ===
    % Matrix format is [Nvox x T], so the average is taken along dim 1.
    % Missing values are ignored rather than propagated, so that a few bad
    % voxels do not blank out the whole time series.
    nVox   = size(voxelwise_signal, 1);
    nNaN   = sum(any(isnan(voxelwise_signal), 2));
    if nNaN > 0
        fprintf(['Participant %s: %d of %d voxels contain NaN, ' ...
                 'these samples are omitted from the average.\n'], ...
                 participant_id, nNaN, nVox);
    end

    mean_signal = mean(voxelwise_signal, 1, 'omitnan');

    if all(isnan(mean_signal))
        error('Averaged signal is entirely NaN for participant %s', participant_id);
    end

    %% === Save output ===
    save(out_file, 'mean_signal', '-v7.3');

    fprintf('Saved raw averaged global BOLD signal for participant %s to:\n%s\n', ...
        participant_id, out_file);
    fprintf('  voxels = %d, timepoints = %d\n', nVox, numel(mean_signal));

catch ME
    fprintf('Error with participant %s: %s\n', participant_id, ME.message);
end
