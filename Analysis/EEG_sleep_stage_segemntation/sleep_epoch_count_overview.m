%% ============================================================
%  Sleep epoch / TR overview for every scored participant
%  ------------------------------------------------------------
%  Scans every EEG scoring file in eegDir and reports, per
%  participant and per sleep stage (and per combined stage set):
%
%     Ep_<stage>  = number of stable epochs  (maximal runs of
%                   consecutive TRs in that stage, length >= minTR)
%     TR_<stage>  = total TRs contained in those epochs
%                   (i.e. the length of the concatenated signal that
%                    segment_stable_sleep_epochs.m would produce)
%
%  Each hypnogram is TRUNCATED to the fMRI run length first
%  (L = min(fMRI, EEG)), so the numbers match what
%  segment_stable_sleep_epochs.m actually extracts.
%  Participants without a signal file are still listed, flagged in
%  Status, and counted over the full EEG length.
%
%  Combined sets (e.g. NREM2+NREM3) allow an epoch to span the stage
%  boundary, exactly like the segmentation script's combined mode.
%
%  Output: one .xlsx  (sheet "Epochs", plus optional sheet "Summary")
%
%  1 TR = 1 fMRI volume = 2.5 s.
% ============================================================

%% ---------------- CONFIG ----------------
eegDir    = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
eegPat    = 'P*_sleep_stage_per_TR.mat';

% fMRI signal folder, used ONLY to get each run's length for truncation
signalDir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
signalPat = 'csf_p*_averaged.mat';
signalVar = 'averaged_slices';

TR     = 2.5;    % seconds per TR/volume
minTR  = 36;     % >= 36 TRs (= 90 s) to qualify as a stable epoch

% Individual stages -> one Ep_/TR_ column pair each
stages = ["Wake","NREM1","NREM2","NREM3","REM"];

% Combined sets -> epochs may run across the stage boundary
combos = { ["NREM2","NREM3"], ["NREM1","NREM2","NREM3"] };

outDir  = '/Users/Richard/Masterabeit_local/SNORE_Tables/Sleep_Scoring/';
outFile = '';    % '' = auto: sleep_epoch_overview_<timestamp>.xlsx

writeSummary = false;   % add a group-level "Summary" sheet

%% ---------------- BUILD THE COLUMN SETS ----------------
sets = {};
for s = 1:numel(stages)
    sets{end+1} = struct('label', shortName(stages(s)), ...
                         'stages', stages(s)); %#ok<SAGROW>
end
for c = 1:numel(combos)
    cs = string(combos{c}(:)).';
    sets{end+1} = struct('label', setLabel(cs), 'stages', cs); %#ok<SAGROW>
end
setLabels = strings(1, numel(sets));
for k = 1:numel(sets); setLabels(k) = sets{k}.label; end
assert(numel(unique(setLabels)) == numel(setLabels), ...
       'Duplicate stage-set label(s): %s', strjoin(setLabels, ', '));

fprintf('\nEEG folder : %s\n', eegDir);
fprintf('Epoch rule : >= %d TR (%.1f s), TR = %.2f s\n', minTR, minTR*TR, TR);
fprintf('Columns    : %s\n\n', strjoin(setLabels, ', '));

%% ---------------- INDEX THE SIGNAL FILES ----------------
sigMap = containers.Map('KeyType','double','ValueType','char');
S = dir(fullfile(signalDir, signalPat));
for i = 1:numel(S)
    tok = regexp(S(i).name, 'p(\d+)', 'tokens', 'once');
    if isempty(tok); continue; end
    sigMap(str2double(tok{1})) = fullfile(S(i).folder, S(i).name);
end
fprintf('Indexed %d signal file(s) for length truncation.\n', sigMap.Count);
if sigMap.Count == 0
    warning(['No signal files matched "%s" in %s -- every participant will be ' ...
             'counted over the FULL EEG length, which will not match the ' ...
             'segmentation output.'], signalPat, signalDir);
end

%% ---------------- SCAN THE SCORING FILES ----------------
E = dir(fullfile(eegDir, eegPat));
assert(~isempty(E), 'No files matching "%s" in %s', eegPat, eegDir);
fprintf('Found %d scoring file(s).\n\n', numel(E));

fprintf('%-7s %8s %8s %8s   %s\n', 'Subj','fMRI','EEG','aligned','status');
fprintf('%s\n', repmat('-',1,70));

rows = [];
for i = 1:numel(E)
    tok = regexp(E(i).name, '^P(\d+)_', 'tokens', 'once');
    if isempty(tok); warning('No P<num> in %s, skipped.', E(i).name); continue; end
    N = str2double(tok{1});

    % ---- labels ----
    Es = load(fullfile(E(i).folder, E(i).name));
    if isfield(Es,'stage_per_TR')
        lab = string(Es.stage_per_TR(:));
    elseif isfield(Es,'time_TR')
        lab = strings(numel(Es.time_TR),1);
    else
        warning('%s has neither stage_per_TR nor time_TR, skipped.', E(i).name); continue
    end
    K = numel(lab);

    % ---- fMRI length -> truncation ----
    status = '';
    if isKey(sigMap, N)
        Sg = load(sigMap(N), signalVar);
        if ~isfield(Sg, signalVar)
            error('No "%s" in %s', signalVar, sigMap(N));
        end
        X  = Sg.(signalVar);
        if size(X,1) < size(X,2); X = X.'; end
        T  = size(X,1);
        L  = min(T, K);
        if T ~= K; status = sprintf('len mismatch fMRI-EEG=%+d', T-K); end
        if K < T; status = [status ' (fMRI longer: tail unlabelled)']; end %#ok<AGROW>
    else
        T = NaN;
        L = K;
        status = 'no signal file -> full EEG length used';
    end
    lab = lab(1:L);

    % ---- counts ----
    row = struct();
    row.Participant = string(sprintf('P%d', N));
    row.SubjectNum  = N;
    row.fMRI_len    = T;
    row.EEG_len     = K;
    row.Aligned_len = L;
    for k = 1:numel(sets)
        [nEp, nTR] = count_epochs(lab, sets{k}.stages, minTR);
        row.(char("Ep_" + sets{k}.label)) = nEp;
        row.(char("TR_" + sets{k}.label)) = nTR;
    end
    row.Unscored_TR = sum(~ismember(lab, stages));
    row.Status      = string(strtrim(status));

    if isnan(T)
        fprintf('P%-6d %8s %8d %8d   %s\n', N, '-', K, L, status);
    else
        fprintf('P%-6d %8d %8d %8d   %s\n', N, T, K, L, status);
    end

    if isempty(rows); rows = row; else; rows(end+1) = row; end %#ok<AGROW>
end
fprintf('%s\n', repmat('-',1,70));

%% ---------------- WRITE THE EXCEL FILE ----------------
Tbl = struct2table(rows);
Tbl = sortrows(Tbl, 'SubjectNum');

if ~exist(outDir, 'dir'); mkdir(outDir); end
if isempty(outFile)
    stamp   = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    outFile = sprintf('sleep_epoch_overview_%s.xlsx', stamp);
end
xlsxPath = fullfile(outDir, outFile);

try
    writetable(Tbl, xlsxPath, 'Sheet', 'Epochs');
    if writeSummary
        Sum = build_summary(Tbl, setLabels, TR);
        writetable(Sum, xlsxPath, 'Sheet', 'Summary');
    end
catch ME
    warning('xlsx write failed (%s) -> writing .csv instead.', ME.message);
    xlsxPath = regexprep(xlsxPath, '\.xlsx$', '.csv');
    writetable(Tbl, xlsxPath);
end

fprintf('\n%d participant(s) written to:\n  %s\n', height(Tbl), xlsxPath);
for k = 1:numel(setLabels)
    ep = Tbl.(char("Ep_" + setLabels(k)));
    tr = Tbl.(char("TR_" + setLabels(k)));
    fprintf('  %-10s  %3d subj with >=1 epoch | %5d epochs | %7d TR (%6.1f min)\n', ...
            setLabels(k), sum(ep > 0), sum(ep), sum(tr), sum(tr)*TR/60);
end
fprintf('\nDone.\n');


%% ======================= HELPERS ===========================
function [nEp, nTR] = count_epochs(lab, targetSet, minTR)
    % maximal runs of consecutive TRs whose label is in targetSet,
    % keeping only runs of at least minTR volumes
    nEp = 0; nTR = 0;
    if isempty(lab); return; end
    mask = ismember(lab.', targetSet);          % 1 x L logical
    if ~any(mask); return; end
    dd     = diff([false, mask, false]);
    starts = find(dd == 1);
    ends   = find(dd == -1) - 1;                % inclusive end
    lens   = ends - starts + 1;
    keep   = lens >= minTR;
    nEp    = sum(keep);
    nTR    = sum(lens(keep));
end

function n = shortName(stage)
    switch string(stage)
        case "Wake",  n = "W";
        case "NREM1", n = "N1";
        case "NREM2", n = "N2";
        case "NREM3", n = "N3";
        case "NREM4", n = "N4";
        case "REM",   n = "REM";
        otherwise
            n = regexprep(string(stage), '^NREM', 'N');
            n = regexprep(n, '[^A-Za-z0-9]', '');
    end
end

function lbl = setLabel(stageSet)
    % canonical order so ["NREM3","NREM2"] and ["NREM2","NREM3"] agree
    order = ["Wake","NREM1","NREM2","NREM3","NREM4","REM"];
    [tf, pos] = ismember(stageSet, order);
    if ~all(tf)
        warning('Stage(s) not in the known EEG vocabulary: %s', ...
                strjoin(stageSet(~tf), ', '));
    end
    key = double(pos); key(~tf) = numel(order) + 1;
    [~, srt] = sort(key);
    short = strings(1, numel(stageSet));
    for k = 1:numel(short); short(k) = shortName(stageSet(srt(k))); end
    lbl = strjoin(short, '_');
end

function Sum = build_summary(Tbl, setLabels, TR)
    n = numel(setLabels);
    Sum = table('Size',[n 8], ...
        'VariableTypes',{'string','double','double','double','double','double','double','double'}, ...
        'VariableNames',{'Stage','N_subj_with_epoch','Total_epochs','Mean_epochs', ...
                         'Total_TR','Mean_TR','Median_TR','Total_minutes'});
    for k = 1:n
        ep = Tbl.(char("Ep_" + setLabels(k)));
        tr = Tbl.(char("TR_" + setLabels(k)));
        Sum.Stage(k)              = setLabels(k);
        Sum.N_subj_with_epoch(k)  = sum(ep > 0);
        Sum.Total_epochs(k)       = sum(ep);
        Sum.Mean_epochs(k)        = mean(ep);
        Sum.Total_TR(k)           = sum(tr);
        Sum.Mean_TR(k)            = mean(tr);
        Sum.Median_TR(k)          = median(tr);
        Sum.Total_minutes(k)      = sum(tr) * TR / 60;
    end
end
