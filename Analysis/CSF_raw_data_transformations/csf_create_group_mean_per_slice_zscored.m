%% ============================================================
%  Group-level mean of the z-scored CSF time series per slice
%  ------------------------------------------------------------
%  Same sample, input and averaging as csf_create_group_mean_per_slice.m,
%  but every participant's time series is z-scored before it enters the
%  group mean, so that participants with high signal levels or large
%  signal swings do not dominate the average.
%
%  Z-scoring ("naive" variant): for each participant and each slice
%  separately, the voxel-averaged time series (T x 1) is centred on its
%  own temporal mean and divided by its own temporal SD:
%
%      z(t) = (x(t) - mean_t x) / SD_t x
%
%  Every slice of every participant therefore has mean 0 and SD 1 over
%  its run. Consequence: amplitude differences BETWEEN slices are removed
%  as well, so the inflow gradient (slice 1 > 2 > 3 > 4) cannot show up in
%  the amplitude of this group mean; only the shape and timing of the
%  fluctuations remain comparable across slices.
%
%  Z-scoring is done on each participant's own run BEFORE NaN padding,
%  so the padding never enters the mean or SD. Unequal run lengths are
%  then handled exactly as in csf_create_group_mean_per_slice.m (NaN
%  padding, mean over the participants with data at each time point).
%
%  Output: <outRoot>/<yyyymmdd>_Group_Average/csf_group_mean_per_slice_zscored.mat
%  The saved struct is called group_mean and has the same fields as the
%  raw version, plus the per-participant means and SDs used for z-scoring.
%  Running again on the same day overwrites the previous result.
%
%  1 TR = 1 volume = 2.5 s.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
% Keep identical to csf_create_group_mean_per_slice.m so that the raw and
% the z-scored group mean are based on the same sample.
dataDir   = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
filePat   = 'csf_p%d_averaged.mat';   % %d is replaced by the participant number
globPat   = 'csf_p*_averaged.mat';    % used when subjects is empty
signalVar = 'averaged_slices';        % T x nSlice, one column per slice

% [] = every csf_p*_averaged.mat found in dataDir, otherwise an explicit list.
subjects = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

TR      = 2.5;    % seconds per volume

outRoot = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data';
outFile = 'csf_group_mean_per_slice_zscored.mat';

%% ---------------- OUTPUT FOLDER ----------------
outDir = fullfile(outRoot, ...
                  sprintf('%s_Group_Average', char(datetime('now','Format','yyyyMMdd'))));
if ~exist(outDir, 'dir'); mkdir(outDir); end

%% ---------------- COLLECT PARTICIPANTS ----------------
if isempty(subjects)
    D = dir(fullfile(dataDir, globPat));
    subjects = [];
    for i = 1:numel(D)
        tok = regexp(D(i).name, 'p(\d+)_', 'tokens', 'once');
        if ~isempty(tok); subjects(end+1) = str2double(tok{1}); end %#ok<SAGROW>
    end
    subjects = sort(subjects);
end
subjects = subjects(:).';

fprintf('\n======= GROUP MEAN Z-SCORED CSF SIGNAL PER SLICE =======\n');
fprintf('Data dir  : %s\n', dataDir);
fprintf('Output    : %s\n', fullfile(outDir, outFile));
fprintf('Requested : %d participant(s)\n\n', numel(subjects));

sigsZ = {}; usedID = []; muP = []; sdP = [];
for N = subjects
    f = fullfile(dataDir, sprintf(filePat, N));
    if exist(f, 'file') ~= 2
        fprintf('  P%-4d file not found -> skipped\n', N);
        continue
    end
    S = load(f, signalVar);
    if ~isfield(S, signalVar)
        fprintf('  P%-4d no "%s" in file -> skipped\n', N, signalVar);
        continue
    end
    X = S.(signalVar);
    if size(X,1) < size(X,2); X = X.'; end     % time is the long dimension

    if all(isnan(X(:)))
        fprintf('  P%-4d signal is entirely NaN -> skipped\n', N);
        continue
    end

    % --- z-score each slice over time (column-wise), NaN-safe ---
    mu = mean(X, 1, 'omitnan');         % 1 x nSlice, temporal mean per slice
    sd = std(X, 0, 1, 'omitnan');       % 1 x nSlice, temporal SD per slice (n-1)
    if any(~(sd > 0))
        fprintf('  P%-4d zero or undefined SD in slice(s) %s -> skipped\n', ...
                N, mat2str(find(~(sd > 0))));
        continue
    end
    Xz = (X - mu) ./ sd;

    sigsZ{end+1}  = Xz;  %#ok<SAGROW>
    usedID(end+1) = N;   %#ok<SAGROW>
    muP(end+1,:)  = mu;  %#ok<SAGROW>
    sdP(end+1,:)  = sd;  %#ok<SAGROW>
end

nSub = numel(sigsZ);
assert(nSub > 0, 'No participant data could be loaded from %s', dataDir);

missing = setdiff(subjects, usedID);
if ~isempty(missing)
    warning('Not included: %s', strjoin("P" + string(missing), ', '));
end

nSlice = size(sigsZ{1}, 2);
lens   = cellfun(@(x) size(x,1), sigsZ);
T      = max(lens);

fprintf('\nIncluded  : %d participant(s)\n', nSub);
fprintf('Slices    : %d\n', nSlice);
fprintf('Run length: %d..%d volumes  (%.1f..%.1f min)\n', ...
        min(lens), max(lens), min(lens)*TR/60, max(lens)*TR/60);

%% ---------------- PAD AND AVERAGE ----------------
% nSub x T x nSlice, NaN wherever a participant's run has already ended
M = nan(nSub, T, nSlice);
for i = 1:nSub
    M(i, 1:lens(i), :) = sigsZ{i};
end

meanPerSlice  = squeeze(mean(M, 1, 'omitnan'));   % T x nSlice
nContributors = squeeze(sum(~isnan(M), 1));       % T x nSlice

%% ---------------- SAVE ----------------
group_mean = struct( ...
    'mean_per_slice',   meanPerSlice, ...     % T x nSlice, mean of z-scores
    'n_contributors',   nContributors, ...    % T x nSlice
    'participants',     usedID, ...
    'n_subjects',       nSub, ...
    'run_lengths',      lens, ...
    'n_slices',         nSlice, ...
    'n_timepoints',     T, ...
    'TR',               TR, ...
    'normalisation',    "zscore per participant and slice over time", ...
    'participant_mean', muP, ...              % nSub x nSlice, raw temporal mean
    'participant_sd',   sdP, ...              % nSub x nSlice, raw temporal SD
    'source_dir',       string(dataDir), ...
    'signal_var',       string(signalVar), ...
    'created',          string(datetime('now')));

save(fullfile(outDir, outFile), 'group_mean', '-v7.3');

%% ---------------- SUMMARY ----------------
fprintf('\nRaw temporal SD per participant (scale that was divided out):\n');
fprintf('%-8s %10s %10s %10s\n', 'slice','median','min','max');
fprintf('%s\n', repmat('-',1,40));
for s = 1:nSlice
    fprintf('slice %-2d %10.2f %10.2f %10.2f\n', ...
            s, median(sdP(:,s)), min(sdP(:,s)), max(sdP(:,s)));
end

fprintf('\nGroup mean of the z-scored signal:\n');
fprintf('%-8s %10s %8s %10s %10s\n', 'slice','mean','SD','min','max');
fprintf('%s\n', repmat('-',1,50));
for s = 1:nSlice
    v = meanPerSlice(:,s); v = v(~isnan(v));
    fprintf('slice %-2d %10.2f %8.2f %10.2f %10.2f\n', ...
            s, mean(v), std(v), min(v), max(v));
end
fprintf('%s\n', repmat('-',1,50));
fprintf('Contributors: %d at the start, %d at the end.\n', ...
        nContributors(1,1), nContributors(end,1));
fprintf('\nSaved to: %s\n\nDone.\n', fullfile(outDir, outFile));
