% Define the folder containing your fMRI DICOM files
dicom_folder = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/1/Night/MR ep2d_bold_samba_2mm_sleep'; % Update this path

% Get a list of all DICOM files in the folder
dicom_files = dir(fullfile(dicom_folder, '*.dcm')); 

% Convert file list to a cell array of full file paths
dicom_filenames = fullfile(dicom_folder, {dicom_files.name});

% Read DICOM headers using SPM
hdrs = spm_dicom_headers(dicom_filenames);

% Initialize an empty array to store slice timing
slice_timings = [];

% Loop through all DICOM headers to extract slice timing
for i = 1:length(hdrs)
    if isfield(hdrs{i}, 'SliceTiming')  % Standard DICOM tag (0018, 9074)
        slice_timings = hdrs{i}.SliceTiming;
        break; % Use the first file that contains the information
    elseif isfield(hdrs{i}, 'MosaicRefAcqTimes')  % Siemens-specific (0019, 1029)
        slice_timings = hdrs{i}.MosaicRefAcqTimes;
        break;
    end
end

% Display the extracted slice timing information
if isempty(slice_timings)
    disp('Slice timing information not found in DICOM headers.');
else
    disp('Extracted Slice Timing (in seconds):');
    disp(slice_timings);
end
