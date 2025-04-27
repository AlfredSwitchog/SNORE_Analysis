function SNORE_preprocessing(participant_id)
    %% ******************************************* %%
    % Pipeline preproc - SNORE 
    %
    % Richard Lohr 15012025
    % version 1: Initial version

    % Requires SPM12 and functions from (nc_SPM_Process)
    % ***************************************** %%
    
    % Clear everything except function parameters
    clearvars -except participant_id;
    fprintf('Processing participant %d\n', participant_id);
    %% Add paths to Matlab (adjust for your paths)

    % Paths for Production
    %scriptpath = '/scratch/c7201319/SNORE_PreProc';
    %generalpath = '/scratch/c7201319/SNORE_MR'; 
    %outputpath = '/scratch/c7201319/SNORE_MR_out';

    % Paths for Leo5 testing environment:
    %scriptpath = '/scratch/c7201319/SNORE_PreProc';
    % generalpath = '/scratch/c7201319/SNORE_MRI_data_dev'; 
    % outputpath = '/scratch/c7201319/SNORE_MRI_data_dev_out';

    % Paths for local testing environment:
      scriptpath = '/Users/Richard/Masterabeit_local/Scripts/SNORE_PreProc';
      generalpath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev'; %Probs where the data is
      outputpath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out';
    
    %Add paths of the helper functions
    addpath([scriptpath '/nc_SPM_process']); % Folder with SPM functions
    addpath(scriptpath); % Main script folder

    % Add SPM to Leo5 environment
    %spm_path = '/scratch/c7201319/spm12_dev';
    %addpath(spm_path)
    %fprintf('SPM used: %d\n', spm_path);

    %% Set study parameters
    pm_file = [scriptpath '']; % Fieldmap defaults (TBD)
    nDummies = 5; % Number of dummy scans to discard
    TR = 2.5; % Repetition time (s)
    nslices = 72;
    order = 1; % Interleaved slice order
    MBFactor = 2; 
    AccFactor = 4;
    Smoothingkernel = [3 3 3];

    %% Set paths for this participant
    archiveData = fullfile(generalpath, num2str(participant_id), 'Night', 'MR ep2d_bold_samba_2mm_sleep');
    fieldMapDir = fullfile(generalpath, num2str(participant_id), 'Night', 'MR gre_field_mapping_mod_2mmiso');
    nightDir = fullfile(generalpath, num2str(participant_id), 'Night');
    T1_folder = fullfile(generalpath, num2str(participant_id), 'T1', 'MR t1_mprage_tra_p2_0.8mm_iso');

    %% Create output directories if it doesn't exist
    
    % Output directories for pre-processing steps 
    OutDir = fullfile(outputpath, num2str(participant_id), 'nifti_raw');
    if ~exist(OutDir, 'dir')
        mkdir(OutDir);
    end
    cd(OutDir); % Move into nifti folder

    % Output directory for coregistration
    CoRegDir = fullfile(outputpath, num2str(participant_id), 'co_reg');
    if ~exist(CoRegDir, 'dir')
        mkdir(CoRegDir);
    end

    %% Convert DICOM to NIfTI
    convertDicomDir2Nifti(archiveData, OutDir);
    convertDicomDir2Nifti(fieldMapDir, fieldMapDir);
    convertDicomDir2Nifti(T1_folder, T1_folder);

    %% Delete Dummy Scans
    deleteDummiesInFolder(nDummies, OutDir);

    %% Realign and unwarp
    FileNames = cellstr(spm_select('FPList', OutDir));
    nc_RealignUnwarp(FileNames);

    %% Slice Timing Correction
    files = cellstr(spm_select('ExtFPList', OutDir, '^u*'));
    nc_SliceTimeCorr(files, nslices, TR, order);

    %% Co-Registration
    
    % select structural (T1) image
    T1_folder = fullfile(generalpath, num2str(participant_id), 'T1', 'MR t1_mprage_tra_p2_0.8mm_iso');
    StructFile=spm_select('FPList', T1_folder, '.*\.nii$') %struct file needs to be nifti file

    % select mean Image
    meanImage = spm_select('ExtFPList', OutDir, '^mean*')
    
    % co-register meanimage of pre-processed sequence to structural (T1)
    nc_CoregEstimateAandCtoB(StructFile,meanImage) % move structural to EPI

    %% Segmentation
    

    %% Save progress
    fprintf('Processing complete for participant %d\n', participant_id);
end
