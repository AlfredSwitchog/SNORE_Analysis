%% Compare z-coordinate extent of three volumes

% --- specify volumes ---
file1 = '/Users/Richard/Documents/20250216_SNORE_QC/29/meanEPI/meanMFHE97CF261124-0007-00001-000001.nii';
file2 = '/Users/Richard/Documents/20250216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-03281-003281.nii'; %Volume that will be cut after reallignment
file3 = '/Users/Richard/Documents/20250216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-00333-000333.nii'; %Volume that won't be cut after reallignment

files = {file1, file2, file3};

fprintf('\n=== Z-coordinate extent of volumes ===\n')

for i = 1:length(files)

    V = spm_vol(files{i});
    dims = V.dim;
    M = V.mat;

    % voxel grid corners
    corners = [
        1       1       1       1;
        dims(1) 1       1       1;
        1       dims(2) 1       1;
        1       1       dims(3) 1;
        dims(1) dims(2) 1       1;
        dims(1) 1       dims(3) 1;
        1       dims(2) dims(3) 1;
        dims(1) dims(2) dims(3) 1
    ]';

    % convert to world coordinates
    world = M * corners;

    zvals = world(3,:);

    volume_z_extend = max(zvals) -min(zvals);

    fprintf('\nVolume %d\n', i)
    fprintf('File: %s\n', files{i})
    fprintf('Dimensions: %d x %d x %d\n', dims(1), dims(2), dims(3))
    fprintf('Z range (mm): %.2f  to  %.2f\n', min(zvals), max(zvals))
    fprintf('Z extend (mm): %.2f\n', volume_z_extend)

end
