%% ============== USER SETTINGS ==============
all_subjects_path = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat';

%% ============== LOAD DATA ==============
S = load(all_subjects_path);
all_subjects = S.averaged_csf_data;   % 1x57 cell array (subjects)

%% ============== REMOVE EMPTY SLICES ==============
nSubj = numel(all_subjects);

for s = 1:nSubj
    subj_data = all_subjects{s};   % nx1 cell array (slices)
    
    % Keep only slices that are not all zeros
    keep_idx = true(size(subj_data));
    for sl = 1:numel(subj_data)
        slice_data = subj_data{sl};   % 1xn vector of timepoints
        if all(slice_data == 0)
            keep_idx(sl) = false;    % mark slice for removal
        end
    end
    
    % Update subject data
    all_subjects{s} = subj_data(keep_idx);
end

%% ============== SAVE CLEANED DATA ==============
save('/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject_cleaned.mat','all_subjects', '-v7.3');
