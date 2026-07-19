clear; clc;

%% Path to group mean file
input_file = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Group_Average/csf_group_mean_per_slice_cleaned.mat';

load(input_file, 'group_mean_csf_data');

%% Plot raw group mean signal for each slice
figure;
hold on;

num_slices = numel(group_mean_csf_data);

for i = 1:num_slices
    slice_data = group_mean_csf_data{i};

    if ~isempty(slice_data)
        plot(slice_data, 'LineWidth', 1.5);
    end
end

xlabel('Timepoint');
ylabel('Group mean CSF signal');
title('Raw Group Mean CSF Signal per Slice');
legend(arrayfun(@(x) sprintf('Slice %d', x), 1:num_slices, 'UniformOutput', false), ...
    'Location', 'best');
grid on;
hold off;