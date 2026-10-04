%% ========================================================================
%  Export stage-wise coupling curves to one long-format CSV for R
%  ------------------------------------------------------------------------
%  Reads the four stage-pure two-stage runs and writes ONE table with
%  one row per participant x stage x lag. The per-stage count table is a
%  group_by on this file, so it is deliberately not written separately.
%
%  W is taken ONCE, from the run with the full participant set. It appears
%  in every paired run but trimmed to a different subset each time by the
%  matching step, which would otherwise produce duplicate W rows at three
%  different sample sizes.
% =========================================================================

clearvars; clc;

%% ---- Configuration -----------------------------------------------------
cfg.base    = '/Users/Richard/Masterabeit_local/SNORE_Plots/Cross_Correlaltion/multi_stage';
cfg.outDir  = '/Users/Richard/Masterabeit_local/SNORE_Plots/Cross_Correlaltion/lmm';
cfg.outFile = 'coupling_long.csv';
cfg.logFile = 'export_log.txt';

% stage label | file relative to cfg.base | which element of results to read
%   element 1 = the sleep condition, element 2 = W
cfg.src = { ...
  "W",  'N1_N2_N3/invvar/group_xcorr_N1_N2_N3_vs_W_twostage.mat', 2 ; ...
  "N1", 'N1/group_xcorr_N1_vs_W_twostage.mat',                    1 ; ...
  "N2", 'N2/invvar/group_xcorr_N2_vs_W_twostage.mat',             1 ; ...
  "N3", 'N3/group_xcorr_N3_vs_W_twostage.mat',                    1 };

%% ---- Output folder and log --------------------------------------------
if ~exist(cfg.outDir, 'dir'); mkdir(cfg.outDir); end
diary off;
logPath = fullfile(cfg.outDir, cfg.logFile);
if exist(logPath, 'file'); delete(logPath); end
diary(logPath);
fprintf('Run : %s\n\n', char(datetime('now')));

%% ---- Read, verify, accumulate -----------------------------------------
nSrc = size(cfg.src, 1);
T    = table();
ref  = struct('lags', [], 'gm', "", 'wt', "", 'TR', [], ...
              'gmRoot', "", 'csfRoot', "");

for s = 1:nSrc
    stage   = cfg.src{s,1};
    relPath = cfg.src{s,2};
    idx     = cfg.src{s,3};
    full    = fullfile(cfg.base, relPath);

    assert(exist(full,'file')==2, 'Missing source file: %s', full);
    S  = load(full);
    el = S.results(idx);

    % ---- consistency checks against the first source --------------------
    if s == 1
        ref.lags = el.lags_s(:)';
        ref.gm   = string(el.gbold_transform);
        ref.wt   = string(el.epoch_weighting);
        ref.TR   = el.TR;
        % Parent of the stage folder: the GM/CSF pipeline variant.
        ref.gmRoot  = string(fileparts(char(el.gm_dir)));
        ref.csfRoot = string(fileparts(char(el.csf_dir)));
    else
        assert(isequal(el.lags_s(:)', ref.lags), ...
               '%s: lag grid differs from the reference.', stage);
        assert(el.TR == ref.TR, '%s: TR differs from the reference.', stage);
        assert(string(el.gbold_transform) == ref.gm, ...
               '%s: gBOLD transform is "%s", reference is "%s".', ...
               stage, string(el.gbold_transform), ref.gm);
        assert(string(el.epoch_weighting) == ref.wt, ...
               '%s: epoch weighting is "%s", reference is "%s".', ...
               stage, string(el.epoch_weighting), ref.wt);
        % THE check that catches a raw-average vs z-scored GM mix-up.
        % gbold_transform only records the derivative (none/deriv/derivthr)
        % and is "none" for both variants, so it cannot detect this.
        assert(string(fileparts(char(el.gm_dir))) == ref.gmRoot, ...
               '%s: GM pipeline is "%s", reference is "%s".', ...
               stage, string(fileparts(char(el.gm_dir))), ref.gmRoot);
        assert(string(fileparts(char(el.csf_dir))) == ref.csfRoot, ...
               '%s: CSF pipeline is "%s", reference is "%s".', ...
               stage, string(fileparts(char(el.csf_dir))), ref.csfRoot);
    end

    ids   = double(el.subject_ids(:));
    nEp   = double(el.n_epochs_used(:));
    nVol  = double(el.n_volumes_used(:));
    Z     = el.z_per_subject;          % [nSubj x nLags]
    Rr    = el.r_per_subject;
    lags  = el.lags_s(:)';
    lagTR = el.lags_TR(:)';
    nSub  = numel(ids);
    nLag  = numel(lags);

    fprintf('%-3s  %-52s  element %d   n = %2d   epochs = %3d   %7.1f min\n', ...
            stage, relPath, idx, nSub, sum(nEp), sum(nVol)*ref.TR/60);

    % ---- expand to long -------------------------------------------------
    blk = table( ...
        repelem(ids,  nLag),                       ...
        repmat(stage, nSub*nLag, 1),               ...
        repmat(lagTR(:), nSub, 1),                 ...
        repmat(lags(:),  nSub, 1),                 ...
        reshape(Z.',  [], 1),                      ...
        reshape(Rr.', [], 1),                      ...
        repelem(nEp,  nLag),                       ...
        repelem(nVol, nLag),                       ...
        repelem(nVol * ref.TR/60, nLag),           ...
        repmat(ref.gm, nSub*nLag, 1),              ...
        repmat(ref.wt, nSub*nLag, 1),              ...
        repmat(ref.gmRoot, nSub*nLag, 1),          ...
        repmat(string(relPath), nSub*nLag, 1),     ...
        'VariableNames', {'subject','stage','lag_tr','lag_s','z','r', ...
                          'n_epochs','n_volumes','minutes', ...
                          'gm_transform','weighting','gm_pipeline','src_file'});
    T = [T; blk]; %#ok<AGROW>
end

%% ---- Final integrity checks -------------------------------------------
key = string(T.subject) + "_" + T.stage + "_" + string(T.lag_s);
assert(numel(unique(key)) == height(T), 'Duplicate subject-stage-lag rows.');
assert(~any(isnan(T.z)), 'NaN values in z.');
fprintf('\nGM pipeline     : %s\nCSF pipeline    : %s\n', ref.gmRoot, ref.csfRoot);
fprintf('gBOLD transform : %s   (derivative flag, not the GM variant)\n', ref.gm);
fprintf('Epoch weighting : %s\nTR              : %.2f s\n', ref.wt, ref.TR);

%% ---- Count summary (same information R will derive) -------------------
U = unique(T(:, {'subject','stage','n_epochs','n_volumes','minutes'}), 'rows');
fprintf('\n%-6s %4s %8s %10s %12s\n', 'stage', 'n', 'epochs', 'minutes', 'median min');
for s = 1:nSrc
    stage = cfg.src{s,1};
    m = U(U.stage == stage, :);
    fprintf('%-6s %4d %8d %10.0f %12.1f\n', stage, height(m), ...
            sum(m.n_epochs), sum(m.minutes), median(m.minutes));
end
fprintf('\nrows: %d  (= %d participant-stage cells x %d lags)\n', ...
        height(T), height(U), numel(ref.lags));

%% ---- Write -------------------------------------------------------------
outPath = fullfile(cfg.outDir, cfg.outFile);
writetable(T, outPath);
fprintf('\nWritten: %s\nLog    : %s\n\n', outPath, logPath);
diary off;
