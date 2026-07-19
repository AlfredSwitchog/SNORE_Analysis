%% ============================================================
%  gBOLD - CSF lagged cross-correlation  ***WITHIN-EPOCH VERSION***
%  ------------------------------------------------------------
%  This is the WITHIN-EPOCH counterpart of csf_gm_cross_correlation.m.
%  Instead of treating the concatenated N2 signal as one continuous
%  series, the lagged cross-correlation is computed SEPARATELY WITHIN
%  each continuous N2 epoch (shifts never cross an epoch join), and the
%  per-epoch curves are then AVERAGED across epochs (length-weighted by
%  the number of overlapping sample pairs at each lag).
%
%  Why: a lagged correlation pairs sample t with sample t+L and assumes
%  they are L*TR apart in real time. At the joins of concatenated epochs
%  that assumption breaks (segments can be minutes apart), contaminating
%  nonzero-lag correlations. Computing within epochs removes that bias;
%  averaging across epochs mirrors how Han (2021) averaged the cross-
%  correlation across continuous runs.
%
%  CONVENTION:   r(L) = corr( gBOLD(t), CSF(t + L) )   [within each epoch]
%     positive lag L  ->  CSF sampled LATER   ->  "CSF follows gBOLD"
%     negative lag L  ->  CSF sampled EARLIER ->  "CSF leads gBOLD"
%
%  NULL BAND: circular shift is applied WITHIN each epoch independently
%  (preserving each epoch's own autocorrelation), then the within-epoch
%  averaged curve is recomputed - so the null respects epoch structure.
%
%  1 TR = 1 volume = 2.5 s.  Only P8 currently has a gBOLD file.
% ============================================================

%% ---------------- CONFIG ----------------
csfDir   = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Sleep_Stage_Segmented/N2';
gmDir    = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/sleep_stage_segmented/N2';
outDir   = '/Users/Richard/Masterabeit_local/SNORE_Plots/Cross_Correlaltion/N2/within_epoch';
TR            = 2.5;    % seconds per TR / volume
maxLagTR      = 5;      % lags -5..+5 TR  (= -12.5 .. +12.5 s)
nPerm         = 5000;   % within-epoch circular-shift permutations for the null band
alpha         = 0.05;   % two-sided significance level for the null band
weightByLength = true;  % average per-epoch r weighted by # overlapping pairs (false = plain mean)
dpi           = 200;
rng(42);                % reproducible permutation null

lagsTR  = -maxLagTR:maxLagTR;
lagsSec = lagsTR * TR;
if ~exist(outDir,'dir'); mkdir(outDir); end

%% ---------------- LOOP over participants with both signals ----------------
D = dir(fullfile(csfDir, 'csf_p*_N2.mat'));
assert(~isempty(D), 'No csf_p*_N2.mat in %s', csfDir);
fprintf('Found %d CSF N2 file(s).\n', numel(D));

for i = 1:numel(D)
    tok = regexp(D(i).name, 'p(\d+)_N2', 'tokens', 'once');
    if isempty(tok); continue; end
    N = str2double(tok{1});

    gmPath = fullfile(gmDir, sprintf('gbold_p%d_N2.mat', N));
    if exist(gmPath, 'file') ~= 2
        fprintf('P%-3d : no gBOLD file -> skipped\n', N); continue
    end

    Cs = load(fullfile(D(i).folder, D(i).name));
    Gs = load(gmPath);
    c = double(Cs.n2_signal(:));      % CSF (first slice), concatenated N2 epochs
    g = double(Gs.n2_signal(:));      % gBOLD (mean_signal), concatenated N2 epochs
    n = min(numel(c), numel(g)); c = c(1:n); g = g(1:n);

    % ---- epoch boundaries (indices into the concatenated signal) ----
    E = Cs.epochs;
    bounds = zeros(numel(E), 2);
    for e = 1:numel(E)
        bounds(e,:) = [E(e).concat_start, min(E(e).concat_end, n)];
    end
    K = size(bounds,1);

    % ---- observed within-epoch averaged cross-correlation ----
    r = cc_within(g, c, bounds, lagsTR, weightByLength);

    % ---- within-epoch circular-shift permutation null band ----
    nullM = zeros(nPerm, numel(lagsTR));
    for p = 1:nPerm
        cperm = c;
        for e = 1:K
            a = bounds(e,1); b = bounds(e,2); ns = b - a + 1;
            cperm(a:b) = circshift(c(a:b), randi(max(ns-1,1)));
        end
        nullM(p,:) = cc_within(g, cperm, bounds, lagsTR, weightByLength);
    end
    lo  = pctl(nullM, 100*alpha/2);
    hi  = pctl(nullM, 100*(1-alpha/2));
    sig = (r < lo) | (r > hi);

    [rmin, imin] = min(r);            % negative (coupling) peak

    % ---- plot (same style as the concatenated version) ----
    fig = figure('Visible','off', 'Color','w', 'Position',[100 100 820 500]);
    hold on;
    fill([lagsSec, fliplr(lagsSec)], [hi, fliplr(lo)], [0.85 0.85 0.85], ...
         'EdgeColor','none', 'DisplayName','null 95% (within-epoch shift)');
    yline(0, 'k-'); xline(0, 'k:');
    plot(lagsSec, r, '-o', 'Color',[0.15 0.35 0.70], 'LineWidth',1.6, ...
         'MarkerFaceColor',[0.15 0.35 0.70], 'DisplayName','gBOLD-CSF (within-epoch avg)');
    if any(sig)
        plot(lagsSec(sig), r(sig), 'o', 'MarkerEdgeColor',[0.75 0 0.10], ...
             'MarkerFaceColor','none', 'MarkerSize',10, 'LineWidth',1.4, ...
             'DisplayName','p<0.05 vs null');
    end
    plot(lagsSec(imin), rmin, 'v', 'Color',[0.75 0 0.10], ...
         'MarkerFaceColor',[0.75 0 0.10], 'MarkerSize',9, 'HandleVisibility','off');
    text(lagsSec(imin), rmin, sprintf('  neg. peak %.1f s, r=%.2f', lagsSec(imin), rmin), ...
         'Color',[0.75 0 0.10], 'VerticalAlignment','top', 'FontSize',9);
    hold off;
    xlabel('Lag (s)     [ positive = CSF follows gBOLD ]');
    ylabel('Pearson correlation   (gBOLD vs CSF)');
    title(sprintf('P%d  -  gBOLD-CSF cross-correlation (N2, within-epoch avg of %d epochs)', N, K), ...
          'Interpreter','none');
    xticks(lagsSec); xlim([min(lagsSec) max(lagsSec)]); grid on;
    legend('Location','northwest', 'Box','off');

    outPng = fullfile(outDir, sprintf('P%d_gBOLD_CSF_xcorr.png', N));
    try
        exportgraphics(fig, outPng, 'Resolution', dpi);
    catch
        print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
    end
    close(fig);

    fprintf('P%-3d : %d epoch(s); within-epoch neg peak r=%+.3f at %+.1f s (%+d TR); significant=%d -> %s\n', ...
            N, K, rmin, lagsSec(imin), lagsTR(imin), sig(imin), outPng);
end
fprintf('Done.\n');

%% ======================= HELPERS ===========================
function r = cc_within(g, c, bounds, lagsTR, weightByLength)
    % Lagged Pearson corr computed WITHIN each epoch, then averaged across
    % epochs. r(k) corresponds to lag lagsTR(k); convention corr(g(t),c(t+L)).
    nL = numel(lagsTR); acc = zeros(1,nL); wsum = zeros(1,nL);
    for e = 1:size(bounds,1)
        a = bounds(e,1); b = bounds(e,2);
        ge = g(a:b); ce = c(a:b); ne = b - a + 1;
        for k = 1:nL
            L = lagsTR(k);
            if L >= 0
                if ne - L < 3, continue; end
                x = ge(1:ne-L);   y = ce(1+L:ne);   % CSF sampled LATER  (follows)
            else
                m = -L;
                if ne - m < 3, continue; end
                x = ge(1+m:ne);   y = ce(1:ne-m);   % CSF sampled EARLIER (leads)
            end
            rr = pear(x, y);
            if ~isfinite(rr), continue; end
            if weightByLength, w = numel(x); else, w = 1; end
            acc(k) = acc(k) + w*rr;  wsum(k) = wsum(k) + w;
        end
    end
    r = acc ./ wsum;                 % weighted mean across epochs (NaN if no epoch qualified)
end

function r = pear(x, y)
    % Fast Pearson correlation (base MATLAB, no toolbox).
    x = x(:); y = y(:); nn = numel(x);
    dx = x - sum(x)/nn;  dy = y - sum(y)/nn;
    d  = sqrt(sum(dx.^2) * sum(dy.^2));
    if d == 0, r = NaN; else, r = sum(dx.*dy) / d; end
end

function v = pctl(M, p)
    % Column-wise p-th percentile (p in 0..100), linear interpolation.
    % Base MATLAB only (no Statistics Toolbox needed).
    M = sort(M, 1); n = size(M,1); v = zeros(1, size(M,2));
    if n == 1, v = M; return; end
    idx = p/100*(n-1) + 1; loI = floor(idx); hiI = ceil(idx); f = idx - loI;
    v = M(loI,:).*(1-f) + M(hiI,:).*f;
end
