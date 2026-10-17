%% ============================================================
%  Group mean raw CSF signal in the four bottom slices
%  ------------------------------------------------------------
%  PLOTTING ONLY. The group mean is computed and saved by
%     CSF_raw_data_transformations/csf_create_group_mean_per_slice.m          (raw)
%     CSF_raw_data_transformations/csf_create_group_mean_per_slice_zscored.m  (z-scored)
%  and is only loaded here, so that re-running this script can never
%  change the underlying average. signalType selects which one is plotted.
%
%  Note on the z-scored version: each participant's slices are z-scored
%  separately, so all slices have SD 1 per participant and the amplitude
%  gradient between slices is removed by construction.
%
%  Expected inflow signature: slice 1 sits at the bottom of the imaging
%  volume and shows the largest fluctuations, decaying upwards.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
% Which group mean enters the plot
signalType = "zscore";   % "raw" | "zscore"

% Group mean files
%   raw    : written by csf_create_group_mean_per_slice.m
%   zscore : written by csf_create_group_mean_per_slice_zscored.m
%            (folder date = day that script was run; adjust if needed)
groupMeanFileRaw = ['/Users/Richard/Masterabeit_local/SNORE_CSF_Data/' ...
                    '20260813_Group_Average/csf_group_mean_per_slice.mat'];
groupMeanFileZ   = ['/Users/Richard/Masterabeit_local/SNORE_CSF_Data/' ...
                    '20261011_Group_Average/csf_group_mean_per_slice_zscored.mat'];

timeUnit = "min";     % "min" | "s" | "vol"   -> x-axis of the figure

plotContributors = true;   % second, separate figure: participants per time point

savePng  = true;
plotRoot = '/Users/Richard/Masterabeit_local/SNORE_Plots/Inflow_Effect';
dpi      = 200;

% Figures go to   <plotRoot>/<yyyymmdd>_Figures/<subfolder>/<file>.png
subDirMeanRaw      = 'group_level_raw_signal';
fileMeanRaw        = 'group_level_raw_csf_signal.png';
subDirMeanZ        = 'group_level_raw_signal_zscored';
fileMeanZ          = 'group_level_raw_csf_signal_zscored.png';
subDirContributors = 'group_level_contributing_participants';
fileContributors   = 'group_level_contributing_participants.png';

%% ---------------- SIGNAL TYPE ----------------
switch string(signalType)
    case "raw"
        groupMeanFile = groupMeanFileRaw;
        producer      = 'csf_create_group_mean_per_slice.m';
        subDirMean    = subDirMeanRaw;   fileMean = fileMeanRaw;
        ylab          = 'Group mean CSF signal (a.u.)';
        ttl           = 'Group mean raw CSF signal per slice';
    case "zscore"
        groupMeanFile = groupMeanFileZ;
        producer      = 'csf_create_group_mean_per_slice_zscored.m';
        subDirMean    = subDirMeanZ;     fileMean = fileMeanZ;
        ylab          = 'Group mean CSF signal (z)';
        ttl           = 'Group mean z-scored CSF signal per slice';
    otherwise
        error('signalType must be "raw" or "zscore", got "%s".', signalType);
end

%% ---------------- LOAD ----------------
assert(exist(groupMeanFile, 'file') == 2, ...
       ['Group mean file not found:\n  %s\n' ...
        'Run %s first.'], groupMeanFile, producer);

L = load(groupMeanFile, 'group_mean');
G = L.group_mean;

groupMean    = G.mean_per_slice;      % T x nSlice
contributors = G.n_contributors(:,1); % T x 1
nSub         = G.n_subjects;
nSlice       = G.n_slices;
TR           = G.TR;

outDir = fullfile(plotRoot, ...
                  sprintf('%s_Figures', char(datetime('now','Format','yyyyMMdd'))));

fprintf('\nSignal type     : %s\n', signalType);
fprintf('Group mean file : %s\n', groupMeanFile);
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
ylabel(ax1, ylab);
title(ax1, sprintf('%s  (n = %d)', ttl, nSub));
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
