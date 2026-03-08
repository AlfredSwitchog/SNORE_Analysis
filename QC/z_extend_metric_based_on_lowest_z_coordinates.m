%% Test delta_min_z metric for a few volumes
% delta_min_z = mean_min_z - raw_min_z

% --- specify volumes ---
% Example 29 with some volumes no clipping and some with clipping
%file1 = '/Users/Richard/Documents/20260216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-02800-002800.nii'; % w/cutting
%file2 = '/Users/Richard/Documents/20260216_SNORE_QC/29/meanEPI/meanMFHE97CF261124-0007-00001-000001.nii'; % meanEPI
%file3 = '/Users/Richard/Documents/20260216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-00333-000333.nii'; % no cutting

% Example 4: These volumes should not be flagged with clipping
file1 = '/Users/Richard/Documents/20260307_SNORE_QC/4/MFIN02MS170624-0014-00497-000497.nii'; %no clipping
file2 = '/Users/Richard/Documents/20260307_SNORE_QC/4/meanMFIN02MS170624-0014-00001-000001.nii'; %meanEPI


files = {file1, file2};

fprintf('\n=== delta_min_z test ===\n')

%% --- compute meanEPI minimum z ---
V = spm_vol(file2);
dims = V.dim;
M = V.mat;

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

world = M * corners;
zvals = world(3,:);
mean_min_z = min(zvals);

fprintf('MeanEPI min z: %.2f mm\n\n', mean_min_z)

%% --- compute delta_min_z for each volume ---
for i = 1:length(files)

    V = spm_vol(files{i});
    dims = V.dim;
    M = V.mat;

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

    world = M * corners;
    zvals = world(3,:);
    raw_min_z = min(zvals);

    delta_min_z = mean_min_z - raw_min_z;

    fprintf('Volume %d\n',i)
    fprintf('File: %s\n',files{i})
    fprintf('raw_min_z: %.2f mm\n',raw_min_z)
    fprintf('delta_min_z: %.2f mm\n\n',delta_min_z)

end
