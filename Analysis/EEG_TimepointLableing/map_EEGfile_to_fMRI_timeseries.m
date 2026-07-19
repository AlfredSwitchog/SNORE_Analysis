%% --------------- CONFIG ----------------
all_subjects_path  = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat';
csvFile            = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_cleaned';  % can be a single CSV file OR a folder containing per-subject CSVs
TR                 = 2.5;                  % seconds
eegLeadsSeconds    = 2.5;                  % EEG starts earlier by 2.5 s
outOfRangeLabel    = "NA";                 % label for out-of-range volumes
requireSameT       = true;                 % enforce same T within each subject, not accross subjects
subjects_to_map    = [17];                   % e.g., [1 2 5]; empty [] => map all subjects

