%% ============================================================
%  Group-level mean CSF time series per slice
%  ------------------------------------------------------------
%  Computes the group mean ONCE and saves it. Plotting scripts only load
%  the result, so the average cannot silently change between figures.
%
%  Input: one file per participant, each holding a T x nSlice matrix,
%  where T is the number of volumes of that participant's run. T differs
%  between participants, so the time series cannot simply be averaged
%  element by element.
%
%  Handling of unequal run lengths: the participants are collected in a
%  matrix in which shorter runs are padded with NaN at the end, and the
%  mean at each time point is taken over those participants who still
%  have data there ('omitnan'). Early time points are therefore averaged
%  over more participants than late ones. The number of contributing
%  participants at each time point is stored alongside the mean, so that
%  any figure can show it. No interpolation and no truncation is applied,
%  which keeps all available data and gives a group mean of maximal
%  length.
%
%  Output: <outRoot>/<yyyymmdd>_Group_Average/csf_group_mean_per_slice.mat
%  Running again on the same day overwrites the previous result.
%
%  1 TR = 1 volume = 2.5 s.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
dataDir   = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
filePat   = 'csf_p%d_averaged.mat';   % %d is replaced by the participant number
globPat   = 'csf_p*_averaged.mat';    % used when subjects is empty
signalVar = 'averaged_slices';        % T x nSlice, one column per slice

% Participants entering the group mean.
% [] = every csf_p*_averaged.mat found in dataDir.
% Otherwise an explicit list of participant numbers. This is the list that
% defines the sample, so it should be stated in the thesis alongside it.
subjects = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

TR      = 2.5;    % seconds per volume

outRoot = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data';
outFile = 'csf_group_mean_per_slice.mat';

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

fprintf('\n============ GROUP MEAN CSF SIGNAL PER SLICE ============\n');
fprintf('Data dir  : %s\n', dataDir);
fprintf('Output    : %s\n', fullfile(outDir, outFile));
fprintf('Requested : %d participant(s)\n\n', numel(subjects));

sigs = {}; usedID = [];
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

    sigs{end+1}   = X;   %#ok<SAGROW>
    usedID(end+1) = N;   %#ok<SAGROW>
end

nSub = numel(sigs);
assert(nSub > 0, 'No participant data could be loaded from %s', dataDir);

missing = setdiff(subjects, usedID);
if ~isempty(missing)
    warning('Not included: %s', strjoin("P" + string(missing), ', '));
end

nSlice = size(sigs{1}, 2);
lens   = cellfun(@(x) size(x,1), sigs);
T      = max(lens);

fprintf('\nIncluded  : %d participant(s)\n', nSub);
fprintf('Slices    : %d\n', nSlice);
fprintf('Run length: %d..%d volumes  (%.1f..%.1f min)\n', ...
        min(lens), max(lens), min(lens)*TR/60, max(lens)*TR/60);

%% ---------------- PAD AND AVERAGE ----------------
% nSub x T x nSlice, NaN wherever a participant's run has already ended
M = nan(nSub, T, nSlice);
for i = 1:nSub
    M(i, 1:lens(i), :) = sigs{i};
end

meanPerSlice  = squeeze(mean(M, 1, 'omitnan'));   % T x nSlice
nContributors = squeeze(sum(~isnan(M), 1));       % T x nSlice

%% ---------------- SAVE ----------------
group_mean = struct( ...
    'mean_per_slice',  meanPerSlice, ...     % T x nSlice
    'n_contributors',  nContributors, ...    % T x nSlice
    'participants',    usedID, ...
    'n_subjects',      nSub, ...
    'run_lengths',     lens, ...
    'n_slices',        nSlice, ...
    'n_timepoints',    T, ...
    'TR',              TR, ...
    'source_dir',      string(dataDir), ...
    'signal_var',      string(signalVar), ...
    'created',         string(datetime('now')));

save(fullfile(outDir, outFile), 'group_mean', '-v7.3');

%% ---------------- SUMMARY ----------------
fprintf('\n%-8s %10s %8s %10s %10s\n', 'slice','mean','SD','min','max');
fprintf('%s\n', repmat('-',1,50));
for s = 1:nSlice
    v = meanPerSlice(:,s); v = v(~isnan(v));
    fprintf('slice %-2d %10.2f %8.2f %10.2f %10.2f\n', ...
            s, mean(v), std(v), min(v), max(v));
end
fprintf('%s\n', repmat('-',1,50));
fprintf('The SD column is the inflow gradient: largest in slice 1 and\n');
fprintf('decreasing towards slice %d.\n', nSlice);
fprintf('Contributors: %d at the start, %d at the end.\n', ...
        nContributors(1,1), nContributors(end,1));
fprintf('\nSaved to: %s\n\nDone.\n', fullfile(outDir, outFile));
