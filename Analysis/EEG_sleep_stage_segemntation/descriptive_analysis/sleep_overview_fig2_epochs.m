%% ============================================================
%  FIGURE 2 - stable epochs available for analysis
%  ------------------------------------------------------------
%  2.1  distribution of stable epoch durations, NREM total vs Wake
%  2.2  number of stable epochs per participant
%
%  A stable epoch is a run of consecutive volumes in the target stages
%  lasting at least minTR volumes, using the same rule as
%  segment_stable_sleep_epochs.m, so the counts match the segmented files.
% ============================================================

%% ---------------- CONFIG ----------------
eegDir   = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
outDir   = fullfile(eegDir, '_overview');
TR       = 2.5;
minTR    = 36;           % >= 36 volumes = 90 s

group    = "all";        % "all" = every scored participant | "subgroup" = low-motion only

subgroup = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];
inflow   = [5 8 9 20 22 23 31 32 33 35 43 47];

NREM     = ["NREM1","NREM2","NREM3"];    % "NREM total"
WAKE     = "Wake";
colN     = [0.20 0.42 0.68];             % blue   - NREM total
colW     = [0.85 0.55 0.20];             % orange - Wake
dpi      = 200;

%% ---------------- LOAD ----------------
if group == "subgroup"
    S = sleep_scoring_load(eegDir, subgroup);
else
    S = sleep_scoring_load(eegDir);
end
nS = numel(S);

%% ---------------- COLLECT EPOCHS ----------------
durN = []; durW = [];                    % all epoch durations, in minutes
cntN = zeros(nS,1); cntW = zeros(nS,1);  % epochs per participant
for i = 1:nS
    lN = stable_epoch_lengths(S(i).lab, NREM, minTR);
    lW = stable_epoch_lengths(S(i).lab, WAKE, minTR);
    durN = [durN, lN * TR/60]; %#ok<AGROW>
    durW = [durW, lW * TR/60]; %#ok<AGROW>
    cntN(i) = numel(lN);  cntW(i) = numel(lW);
end

fprintf('\ngroup = %s, n = %d\n', group, nS);
fprintf('NREM total : %d epochs, median %.1f min (range %.1f-%.1f)\n', ...
        numel(durN), median(durN), min(durN), max(durN));
fprintf('Wake       : %d epochs, median %.1f min (range %.1f-%.1f)\n', ...
        numel(durW), median(durW), min(durW), max(durW));
fprintf('epochs per participant: NREM median %.0f, Wake median %.0f\n', ...
        median(cntN), median(cntW));
fprintf('participants with no stable NREM epoch: %d\n\n', sum(cntN == 0));

%% ---------------- PLOT ----------------
fig = figure('Color','w', 'Position',[100 100 1020 max(420, 14*nS + 160)]);

% ---- 2.1 duration distribution ----
subplot(1,2,1); hold on;
edges = 0:2.5:max([durN, durW, 10]) + 2.5;
histogram(durN, edges, 'FaceColor',colN, 'FaceAlpha',0.55, 'EdgeColor','none', ...
          'DisplayName', sprintf('NREM total (%d epochs)', numel(durN)));
histogram(durW, edges, 'FaceColor',colW, 'FaceAlpha',0.55, 'EdgeColor','none', ...
          'DisplayName', sprintf('Wake (%d epochs)', numel(durW)));
xline(minTR*TR/60, 'k:', 'HandleVisibility','off');       % the 90 s cut-off
hold off;
xlabel('Epoch duration (min)'); ylabel('Number of epochs');
title('2.1  Stable epoch durations');
legend('Location','northeast', 'Box','off'); box on;

% ---- 2.2 epochs per participant ----
subplot(1,2,2);
[~, ord] = sort(cntN);                      % sort by NREM count
barh(1:nS, [cntN(ord), cntW(ord)], 'grouped', 'EdgeColor','none');
colororder([colN; colW]);

lbl = strings(nS,1);
for i = 1:nS
    k = ord(i); mark = "";
    if ismember(S(k).id, subgroup); mark = mark + " *"; end
    if ismember(S(k).id, inflow);   mark = mark + "+";  end
    lbl(i) = "P" + string(S(k).id) + mark;
end
yticks(1:nS); yticklabels(lbl);
set(gca, 'TickLabelInterpreter','none', 'FontSize',8);
ylim([0.5 nS+0.5]);
xlabel('Number of stable epochs');
ylabel('Participant   ( * low-motion subgroup,  + inflow effect )');
title('2.2  Stable epochs per participant');
legend({'NREM total','Wake'}, 'Location','southeast', 'Box','off'); box on;

sgtitle(sprintf('Stable epochs of at least %.0f s  (group = %s, n = %d)', ...
                minTR*TR, group, nS));

%% ---------------- SAVE ----------------
if ~exist(outDir, 'dir'); mkdir(outDir); end
outPng = fullfile(outDir, sprintf('fig2_stable_epochs_%s.png', group));
try
    exportgraphics(fig, outPng, 'Resolution', dpi);
catch
    print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
end
fprintf('Saved: %s\n', outPng);
