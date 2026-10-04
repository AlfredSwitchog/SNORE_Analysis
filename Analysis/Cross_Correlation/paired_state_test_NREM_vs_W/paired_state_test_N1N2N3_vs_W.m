%% ========================================================================
%  Paired sleep vs. wake test of gBOLD-CSF coupling (H3)
%  Untransformed negative peak, two-tailed, paired t-test + Wilcoxon.
%
%  Reads the stage-1 two-stage output. Nothing upstream is recomputed.
% =========================================================================

clearvars; clc;

%% ---- Configuration -----------------------------------------------------
cfg.resultsFile = ['/Users/Richard/Masterabeit_local/SNORE_Plots/' ...
                   'Cross_Correlaltion/multi_stage/N1_N2_N3/invvar/' ...
                   'group_xcorr_N1_N2_N3_vs_W_twostage.mat'];
cfg.sleepIdx     = 1;              % results(1) = N1+N2+N3
cfg.wakeIdx      = 2;              % results(2) = W
cfg.testLag      = -5.0;           % s, untransformed negative peak (H3)
cfg.checkLags    = -2.5;           % s, neighbouring lag(s) as a check
cfg.expectedSign = -1;             % H3: sleep more negative at this peak
cfg.alpha        = 0.05;
cfg.minMinutes   = 5;              % primary sensitivity: usable min / condition
cfg.sweepMinutes = [5 8 10 15];    % threshold sweep
cfg.makePlot     = true;
cfg.saveResults  = true;
cfg.outDir       = ['/Users/Richard/Masterabeit_local/SNORE_Plots/' ...
                    'Cross_Correlaltion/sleep_wake_pairedTest'];
cfg.outFile      = 'paired_state_test_N1N2N3_vs_W.mat';
cfg.logFile      = 'output.txt';
cfg.figFile      = 'within_participant_change';   % written as .png and .fig

%% ---- Output folder and command-window log ------------------------------
% Everything printed below is mirrored into cfg.logFile.
if ~exist(cfg.outDir, 'dir'); mkdir(cfg.outDir); end
diary off;                                      % close any stale diary
logPath = fullfile(cfg.outDir, cfg.logFile);
if exist(logPath, 'file'); delete(logPath); end
diary(logPath);
fprintf('Run  : %s\n', char(datetime('now')));
fprintf('Input: %s\n\n', cfg.resultsFile);

%% ---- Load --------------------------------------------------------------
S  = load(cfg.resultsFile);
sl = S.results(cfg.sleepIdx);
wk = S.results(cfg.wakeIdx);

fprintf('Sleep condition : %s\n', sl.stage_label);
fprintf('Wake condition  : %s\n', wk.stage_label);
fprintf('Weighting       : %s\n', sl.epoch_weighting);
fprintf('gBOLD transform : %s\n', sl.gbold_transform);
fprintf('Lag convention  : %s\n\n', sl.lag_convention);

%% ---- Match participants across conditions ------------------------------
% Matched by identifier, never by row position.
[ids, iS, iW] = intersect(sl.subject_ids(:), wk.subject_ids(:), 'stable');
assert(numel(ids) == numel(sl.subject_ids), ...
       'Participant sets differ: %d matched of %d.', ...
       numel(ids), numel(sl.subject_ids));

Zs   = sl.z_per_subject(iS, :);
Zw   = wk.z_per_subject(iW, :);
lags = sl.lags_s(:)';
TR   = sl.TR;

% Usable data per participant. Volume counts are pre-lag; at the largest lag
% each epoch loses up to max_lag_TR volumes of overlap.
minS = double(sl.n_volumes_used(iS)) * TR / 60;
minW = double(wk.n_volumes_used(iW)) * TR / 60;
epS  = double(sl.n_epochs_used(iS));
epW  = double(wk.n_epochs_used(iW));

%% ---- Locate the test lag -----------------------------------------------
[dev, k] = min(abs(lags - cfg.testLag));
assert(dev < 1e-6, 'Lag %.2f s is not on the grid.', cfg.testLag);

[~, kPeak] = min(mean(Zs, 1));
if kPeak ~= k
    warning('Group negative peak in sleep sits at %.2f s, not %.2f s.', ...
            lags(kPeak), lags(k));
end

%% ---- Data per participant ----------------------------------------------
% Epoch counts are descriptive only. A single uninterrupted epoch can carry
% more data than many short ones, so inclusion is decided on minutes.
worst = min(minS, minW);
fprintf('Usable data   sleep: %.0f min total, median %.1f (range %.1f-%.1f)\n', ...
        sum(minS), median(minS), min(minS), max(minS));
fprintf('               wake: %.0f min total, median %.1f (range %.1f-%.1f)\n', ...
        sum(minW), median(minW), min(minW), max(minW));
fprintf('Weaker condition per participant: median %.1f min, min %.1f min\n', ...
        median(worst), min(worst));
fprintf('Epochs        sleep: median %g (range %g-%g), total %g\n', ...
        median(epS), min(epS), max(epS), sum(epS));
fprintf('               wake: median %g (range %g-%g), total %g\n\n', ...
        median(epW), min(epW), max(epW), sum(epW));

%% ---- Primary test ------------------------------------------------------
fprintf('========================================================\n');
res.primary = pairedTest(Zs(:,k), Zw(:,k), cfg);
printResult(sprintf('PRIMARY  lag %+.1f s, all %d participants', ...
                    lags(k), numel(ids)), res.primary, cfg.alpha);

%% ---- Sensitivity: minimum usable data ----------------------------------
keep = worst >= cfg.minMinutes;
if any(~keep)
    res.minMinutes = pairedTest(Zs(keep,k), Zw(keep,k), cfg);
    printResult(sprintf('SENSITIVITY  >= %g min per condition (excl. %s)', ...
                cfg.minMinutes, mat2str(ids(~keep)')), res.minMinutes, cfg.alpha);
else
    fprintf('--- SENSITIVITY: no participant below %g min per condition ---\n\n', ...
            cfg.minMinutes);
end

%% ---- Threshold sweep ---------------------------------------------------
fprintf('--- THRESHOLD SWEEP (lag %+.1f s) ---\n', lags(k));
fprintf('  %8s %4s %10s %10s %8s\n', 'min/cond', 'n', 'p(t)', 'p(W)', 'dz');
res.sweep = struct('threshold', {}, 'stats', {});
for thr = cfg.sweepMinutes
    sel = worst >= thr;
    if sum(sel) < 4, continue; end
    st = pairedTest(Zs(sel,k), Zw(sel,k), cfg);
    res.sweep(end+1) = struct('threshold', thr, 'stats', st);                %#ok<SAGROW>
    fprintf('  %8g %4d %10.4f %10.4f %+8.3f\n', ...
            thr, st.n, st.p_ttest, st.p_wilcoxon, st.dz);
end
fprintf('\n');

%% ---- Robustness: neighbouring lags -------------------------------------
% The negative peak is shallow, so the choice of lag is worth checking.
res.lagCheck = struct('lag', {}, 'stats', {});
for L = cfg.checkLags
    [~, kk] = min(abs(lags - L));
    st = pairedTest(Zs(:,kk), Zw(:,kk), cfg);
    res.lagCheck(end+1) = struct('lag', lags(kk), 'stats', st);              %#ok<SAGROW>
    printResult(sprintf('ROBUSTNESS  lag %+.1f s', lags(kk)), st, cfg.alpha);
end

%% ---- Paired plot -------------------------------------------------------
if cfg.makePlot
    nSub = numel(ids);
    if exist('turbo', 'file') == 2
        cmap = turbo(nSub);
    else
        cmap = hsv(nSub);
    end

    fh = figure('Color', 'w', 'Position', [100 100 440 470]); hold on;

    % One coloured line per participant, labelled with the subject ID.
    for i = 1:nSub
        plot([1 2], [tanh(Zs(i,k)) tanh(Zw(i,k))], '-o', ...
             'Color', cmap(i,:), 'LineWidth', 1.2, ...
             'MarkerSize', 4, 'MarkerFaceColor', cmap(i,:));
        text(2.06, tanh(Zw(i,k)), num2str(ids(i)), ...
             'Color', cmap(i,:), 'FontSize', 7, 'VerticalAlignment', 'middle');
    end

    % Group mean in bold black, drawn on top.
    plot([1 2], [res.primary.rSleep res.primary.rWake], '-o', ...
         'Color', 'k', 'LineWidth', 3, 'MarkerSize', 8, 'MarkerFaceColor', 'k');

    set(gca, 'XTick', [1 2], 'XTickLabel', {'NREM', 'Wake'}, ...
             'XLim', [0.8 2.25], 'FontSize', 11);
    ylabel(sprintf('Coupling r at %+.1f s', lags(k)));
    title(sprintf('Within-participant change (n = %d, p = %.4f)', ...
                  nSub, res.primary.p_ttest));
    box off; hold off;

    if cfg.saveResults
        exportgraphics(fh, fullfile(cfg.outDir, [cfg.figFile '.png']), ...
                       'Resolution', 300);
        savefig(fh, fullfile(cfg.outDir, [cfg.figFile '.fig']));
    end
end

%% ---- Save --------------------------------------------------------------
if cfg.saveResults
    res.cfg = cfg; res.lag = lags(k); res.ids = ids;
    res.minutesSleep = minS; res.minutesWake = minW;
    matPath = fullfile(cfg.outDir, cfg.outFile);
    save(matPath, '-struct', 'res');
    fprintf('Results : %s\n', matPath);
    fprintf('Figure  : %s.png / .fig\n', fullfile(cfg.outDir, cfg.figFile));
    fprintf('Log     : %s\n\n', logPath);
end

diary off;

%% ---- Local functions ---------------------------------------------------
function r = pairedTest(zs, zw, cfg)
    % All three tests are Statistics Toolbox built-ins. This wrapper only
    % collects their output, since no single function runs all of them.
    % Note the differing output order: ttest -> [h,p,ci,stats]
    %                                  signrank -> [p,h,stats]

    [~, p_t, ci, st_t] = ttest(zs, zw, 'Alpha', cfg.alpha, 'Tail', 'both');
    [p_w, ~, st_w]     = signrank(zs, zw, 'alpha', cfg.alpha, 'tail', 'both');

    d = zs - zw;
    r.n            = numel(d);
    r.rSleep       = tanh(mean(zs));
    r.rWake        = tanh(mean(zw));
    r.meanDiffZ    = mean(d);
    r.sdDiffZ      = std(d);
    r.ciDiffZ      = ci(:)';
    r.nAsPredicted = sum(sign(d) == cfg.expectedSign);

    % Paired t-test
    r.t       = st_t.tstat;
    r.df      = st_t.df;
    r.p_ttest = p_t;

    % Wilcoxon signed-rank
    r.p_wilcoxon = p_w;
    r.W          = st_w.signedrank;
    if isfield(st_w, 'zval')          % normal approximation, larger n
        r.z_wilcoxon = st_w.zval;
        r.wMethod    = 'approximate';
    else                              % exact distribution, smaller n
        r.z_wilcoxon = NaN;
        r.wMethod    = 'exact';
    end

    % Effect size
    if exist('meanEffectSize', 'file') == 2        % R2022a and later
        e = meanEffectSize(zs, zw, 'Paired', true, 'Effect', 'cohen', ...
                           'ConfidenceIntervalType', 'exact');
        r.dz    = e.Effect;
        r.dz_ci = e.ConfidenceIntervals;
    else
        r.dz    = mean(d) / std(d);
        r.dz_ci = [NaN NaN];
    end
end

function printResult(label, r, alpha)
    fprintf('--- %s ---\n', label);
    fprintf('  n = %d   (predicted direction in %d of %d)\n', ...
            r.n, r.nAsPredicted, r.n);
    fprintf('  mean r:  NREM %+.3f   wake %+.3f\n', r.rSleep, r.rWake);
    fprintf('  difference (Fisher z): %+.4f   95%% CI [%+.4f, %+.4f]\n', ...
            r.meanDiffZ, r.ciDiffZ(1), r.ciDiffZ(2));
    fprintf('  paired t(%d) = %+.3f,  p = %.4f\n', r.df, r.t, r.p_ttest);
    if isnan(r.z_wilcoxon)
        fprintf('  Wilcoxon signed-rank: W = %g,  p = %.4f  (%s)\n', ...
                r.W, r.p_wilcoxon, r.wMethod);
    else
        fprintf('  Wilcoxon signed-rank: W = %g, z = %+.3f,  p = %.4f  (%s)\n', ...
                r.W, r.z_wilcoxon, r.p_wilcoxon, r.wMethod);
    end
    if ~isnan(r.dz_ci(1))
        fprintf('  Cohen''s dz = %+.3f  [%+.3f, %+.3f]\n', r.dz, r.dz_ci);
    else
        fprintf('  Cohen''s dz = %+.3f\n', r.dz);
    end
    if (r.p_ttest < alpha) ~= (r.p_wilcoxon < alpha)
        fprintf('  NOTE: the two tests disagree at alpha = %.2f.\n', alpha);
    end
    fprintf('\n');
end