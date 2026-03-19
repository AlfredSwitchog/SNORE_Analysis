% Create overall movement QC plots and summary using Framewise Displacement (FD)
% Based on Power et al. (2012):
% FD_t = |dx| + |dy| + |dz| + r*|dalpha| + r*|dbeta| + r*|dgamma|
% where rotations are converted from radians to mm using r = 50 mm.

base_dir = '/scratch/c7201319/SNORE_MR_out';
out_dir  = '/scratch/c7201319/SNORE_Analysis/QC/plots/rp_overall_movement';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

subj_dirs = dir(base_dir);

% Rotation radius in mm for converting radians to approximate arc length
r = 50;

% Threshold often used in Power-style QC
fd_thresh = 0.5;

% Summary containers
participant_ids = {};
mean_fd_values = [];
max_fd_values = [];
pct_fd_over_thresh = [];
n_volumes = [];

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
        
        % Columns:
        % 1-3 = translations (mm)
        % 4-6 = rotations (radians)
        trans = rp(:,1:3);
        rot   = rp(:,4:6);
        
        % Backward differences between consecutive volumes
        d_trans = diff(trans, 1, 1);   % mm
        d_rot   = diff(rot, 1, 1);     % radians
        
        % Convert rotational changes to mm
        d_rot_mm = r * abs(d_rot);
        
        % Power FD for volumes 2..N
        fd = sum(abs(d_trans), 2) + sum(d_rot_mm, 2);
        
        % Prepend first volume with 0 so plotting aligns with original volume count
        fd_plot = [0; fd];
        vol_idx = (1:numel(fd_plot))';
        
        % Participant summary metrics
        mean_fd = mean(fd);
        max_fd  = max(fd);
        pct_over = 100 * mean(fd > fd_thresh);
        
        % Store summary
        participant_ids{end+1,1} = subj_name;
        mean_fd_values(end+1,1) = mean_fd;
        max_fd_values(end+1,1) = max_fd;
        pct_fd_over_thresh(end+1,1) = pct_over;
        n_volumes(end+1,1) = size(rp,1);
        
        % Create per-participant plot
        fig = figure('Visible', 'off');
        plot(vol_idx, fd_plot, 'k', 'LineWidth', 1);
        hold on
        yline(fd_thresh, '--r', 'LineWidth', 1);
        
        xlabel('Volume');
        ylabel('Framewise Displacement (mm)');
        title(sprintf(['Participant %s: FD\n' ...
                       'Mean FD = %.3f mm | Max FD = %.3f mm | %.2f%% > %.1f mm'], ...
                       subj_name, mean_fd, max_fd, pct_over, fd_thresh));
        grid on
        
        saveas(fig, fullfile(out_dir, sprintf('participant_%s_fd.png', subj_name)));
        close(fig);
        
        fprintf('Saved FD plot for participant %s\n', subj_name);
    end
end

% Create summary table
summary_table = table(participant_ids, n_volumes, mean_fd_values, max_fd_values, pct_fd_over_thresh, ...
    'VariableNames', {'Participant', 'NumVolumes', 'MeanFD_mm', 'MaxFD_mm', 'PercentFDOver0p5'});

% Sort by mean FD ascending
summary_table = sortrows(summary_table, 'MeanFD_mm');

% Save summary table
summary_csv = fullfile(out_dir, 'participant_fd_summary.csv');
writetable(summary_table, summary_csv);

fprintf('\nSaved participant FD summary to:\n%s\n', summary_csv);
disp(summary_table);