function qc_inferior_coverage_spm(epi_path, N_slices, thr_mode)
% qc_inferior_coverage_spm
% Coverage QC for bottom slices in an EPI time series using SPM.
%
% Inputs
%   epi_path : path to 4D NIfTI (e.g., 'sub-29_task-rest_bold.nii')
%              OR a char array / string to a single file.
%   N_slices : number of bottom slices to inspect (default 12)
%   thr_mode : 'nonzero' (default) or 'relative'
%              - 'nonzero'  : voxel is valid if finite & ~= 0
%              - 'relative' : voxel is valid if > 0.05 * median(positive voxels of ref volume)
%
% Output: prints summary + plots coverage per volume.

    if nargin < 2 || isempty(N_slices), N_slices = 12; end
    if nargin < 3 || isempty(thr_mode), thr_mode = 'nonzero'; end

    % --- Ensure SPM is on path and initialized (safe even if already initialized)
    if exist('spm', 'file') ~= 2
        error('SPM not found on MATLAB path. Add SPM12 to path first.');
    end
    spm('Defaults','fMRI');

    % --- Load volumes
    V = spm_vol(epi_path);  % for 4D, returns array of structs (one per volume)
    nVol = numel(V);
    if nVol < 2
        warning('Only %d volume detected. Is this a 4D file?', nVol);
    end

    % --- Read first volume to get dims & set threshold if needed
    Y0 = spm_read_vols(V(1));
    dims = size(Y0);
    if numel(dims) ~= 3
        error('Expected 3D volume per timepoint. Got dims: %s', mat2str(dims));
    end
    nz = dims(3);

    if N_slices >= nz
        error('N_slices (%d) must be < number of slices (%d).', N_slices, nz);
    end

    bottom_idx = 1:N_slices;
    top_idx    = (nz - N_slices + 1):nz;

    % Threshold setup
    thr = 0;
    if strcmpi(thr_mode, 'relative')
        pos = Y0(isfinite(Y0) & Y0 > 0);
        if isempty(pos)
            warning('No positive voxels found in reference volume; falling back to nonzero mode.');
            thr_mode = 'nonzero';
        else
            thr = 0.05 * median(pos);  % conservative relative threshold
        end
    end

    % --- Compute coverage for each volume
    cov_bottom = nan(nVol,1);
    cov_top    = nan(nVol,1);

    for i = 1:nVol
        Yi = spm_read_vols(V(i));

        if strcmpi(thr_mode, 'nonzero')
            valid_bottom = isfinite(Yi(:,:,bottom_idx)) & (Yi(:,:,bottom_idx) ~= 0);
            valid_top    = isfinite(Yi(:,:,top_idx))    & (Yi(:,:,top_idx) ~= 0);
        else
            valid_bottom = isfinite(Yi(:,:,bottom_idx)) & (Yi(:,:,bottom_idx) > thr);
            valid_top    = isfinite(Yi(:,:,top_idx))    & (Yi(:,:,top_idx) > thr);
        end

        cov_bottom(i) = nnz(valid_bottom) / numel(valid_bottom);
        cov_top(i)    = nnz(valid_top)    / numel(valid_top);
    end

    % --- Heuristic flagging
    % Use a robust cutoff based on the subject’s own distribution
    medB = median(cov_bottom, 'omitnan');
    madB = mad(cov_bottom, 1); % median absolute deviation
    % Flag volumes that are much worse than typical (tunable)
    cutoff = max(0, medB - 5*madB);

    flagged = find(cov_bottom < cutoff);

    % --- Print summary
    fprintf('\n=== Inferior coverage QC (SPM) ===\n');
    fprintf('File: %s\n', epi_path);
    fprintf('Volumes: %d | Slices (Z): %d | Bottom slices checked: %d\n', nVol, nz, N_slices);
    fprintf('Mode: %s', thr_mode);
    if strcmpi(thr_mode,'relative')
        fprintf(' (thr = %.4g)\n', thr);
    else
        fprintf('\n');
    end

    fprintf('Bottom coverage: median=%.4f | min=%.4f (vol %d)\n', ...
        medB, min(cov_bottom), find(cov_bottom==min(cov_bottom),1,'first'));
    fprintf('Top coverage:    median=%.4f | min=%.4f (vol %d)\n', ...
        median(cov_top,'omitnan'), min(cov_top), find(cov_top==min(cov_top),1,'first'));

    fprintf('Auto cutoff = %.4f | Flagged volumes: %d (%.2f%%)\n', ...
        cutoff, numel(flagged), 100*numel(flagged)/nVol);

    if ~isempty(flagged)
        fprintf('First 20 flagged vol indices: %s\n', mat2str(flagged(1:min(20,end))'));
    end
    fprintf('Note: If TOP coverage drops but BOTTOM does not, your data may be flipped in Z.\n');

    % --- Plot
    figure('Name','Inferior coverage QC');
    plot(cov_bottom, 'LineWidth', 1.5); hold on;
    plot(cov_top, '--', 'LineWidth', 1.0);
    yline(cutoff, ':', 'Cutoff');

    if ~isempty(flagged)
        scatter(flagged, cov_bottom(flagged), 40, 'filled');
    end

    xlabel('Volume index');
    ylabel('Coverage fraction in N slices');
    legend({'Bottom N slices','Top N slices','Cutoff','Flagged bottom'}, 'Location','best');
    grid on;
    title(sprintf('Coverage QC | Bottom N=%d | %s', N_slices, spm_file(epi_path,'filename')));

end
