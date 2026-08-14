% File paths
z_file = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/pre_processing/average/gbold_p8_z_average.mat';
raw_file = '/Users/Richard/Masterabeit_local/SNORE_GM_Data/pre_processing/average_raw/gbold_p8_raw_average.mat';

% Load files
z_data = load(z_file);
raw_data = load(raw_file);

% Get signal variable from each file
z_fields = fieldnames(z_data);
raw_fields = fieldnames(raw_data);

gbold_z = z_data.(z_fields{1});
gbold_raw = raw_data.(raw_fields{1});

% Make sure signals are vectors
gbold_z = gbold_z(:);
gbold_raw = gbold_raw(:);

% Plot
figure;

plot(gbold_z, 'LineWidth', 1.2);
hold on;
plot(gbold_raw, 'LineWidth', 1.2);

xlabel('Time point');
ylabel('Signal');
legend('Z-scored gBOLD', 'Raw gBOLD');
title('Participant 8 gBOLD signals');

grid on;
box off;