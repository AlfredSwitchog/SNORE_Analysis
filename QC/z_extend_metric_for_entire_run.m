%% Full-run z-extend QC
% Metric per volume:
%   z_metric = volume_z_extend - meanEPI_z_extend
%
% Outputs:
%   1) fraction of volumes with z_metric > 1
%   2) bar plot of z_metric across the run

% --- paths ---
mean_file = '/scratch/c7201319/SNORE_MR_out/4/meanEPI/meanMFIN02MS170624-0014-00001-000001.nii';
raw_dir   = '/scratch/c7201319/SNORE_MR_out/4/nifti_raw';
out_dir = '/scratch/c7201319/SNORE_MR_out/4/QC';

if ~exist(out_dir,'dir')
    mkdir(out_dir)
end

% --- add SPM ---
spm_path    = '/scratch/c7201319/spm12_dev';
addpath(spm_path)


log_file = fullfile(out_dir,'z_extent_QC.txt');
fid = fopen(log_file,'w');


% --- get raw volumes ---
files = spm_select('FPList', raw_dir, '^MF.*\.nii$');
nVol  = size(files,1);


vol_names = cell(nVol,1);


%% mean EPI z-extend
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

%% compute metric for each volume
z_metric = nan(nVol,1);

for i = 1:nVol

    file = strtrim(files(i,:));
    [~,name,~] = fileparts(file);

    % extract volume number after last dash
    tokens = regexp(name,'-(\d+)$','tokens');
    vol_names{i} = tokens{1}{1};

    V = spm_vol(file);
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

%% fraction above threshold
threshold = 1;
frac_above = sum(z_metric > threshold) / nVol;

fprintf(fid,'Mean EPI z-extend: %.2f mm\n', mean_z_extend);
fprintf(fid,'Volumes with z_metric > %.2f: %d / %d\n', threshold, sum(z_metric > threshold), nVol);
fprintf(fid,'Fraction: %.4f\n', frac_above);

%% plot
figure;
bar(z_metric);
hold on
yline(threshold,'r--','Threshold = 1');

xticks(1:nVol)
xticklabels(vol_names)
xtickangle(90)

xlabel('Volume')
ylabel('z-extend metric (mm)')
title(sprintf('z-extend metric | fraction >1 = %.3f',frac_above))
grid on

plot_file = fullfile(out_dir,'z_extent_plot.png');
saveas(gcf, plot_file);

fclose(fid);

%% save MAT file with volume number + z-extend metric

vol_num = str2double(vol_names);          % column 1
qc_mat  = [vol_num, z_metric];            % column 2

save(fullfile(out_dir,'z_extent_values.mat'),'qc_mat')


