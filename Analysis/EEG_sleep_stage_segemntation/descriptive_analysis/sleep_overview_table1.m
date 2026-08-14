%% ============================================================
%  TABLE 1 - sleep composition of the cohort
%  ------------------------------------------------------------
%  Two columns: the full scored cohort and the low-motion subgroup.
%  Values are median [25th-75th percentile] unless stated otherwise.
%  A final block reports how many participants reached each stage at all,
%  which the medians alone can hide (the median for NREM3 and REM is 0).
%
%  Note: "proportion of scan asleep" is used instead of sleep efficiency,
%  because there is no time in bed in a scanner protocol.
% ============================================================

%% ---------------- CONFIG ----------------
eegDir   = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
outDir   = fullfile(eegDir, '_overview');
TR       = 2.5;                       % seconds per volume

% low-motion subgroup with intact slices
subgroup = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

STAGES   = ["Wake","NREM1","NREM2","NREM3","REM"];

%% ---------------- LOAD ----------------
Sall = sleep_scoring_load(eegDir);            % everyone with a scoring file
Ssub = Sall(ismember([Sall.id], subgroup));   % subgroup, minus anyone unscored

fprintf('\nfull cohort      : n = %d\n', numel(Sall));
fprintf('low-motion group : n = %d (of %d listed)\n\n', numel(Ssub), numel(subgroup));

%% ---------------- BUILD THE TABLE ----------------
rowNames = ["Scan length (min)"; "Time asleep (min)"; "Proportion of scan asleep (%)"; ...
            "Wake (% of scan)"; "NREM1 (% of scan)"; "NREM2 (% of scan)"; ...
            "NREM3 (% of scan)"; "REM (% of scan)"; ...
            "Reached NREM1, n (%)"; "Reached NREM2, n (%)"; ...
            "Reached NREM3, n (%)"; "Reached REM, n (%)"];

colAll = summarise(Sall, TR, STAGES);
colSub = summarise(Ssub, TR, STAGES);

T = table(rowNames, colAll, colSub, 'VariableNames', ...
          {'Measure', sprintf('Full_cohort_n%d', numel(Sall)), ...
                      sprintf('Low_motion_n%d',  numel(Ssub))});

%% ---------------- PRINT AND SAVE ----------------
fprintf('%-32s %22s %22s\n', 'Measure', ...
        sprintf('full cohort (n=%d)', numel(Sall)), ...
        sprintf('low motion (n=%d)',  numel(Ssub)));
fprintf('%s\n', repmat('-', 1, 78));
for i = 1:height(T)
    if i == 9; fprintf('%s\n', repmat('-', 1, 78)); end   % separate the "reached" block
    fprintf('%-32s %22s %22s\n', T.Measure(i), T{i,2}, T{i,3});
end
fprintf('%s\n', repmat('-', 1, 78));

if ~exist(outDir, 'dir'); mkdir(outDir); end
outFile = fullfile(outDir, 'table1_sleep_composition.csv');
writetable(T, outFile);
fprintf('\nSaved: %s\n', outFile);


%% ======================= HELPERS =======================
function col = summarise(S, TR, STAGES)
    n = numel(S);
    nVol = arrayfun(@(s) numel(s.lab), S);
    pct  = zeros(n, numel(STAGES));
    for i = 1:n
        for g = 1:numel(STAGES)
            pct(i,g) = 100 * sum(S(i).lab == STAGES(g)) / nVol(i);
        end
    end
    asleepPct = 100 - pct(:, STAGES == "Wake");
    minutes   = nVol(:) * TR / 60;
    asleepMin = minutes .* asleepPct / 100;

    col = strings(12,1);
    col(1) = mIQR(minutes);
    col(2) = mIQR(asleepMin);
    col(3) = mIQR(asleepPct);
    for g = 1:5; col(3+g) = mIQR(pct(:,g)); end
    % how many participants reached each stage at all
    for g = 2:5
        k = sum(pct(:,g) > 0);
        col(7+g) = sprintf('%d (%.0f%%)', k, 100*k/n);
    end
end

function s = mIQR(v)
    v = v(:);
    s = sprintf('%.1f [%.1f-%.1f]', median(v), pctl(v,25), pctl(v,75));
end

function q = pctl(v, p)
    % percentile with linear interpolation, base MATLAB only
    v = sort(v(:)); n = numel(v);
    if n == 1; q = v; return; end
    idx = p/100*(n-1) + 1;
    lo = floor(idx); hi = ceil(idx); f = idx - lo;
    q = v(lo)*(1-f) + v(hi)*f;
end
