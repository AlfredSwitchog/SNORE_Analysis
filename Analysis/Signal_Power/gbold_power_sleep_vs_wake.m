%% ============================================================
%  gBOLD SIGNAL POWER:  SLEEP vs WAKE      (Fultz et al. 2019, Fig. 3C)
%  ------------------------------------------------------------
%  Asks a different question from the cross-correlation analyses.
%  The cross-correlation asks WHETHER the gBOLD and CSF signals are
%  related. This asks whether the gBOLD oscillation itself becomes
%  LARGER during sleep than during wakefulness.
%
%  "Power" is simply variance: how much the signal swings about its own
%  mean. The power spectrum splits that variance up by frequency, and
%  the band power is the part of it that lives in slow fluctuations.
%
%  PROCEDURE  (following Fultz et al. 2019)
%    1. take every stable epoch of a participant, in each condition
%    2. demean and detrend it
%    3. estimate its power spectrum with the multitaper method
%    4. integrate the spectrum over the low-frequency band
%    5. average across that participant's epochs (plain mean)
%    6. per participant:  dB = 10*log10( P_sleep / P_wake )
%    7. paired Wilcoxon signed-rank test across participants, with a
%       distribution-free confidence interval obtained by inverting
%       the test (Hodges-Lehmann)
%
%  Fultz et al. report +3.28 dB, CI (0.09, 6.54), p = 0.032, n = 11.
%  3.28 dB corresponds to about 2.1 times more power during sleep.
%
%  NOTE ON THE gBOLD NORMALISATION
%  gBOLD is a per-voxel z-scored average, so its amplitude reflects how
%  synchronously gray matter fluctuates. The z-score divisor is one
%  constant per participant and per run, so it cancels out of the
%  sleep/wake ratio entirely - the dB difference does not depend on it.
%
%  Requires the Signal Processing Toolbox for pmtm().
%  Everything else is base MATLAB.
%  1 TR = 1 volume = 2.5 s.
% ============================================================

%% ---------------- CONFIG ----------------
% The two conditions to compare. Folder names under gmRoot.
%   "N2" | "N2_N3" | "N1_N2_N3"   vs   "W"
sleepLabel = "N1_N2_N3";
wakeLabel  = "W";

% Participants. [] = every participant that has BOTH conditions.
% Otherwise a list of numbers, e.g. [5 8 22 23]
subjects   = [];

TR         = 2.5;      % seconds per TR / volume

% Frequency band that is integrated to give one power value per epoch.
% Fultz et al. use 0-0.1 Hz. The present data were high-pass filtered at
% 0.01 Hz before extraction, so the lower edge is set to that cutoff -
% below it the data carry no signal, only filter roll-off. Setting the
% lower edge to 0 instead gives almost the same answer, because the
% suppressed region contributes very little power.
band       = [0.01 0.10];   % Hz

timeBandwidth = 3;     % pmtm time-bandwidth product; 2*nw-1 = 5 tapers,
                       % matching the 5 tapers used by Fultz et al.
nfft          = 512;   % fixed FFT length, so every epoch lands on the
                       % same frequency grid and the spectra can be
                       % averaged. This interpolates, it does not add
                       % resolution: true resolution is 1/epoch duration.

detrendEpochs = true;  % remove mean and linear trend from each epoch
alphaCI       = 0.05;  % for the confidence interval on the difference

saveResults = true;
dpi         = 200;

% ---- paths ----
gmRoot   = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/sleep_stage_segmented';
outDir   = '/Users/Richard/Masterabeit_local/SNORE_Plots/Signal_Power';

%% ---------------- SETUP ----------------
sleepLabel = string(sleepLabel);
wakeLabel  = string(wakeLabel);
fs         = 1/TR;                       % sampling frequency, 0.4 Hz
if ~exist(outDir, 'dir'); mkdir(outDir); end

fprintf('\n=============== gBOLD POWER: SLEEP vs WAKE ===============\n');
fprintf('Sleep     : %s\n', sleepLabel);
fprintf('Wake      : %s\n', wakeLabel);
fprintf('Band      : %.3f - %.3f Hz\n', band(1), band(2));
fprintf('Sampling  : %.2f Hz (TR = %.1f s), Nyquist = %.2f Hz\n', fs, TR, fs/2);
fprintf('Tapers    : %d  (time-bandwidth %.1f)\n', 2*timeBandwidth-1, timeBandwidth);
fprintf('==========================================================\n\n');

%% ---------------- LOAD AND MEASURE ----------------
[Ps, Fs_, ids_s, nEp_s] = conditionPower(sleepLabel, gmRoot, subjects, ...
                                         TR, band, timeBandwidth, nfft, detrendEpochs);
[Pw, Fw_, ids_w, nEp_w] = conditionPower(wakeLabel,  gmRoot, subjects, ...
                                         TR, band, timeBandwidth, nfft, detrendEpochs);

% keep participants that have BOTH conditions
ids = intersect(ids_s, ids_w);
assert(numel(ids) >= 2, 'Need at least 2 participants with both conditions.');
[~, is] = ismember(ids, ids_s);
[~, iw] = ismember(ids, ids_w);

powSleep = Ps.bandPower(is);      % 1 x nSubj
powWake  = Pw.bandPower(iw);
psdSleep = Ps.psd(is, :);         % nSubj x nFreq, mean spectrum per participant
psdWake  = Pw.psd(iw, :);
freq     = Fs_;                   % common frequency grid
nEpS     = nEp_s(is);
nEpW     = nEp_w(iw);
nSubj    = numel(ids);

fprintf('Participants with both conditions: %d\n', nSubj);
if numel(ids_s) > nSubj
    fprintf('  only %s : %s\n', sleepLabel, strjoin("P"+string(setdiff(ids_s, ids)), ', '));
end
if numel(ids_w) > nSubj
    fprintf('  only %s : %s\n', wakeLabel,  strjoin("P"+string(setdiff(ids_w, ids)), ', '));
end

%% ---------------- PER-PARTICIPANT DIFFERENCE ----------------
dB = 10*log10(powSleep ./ powWake);       % 1 x nSubj

fprintf('\n%-7s %8s %8s %12s %12s %9s\n', ...
        'Subj','#epSlp','#epWake','P_sleep','P_wake','dB');
fprintf('%s\n', repmat('-',1,62));
for k = 1:nSubj
    fprintf('P%-6d %8d %8d %12.4g %12.4g %+9.2f\n', ...
            ids(k), nEpS(k), nEpW(k), powSleep(k), powWake(k), dB(k));
end
fprintf('%s\n', repmat('-',1,62));

%% ---------------- PAIRED TEST ----------------
[pVal, W, zStat]        = signRankTest(dB);
[hlEst, ciLo, ciHi]     = hodgesLehmann(dB, alphaCI);

nUp = sum(dB > 0);
fprintf('\nSleep > wake in %d of %d participants (%.0f%%)\n', ...
        nUp, nSubj, 100*nUp/nSubj);
fprintf('median difference : %+.2f dB   (x%.2f in power)\n', ...
        median(dB), 10^(median(dB)/10));
fprintf('Hodges-Lehmann    : %+.2f dB   %.0f%% CI [%+.2f, %+.2f]\n', ...
        hlEst, 100*(1-alphaCI), ciLo, ciHi);
fprintf('Wilcoxon signed-rank: W = %.1f, z = %+.3f, p = %.4g\n', W, zStat, pVal);
fprintf('\nFultz et al. (2019) report +3.28 dB, CI (0.09, 6.54), p = 0.032, n = 11.\n');

%% ---------------- FIGURE 1: MEAN POWER SPECTRA ----------------
colS = [0.15 0.35 0.70];      % blue   - sleep
colW = [0.85 0.33 0.10];      % orange - wake

mS = mean(psdSleep, 1);  seS = std(psdSleep, 0, 1)/sqrt(nSubj);
mW = mean(psdWake,  1);  seW = std(psdWake,  0, 1)/sqrt(nSubj);

fig1 = figure('Visible','off', 'Color','w', 'Position',[100 100 860 500]);
hold on;
inBand = freq >= band(1) & freq <= band(2);
yl = [min([mS(freq<=0.2) mW(freq<=0.2)])*0.5, max([mS mW])*1.6];
patch([band(1) band(2) band(2) band(1)], [yl(1) yl(1) yl(2) yl(2)], ...
      [0.93 0.93 0.93], 'EdgeColor','none', 'HandleVisibility','off');

fill([freq, fliplr(freq)], [mS+seS, fliplr(max(mS-seS, eps))], colS, ...
     'FaceAlpha',0.15, 'EdgeColor','none', 'HandleVisibility','off');
fill([freq, fliplr(freq)], [mW+seW, fliplr(max(mW-seW, eps))], colW, ...
     'FaceAlpha',0.15, 'EdgeColor','none', 'HandleVisibility','off');
plot(freq, mS, '-', 'Color',colS, 'LineWidth',2, ...
     'DisplayName', sprintf('%s  (n = %d)', prettyStageName(sleepLabel), nSubj));
plot(freq, mW, '-', 'Color',colW, 'LineWidth',2, ...
     'DisplayName', sprintf('%s  (n = %d)', prettyStageName(wakeLabel), nSubj));
hold off;

set(gca, 'YScale','log');
xlabel('Frequency (Hz)');
ylabel('Power spectral density (a.u. / Hz)');
title(sprintf('gBOLD power spectrum, %s vs %s   (shaded band = %.2f-%.2f Hz)', ...
              prettyStageName(sleepLabel), prettyStageName(wakeLabel), ...
              band(1), band(2)), 'Interpreter','none');
xlim([0 fs/2]); ylim(yl);
legend('Location','northeast', 'Box','off'); grid off;

png1 = fullfile(outDir, sprintf('gbold_psd_%s_vs_%s.png', sleepLabel, wakeLabel));
exportFig(fig1, png1, dpi);

%% ---------------- FIGURE 2: PAIRED COMPARISON (Fultz Fig. 3C) ----------
fig2 = figure('Visible','off', 'Color','w', 'Position',[100 100 520 520]);
hold on;
x = [1 2];
for k = 1:nSubj
    plot(x, [powWake(k) powSleep(k)], '-', 'Color',[0.75 0.75 0.75], ...
         'LineWidth',0.8, 'HandleVisibility','off');
end
plot(ones(1,nSubj)*x(1), powWake,  'o', 'Color',colW, 'MarkerFaceColor',colW, ...
     'MarkerSize',6, 'HandleVisibility','off');
plot(ones(1,nSubj)*x(2), powSleep, 'o', 'Color',colS, 'MarkerFaceColor',colS, ...
     'MarkerSize',6, 'HandleVisibility','off');
plot(x, [median(powWake) median(powSleep)], '-k', 'LineWidth',2.5, ...
     'DisplayName','group median');
plot(x, [median(powWake) median(powSleep)], 'sk', 'MarkerFaceColor','k', ...
     'MarkerSize',9, 'HandleVisibility','off');
hold off;

set(gca, 'YScale','log');
xticks(x); xticklabels({char(prettyStageName(wakeLabel)), char(prettyStageName(sleepLabel))});
xlim([0.6 2.4]);
ylabel(sprintf('gBOLD power, %.2f-%.2f Hz (a.u.)', band(1), band(2)));
title(sprintf('%+.2f dB, p = %.3g  (n = %d)', hlEst, pVal, nSubj), 'Interpreter','none');
legend('Location','best', 'Box','off'); grid off;

png2 = fullfile(outDir, sprintf('gbold_power_paired_%s_vs_%s.png', sleepLabel, wakeLabel));
exportFig(fig2, png2, dpi);

fprintf('\nFigures:\n  %s\n  %s\n', png1, png2);

%% ---------------- SAVE ----------------
if saveResults
    results = struct( ...
        'sleep_label',    sleepLabel, ...
        'wake_label',     wakeLabel, ...
        'subject_ids',    ids, ...
        'n_subjects',     nSubj, ...
        'n_epochs_sleep', nEpS, ...
        'n_epochs_wake',  nEpW, ...
        'band_Hz',        band, ...
        'power_sleep',    powSleep, ...
        'power_wake',     powWake, ...
        'dB_per_subject', dB, ...
        'median_dB',      median(dB), ...
        'hodges_lehmann_dB', hlEst, ...
        'ci_lo_dB',       ciLo, ...
        'ci_hi_dB',       ciHi, ...
        'p_signrank',     pVal, ...
        'W_statistic',    W, ...
        'z_statistic',    zStat, ...
        'freq_Hz',        freq, ...
        'psd_sleep',      psdSleep, ...
        'psd_wake',       psdWake, ...
        'TR',             TR, ...
        'time_bandwidth', timeBandwidth, ...
        'n_tapers',       2*timeBandwidth-1, ...
        'nfft',           nfft, ...
        'detrended',      detrendEpochs, ...
        'gm_dir',         string(gmRoot), ...
        'created',        string(datetime('now')));
    outMat = fullfile(outDir, sprintf('gbold_power_%s_vs_%s.mat', sleepLabel, wakeLabel));
    save(outMat, 'results');
    fprintf('Results: %s\n', outMat);
end
fprintf('\nDone.\n');


%% ======================= WORKERS =======================
function [out, freq, ids, nEpUsed] = conditionPower(stageLabel, gmRoot, subjects, ...
                                        TR, band, nw, nfft, doDetrend)
    % One condition -> band power and mean spectrum for every participant.
    gmDir = fullfile(gmRoot, char(stageLabel));
    D = dir(fullfile(gmDir, sprintf('gbold_p*_%s.mat', stageLabel)));
    assert(~isempty(D), 'No gbold_p*_%s.mat in %s', stageLabel, gmDir);

    fs = 1/TR;
    ids = []; bandPower = []; psdAll = []; nEpUsed = []; freq = [];

    fprintf('--- %s : %d file(s) in %s\n', stageLabel, numel(D), gmDir);

    for i = 1:numel(D)
        tok = regexp(D(i).name, 'p(\d+)_', 'tokens', 'once');
        if isempty(tok); continue; end
        N = str2double(tok{1});
        if ~isempty(subjects) && ~ismember(N, subjects); continue; end

        S = load(fullfile(D(i).folder, D(i).name));
        g = double(loadStageSignal(S, D(i).name));
        bounds = epochBounds(S.epochs, numel(g));

        pxxSum = []; bpList = []; nUsed = 0;
        for e = 1:size(bounds,1)
            seg = g(bounds(e,1):bounds(e,2));
            if numel(seg) < 8 || ~all(isfinite(seg)); continue; end

            if doDetrend
                seg = detrendLinear(seg);       % removes mean AND linear trend
            else
                seg = seg - mean(seg);
            end
            if std(seg) == 0; continue; end

            % multitaper spectrum on a FIXED frequency grid, so that the
            % spectra of epochs of different length can be averaged
            [pxx, f] = pmtm(seg, nw, nfft, fs);
            pxx = pxx(:).'; f = f(:).';

            % band power = area under the spectrum inside the band
            inB = f >= band(1) & f <= band(2);
            bp  = trapz(f(inB), pxx(inB));

            if isempty(pxxSum); pxxSum = zeros(size(pxx)); freq = f; end
            pxxSum = pxxSum + pxx;
            bpList(end+1) = bp; %#ok<AGROW>
            nUsed = nUsed + 1;
        end

        if nUsed == 0
            fprintf('    P%-5d no usable epoch -> skipped\n', N);
            continue
        end

        ids(end+1)        = N;                 %#ok<AGROW>
        bandPower(end+1)  = mean(bpList);      %#ok<AGROW>  plain mean, as Fultz
        psdAll(end+1,:)   = pxxSum / nUsed;    %#ok<AGROW>  mean spectrum
        nEpUsed(end+1)    = nUsed;             %#ok<AGROW>
    end

    fprintf('    %d participant(s) with usable epochs\n', numel(ids));
    out = struct('bandPower', bandPower, 'psd', psdAll);
end

function y = detrendLinear(x)
    % Remove mean and linear trend without the Signal Processing detrend().
    x = x(:); n = numel(x);
    t = (1:n).'; t = t - mean(t);
    b = (t.'*x) / (t.'*t);          % least-squares slope
    y = x - mean(x) - b*t;
end


%% ======================= STATISTICS =======================
function [p, W, z] = signRankTest(d)
    % Two-sided Wilcoxon signed-rank test against a median of zero.
    % Normal approximation with continuity and tie correction, which is
    % appropriate at the sample sizes used here. Base MATLAB only.
    d = d(:); d = d(d ~= 0);
    n = numel(d);
    assert(n >= 2, 'Not enough non-zero differences for a signed-rank test.');

    r = tiedRanks(abs(d));              % average ranks, ties share a rank

    W = sum(r(d > 0));                  % sum of positive ranks
    mu = n*(n+1)/4;

    % variance with correction for ties in |d|
    [~, ~, grp] = unique(abs(d));
    tieSizes = accumarray(grp, 1);
    sigma2 = n*(n+1)*(2*n+1)/24 - sum(tieSizes.^3 - tieSizes)/48;

    z = (W - mu - 0.5*sign(W - mu)) / sqrt(sigma2);   % continuity correction
    p = erfc(abs(z)/sqrt(2));                          % two-sided
end

function r = tiedRanks(x)
    x = x(:); n = numel(x);
    [xs, ord] = sort(x);
    rs = (1:n).';
    i = 1;
    while i <= n
        j = i;
        while j < n && xs(j+1) == xs(i); j = j + 1; end
        if j > i; rs(i:j) = mean(i:j); end
        i = j + 1;
    end
    r = zeros(n,1); r(ord) = rs;
end

function [est, lo, hi] = hodgesLehmann(d, alpha)
    % Hodges-Lehmann estimate of the median difference and the
    % distribution-free confidence interval obtained by inverting the
    % signed-rank test - the approach used by Fultz et al.
    d = d(:); n = numel(d);
    W = [];
    for i = 1:n
        W = [W; (d(i) + d(i:n))/2]; %#ok<AGROW>   Walsh averages
    end
    W = sort(W); M = numel(W);
    est = median(W);

    % critical rank from the normal approximation to the signed-rank null
    zc = sqrt(2)*erfcinv(alpha);                        % two-sided z
    k  = round(n*(n+1)/4 - zc*sqrt(n*(n+1)*(2*n+1)/24));
    k  = max(1, min(k, M));
    lo = W(k);
    hi = W(M + 1 - k);
end


%% ======================= SHARED HELPERS =======================
function v = loadStageSignal(S, src)
    % PURE LOADER. segment_stable_sleep_epochs.m saves stage_signal;
    % the older _N2 script saved n2_signal.
    if     isfield(S, 'stage_signal'); v = S.stage_signal(:);
    elseif isfield(S, 'n2_signal');    v = S.n2_signal(:);
    else
        error('Neither "stage_signal" nor "n2_signal" found in %s', char(src));
    end
end

function bounds = epochBounds(epochs, nMax)
    % Start/end index of each epoch inside the concatenated signal.
    bounds = zeros(numel(epochs), 2);
    for e = 1:numel(epochs)
        bounds(e,:) = [epochs(e).concat_start, min(epochs(e).concat_end, nMax)];
    end
    bounds = bounds(bounds(:,2) >= bounds(:,1), :);
end

function name = prettyStageName(stageLabel)
    % "W" -> "Wake";  "N1_N2_N3" -> "Sleep (N1, N2, N3)"
    s = string(stageLabel);
    if strcmpi(s, "W")
        name = "Wake";
    else
        parts = split(s, "_");
        name  = "Sleep (" + strjoin(parts.', ", ") + ")";
    end
end

function exportFig(fig, outPng, dpi)
    try
        exportgraphics(fig, outPng, 'Resolution', dpi);
    catch
        print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
    end
    close(fig);
end
