% List participants whose maximum absolute Trans_Z movement stays within ±5 mm

base_dir = '/scratch/c7201319/SNORE_MR_out';

subj_dirs = dir(base_dir);
participants_within_5mm = {};
max_abs_trans_z_values = [];

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
        subj_max_abs_z = max(abs(trans_z));
        
        if subj_max_abs_z <= 5
            participants_within_5mm{end+1,1} = subj_name;
            max_abs_trans_z_values(end+1,1) = subj_max_abs_z;
        end
    end
end

fprintf('\nParticipants with max |Trans Z| <= 5 mm:\n');
for i = 1:numel(participants_within_5mm)
    fprintf('Participant %s: max |Trans Z| = %.3f mm\n', ...
        participants_within_5mm{i}, max_abs_trans_z_values(i));
end