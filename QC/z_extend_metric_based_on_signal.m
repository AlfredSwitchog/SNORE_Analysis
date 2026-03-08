%% Compare signal-based z-range of volumes
% Signal-based z-range:
%   highest world-z with signal - lowest world-z with signal

% --- specify volumes ---

% positive example where the z-extend should reflect no strong inferior
% slice loss
%file1 = '/Users/Richard/Documents/20260307_SNORE_QC/4/MFIN02MS170624-0014-00497-000497.nii'; % high header z-extend but visually misleading
%file2 = '/Users/Richard/Documents/20260307_SNORE_QC/4/meanMFIN02MS170624-0014-00001-000001.nii'; % meanEPI
%files = {file1, file2};

% positive example where the z-extend should reflect no strong inferior
% slice loss
%file1 = '/Users/Richard/Documents/20260307_SNORE_QC/4/MFIN02MS170624-0014-00497-000497.nii'; % high header z-extend but visually misleading
%file2 = '/Users/Richard/Documents/20260307_SNORE_QC/4/meanMFIN02MS170624-0014-00001-000001.nii'; % meanEPI
%files = {file1, file2};


% negative example where the z-extend should reflect strong inferior
% slice loss
file1 = '/Users/Richard/Documents/20260216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-02800-002800.nii'; % w/cutting
file2 = '/Users/Richard/Documents/20260216_SNORE_QC/29/meanEPI/meanMFHE97CF261124-0007-00001-000001.nii'; % meanEPI
file3 = '/Users/Richard/Documents/20260216_SNORE_QC/29/nifti_raw/MFHE97CF261124-0007-00333-000333.nii'; % no cutting
files = {file1, file2, file3};

fprintf('\n=== Signal-based z-range of volumes ===\n')

for i = 1:length(files)

    V = spm_vol(files{i});
    Y = spm_read_vols(V);

    nz = size(Y,3);

    % slice is counted as containing signal if >1%% of voxels are nonzero
    has_signal = false(nz,1);

    for z = 1:nz
        slice = Y(:,:,z);
        frac_nonzero = nnz(isfinite(slice) & slice ~= 0) / numel(slice);
        has_signal(z) = frac_nonzero > 0.01;
    end

    sig_slices = find(has_signal);

    if isempty(sig_slices)
        fprintf('\nVolume %d\n', i)
        fprintf('File: %s\n', files{i})
        fprintf('No slices with signal found.\n')
        continue
    end

    z_low_idx  = sig_slices(1);
    z_high_idx = sig_slices(end);

    % convert slice indices to world z coordinates using center voxel in x/y
    x0 = round(size(Y,1)/2);
    y0 = round(size(Y,2)/2);

    low_mm  = V.mat * [x0; y0; z_low_idx; 1];
    high_mm = V.mat * [x0; y0; z_high_idx; 1];

    z_low_mm  = low_mm(3);
    z_high_mm = high_mm(3);
    z_range_signal = abs(z_high_mm - z_low_mm);

    fprintf('\nVolume %d\n', i)
    fprintf('File: %s\n', files{i})
    fprintf('Lowest slice with signal:  %d (z = %.2f mm)\n', z_low_idx, z_low_mm)
    fprintf('Highest slice with signal: %d (z = %.2f mm)\n', z_high_idx, z_high_mm)
    fprintf('Signal-based z-range:      %.2f mm\n', z_range_signal)

end
