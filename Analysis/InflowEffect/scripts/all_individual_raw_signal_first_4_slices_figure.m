%% ============== USER SETTINGS ==============
all_subjects_path = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat';
output_dir        = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/InflowEffect/Figures/all_individual_figures';
subject_indices   = [];            % [] = process ALL subjects; or e.g., [50] or [1 5 12]
TR_seconds        = [];            % e.g., 2.0 to label seconds; [] keeps timepoints
save_png          = true;          % set false if you don’t want PNGs
save_pdf          = false;         % set true if you also want PDFs
%% ===========================================

% Load
S = load(all_subjects_path);
assert(isfield(S,'averaged_csf_data'), 'Variable "averaged_csf_data" not found.');
averaged_csf_data = S.averaged_csf_data;   % {subject} -> {slice} -> 1xT vector

% Subjects to process
if isempty(subject_indices)
    subject_indices = 1:numel(averaged_csf_data);
end

% Ensure output dir
if ~exist(output_dir, 'dir'); mkdir(output_dir); end

for subj = subject_indices
    % --- Get subject data ---
    assert(subj>=1 && subj<=numel(averaged_csf_data), 'Subject %d out of range.', subj);
    slice_cells = averaged_csf_data{subj};
    assert(iscell(slice_cells), 'Expected cell array of slices for subject %d.', subj);

    % --- Pick first 4 non-empty slices ---
    valid = find(cellfun(@(x) ~isempty(x) && isnumeric(x) && isvector(x), slice_cells));
    if isempty(valid)
        warning('Subject %d has no valid slices. Skipping.', subj);
        continue;
    end
    slice_ids = valid(1:min(4, numel(valid)));

    % --- Build x-axis ---
    T_guess = numel(slice_cells{slice_ids(1)});
    if ~isempty(TR_seconds)
        x = (0:T_guess-1) * TR_seconds;
        xlab = 'Time (s)';
    else
        x = 1:T_guess;
        xlab = 'Timepoint';
    end

    % --- Create per-subject figure ---
    fh = figure('Visible','off');
    hold on;
    legends = strings(0);

    for k = 1:numel(slice_ids)
        sl = slice_ids(k);
        y = slice_cells{sl};
        if numel(y) ~= numel(x)
            T = min(numel(y), numel(x));
            plot(x(1:T), y(1:T), 'LineWidth', 1.5);
        else
            plot(x, y, 'LineWidth', 1.5);
        end
        legends(end+1) = sprintf('Slice %d', sl); %#ok<SAGROW>
    end

    title(sprintf('Subject %03d – CSF Raw Time Series (First 4 Slices)', subj));
    xlabel(xlab); ylabel('Raw CSF signal');
    legend(legends, 'Location','best');
    grid on; hold off;

    % --- Save (no subfolders) ---
    base = fullfile(output_dir, sprintf('sub-%03d_first4_raw', subj));
    if save_png, exportgraphics(fh, [base '.png'], 'Resolution', 300); end
    if save_pdf, exportgraphics(fh, [base '.pdf']); end
    close(fh);
end

disp("Done. Figures saved in: " + string(output_dir));
