% Load motion parameters
rp = load('/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/29/rp_MFHE97CF261124-0007-00001-000001.txt');

% Create volume index (matches original EPI volume number)
VolumeIndex = (1:size(rp,1))';

% Convert to table with labeled columns
rp_table = table( ...
    VolumeIndex, ...
    rp(:,1), rp(:,2), rp(:,3), ...
    rp(:,4), rp(:,5), rp(:,6), ...
    'VariableNames', { ...
        'VolumeIndex', ...
        'Trans_X_mm', ...
        'Trans_Y_mm', ...
        'Trans_Z_mm', ...
        'Rot_Pitch_rad', ...
        'Rot_Roll_rad', ...
        'Rot_Yaw_rad' ...
    });

% Display first rows
head(rp_table)

% Sort table by Z translation
rp_sorted = sortrows(rp_table, 'Trans_Z_mm');

% 5 lowest Z values
lowest_z = rp_sorted(1:20, :);

% 5 highest Z values
highest_z = rp_sorted(end-4:end, :);

figure;

plot(rp_table.VolumeIndex, rp_table.Trans_Z_mm, 'k', 'LineWidth', 1);

xlabel('Volume');
ylabel('Z Translation (mm)');
title('QC Plot: Z Translation Across Volumes');

grid on;


