%% ============== USER SETTINGS ==============
individual_file = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat';
output_dir        = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/InflowEffect/Figures/all_individual_figs_95th_to_5th';
subject_indices = [];                 % [] = all subjects; or e.g., [1 50]
slices_to_eval  = 1:7;                % slices for the ratio calculation
save_png        = true;
save_pdf        = false;
save_matrix_csv = true;               % also write a CSV of all ratios
%% ===========================================

% Load individual data
Si = load(individual_file);
assert(isfield(Si,'averaged_csf_data'), 'Variable "averaged_csf_data" not found in %s', individual_file);
all_subjects = Si.averaged_csf_data;                       % {subject} -> {slice} -> 1xT vector
nSubj = numel(all_subjects);

% Subjects to process
if isempty(subject_indices), subject_indices = 1:nSubj; end

% Ensure output dir
if ~exist(output_dir,'dir'), mkdir(output_dir); end

% Prepare result matrix: rows=subjects, cols=slices
maxSlice = max(slices_to_eval);
ratios_matrix = nan(nSubj, maxSlice);

%% === Per-subject ratio computation + per-subject figure ===
for subj = subject_indices
    assert(subj>=1 && subj<=nSubj, 'Subject %d out of range.', subj);
    mean_csf_data = all_subjects{subj};
    if ~iscell(mean_csf_data)
        warning('Subject %d data not a cell array. Skipping.', subj);
        continue
    end

    % Compute 95th/5th percentile ratio across requested slices
    for slice_idx = slices_to_eval
        if slice_idx > numel(mean_csf_data) || isempty(mean_csf_data{slice_idx}) ...
                || ~isvector(mean_csf_data{slice_idx})
            fprintf('Subject %d – Slice %d: No valid data. Skipping.\n', subj, slice_idx);
            continue
        end

        ts = mean_csf_data{slice_idx}(:);   % ensure column vector

        % Treat zeros as missing (optional); then filter to valid values  %% FIX
        ts(ts == 0) = NaN;
        valid = isfinite(ts) & ~isnan(ts);
        if nnz(valid) < 2
            ratios_matrix(subj, slice_idx) = NaN;
            fprintf('Subject %d – Slice %d: insufficient valid points.\n', subj, slice_idx);
            continue
        end

        % Percentiles without the 'omitnan' flag (version-proof)          %% FIX
        p95 = prctile(ts(valid), 95);
        p5  = prctile(ts(valid), 5);

        if ~isnan(p95) && ~isnan(p5) && p5 ~= 0
            ratios_matrix(subj, slice_idx) = p95 / p5;
        else
            ratios_matrix(subj, slice_idx) = NaN;
        end

        fprintf('Subject %d – Slice %d: 95th/5th ratio = %.4f\n', ...
            subj, slice_idx, ratios_matrix(subj, slice_idx));
    end

    % --- Per-subject ratio figure (first 7 slices, or as set) ---
    x = slices_to_eval;
    y = ratios_matrix(subj, x);

    fh = figure('Visible','off');
    plot(x, y, '-o', 'LineWidth', 2);
    xlabel('Slice Number');
    ylabel('95th / 5th Percentile Ratio');
    title(sprintf('Subject %03d – CSF 95th/5th Ratio (Slices %d–%d)', subj, x(1), x(end)));
    grid on;

    base = fullfile(output_dir, sprintf('sub-%03d_ratio_slices%dto%d', subj, x(1), x(end)));
    if save_png, exportgraphics(fh, [base '.png'], 'Resolution', 300); end
    if save_pdf, exportgraphics(fh, [base '.pdf']); end
    close(fh);
end