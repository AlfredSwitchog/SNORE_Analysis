%-----------------------------------------------------------------------
% Input: folder path
% Output: None
% Function: loop through every file of the folder convert it to nifti and put it in another folder
%-----------------------------------------------------------------------


function convertDicomDir2Nifti(dicom_folder, output_folder)

% Initialize SPM
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

% Select all DICOM files in the folder
dicom_files = spm_select('FPList', dicom_folder, '.*\.dcm$'); % Adjust extension if needed

% Check if any DICOM files were found
if isempty(dicom_files)
    error('No DICOM files found in the specified folder: %s', dicom_folder);
end

% Read DICOM headers
dicom_headers = spm_dicom_headers(dicom_files);

% Set the output directory for NIfTI files
if ~exist(output_folder, 'dir')
    mkdir(output_folder); % Create the output folder if it doesn't exist
end

% Change to output directory
cd(output_folder);

% Convert DICOM to NIfTI
fprintf('Converting DICOM files in folder: %s\n', dicom_folder);
spm_dicom_convert(dicom_headers, 'all', 'flat', 'nii'); % 'all': convert all files, 'flat': no subdirectories, 'nii': NIfTI format

fprintf('Conversion completed. NIfTI files saved in folder: %s\n', output_folder);
