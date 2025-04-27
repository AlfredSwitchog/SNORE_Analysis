% Path to your JSON file
jsonFilePath = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/1/Night/MR_ep2d_bold_samba_2mm_sleep/MR_ep2d_bold_samba_2mm_sleep_ep2d_bold_samba_2mm_sleep_20240701225527_11a.json';

% Read the JSON file as a character vector
jsonText = fileread(jsonFilePath);

% Decode the JSON text into a MATLAB struct
jsonData = jsondecode(jsonText);

% Extract only SliceTiming
sliceTiming = jsonData.SliceTiming;


% Define output .mat filename (can also change the path here)
matFilePath = 'slice_timing.mat';

% Save to .mat file
save(matFilePath, 'sliceTiming');
