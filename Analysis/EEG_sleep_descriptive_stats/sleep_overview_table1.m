%% ============================================================
%  TABLE 1 - sleep composition of the cohort
%  ------------------------------------------------------------
%  Two columns: the full scored cohort and the low-motion subgroup.
%  Values are median (minimum - maximum) unless stated otherwise.
%  The final block reports how many PARTICIPANTS reached each stage at
%  all, which the medians alone can hide (the median for NREM3 and REM
%  is 0 even though many participants do reach those stages).
%
%  "Asleep" is defined as any NREM stage (NREM1, NREM2 or NREM3).
%  REM is excluded; add it to asleepStages below to include it.
%  The term sleep efficiency is avoided, because there is no time in bed
%  in a scanner protocol.
% ============================================================

%% ---------------- CONFIG ----------------
eegDir   = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
outDir   = '/Users/Richard/Masterabeit_local/SNORE_Plots/EEG_Plots/descriptive_statistics';
TR       = 2.5;                       % seconds per volume

% low-motion subgroup: low physiological noise and intact bottom slices
subgroup = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

STAGES       = ["Wake","NREM1","NREM2","NREM3","REM"];
asleepStages = ["NREM1","NREM2","NREM3"];

%% ---------------- LOAD ----------------
Sall = sleep_scoring_load(eegDir);            % everyone with a scoring file
Ssub = Sall(ismember([Sall.id], subgroup));   % subgroup, minus anyone unscored

fprintf('\nfull cohort : n = %d\n', numel(Sall));
fprintf('low motion  : n = %d (of %d listed)\n\n', numel(Ssub), numel(subgroup));

%% ---------------- BUILD THE TABLE ----------------
rowNames = ["Scan length (min)"; "Time asleep (min)"; "Proportion of scan asleep (%)"; ...
            "Wake (% of scan)"; "NREM1 (% of scan)"; "NREM2 (% of scan)"; ...
            "NREM3 (% of scan)"; "REM (% of scan)"; ...
            "Participants reaching NREM1, n (%)"; "Participants reaching NREM2, n (%)"; ...
            "Participants reaching NREM3, n (%)"; "Participants reaching REM, n (%)"];

colAll = summarise(Sall, TR, STAGES, asleepStages);
colSub = summarise(Ssub, TR, STAGES, asleepStages);

T = table(rowNames, colAll, colSub, 'VariableNames', ...
          {'Measure', sprintf('Full_cohort_n%d', numel(Sall)), ...
                      sprintf('Low_motion_n%d',  numel(Ssub))});

%% ---------------- PRINT AND SAVE ----------------
fprintf('%-36s %20s %20s\n', 'Measure', ...
        sprintf('full cohort (n=%d)', numel(Sall)), ...
        sprintf('low motion (n=%d)',  numel(Ssub)));
fprintf('%s\n', repmat('-', 1, 80));
for i = 1:height(T)
    if i == 9; fprintf('%s\n', repmat('-', 1, 80)); end   % separate the "reaching" block
    fprintf('%-36s %20s %20s\n', T.Measure(i), T{i,2}, T{i,3});
end
fprintf('%s\n', repmat('-', 1, 80));
fprintf('median (min - max); last block is a participant count, not a percentage of scan\n');

if ~exist(outDir, 'dir'); mkdir(outDir); end
outFile = fullfile(outDir, 'table1_sleep_composition.csv');
writetable(T, outFile);
fprintf('\nSaved: %s\n', outFile);


%% ======================= HELPERS =======================
function col = summarise(S, TR, STAGES, asleepStages)
    n = numel(S);
    nVol = arrayfun(@(s) numel(s.lab), S);
    pct  = zeros(n, numel(STAGES));
    for i = 1:n
        for g = 1:numel(STAGES)
            pct(i,g) = 100 * sum(S(i).lab == STAGES(g)) / nVol(i);
        end
    end
    asleepPct = zeros(n,1);
    for i = 1:n
        asleepPct(i) = 100 * sum(ismember(S(i).lab, asleepStages)) / nVol(i);
    end
    minutes   = nVol(:) * TR / 60;
    asleepMin = minutes .* asleepPct / 100;

    col = strings(12,1);
    col(1) = mRange(minutes);
    col(2) = mRange(asleepMin);
    col(3) = mRange(asleepPct);
    for g = 1:5; col(3+g) = mRange(pct(:,g)); end
    % how many PARTICIPANTS reached each stage at all
    for g = 2:5
        k = sum(pct(:,g) > 0);
        col(7+g) = sprintf('%d (%.0f%%)', k, 100*k/n);
    end
end

function s = mRange(v)
    v = v(:);
    s = sprintf('%.1f (%.1f-%.1f)', median(v), min(v), max(v));
end
