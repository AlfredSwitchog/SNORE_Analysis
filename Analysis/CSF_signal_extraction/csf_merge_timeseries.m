% Set folder containing the .mat files
data_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Raw_Signal';
file_list = dir(fullfile(data_folder, '*.mat'));
output_path= '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data';

% Initialize output cell
all_csf_data = cell(1, numel(file_list));

for i = 1:numel(file_list)
    % Load each file
    file_path = fullfile(data_folder, file_list(i).name);
    loaded = load(file_path);  % Assumes variable is named 'slice_data_struct'
    
    % Check if 'slice_data_struct' exists
    if isfield(loaded, 'slice_data_struct')
        all_csf_data{i} = loaded.slice_data_struct;
    else
        warning('File %s does not contain "slice_data_struct". Skipping.', file_list(i).name);
    end
end

% Save combined data
out_file = fullfile(output_path, 'all_csf_data.mat');
save(out_file, 'all_csf_data', '-v7.3');  % v7.3 handles large files
