%% ============================================================
%  Group mean raw CSF signal in the four bottom slices
%  ------------------------------------------------------------
%  PLOTTING ONLY. The group mean is computed and saved by
%     CSF_raw_data_transformations/csf_create_group_mean_per_slice.m
%  and is only loaded here, so that re-running this script can never
%  change the underlying average.
%
%  Expected inflow signature: slice 1 sits at the bottom of the imaging
%  volume and shows the largest fluctuations, decaying upwards.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
% Group mean file written by csf_create_group_mean_per_slice.m
groupMeanFile = ['/Users/Richard/Masterabeit_local/SNORE_CSF_Data/' ...
              '20260813_Group_Average/csf_group_mean_per_slice.mat'];

timeUnit = "min";     % "min" | "s" | "vol"   -> x-axis of the figure

plotContributors = true;   % second, separate figure: participants per time point

savePng  = true;
plotRoot = '/Users/Richard/Masterabeit_local/SNORE_Plots/Inflow_Effect';
dpi      = 200;

% Figures go to   <plotRoot>/<yyyymmdd>_Figures/<subfolder>/<file>.png
subDirMean         = 'group_level_raw_signal';
fileMean           = 'group_level_raw_csf_signal.png';
subDirContributors = 'group_level_contributing_participants';
fileContributors   = 'group_level_contributing_participants.png';

%% ---------------- LOAD ----------------
assert(exist(groupMeanFile, 'file') == 2, ...
       ['Group mean file not found:\n  %s\n' ...
        'Run csf_create_group_mean_per_slice.m first.'], groupMeanFile);

L = load(groupMeanFile, 'group_mean');
G = L.group_mean;

groupMean    = G.mean_per_slice;      % T x nSlice
contributors = G.n_contributors(:,1); % T x 1
nSub         = G.n_subjects;
nSlice       = G.n_slices;
TR           = G.TR;

outDir = fullfile(plotRoot, ...
                  sprintf('%s_Figures', char(datetime('now','Format','yyyyMMdd'))));

fprintf('\nGroup mean file : %s\n', groupMeanFile);
fprintf('Created         : %s\n', G.created);
fprintf('Participants    : %d\n', nSub);
fprintf('Output          : %s\n\n', outDir);

%% ---------------- TIME AXIS ----------------
T = size(groupMean, 1);
switch string(timeUnit)
    case "min", t = (0:T-1).' * TR / 60;  xlab = 'Time (min)';
    case "s",   t = (0:T-1).' * TR;       xlab = 'Time (s)';
    otherwise,  t = (1:T).';              xlab = 'Volume';
end

%% ---------------- FIGURE 1: group mean CSF signal per slice ----------------
fig1 = figure('Color','w', 'Position',[100 100 1000 500]);
ax1  = axes(fig1); hold(ax1,'on');

cols = lines(nSlice);
for s = 1:nSlice
    if s == 1
        name = sprintf('Slice %d (bottom)', s);
    else
        name = sprintf('Slice %d', s);
    end
    plot(ax1, t, groupMean(:,s), '-', 'Color',cols(s,:), 'LineWidth',1.4, ...
         'DisplayName', name);
end
hold(ax1,'off');
xlabel(ax1, xlab);
ylabel(ax1, 'Group mean CSF signal (a.u.)');
title(ax1, sprintf('Group mean raw CSF signal per slice  (n = %d)', nSub));
legend(ax1, 'Location','northeast', 'Box','off');
grid(ax1,'off'); xlim(ax1, [t(1) t(end)]);

%% ---------------- FIGURE 2: contributing participants ----------------
if plotContributors
    fig2 = figure('Color','w', 'Position',[100 100 1000 320]);
    ax2  = axes(fig2);
    area(ax2, t, contributors, 'FaceColor',[0.80 0.83 0.90], 'EdgeColor',[0.45 0.50 0.62]);
    xlabel(ax2, xlab);
    ylabel(ax2, 'Participants (n)');
    title(ax2, sprintf(['Participants contributing to the group mean at each time point ' ...
                        '(n = %d at the start, %d at the end)'], ...
                       contributors(1), contributors(end)));
    xlim(ax2, [t(1) t(end)]); ylim(ax2, [0 nSub*1.05]); grid(ax2,'off');
end

%% ---------------- SAVE ----------------
if savePng
    p1 = fullfile(outDir, subDirMean, fileMean);
    savePlot(fig1, p1, dpi);
    fprintf('Figure saved to: %s\n', p1);

    if plotContributors
        p2 = fullfile(outDir, subDirContributors, fileContributors);
        savePlot(fig2, p2, dpi);
        fprintf('Figure saved to: %s\n', p2);
    end
end
fprintf('\nDone.\n');


%% ======================= HELPER =======================
function savePlot(fig, pngPath, dpi)
    folder = fileparts(pngPath);
    if ~exist(folder, 'dir'); mkdir(folder); end
    try
        exportgraphics(fig, pngPath, 'Resolution', dpi);
    catch
        print(fig, pngPath, '-dpng', sprintf('-r%d', dpi));
    end
end
