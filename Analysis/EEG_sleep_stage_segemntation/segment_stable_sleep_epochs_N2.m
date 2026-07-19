%% ============================================================
%  Concatenate stable NREM2 sleep epochs from fMRI runs
%  ------------------------------------------------------------
%  Replicates a Fultz-2019-style "stable sleep epoch" extraction.
%
%  For every signal file in a folder:
%    1. load the fMRI signal (CSF first slice, or gBOLD mean_signal)
%    2. load the matching EEG label vector stage_per_TR
%    3. align them (truncate both to the shorter length; assumes a
%       common start / trigger)
%    4. find every MAXIMAL run of consecutive NREM2 TRs
%    5. keep runs >= minTR (default 36 TRs = 90 s at 2.5 s/TR)
%    6. CONCATENATE the signal of all kept runs into one vector
%    7. save one .mat per participant (concatenated signal + the
%       index bookkeeping needed to split it back into epochs)
%
%  Run this file directly: it processes CSF and gBOLD in turn.
%  The worker segment_folder() is reusable for any signal folder.
%
%  1 TR = 1 fMRI volume = 2.5 s.
% ============================================================

%% ---------------- CONFIG (shared) ----------------
eegDir      = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
targetStage = "NREM2";
minTR       = 36;        % >= 36 TRs (= 90 s) to qualify as a stable epoch
TR          = 2.5;       % seconds per TR/volume

%% ---------------- CSF ----------------
cfgCSF = struct( ...
    'signalDir',   '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal', ...
    'signalPat',   'csf_p*_averaged.mat', ...
    'signalVar',   'averaged_slices', ...   % T x 4 (4 slices)
    'signalCol',   1, ...                   % keep FIRST slice only
    'outDir',      '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Sleep_Stage_Segmented/N2', ...
    'outPrefix',   'csf_');

%% ---------------- gBOLD ----------------
cfgGBOLD = struct( ...
    'signalDir',   '/Users/Richard/Masterabeit_local/SNORE_GM_Data/pre_processing/average', ...
    'signalPat',   'gbold_p*_z_average.mat', ...
    'signalVar',   'mean_signal', ...       % T x 1
    'signalCol',   1, ...
    'outDir',      '/Users/Richard/Masterabeit_local/SNORE_GM_Data/sleep_stage_segmented/N2', ...
    'outPrefix',   'gbold_');

%% ---------------- RUN ----------------
fprintf('\n######## CSF ########\n');
segment_folder(cfgCSF,   eegDir, targetStage, minTR, TR);
fprintf('\n######## gBOLD ########\n');
segment_folder(cfgGBOLD, eegDir, targetStage, minTR, TR);
fprintf('\nAll done.\n');


%% ======================= WORKER ===========================
function segment_folder(cfg, eegDir, targetStage, minTR, TR)
    if ~exist(cfg.outDir, 'dir'); mkdir(cfg.outDir); end

    D = dir(fullfile(cfg.signalDir, cfg.signalPat));
    assert(~isempty(D), 'No files matching "%s" in %s', cfg.signalPat, cfg.signalDir);
    fprintf('Found %d signal file(s) in %s\n', numel(D), cfg.signalDir);
    fprintf('%-7s %8s %8s %8s %9s %10s   %s\n', ...
            'Subj','fMRI','EEG','aligned','#epochs','concatTR','status');
    fprintf('%s\n', repmat('-',1,76));

    nWritten = 0;
    for i = 1:numel(D)
        % ---- subject number from filename (…p<NUM>…) ----
        tok = regexp(D(i).name, 'p(\d+)', 'tokens', 'once');
        if isempty(tok); warning('No p<num> in %s, skipped.', D(i).name); continue; end
        N = str2double(tok{1});

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

        % ---- maximal runs of consecutive targetStage, length >= minTR ----
        mask = (lab.' == targetStage);              % 1 x L logical
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
        n2_signal    = zeros(0,1);
        src_TR_index = zeros(0,1);                  % original (aligned) TR index per sample
        epochs = struct('epoch',{},'src_start_TR',{},'src_end_TR',{}, ...
                        'n_TR',{},'dur_s',{},'concat_start',{},'concat_end',{});
        pos = 0;
        for r = 1:nEp
            idx = (starts(r):ends(r)).';
            n2_signal    = [n2_signal;    sig(idx)]; %#ok<AGROW>
            src_TR_index = [src_TR_index; idx];      %#ok<AGROW>
            ln = numel(idx);
            epochs(r) = struct('epoch',r, 'src_start_TR',starts(r), 'src_end_TR',ends(r), ...
                               'n_TR',ln, 'dur_s',ln*TR, ...
                               'concat_start',pos+1, 'concat_end',pos+ln);
            pos = pos + ln;
        end

        status = '';
        if T ~= K; status = sprintf('len mismatch fMRI-EEG=%+d', T-K); end
        if K < T; status = [status ' (fMRI longer: tail volumes unlabelled)']; end %#ok<AGROW>
        fprintf('P%-6d %8d %8d %8d %9d %10d   %s\n', N, T, K, L, nEp, numel(n2_signal), status);

        % ---- save one file per participant (only if it has >=1 epoch) ----
        if nEp == 0; continue; end
        meta = struct('subject',sprintf('P%d',N), 'stage',targetStage, ...
                      'min_TR',minTR, 'min_seconds',minTR*TR, 'TR',TR, ...
                      'n_epochs',nEp, 'n_TRs_total',numel(n2_signal), ...
                      'duration_total_s',numel(n2_signal)*TR, ...
                      'fmri_len',T, 'eeg_len',K, 'aligned_len',L, ...
                      'signal_source',string(fullfile(D(i).folder, D(i).name)), ...
                      'eeg_source',string(eegPath), ...
                      'signal_var',string(cfg.signalVar), 'signal_col',cfg.signalCol, ...
                      'created',string(datetime('now')));
        outName = sprintf('%sp%d_N2.mat', cfg.outPrefix, N);
        save(fullfile(cfg.outDir, outName), 'n2_signal', 'src_TR_index', 'epochs', 'meta');
        nWritten = nWritten + 1;
    end

    fprintf('%s\n', repmat('-',1,76));
    fprintf('Wrote %d file(s) to %s\n', nWritten, cfg.outDir);
end
