% --- Settings ---
merged_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/filt_preproc_out/filtered_s3uaMFRO01GG010724.nii';     % Your 4D merged data
filtered_file = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/filt_preproc_out/filtered_s3uaMFRO01GG010724.nii';     % Your 4D filtered data
TR = 2.5;

% --- Load 4D data ---
V_m = spm_vol(merged_file);
Y_m = spm_read_vols(V_m);  % Y: [X, Y, Z, Time]

V_f = spm_vol(filtered_file);
Y_f = spm_read_vols(V_f);  % Y: [X, Y, Z, Time]

%% --- Reshape to [voxels x time] ---
dims = size(Y_m);
n_timepoints = dims(4);
Y_m_reshaped = reshape(Y_m, [], n_timepoints); % Merged 
Y_f_reshaped = reshape(Y_f, [], n_timepoints); % Filtered

%% --- Pick a random voxel (or specify coordinates) ---
voxel_idx = 117001;  % Example: voxel number 5000

original_timeseries = Y_m_reshaped(voxel_idx, :);
filtered_timeseries = Y_f_reshaped(voxel_idx, :);

% --- Time vector for x-axis ---
time_vec = (0:n_timepoints-1) * TR;

% --- Plot ---
figure;
plot(time_vec, original_timeseries, 'b-', 'LineWidth', 1.5); hold on;
%plot(time_vec, filtered_timeseries, 'r-', 'LineWidth', 1.5);
xlabel('Time (seconds)');
ylabel('Signal Intensity');
legend('Original', 'Filtered');
title(sprintf('Voxel %d: Before and After Highpass Filtering', voxel_idx));
grid on;

%% Frequency analysis of a single voxel

Fs = 1 / TR;  % Sampling rate
voxel_idx = 116968;  % Just pick a voxel index

% Get time series
voxel_timeseries = Y_m_reshaped(voxel_idx, :);

% FFT
N = length(voxel_timeseries);
fft_voxel = fft(voxel_timeseries);
fft_magnitude = abs(fft_voxel);

% Frequency axis
freq = (0:N-1)*(Fs/N);

% Plot frequency spectrum
figure;
plot(freq, fft_magnitude);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title(['Voxel ' num2str(voxel_idx) ' frequency content']);
xlim([0 0.1]);  % Focus on low frequencies

