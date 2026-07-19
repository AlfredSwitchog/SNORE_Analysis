% Creates the plot for the 95th to 5th percentile for individual slices.
% To calculate the error bars it is necessary to load all individual
% averaged files, so that the variability across participants can be
% calculated.

% Group mean:Also the 95th/5th reatio is calculated on the averaged data
% itself as a comparison 

clear; clc;

%% === Paths ===
group_file = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Group_Average/csf_group_mean_per_slice_cleaned.mat';
data_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';

%% === Settings ===
slices = 1:4;
exclude_participants = [5 9];   % example: [5 12 33]

%% === Load group mean data ===
load(group_file, 'group_mean_csf_data');

%% === Helper ===
ratio95over5 = @(x) prctile(x,95) ./ prctile(x,5);

%% === 1) Group curve from group mean time series ===
group_ratio = nan(1, numel(slices));

for i = 1:numel(slices)
    sl = slices(i);

    if sl > numel(group_mean_csf_data) || isempty(group_mean_csf_data{sl})
        continue;
    end

    xg = group_mean_csf_data{sl};
    xg(xg == 0) = NaN;

    p95 = prctile(xg, 95, 'all');
    p5  = prctile(xg, 5, 'all');

    if ~isnan(p95) && ~isnan(p5) && p5 ~= 0
        group_ratio(i) = p95 / p5;
    end
end

%% === 2) Per-subject ratios per slice ===
files = dir(fullfile(data_folder, 'csf_p*_averaged.mat'));

all_ratios = [];
included_participants = [];

for f = 1:length(files)
    file_name = files(f).name;
    file_path = fullfile(data_folder, file_name);

    % Extract participant number
    tokens = regexp(file_name, 'csf_p(\d+)_averaged\.mat', 'tokens');
    if isempty(tokens)
        fprintf('Skipping file with unexpected name: %s\n', file_name);
        continue;
    end

    participant_id = str2double(tokens{1}{1});

    if ismember(participant_id, exclude_participants)
        fprintf('Excluding participant %d\n', participant_id);
        continue;
    end

    S = load(file_path);

    if ~isfield(S, 'averaged_csf_data')
        fprintf('Skipping %s (no averaged_csf_data found)\n', file_name);
        continue;
    end

    subj_slices = S.averaged_csf_data;
    subj_ratio = nan(1, numel(slices));

    for i = 1:numel(slices)
        sl = slices(i);

        if sl > numel(subj_slices) || isempty(subj_slices{sl})
            continue;
        end

        x = subj_slices{sl};
        x(x == 0) = NaN;

        p95 = prctile(x, 95, 'all');
        p5  = prctile(x, 5, 'all');

        if ~isnan(p95) && ~isnan(p5) && p5 ~= 0
            subj_ratio(i) = p95 / p5;
        end
    end

    all_ratios = [all_ratios; subj_ratio];
    included_participants(end+1) = participant_id;
end

%% === 3) Mean ± SEM across subjects ===
mean_subj = mean(all_ratios, 1, 'omitnan');
N_per_slice = sum(~isnan(all_ratios), 1);
sem_subj = std(all_ratios, 0, 1, 'omitnan') ./ sqrt(max(N_per_slice, 1));

%% === 4) Plot ===
figure; hold on;

h1 = errorbar(slices, mean_subj, sem_subj, '-o', 'LineWidth', 2, 'CapSize', 8);
h2 = plot(slices, group_ratio, '--s', 'LineWidth', 1.5);

xlabel('Slice Number');
ylabel('95th / 5th Percentile Ratio');
title('CSF Signal: Mean \pm SEM across subjects (overlay: group curve)');
grid on;
box off;
legend([h1 h2], {'Mean±SEM (subjects)', 'Group curve'}, 'Location', 'best');

%% === 5) Print summary ===
fprintf('\nIncluded participants:\n');
disp(included_participants)

fprintf('N per slice:\n');
disp(N_per_slice)