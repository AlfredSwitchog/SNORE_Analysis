% Number of slices to plot
num_slices_to_plot = min(4, numel(group_mean_csf_data));

% Create a new figure
figure;
hold on;

% Loop through the first 4 slices and plot the CSF signal
for slice_idx = 1:num_slices_to_plot
    slice_signal = group_mean_csf_data{slice_idx};

    if isempty(slice_signal)
        warning('Slice %d has no data. Skipping.', slice_idx);
        continue;
    end

    plot(slice_signal, 'LineWidth', 1.5);
end

% Formatting the plot
title('Group-Averaged CSF Signal for First 4 Slices');
xlabel('Timepoint');
ylabel('Raw Signal');
legend(arrayfun(@(x) sprintf('Slice %d', x), 1:num_slices_to_plot, 'UniformOutput', false));
grid on;
hold off;

%% mean value per slice

% Preallocate mean values
num_slices = numel(group_mean_csf_data);
mean_signal_per_slice = nan(1, num_slices);

% Compute mean across timepoints for each slice
for slice_idx = 1:num_slices
    signal = group_mean_csf_data{slice_idx};
    if isempty(signal)
        warning('Slice %d has no data. Skipping.', slice_idx);
        continue;
    end
    mean_signal_per_slice(slice_idx) = mean(signal, 'omitnan');
end

% Plot mean signal per slice
figure;
bar(1:num_slices, mean_signal_per_slice);
xlabel('Slice Index');
ylabel('Mean CSF Signal');
title('Mean Group CSF Signal per Slice');
grid on;
