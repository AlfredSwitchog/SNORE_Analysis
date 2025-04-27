% List of open inputs
% fMRI model specification: Onsets - cfg_entry
% fMRI model specification: Durations - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'/Users/Richard/Masterabeit_local/Scripts/SNORE_PreProc/_batchFiles/1stLevelGLMTest_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(2, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Onsets - cfg_entry
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % fMRI model specification: Durations - cfg_entry
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
