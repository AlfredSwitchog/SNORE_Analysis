    %% Co-Registration
    
    % select structural (T1) image
    T1_folder = fullfile(generalpath, num2str(participant_id), 'T1', 'MR t1_mprage_tra_p2_0.8mm_iso');
    StructFile=spm_select('ExtFPList', T1_folder, '.*\.nii$'); %struct file needs to be nifti file

    % select mean Image
    meanImage = spm_select('ExtFPList', OutDir, '^mean*');
    
    % co-register meanimage of pre-processed sequence to structural (T1)
    nc_CoregEstimateAandCtoB(StructFile,meanImage) % move structural to EPI

    %% Segmentation
    % expects the co-registered structural image and the path of the
    % spm_scripts as input (so the spm templates can be used)
    % biasfwmh set to 30 as suggested by Dorothea
    nc_segmentation(StructFile, spm_path, 30) 