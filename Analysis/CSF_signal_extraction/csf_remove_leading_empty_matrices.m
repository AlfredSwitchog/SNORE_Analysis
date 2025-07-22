for subj = 1:numel(all_csf_data)
    data = all_csf_data{subj};  % struct array
    
    % Extract whether each struct has a non-empty .signal field
    has_signal = arrayfun(@(s) ~isempty(s.signals), data);
    
    % Find first struct with signal
    first_valid_idx = find(has_signal, 1, 'first');
    
    if ~isempty(first_valid_idx)
        % Keep from the first valid struct onward
        all_csf_data{subj} = data(first_valid_idx:end);
    else
        % If all entries are empty, optionally set to empty
        all_csf_data{subj} = struct('signal', []);
    end
end

%% Save combined data
output_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data';
output_path = fullfile(output_folder, 'csf_trimmed.mat');
save(output_path, 'all_csf_data', '-v7.3');  % v7.3 handles large files

