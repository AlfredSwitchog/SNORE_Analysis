% Create participant movement summary CSV
% Columns:
% - Participant
% - MinTransZ_mm
% - MaxTransZ_mm
% - RangeTransZ_mm
% - MeanFD_mm
%
% Sorted by RangeTransZ_mm (largest to smallest)

base_dir = '/scratch/c7201319/SNORE_MR_out';
out_dir  = '/scratch/c7201319/SNORE_Analysis/QC';
out_csv  = fullfile(out_dir, 'participant_movement_summary.csv');

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

subj_dirs = dir(base_dir);

% Radius for FD rotation-to-mm conversion
r = 50;

% Initialize containers
participant_ids = {};
min_trans_z_vals = [];
max_trans_z_vals = [];
range_trans_z_vals = [];
mean_fd_vals = [];

for i = 1:numel(subj_dirs)
    subj_name = subj_dirs(i).name;
    
    % keep numeric participant folders only
    if subj_dirs(i).isdir && ~startsWith(subj_name, '.') && all(isstrprop(subj_name, 'digit'))
        
        meanEPI_dir = fullfile(base_dir, subj_name, 'meanEPI');
        if ~exist(meanEPI_dir, 'dir')
            continue
        end
        
        rp_file = dir(fullfile(meanEPI_dir, 'rp*.txt'));
        if isempty(rp_file)
            fprintf('No rp file found for participant %s\n', subj_name);
            continue
        end
        
        rp_path = fullfile(meanEPI_dir, rp_file(1).name);
        rp = load(rp_path);
        
        % Require 6 motion parameters
        if size(rp,2) < 6
            fprintf('rp file for participant %s does not have 6 columns\n', subj_name);
            continue
        end
        
        % -------------------------
        % Z translation summary
        % -------------------------
        trans_z = rp(:,3);
        min_trans_z = min(trans_z);
        max_trans_z = max(trans_z);
        range_trans_z = max_trans_z - min_trans_z;
        
        % -------------------------
        % Mean FD summary
        % -------------------------
        trans = rp(:,1:3);   % mm
        rot   = rp(:,4:6);   % radians
        
        d_trans = diff(trans, 1, 1);
        d_rot   = diff(rot, 1, 1);
        
        fd = sum(abs(d_trans), 2) + sum(r * abs(d_rot), 2);
        mean_fd = mean(fd);
        
        % -------------------------
        % Store results
        % -------------------------
        participant_ids{end+1,1} = subj_name;
        min_trans_z_vals(end+1,1) = min_trans_z;
        max_trans_z_vals(end+1,1) = max_trans_z;
        range_trans_z_vals(end+1,1) = range_trans_z;
        mean_fd_vals(end+1,1) = mean_fd;
    end
end

% Create summary table
summary_table = table( ...
    participant_ids, ...
    min_trans_z_vals, ...
    max_trans_z_vals, ...
    range_trans_z_vals, ...
    mean_fd_vals, ...
    'VariableNames', { ...
        'Participant', ...
        'MinTransZ_mm', ...
        'MaxTransZ_mm', ...
        'RangeTransZ_mm', ...
        'MeanFD_mm'} ...
    );

% Sort by z translation movement range (largest first)
summary_table = sortrows(summary_table, 'RangeTransZ_mm', 'descend');

% Save CSV
writetable(summary_table, out_csv);

fprintf('\nSaved movement summary CSV to:\n%s\n', out_csv);
disp(summary_table);