function SNORE_preprocessing_STC_S3(participant_id)
    %% ******************************************* %%
    % Pipeline preproc - SNORE Part 2. After Skull stripping. Smoothing
    % with a 3x3x3 Kernel
    %
    % Richard Lohr 15012025
    % version 1: Initial version

    % Requires SPM12 and functions from (nc_SPM_Process)
    % ***************************************** %%
    
    % Clear everything except function parameters
    clearvars -except participant_id;
    fprintf('Processing participant %d\n', participant_id);

    %% Set environment: 'local', 'leo5_prod', or 'leo5_test'
    env = 'leo5_prod';  % <-- Change this to the appropriate environment
    
    if strcmpi(env, 'local')
        scriptpath  = '/Users/Richard/Masterabeit_local/SNORE_Analysis/PreProc';
        generalpath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev';
        outputpath  = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out';
        spm_path    = '/Users/Richard/MatLAB/spm12_dev';
    
    elseif strcmpi(env, 'leo5_prod')
        scriptpath  = '/scratch/c7201319/SNORE_Analysis/PreProc';
        generalpath = '/scratch/c7201319/SNORE_MRI';
        outputpath  = '/scratch/c7201319/SNORE_MR_out';
        spm_path    = '/scratch/c7201319/spm12_dev';
    
    elseif strcmpi(env, 'leo5_test')
        scriptpath  = '/scratch/c7201319/SNORE_Analysis/PreProc';
        generalpath = '/scratch/c7201319/SNORE_MRI_data_dev';
        outputpath  = '/scratch/c7201319/SNORE_MRI_data_dev_out';
        spm_path    = '/scratch/c7201319/spm12_dev';
    
    else
        error('Unknown environment "%s". Choose from: local, leo5_prod, leo5_test.', env);
    end

    % Add SPM
    addpath(spm_path)
    fprintf('SPM used: %s\n', spm_path);

    % Add scriptpath
    addpath([scriptpath '/nc_SPM_process']);
    addpath(scriptpath);

    %% Set study parameters
    TR = 2.5; % Repetition time (s)
    nslices = 72;
    Smoothingkernel = [3 3 3];

    %% Set paths for this participant
    archiveData = fullfile(generalpath, num2str(participant_id), 'Night', 'MR ep2d_bold_samba_2mm_sleep');
    nightDir = fullfile(generalpath, num2str(participant_id), 'Night');
    T1_folder = fullfile(generalpath, num2str(participant_id), 'T1', 'MR t1_mprage_tra_p2_0.8mm_iso');

    %% Structural: Create output directories if it doesn't exist and convert DICOM to Nifti
    %OutDir_T1 = fullfile(outputpath, num2str(participant_id), 'T1');
    %if ~exist(OutDir_T1, 'dir')
     %   mkdir(OutDir_T1);
    %end
    %cd(OutDir_T1); % Move into nifti folder

    %convertDicomDir2Nifti(T1_folder, OutDir_T1);
    %%  Functionals: Create output directories if it doesn't exist and convert DICOM to Nifti
    %OutDir = fullfile(outputpath, num2str(participant_id), 'nifti_raw_2');
    %if ~exist(OutDir, 'dir')
    %    mkdir(OutDir);
    %end
    %cd(OutDir); % Move into nifti folder
    
    %convertDicomDir2Nifti(archiveData, OutDir);
    %% Realign only
    %OutDir = fullfile(outputpath, num2str(participant_id), 'nifti_raw_2');
    %OutDir_r = fullfile(outputpath, num2str(participant_id), 'SPM_preproc/Realign');

    %filesRealign = cellstr(spm_select('FPList', OutDir, '^MF.*\.nii$'));
    %nc_Realign(filesRealign);

    %% Unzipp the output from FSL and remove the compressed .gz files
    OutDir = fullfile(outputpath, num2str(participant_id), 'skull_stripp');

    unzip_nii_gz(OutDir, true)

    %% Slice Timing Correction

    %filesSliceTiming = cellstr(spm_select('FPList', OutDir, 'brain_r.*\.nii$'));
    
    %load slice timing information from exact slice timing aquired from
    %json sidecar after running dcm2niix
    %sliceTimingFile = load([scriptpath '/nc_SPM_process/SNORE_Night_slice_times.mat']);
    %silceTimingArray = sliceTimingFile.sliceTimes; %extract the array of the struct
    
    %run slice time correction
    %nc_SliceTimeCorr(filesSliceTiming, nslices, TR, silceTimingArray);
    
    %% Smoothing

    filesSmoothing = cellstr(spm_select('FPList', OutDir, 'brain_a_r.*\.nii$'));
    nc_SmoothSPM(filesSmoothing,Smoothingkernel)

    %% Save progress
    fprintf('Processing complete for participant %d\n', participant_id);
end
