%% ============================================================
%  Concatenate stable sleep epochs from fMRI runs  (any stage set)
%  ------------------------------------------------------------
%  Replicates a Fultz-2019-style "stable sleep epoch" extraction.
%
%  For every signal file in a folder:
%    1. load the fMRI signal (CSF first slice, or gBOLD mean_signal)
%    2. load the matching EEG label vector stage_per_TR
%    3. align them (truncate both to the shorter length; assumes a
%       common start / trigger)
%    4. find every MAXIMAL run of consecutive TRs whose label is in
%       targetStages  (COMBINED mode: a run may span stage borders,
%       e.g. NREM2 -> NREM3 stays ONE continuous epoch)
%    5. keep runs >= minTR (default 36 TRs = 90 s at 2.5 s/TR)
%    6. CONCATENATE the signal of all kept runs into one vector
%    7. save one .mat per participant (concatenated signal + the
%       index bookkeeping needed to split it back into epochs)
%
%  Outputs go to   <outBase>/<stageLabel>/<prefix>p<NUM>_<stageLabel>.mat
%  e.g.            .../Sleep_Stage_Segmented/N2_N3/csf_p10_N2_N3.mat
%
%  EEG label vocabulary found in the scoring files:
%      "Wake"  "NREM1"  "NREM2"  "NREM3"  "REM"   (rarely "NA")
%
%  Run this file directly: it processes CSF and gBOLD in turn.
%  The worker segment_folder() is reusable for any signal folder.
%
%  1 TR = 1 fMRI volume = 2.5 s.
% ============================================================

%% ---------------- CONFIG (shared) ----------------
eegDir       = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';

% Stages to pool into one analysis. COMBINED: a TR qualifies if its
% label is ANY of these, and epochs may run across stage boundaries.
%   ["W"]                      -> folder/suffix W
%   ["NREM2"]                  -> folder/suffix  N2
%   ["NREM2","NREM3"]          -> folder/suffix  N2_N3
%   ["NREM1","NREM2","NREM3"]  -> folder/suffix  N1_N2_N3
targetStages = ["Wake"];

% Participants to analyse. [] = every participant found in signalDir.
% Otherwise a list of participant numbers, e.g. [1 10 14 22 30]
% For SNORE study: These are the ones with an inflow effect [5 8 9 20 22 23 31 32 33 35 43 47]
subjects     = [];

minTR        = 36;       % >= 36 TRs (= 90 s) to qualify as a stable epoch
TR           = 2.5;      % seconds per TR/volume
saveEmpty    = false;    % true = also write a .mat for subjects with 0 epochs

% Folder/file suffix. "" = built automatically from targetStages
% (NREM1->N1, NREM2->N2, NREM3->N3, REM->REM, Wake->W, joined by "_").
% Set e.g. "SWS" to override.
outLabel     = "";

%% ---------------- CSF ----------------
cfgCSF = struct( ...
    'signalDir',   '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal', ...
    'signalPat',   'csf_p*_averaged.mat', ...
    'signalVar',   'averaged_slices', ...   % T x 4 (4 slices)
    'signalCol',   1, ...                   % keep FIRST slice only
    'outBase',     '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Sleep_Stage_Segmented', ...
    'outPrefix',   'csf_');

%% ---------------- gBOLD ----------------
cfgGBOLD = struct( ...
    'signalDir',   '/Users/Richard/Masterabeit_local/SNORE_GM_Data/pre_processing/average', ...
    'signalPat',   'gbold_p*_z_average.mat', ...
    'signalVar',   'mean_signal', ...       % T x 1
    'signalCol',   1, ...
    'outBase',     '/Users/Richard/Masterabeit_local/SNORE_GM_Data/sleep_stage_segmented', ...
    'outPrefix',   'gbold_');

%% ---------------- RUN ----------------
targetStages = string(targetStages(:)).';
stageLabel   = make_stage_label(targetStages, outLabel);

fprintf('\nStages   : %s   ->  label "%s"\n', strjoin(targetStages, ' + '), stageLabel);
fprintf('Min epoch: %d TR (%.1f s)\n', minTR, minTR*TR);
if isempty(subjects)
    fprintf('Subjects : all found\n');
else
    fprintf('Subjects : %s\n', strjoin(string(subjects(:)).', ', '));
end

fprintf('\n######## CSF ########\n');
segment_folder(cfgCSF,   eegDir, targetStages, stageLabel, subjects, minTR, TR, saveEmpty);
fprintf('\n######## gBOLD ########\n');
segment_folder(cfgGBOLD, eegDir, targetStages, stageLabel, subjects, minTR, TR, saveEmpty);
fprintf('\nAll done.\n');


%% ======================= WORKER ===========================
function segment_folder(cfg, eegDir, targetStages, stageLabel, subjects, minTR, TR, saveEmpty)

    outDir = fullfile(cfg.outBase, char(stageLabel));
    if ~exist(outDir, 'dir'); mkdir(outDir); end

    D = dir(fullfile(cfg.signalDir, cfg.signalPat));
    assert(~isempty(D), 'No files matching "%s" in %s', cfg.signalPat, cfg.signalDir);
    fprintf('Found %d signal file(s) in %s\n', numel(D), cfg.signalDir);
    fprintf('%-7s %8s %8s %8s %9s %10s   %s\n', ...
            'Subj','fMRI','EEG','aligned','#epochs','concatTR','status');
    fprintf('%s\n', repmat('-',1,76));

    nWritten = 0;
    seen     = [];
    for i = 1:numel(D)
        % ---- subject number from filename (…p<NUM>…) ----
        tok = regexp(D(i).name, 'p(\d+)', 'tokens', 'once');
        if isempty(tok); warning('No p<num> in %s, skipped.', D(i).name); continue; end
        N = str2double(tok{1});

        % ---- participant selection ----
        if ~isempty(subjects) && ~ismember(N, subjects); continue; end
        seen(end+1) = N; %#ok<AGROW>

        % ---- load + orient signal so time is the long dimension ----
        Sg = load(fullfile(D(i).folder, D(i).name));
        assert(isfield(Sg, cfg.signalVar), 'No "%s" in %s', cfg.signalVar, D(i).name);
        X = Sg.(cfg.signalVar);
        if size(X,1) < size(X,2); X = X.'; end      % rows = time
        sig = X(:, cfg.signalCol);                  % T x 1
        T   = numel(sig);

        % ---- matching EEG labels ----
        eegPath = fullfile(eegDir, sprintf('P%d_sleep_stage_per_TR.mat', N));
        if exist(eegPath, 'file') ~= 2
            fprintf('P%-6d %8d %8s %8s %9s %10s   %s\n', N, T, '-','-','-','-', 'EEG missing -> skipped');
            continue
        end
        Es  = load(eegPath);
        if isfield(Es,'stage_per_TR'); lab = string(Es.stage_per_TR(:));
        else;                          lab = strings(numel(Es.time_TR),1); end
        K = numel(lab);

        % ---- align (assume common start; truncate to shorter length) ----
        L   = min(T, K);
        sig = sig(1:L);
        lab = lab(1:L);

        % ---- maximal runs whose label is in targetStages, length >= minTR ----
        mask = ismember(lab.', targetStages);       % 1 x L logical
        starts = []; ends = [];
        if any(mask)
            dd     = diff([false, mask, false]);
            starts = find(dd == 1);
            ends   = find(dd == -1) - 1;            % inclusive end
            lens   = ends - starts + 1;
            ok     = lens >= minTR;
            starts = starts(ok); ends = ends(ok);
        end
        nEp = numel(starts);

        % ---- concatenate kept epochs + bookkeeping ----
        stage_signal     = zeros(0,1);
        src_TR_index     = zeros(0,1);              % original (aligned) TR index per sample
        stage_per_sample = strings(0,1);            % EEG label per concatenated sample
        epochs = struct('epoch',{},'src_start_TR',{},'src_end_TR',{}, ...
                        'n_TR',{},'dur_s',{},'concat_start',{},'concat_end',{}, ...
                        'stages_in_epoch',{},'dominant_stage',{});
        pos = 0;
        for r = 1:nEp
            idx  = (starts(r):ends(r)).';
            eLab = lab(idx);
            stage_signal     = [stage_signal;     sig(idx)];  %#ok<AGROW>
            src_TR_index     = [src_TR_index;     idx];       %#ok<AGROW>
            stage_per_sample = [stage_per_sample; eLab];      %#ok<AGROW>
            ln = numel(idx);

            uStg = unique(eLab, 'stable');
            cnts = arrayfun(@(s) sum(eLab == s), uStg);
            [~,imax] = max(cnts);

            epochs(r) = struct('epoch',r, 'src_start_TR',starts(r), 'src_end_TR',ends(r), ...
                               'n_TR',ln, 'dur_s',ln*TR, ...
                               'concat_start',pos+1, 'concat_end',pos+ln, ...
                               'stages_in_epoch',strjoin(uStg.', '+'), ...
                               'dominant_stage',uStg(imax));
            pos = pos + ln;
        end

        status = '';
        if T ~= K; status = sprintf('len mismatch fMRI-EEG=%+d', T-K); end
        if K < T; status = [status ' (fMRI longer: tail volumes unlabelled)']; end %#ok<AGROW>
        if nEp == 0; status = strtrim([status ' no epoch >= minTR']); end
        fprintf('P%-6d %8d %8d %8d %9d %10d   %s\n', N, T, K, L, nEp, numel(stage_signal), status);

        % ---- save one file per participant (only if it has >=1 epoch) ----
        if nEp == 0 && ~saveEmpty; continue; end
        meta = struct('subject',sprintf('P%d',N), ...
                      'stages',targetStages, 'stage_label',stageLabel, ...
                      'min_TR',minTR, 'min_seconds',minTR*TR, 'TR',TR, ...
                      'n_epochs',nEp, 'n_TRs_total',numel(stage_signal), ...
                      'duration_total_s',numel(stage_signal)*TR, ...
                      'fmri_len',T, 'eeg_len',K, 'aligned_len',L, ...
                      'signal_source',string(fullfile(D(i).folder, D(i).name)), ...
                      'eeg_source',string(eegPath), ...
                      'signal_var',string(cfg.signalVar), 'signal_col',cfg.signalCol, ...
                      'created',string(datetime('now')));
        outName = sprintf('%sp%d_%s.mat', cfg.outPrefix, N, stageLabel);
        save(fullfile(outDir, outName), ...
             'stage_signal', 'src_TR_index', 'stage_per_sample', 'epochs', 'meta');
        nWritten = nWritten + 1;
    end

    % ---- participants requested but not found in signalDir ----
    if ~isempty(subjects)
        for N = setdiff(subjects(:).', seen)
            fprintf('P%-6d %8s %8s %8s %9s %10s   %s\n', N, '-','-','-','-','-', ...
                    'signal file missing -> skipped');
        end
    end

    fprintf('%s\n', repmat('-',1,76));
    fprintf('Wrote %d file(s) to %s\n', nWritten, outDir);
end


%% ======================= HELPERS ===========================
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

function lbl = make_stage_label(targetStages, outLabel)
    if strlength(string(outLabel)) > 0
        lbl = string(outLabel);
        return
    end
    order = ["Wake","NREM1","NREM2","NREM3","NREM4","REM"];
    [tf, pos] = ismember(targetStages, order);
    if ~all(tf)
        warning('Stage(s) not in the known EEG vocabulary: %s', ...
                strjoin(targetStages(~tf), ', '));
    end
    key = double(pos); key(~tf) = numel(order) + 1;   % unknown stages last
    [~, srt] = sort(key);
    short = strings(1, numel(targetStages));
    for k = 1:numel(short); short(k) = shortName(targetStages(srt(k))); end
    lbl = strjoin(short, '_');
end
