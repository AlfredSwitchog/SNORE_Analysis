%% ============================================================
%  Descriptive statistics of the raw CSF signal, per slice
%  ------------------------------------------------------------
%  Builds one table with mean, SD, minimum and maximum of the CSF signal
%  for every participant and every slice, and appends the same statistics
%  for the group mean time series as a final block.
%
%  The SD column is the quantity of interest: the inflow effect shows up
%  as a larger SD in the bottom slice, decaying upwards. The mean column
%  is reported for completeness but is not a reliable indicator, because
%  it is influenced by tissue composition, partial volume and coil
%  sensitivity rather than by fluid movement.
%
%  Requires the Statistics and Machine Learning Toolbox is NOT needed here
%  (mean, std, min and max are base MATLAB).
%
%  1 TR = 1 volume = 2.5 s.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
dataDir   = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
filePat   = 'csf_p%d_averaged.mat';   % %d is replaced by the participant number
globPat   = 'csf_p*_averaged.mat';    % used when subjects is empty
signalVar = 'averaged_slices';        % T x nSlice, one column per slice

% Group mean file written by csf_create_group_mean_per_slice.m
groupMeanFile = ['/Users/Richard/Masterabeit_local/SNORE_CSF_Data/' ...
                 '20260813_Group_Average/csf_group_mean_per_slice.mat'];

% Participants in the table. [] = every file found in dataDir.
subjects = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

slices = 1:4;          % slices to report

treatZeroAsMissing = true;   % exact zeros are outside the mask, not data

saveCsv  = true;
plotRoot = '/Users/Richard/Masterabeit_local/SNORE_Plots/Inflow_Effect';
subDir   = 'signal_statistics_per_slice';
csvName  = 'csf_signal_statistics_per_slice.csv';

%% ---------------- OUTPUT FOLDER ----------------
outDir = fullfile(plotRoot, ...
                  sprintf('%s_Figures', char(datetime('now','Format','yyyyMMdd'))), ...
                  subDir);
if saveCsv && ~exist(outDir, 'dir'); mkdir(outDir); end

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

fprintf('\n========== CSF SIGNAL STATISTICS PER SLICE ==========\n');
fprintf('Data dir  : %s\n', dataDir);
fprintf('Group mean: %s\n', groupMeanFile);
fprintf('Output    : %s\n', fullfile(outDir, csvName));
fprintf('Subjects  : %d requested, slices %d-%d\n', ...
        numel(subjects), slices(1), slices(end));
fprintf('=====================================================\n\n');

%% ---------------- BUILD THE TABLE ----------------
who = strings(0,1); sl = []; mu = []; sd = []; mn = []; mx = [];

fprintf('%-12s %6s %10s %8s %10s %10s\n', 'Participant','slice','mean','SD','min','max');
fprintf('%s\n', repmat('-',1,60));

for N = subjects
    f = fullfile(dataDir, sprintf(filePat, N));
    if exist(f, 'file') ~= 2
        fprintf('P%-11d file not found -> skipped\n', N); continue
    end
    S = load(f, signalVar);
    if ~isfield(S, signalVar)
        fprintf('P%-11d no "%s" in file -> skipped\n', N, signalVar); continue
    end
    X = S.(signalVar);
    if size(X,1) < size(X,2); X = X.'; end     % time is the long dimension

    for s = slices
        if s > size(X,2); continue; end
        v = X(:, s);
        if treatZeroAsMissing; v(v == 0) = NaN; end
        v = v(isfinite(v));
        if isempty(v)
            fprintf('P%-11d %6d   no valid data\n', N, s); continue
        end
        who(end+1,1) = "P" + string(N);   %#ok<SAGROW>
        sl(end+1,1)  = s;                 %#ok<SAGROW>
        mu(end+1,1)  = mean(v);           %#ok<SAGROW>
        sd(end+1,1)  = std(v);            %#ok<SAGROW>
        mn(end+1,1)  = min(v);            %#ok<SAGROW>
        mx(end+1,1)  = max(v);            %#ok<SAGROW>
        fprintf('P%-11d %6d %10.2f %8.2f %10.2f %10.2f\n', ...
                N, s, mu(end), sd(end), mn(end), mx(end));
    end
end

%% ---------------- GROUP MEAN BLOCK ----------------
if exist(groupMeanFile, 'file') == 2
    L = load(groupMeanFile, 'group_mean');
    G = L.group_mean;
    fprintf('%s\n', repmat('-',1,60));
    for s = slices
        if s > size(G.mean_per_slice, 2); continue; end
        v = G.mean_per_slice(:, s);
        v = v(isfinite(v));
        if isempty(v); continue; end
        who(end+1,1) = "GroupMean";  %#ok<SAGROW>
        sl(end+1,1)  = s;            %#ok<SAGROW>
        mu(end+1,1)  = mean(v);      %#ok<SAGROW>
        sd(end+1,1)  = std(v);       %#ok<SAGROW>
        mn(end+1,1)  = min(v);       %#ok<SAGROW>
        mx(end+1,1)  = max(v);       %#ok<SAGROW>
        fprintf('%-12s %6d %10.2f %8.2f %10.2f %10.2f\n', ...
                'GroupMean', s, mu(end), sd(end), mn(end), mx(end));
    end
    fprintf('\nGroup mean built from %d participant(s), created %s\n', ...
            G.n_subjects, G.created);
else
    warning(['Group mean file not found:\n  %s\n' ...
             'Run csf_create_group_mean_per_slice.m first. ' ...
             'The table is written without the group mean block.'], groupMeanFile);
end

Tb = table(who, sl, mu, sd, mn, mx, ...
           'VariableNames', {'Participant','Slice','Mean','SD','Min','Max'});

%% ---------------- SAVE ----------------
fprintf('%s\n', repmat('-',1,60));
fprintf('%d row(s) in the table.\n', height(Tb));

if saveCsv
    writetable(Tb, fullfile(outDir, csvName));
    fprintf('Table saved to: %s\n', fullfile(outDir, csvName));
end
fprintf('\nDone.\n');
