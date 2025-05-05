function segmentT1(participant_id)
    %set paths
    spm_path = '/Users/Richard/MatLAB/spm12_dev';
    scriptpath = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Segm';
    structFileBase = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/';
    structFileEnding = '/T1/MR t1_mprage_tra_p2_0.8mm_iso';

    % add scripts to matlab path
    addpath(genpath(scriptpath))
    
    % select T1 directory
    T1dir = [structFileBase, num2str(participant_id), structFileEnding]; 
    
    % Convert to nifti
    %convertDicomDir2Nifti(T1dir, T1dir);
    
    % select struct file as nifti
    structfile = spm_select('ExtFPList', T1dir , '^.*\.nii$');
    
    % run segmentation
    nc_segmentation(structfile, spm_path, 30)
end