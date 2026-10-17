% Create Trans_Z QC plots for all participants
base_dir = '/scratch/c7201319/SNORE_MR_out';
out_dir  = '/scratch/c7201319/SNORE_Analysis/QC/plots/trans_z_mm';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

subj_dirs = dir(base_dir);

% -------------------------------
% First pass: common y-axis range across all participants
% -------------------------------
range_thresh = 5;   % inclusion criterion: max(Trans_Z) - min(Trans_Z) must be <= range_thresh (mm)
y_lo =  Inf;
y_hi = -Inf;

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
        
        trans_z = rp(:,3);
        z_min = min(trans_z);
        z_max = max(trans_z);
        
        % axis must show both the trace and the inclusion band [min, min + range_thresh]
        y_lo = min(y_lo, z_min);
        y_hi = max(y_hi, max(z_max, z_min + range_thresh));
    end
end

% Common y-axis limits across participants (5% margin)
pad = 0.05 * (y_hi - y_lo);
y_limits = [y_lo - pad, y_hi + pad];

% -------------------------------
% Second pass: create plots with common y-axis
% -------------------------------
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
        
        vol_idx = (1:size(rp,1))';
        trans_z = rp(:,3);
        
        fig = figure('Visible', 'off');
        plot(vol_idx, trans_z, 'k', 'LineWidth', 1);
        hold on
        
        % Inclusion band: Trans_Z range (max - min) must not exceed range_thresh
        z_min    = min(trans_z);
        z_range  = max(trans_z) - z_min;
        included = z_range <= range_thresh;
        yline(z_min, '--r', 'min', 'LineWidth', 1);
        yline(z_min + range_thresh, '--r', sprintf('min + %g mm', range_thresh), 'LineWidth', 1);
        
        xlabel('Volume');
        ylabel('Trans Z (mm)');
        if included, status = 'included'; else, status = 'EXCLUDED'; end
        title(sprintf('Participant %s: Trans Z (range = %.2f mm, %s)', subj_name, z_range, status));
        ylim(y_limits);
        grid on;
        
        saveas(fig, fullfile(out_dir, sprintf('participant_%s_trans_z.png', subj_name)));
        close(fig);
        
        fprintf('Saved plot for participant %s\n', subj_name);
    end
end