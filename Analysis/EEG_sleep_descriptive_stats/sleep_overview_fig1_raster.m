%% ============================================================
%  FIGURE 1 - hypnogram raster across participants
%  ------------------------------------------------------------
%  One horizontal row per participant, time on the x-axis, colour-coded by
%  sleep stage. Rows are sorted by how much of the scan was spent asleep,
%  most asleep at the top. Participants belonging to the low-motion
%  subgroup are marked with * in the y-axis label.
% ============================================================

%% ---------------- CONFIG ----------------
eegDir   = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
outDir   = '/Users/Richard/Masterabeit_local/SNORE_Plots/EEG_Plots/descriptive_statistics';
TR       = 2.5;

group    = "all";        % "all" = full cohort | "subgroup" = low motion only
xMax = 150;   % maximum displayed scan time in minutes

subgroup = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

STAGES       = ["Wake","NREM1","NREM2","NREM3","REM"];
asleepStages = ["NREM1","NREM2","NREM3"];
COLS     = [0.86 0.86 0.86;      % Wake   light grey
            0.70 0.82 0.92;      % NREM1  light blue
            0.35 0.60 0.83;      % NREM2  medium blue
            0.12 0.30 0.55;      % NREM3  dark blue
            0.90 0.55 0.20];     % REM    orange
dpi      = 200;

%% ---------------- LOAD ----------------
if group == "subgroup"
    S = sleep_scoring_load(eegDir, subgroup);
else
    S = sleep_scoring_load(eegDir);
end
nS = numel(S);
fprintf('Figure 1: %d participant(s), group = %s\n', nS, group);

%% ---------------- SORT BY PROPORTION ASLEEP ----------------
asleep = arrayfun(@(s) 100 * mean(ismember(s.lab, asleepStages)), S);
[~, ord] = sort(asleep, 'descend');
S = S(ord);

%% ---------------- BUILD THE STAGE MATRIX ----------------
maxVol  = max(arrayfun(@(s) numel(s.lab), S));
maxMin  = (maxVol - 1) * TR / 60;           % longest run, in minutes
M = nan(nS, maxVol);                        % NaN = scan already finished
for i = 1:nS
    [tf, code] = ismember(S(i).lab, STAGES);
    code(~tf)  = NaN;                       % anything unexpected (e.g. "NA")
    M(i, 1:numel(code)) = code;
end

%% ---------------- PLOT ----------------
fig = figure('Color','w', 'Position',[100 100 1000 max(360, 16*nS + 120)]);

imagesc([0 maxMin], [1 nS], M, 'AlphaData', ~isnan(M));
colormap(COLS); clim([0.5 numel(STAGES)+0.5]);
xlim([0 xMax]);                           % box ends at the longest run
ylim([0.5 nS+0.5]);

% y labels, with * marking the low-motion subgroup
lbl = strings(nS,1);
for i = 1:nS
    if ismember(S(i).id, subgroup)
        lbl(i) = "P" + string(S(i).id) + " *";
    else
        lbl(i) = "P" + string(S(i).id);
    end
end
yticks(1:nS); yticklabels(lbl); set(gca, 'TickLabelInterpreter','none', 'FontSize',8);
xlabel('Time in scan (min)');
ylabel('Participant   ( * low-motion subgroup )');
title(sprintf('Sleep stage over the scan, sorted by proportion asleep (n = %d)', nS));
box on;

% stage legend, drawn as invisible patches so the colours are named
hold on;
h = gobjects(1, numel(STAGES));
for g = 1:numel(STAGES)
    h(g) = patch(NaN, NaN, COLS(g,:), 'EdgeColor','none', 'DisplayName', STAGES(g));
end
hold off;
legend(h, 'Location','eastoutside', 'Box','off');

%% ---------------- SAVE ----------------
if ~exist(outDir, 'dir'); mkdir(outDir); end
outPng = fullfile(outDir, sprintf('fig1_hypnogram_raster_%s.png', group));
try
    exportgraphics(fig, outPng, 'Resolution', dpi);
catch
    print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
end
fprintf('Saved: %s\n', outPng);
