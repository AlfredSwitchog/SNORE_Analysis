%% === User settings ===
file_path = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260329_Raw_Signals/csf_p46.mat';

%% === Load file ===
S = load(file_path);

% Extract matrix
averaged_slices = S.slice_data_struct;

%% === Plot raw signal per slice ===
figure; hold on;
numSlices = size(averaged_slices, 1);

for i = 1:numSlices
    sliceData = averaged_slices(i, :);   % one row = one slice time series
    plot(sliceData, 'LineWidth', 1.5);
end

xlabel('Time (volumes)');
ylabel('CSF signal (a.u.)');
title('Raw CSF Signal Per Slice');
legend(arrayfun(@(x) sprintf('Slice %d', x), 1:numSlices, 'UniformOutput', false));
grid on;