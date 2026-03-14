% Create Trans_Z QC plots for all participants
base_dir = '/scratch/c7201319/SNORE_MR_out';
out_dir  = '/scratch/c7201319/SNORE_Analysis/QC/plots/trans_z_mm';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

subj_dirs = dir(base_dir);

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
        xlabel('Volume');
        ylabel('Trans Z (mm)');
        title(sprintf('Participant %s: Trans Z', subj_name));
        grid on;
        
        saveas(fig, fullfile(out_dir, sprintf('participant_%s_trans_z.png', subj_name)));
        close(fig);
        
        fprintf('Saved plot for participant %s\n', subj_name);
    end
end