% === Define folders ===
input_dir = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/preproc_out';         % Unfiltered 3D images
filtered_dir = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/filt_preproc_out'; % Highpass filtered images

% === Gunzip .nii.gz files if necessary ===
gunzip(fullfile(input_dir, '*.nii.gz'));
gunzip(fullfile(filtered_dir, '*.nii.gz'));

% === Get sorted list of .nii files ===
raw_files = spm_select('ExtFPList', input_dir, '^.*\.nii$', Inf);
filt_files = spm_select('ExtFPList', filtered_dir, '^.*\.nii$', Inf);

% === Choose voxel coordinate ===
voxel_mm = [30, -20, 40];  % Example MNI or scanner space coordinate

% === Load header to transform voxel coordinates ===
V = spm_vol(raw_files(1,:));  % Load first image for raw
xyz_voxel = round(inv(V.mat) * [voxel_mm 1]'); % Transform mm to voxel space

% === Extract raw and filtered time series ===
n_vols = size(raw_files, 1);
raw_ts = zeros(n_vols, 1);
filt_ts = zeros(n_vols, 1);

for i = 1:n_vols
    V_raw = spm_vol(raw_files(i,:));
    vol_raw = spm_read_vols(V_raw);
    raw_ts(i) = vol_raw(xyz_voxel(1), xyz_voxel(2), xyz_voxel(3));

    V_filt = spm_vol(filt_files(i,:));
    vol_filt = spm_read_vols(V_filt);
    filt_ts(i) = vol_filt(xyz_voxel(1), xyz_voxel(2), xyz_voxel(3));
end

% === Plot time courses ===
figure;
plot(raw_ts, 'b', 'DisplayName', 'Raw');
hold on;
plot(filt_ts, 'r', 'DisplayName', 'Filtered');
xlabel('Time (volume)');
ylabel('Signal intensity');
legend;
title(sprintf('Time series at [%d %d %d] mm', voxel_mm));

% === Frequency domain analysis ===
TR = 2.5;
Fs = 1 / TR;
freqs = (0:n_vols-1)*(Fs/n_vols);
raw_fft = abs(fft(raw_ts));
filt_fft = abs(fft(filt_ts));

figure;
plot(freqs, raw_fft, 'b', 'DisplayName', 'Raw');
hold on;
plot(freqs, filt_fft, 'r', 'DisplayName', 'Filtered');
xline(0.01, '--k', '0.01 Hz cutoff');
xlim([0 0.1]);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
legend;
title('Voxel Power Spectrum');

