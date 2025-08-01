function segmentT1(participant_id)
    %% Set environment: 'local', 'leo5_prod', or 'leo5_test'
    env = 'leo5_prod';  % <-- Change this to the appropriate environment    
    
    if strcmpi(env, 'local')
        spm_path = '/Users/Richard/MatLAB/spm12_dev';
        scriptpath = '/Users/Richard/Masterabeit_local/SNORE_Analysis/PreProc/nc_SPM_process';
        structFileBase = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/';
        structFileEnding = '/T1/MR t1_mprage_tra_p2_0.8mm_iso';
        structFileBase_out = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/';
        structFileEnding_out = '/T1';

     elseif strcmpi(env, 'leo5_prod')
        spm_path    = '/scratch/c7201319/spm12_dev';
        scriptpath = '/scratch/c7201319/SNORE_Analysis/';
        structFileBase = '/scratch/c7201319/SNORE_MRI/';
        structFileEnding = '/T1/MR t1_mprage_tra_p2_0.8mm_iso';
        structFileBase_out = '/scratch/c7201319/SNORE_MR_out/';
        structFileEnding_out = '/T1';

      else
        error('Unknown environment "%s". Choose from: local, leo5_prod, leo5_test.', env);
    end

    % add scripts to matlab path
    addpath(genpath(scriptpath))
    addpath(spm_path)
    
    % select T1 directory
    T1dir = [structFileBase, num2str(participant_id), structFileEnding]; 
    T1dir_out = [structFileBase_out, num2str(participant_id), structFileEnding_out];
    
    % Convert to nifti
     convertDicomDir2Nifti(T1dir, T1dir_out);
    
    % select struct file as nifti
    structfile = spm_select('ExtFPList', T1dir_out , '^.*\.nii$');
    
    % run segmentation
    nc_segmentation(structfile, spm_path, 30)
end
