%% clean up job used for testing the preprocess pipline

clear

generalpath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev'; %Probs where the data is
outputpath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out';


ids = [1:2];


for i = 1:length(ids)


    %/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/nifti_raw
    %/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/preproc_out

    niftiraw = [outputpath '/' num2str(ids(i)) '/nifti_raw'];
    preproc_out = [outputpath '/' num2str(ids(i)) '/preproc_out'];

    
    %delete all files in folder niftiraw
    delete(fullfile(niftiraw, '*'));   % Deletes all files in the folder
    delete(fullfile(preproc_out, '*'));   % Deletes all files in the folder

    %delete only nifti files in folder 
    %/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/1/Night/MR gre_field_mapping_mod_2mmiso

    fieldMapDir = [generalpath '/' num2str(ids(i)) '/Night/MR gre_field_mapping_mod_2mmiso'];

    niiFiles = dir(fullfile(fieldMapDir, '*.nii')); % Get list of .nii files

    for i = 1:length(niiFiles)
        delete(fullfile(fieldMapDir, niiFiles(i).name)); % Delete each .nii file
    end


end