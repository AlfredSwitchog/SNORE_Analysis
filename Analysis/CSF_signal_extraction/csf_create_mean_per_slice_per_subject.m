csf_time_series = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_trimmed.mat';
load(csf_time_series);
%%
averaged_csf_data = cell(size(all_csf_data));  % same size as input

for subj = 1:numel(all_csf_data)
    subj_data = all_csf_data{subj};
    averaged_subj = cell(numel(subj_data), 1);  % one per slice

    for slice_idx = 1:numel(subj_data)
        slice_matrix = subj_data(slice_idx).signals;

        if ~isempty(slice_matrix)
            % Average across voxels (rows), result is 1 x timepoints
            averaged_subj{slice_idx} = mean(slice_matrix, 1);  % mean across voxels
        else
            averaged_subj{slice_idx} = [];
        end
    end

    averaged_csf_data{subj} = averaged_subj;
end

%% Save combined data
output_folder = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data';
output_path = fullfile(output_folder, 'csf_mean_per_slice_pre_subject.mat');
save(output_path, 'averaged_csf_data', '-v7.3');  % v7.3 handles large files
