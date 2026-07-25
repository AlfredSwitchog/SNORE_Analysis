%% Load raw
raw_signal = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/Raw_Signals/gbold_p8.mat'; 
load(raw_signal, "gbold_data");
gbold = gbold_data{1}.voxelwise_signal;

%% Load z-score
z_score = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/z_score_corrected/gbold_p8_z_score_corrected.mat'; 
gbold_data_z_scored = load(z_score, "gbold_data");
gbold_z = gbold_data_z_scored.gbold_data{1}.voxelwise_z;

%% Load average
average = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/average/gbold_p8_z_average.mat'; 
load(average);

%% mean and std

% Row-wise means and SDs
raw_mean = mean(gbold, 2);
raw_sd   = std(gbold, 0, 2);

z_mean = mean(gbold_z, 2);
z_sd   = std(gbold_z, 0, 2);

fprintf('Raw data:\n');
fprintf('  Mean of voxel means: %.6f\n', mean(raw_mean));
fprintf('  Mean of voxel SDs  : %.6f\n', mean(raw_sd));

fprintf('Z-scored data:\n');
fprintf('  Max abs voxel mean : %.6e\n', max(abs(z_mean)));
fprintf('  Mean voxel SD      : %.6f\n', mean(z_sd));

%% 
% Count rows that are all zero after z-scoring
all_zero_rows = all(gbold_z == 0, 2);
fprintf('  Number of all-zero rows in z-data: %d\n', sum(all_zero_rows));

% For non-zero rows, check closeness to SD=1
nonzero_rows = ~all_zero_rows;
fprintf('  Mean voxel SD (non-zero rows): %.6f\n', mean(z_sd(nonzero_rows)));
fprintf('  Min voxel SD (non-zero rows) : %.6f\n', min(z_sd(nonzero_rows)));
fprintf('  Max voxel SD (non-zero rows) : %.6f\n', max(z_sd(nonzero_rows)));

%% One examploratory voxel
i = 1;  % example voxel
raw_row = gbold(i,:);
z_row   = gbold_z(i,:);

fprintf('mean raw row: %.6f\n', mean(raw_row));
fprintf('mean z row: %.6f\n', mean(z_row));
fprintf('std raw row: %.6f\n', std(raw_row, 0, 2));
fprintf('std z row: %.6f\n', std(z_row, 0, 2));

%% save output file
participant_id='8';
output_dir = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/z_score_corrected';
out_file = fullfile(output_dir, sprintf('gbold_p%s_z_score_corrected.mat', participant_id));
voxelwise_z = gbold_z;
save(out_file, 'voxelwise_z', '-v7.3');

%% check if average calculation worked
mean_z_score_man = mean(gbold_z, 1);

mean_z_score_man(1:5)
mean_signal(1:5)


