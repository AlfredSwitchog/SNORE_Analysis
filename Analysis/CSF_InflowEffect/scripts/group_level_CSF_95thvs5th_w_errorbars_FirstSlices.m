% Creates the plot for the 95th to 5th percentile for individual slices.
% To calculate the error bars it is necessary to load all individual
% averaged files, so that the variability across participants can be
% calculated.
%
% Two orders of operations are possible and they give different answers:
%   A) ratio first, then average : compute the 95th/5th ratio for every
%      participant, then average those ratios. This describes the typical
%      participant and is the curve to report.
%   B) average first, then ratio : average the participants into one mean
%      signal, then compute the ratio on that averaged signal. This comes
%      out much smaller, because the CSF waves of different participants
%      are not synchronised with each other, so one person's peak lands on
%      another's trough and they partly cancel when averaged. The averaged
%      signal is therefore flatter than any individual one.
% Both are plotted: A with error bars, B as a comparison line.
%
% Requires the Statistics and Machine Learning Toolbox (prctile).

clear; clc;

%% === Paths ===
group_file  = ['/Users/Richard/Masterabeit_local/SNORE_CSF_Data/' ...
               '20260813_Group_Average/csf_group_mean_per_slice.mat'];
data_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';

signal_var  = 'averaged_slices';        % T x nSlice in each participant file

%% === Settings ===
slices = 1:4;

% Participants entering the mean and the error bars.
% [] = every csf_p*_averaged.mat found in data_folder.
subjects = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

save_png  = true;
plot_root = '/Users/Richard/Masterabeit_local/SNORE_Plots/Inflow_Effect';
sub_dir   = 'group_level_95th_to_5th';
file_name = 'group_level_95th_to_5th.png';
dpi       = 200;

out_dir = fullfile(plot_root, ...
                   sprintf('%s_Figures', char(datetime('now','Format','yyyyMMdd'))), ...
                   sub_dir);

%% === Load group mean data ===
assert(exist(group_file, 'file') == 2, ...
       ['Group mean file not found:\n  %s\n' ...
        'Run csf_create_group_mean_per_slice.m first.'], group_file);

L = load(group_file, 'group_mean');
G = L.group_mean;
group_mean_per_slice = G.mean_per_slice;      % T x nSlice

fprintf('\nGroup mean file : %s\n', group_file);
fprintf('Created         : %s\n', G.created);
fprintf('Built from      : %d participant(s)\n\n', G.n_subjects);

%% === 1) Group curve from the group mean time series ===
group_ratio = nan(1, numel(slices));

for i = 1:numel(slices)
    sl = slices(i);
    if sl > size(group_mean_per_slice, 2); continue; end

    xg = group_mean_per_slice(:, sl);
    xg(xg == 0) = NaN;
    xg = xg(isfinite(xg));
    if numel(xg) < 2; continue; end

    p95 = prctile(xg, 95);
    p5  = prctile(xg,  5);
    if p5 > 0
        group_ratio(i) = p95 / p5;
    end
end

%% === 2) Per-subject ratios per slice ===
if isempty(subjects)
    files = dir(fullfile(data_folder, 'csf_p*_averaged.mat'));
    subjects = [];
    for f = 1:numel(files)
        tok = regexp(files(f).name, 'csf_p(\d+)_averaged\.mat', 'tokens', 'once');
        if ~isempty(tok); subjects(end+1) = str2double(tok{1}); end %#ok<SAGROW>
    end
    subjects = sort(subjects);
end
subjects = subjects(:).';

all_ratios = [];
included_participants = [];

for participant_id = subjects
    file_path = fullfile(data_folder, sprintf('csf_p%d_averaged.mat', participant_id));

    if exist(file_path, 'file') ~= 2
        fprintf('Participant %d: file not found, skipped\n', participant_id);
        continue;
    end

    S = load(file_path, signal_var);
    if ~isfield(S, signal_var)
        fprintf('Participant %d: no "%s" found, skipped\n', participant_id, signal_var);
        continue;
    end

    X = S.(signal_var);
    if size(X,1) < size(X,2); X = X.'; end     % time is the long dimension

    subj_ratio = nan(1, numel(slices));

    for i = 1:numel(slices)
        sl = slices(i);
        if sl > size(X,2); continue; end

        x = X(:, sl);
        x(x == 0) = NaN;
        x = x(isfinite(x));
        if numel(x) < 2; continue; end

        p95 = prctile(x, 95);
        p5  = prctile(x,  5);
        if p5 > 0
            subj_ratio(i) = p95 / p5;
        end
    end

    if all(isnan(subj_ratio))
        fprintf('Participant %d: no valid slice, skipped\n', participant_id);
        continue;
    end

    all_ratios = [all_ratios; subj_ratio];              %#ok<AGROW>
    included_participants(end+1) = participant_id;      %#ok<SAGROW>
end

assert(~isempty(all_ratios), 'No participant data could be loaded from %s', data_folder);

%% === 3) Mean +/- SEM across subjects ===
mean_subj   = mean(all_ratios, 1, 'omitnan');
N_per_slice = sum(~isnan(all_ratios), 1);
sem_subj    = std(all_ratios, 0, 1, 'omitnan') ./ sqrt(max(N_per_slice, 1));

%% === 4) Plot ===
fh = figure('Color','w', 'Position',[100 100 720 520]);
hold on;

h1 = errorbar(slices, mean_subj, sem_subj, '-o', 'LineWidth', 2, 'CapSize', 8);
h2 = plot(slices, group_ratio, '--s', 'LineWidth', 1.5);

xlabel('Slice (1 = bottom of the imaging volume)');
ylabel('95th / 5th percentile ratio');
title(sprintf(['CSF signal amplitude across slices\n' ...
               'mean \\pm SEM across participants (n = %d), ' ...
               'overlay: ratio computed on the group mean signal'], ...
              numel(included_participants)));
xticks(slices); xlim([slices(1)-0.3 slices(end)+0.3]);
yline(1, 'k:', 'HandleVisibility','off');
grid off; box off;
legend([h1 h2], {sprintf('mean \\pm SEM across participants (n = %d)', ...
                         numel(included_participants)), ...
                 'ratio computed on the group mean signal'}, ...
                'Location','northeast', 'Box','off');
hold off;

%% === 5) Save ===
if save_png
    if ~exist(out_dir, 'dir'); mkdir(out_dir); end
    out_png = fullfile(out_dir, file_name);
    try
        exportgraphics(fh, out_png, 'Resolution', dpi);
    catch
        print(fh, out_png, '-dpng', sprintf('-r%d', dpi));
    end
    fprintf('Figure saved to: %s\n', out_png);
end

%% === 6) Print summary ===
fprintf('\nIncluded participants (n = %d):\n', numel(included_participants));
disp(included_participants)

fprintf('%-8s %10s %10s %8s %18s\n', ...
        'slice','mean','SEM','N','on group mean sig');
fprintf('%s\n', repmat('-',1,54));
for i = 1:numel(slices)
    fprintf('%-8d %10.3f %10.3f %8d %14.3f\n', ...
            slices(i), mean_subj(i), sem_subj(i), N_per_slice(i), group_ratio(i));
end
fprintf('%s\n', repmat('-',1,54));
fprintf(['The two columns differ by construction. Averaging the participants\n' ...
         'first cancels their unsynchronised fluctuations, so the ratio taken\n' ...
         'on the group mean signal is smaller than the typical participant''s.\n' ...
         'Report the mean +/- SEM column.\n\nDone.\n']);
