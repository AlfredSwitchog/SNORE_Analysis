%% Full-run z-extend QC
% Metric per volume:
%   z_metric = volume_z_extend - meanEPI_z_extend
%
% Outputs:
%   1) fraction of volumes with z_metric > 1
%   2) bar plot of z_metric across the run

% --- paths ---
mean_file = '/Users/Richard/Documents/20250216_SNORE_QC/29/meanEPI/meanMFHE97CF261124-0007-00001-000001.nii';
raw_dir   = '/Users/Richard/Documents/20250216_SNORE_QC/29/nifti_raw';

% --- get raw volumes ---
files = spm_select('FPList', raw_dir, '^MF.*\.nii$');
nVol  = size(files,1);

% --- mean EPI z-extend ---
V = spm_vol(mean_file);
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
mean_z_extend = max(zvals) - min(zvals);

% --- compute metric for each raw volume ---
z_metric = nan(nVol,1);

for i = 1:nVol
    V = spm_vol(strtrim(files(i,:)));
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
    vol_z_extend = max(zvals) - min(zvals);

    z_metric(i) = vol_z_extend - mean_z_extend;
end

% --- fraction above threshold ---
threshold = 1;
frac_above = sum(z_metric > threshold) / nVol;

fprintf('Mean EPI z-extend: %.2f mm\n', mean_z_extend);
fprintf('Volumes with z_metric > %.2f: %d / %d\n', threshold, sum(z_metric > threshold), nVol);
fprintf('Fraction: %.4f\n', frac_above);

% --- plot ---
figure;
bar(z_metric);
hold on;
yline(threshold, 'r--', 'Threshold = 1');
xlabel('Volume');
ylabel('z-extend metric (mm)');
title(sprintf('z-extend metric across run | fraction > 1 = %.3f', frac_above));
grid on;
