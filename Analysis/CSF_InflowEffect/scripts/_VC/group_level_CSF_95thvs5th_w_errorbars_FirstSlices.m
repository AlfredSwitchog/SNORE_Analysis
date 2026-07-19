%% === Load data ===
% group_mean_csf_data: 20x1 cell, each cell is 1xT group-mean time series for that slice
load('/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_group_mean_per_slice.mat', ...
     'group_mean_csf_data');

% averaged_csf_data: {subject}->{slice}->1xT subject time series
load('/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat', ...
     'averaged_csf_data');

%% === Settings ===
slices = 1:7;
ratio95over5 = @(x) (prctile(x,95) ./ prctile(x,5)); %takes 1 x as input 

%% === 1) Group curve (from group-mean time series) ===
group_ratio = nan(1,numel(slices)); %empty vector to store the values

for i = 1:numel(slices)
    sl = slices(i);

    %safety check for missing data
    if sl > numel(group_mean_csf_data) || isempty(group_mean_csf_data{sl}), continue; end
    
    xg = group_mean_csf_data{sl};

    xg(xg==0) = NaN; % replace 0 with NaN

    p95 = prctile(xg,95,'all'); 
    p5 = prctile(xg,5,'all');

    %check that neither percentile value is nan and avoid devision by zero
    if ~isnan(p95) && ~isnan(p5) && p5~=0
        group_ratio(i) = p95 / p5; %store the result in group_ratio vector
    end
end

%% === 2) Per-subject ratios per slice (for SEM across subjects) ===
nSubj = numel(averaged_csf_data);
subj_ratios = nan(nSubj, numel(slices)); % rows=subjects, cols=slices

for s = 1:nSubj
    subj_slices = averaged_csf_data{s};
    for i = 1:numel(slices)
        sl = slices(i);
        if sl > numel(subj_slices) || isempty(subj_slices{sl}), continue; end
        x = subj_slices{sl};
        x(x==0) = NaN; % optional
        p95 = prctile(x,95,'all'); p5 = prctile(x,5,'all');
        if ~isnan(p95) && ~isnan(p5) && p5~=0
            subj_ratios(s,i) = p95 / p5;
        end
    end
end

% Mean ± SEM across subjects
mean_subj = mean(subj_ratios, 1, 'omitnan');
N_per_slice = sum(~isnan(subj_ratios), 1);
sem_subj  = std(subj_ratios, 0, 1, 'omitnan') ./ sqrt(max(N_per_slice,1));

%% === 3) Plot ===
figure; hold on
% Statistically consistent: center = mean of subject ratios; error = SEM across subjects
h1 = errorbar(slices, mean_subj, sem_subj, '-o', 'LineWidth', 2, 'CapSize', 8);
% Optional: overlay your group curve for comparison (no error bars on it)
h2 = plot(slices, group_ratio, '--s', 'LineWidth', 1.5);

xlabel('Slice Number');
ylabel('95th / 5th Percentile Ratio');
title('CSF Signal (first 7 slices): Mean ± SEM across subjects (overlay: group curve)');
grid on; box off;
legend([h1 h2], {'Mean±SEM (subjects)', 'Group curve'}, 'Location', 'best');
