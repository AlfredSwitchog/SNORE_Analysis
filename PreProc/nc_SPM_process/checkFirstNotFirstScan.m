% Purpose checks if the first file of a directory corresponds to the first
% volume of a scan e.g. 
% MFRO01GG010724-0011-00006-000006.nii --> 0
% MFRO01GG010724-0011-00006-000000.nii --> 1
%
% Input: Filepath as String
% Output: True/False

path = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/nifti_raw/MFRO01GG010724-0011-00006-000008.nii'
path = extractBefore(path, '.')
path = extractAfter(path, strlength(path) - 6)
path = str2double(path)
if path == 0
    result = true; 
else
    result = false;
end

%fprintf('This is the result: %s\n', result)
disp(path)
disp(result)
