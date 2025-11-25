%% ========= SETTINGS =========
input_dir    = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Data';
output_dir   = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Data/Average';
subject_indices = [];   % [] = process all; e.g., [1] or [3 7] for quick tests
%% ===========================

if ~exist(output_dir, 'dir'); mkdir(output_dir); end

files = dir(fullfile(input_dir, '*.mat'));
assert(~isempty(files), 'No .mat files found in %s', input_dir);

% Sort by trailing number in filename (p1, p2, ...)
names = {files.name};
nums  = nan(size(names));
for i = 1:numel(names)
    t = regexp(names{i}, '(\d+)', 'tokens');
    if ~isempty(t); nums(i) = str2double(t{end}{1}); end
end
[~, ord] = sortrows([isnan(nums(:)) nums(:)]);
files = files(ord);

if ~isempty(subject_indices)
    assert(all(subject_indices >= 1 & subject_indices <= numel(files)), ...
        'subject_indices outside range 1..%d', numel(files));
    files = files(subject_indices);
end

fprintf('Found %d subject file(s) to process.\n', numel(files));

for s = 1:numel(files)
    fpath = fullfile(files(s).folder, files(s).name);
    fprintf('[%d/%d] Loading %s ...\n', s, numel(files), files(s).name);
    S = load(fpath);

    % Detect struct with 'signals'
    fn = fieldnames(S);
    use_name = '';
    for k = 1:numel(fn)
        v = S.(fn{k});
        if isstruct(v) && isfield(v, 'signals')
            use_name = fn{k}; break
        end
    end
    if isempty(use_name)
        warning('No struct with field "signals" in %s. Skipping.', files(s).name);
        continue
    end

    subj_struct = S.(use_name);
    assert(isstruct(subj_struct), 'Expected struct array in %s.', files(s).name);

    N = numel(subj_struct);

    % === N×1 cell: each cell is a 1×T row vector ===
    averaged_csf_data = cell(N, 1);

    for sl = 1:N
        if ~isfield(subj_struct(sl), 'signals') || isempty(subj_struct(sl).signals) ...
                || ~isnumeric(subj_struct(sl).signals)
            averaged_csf_data{sl} = [];
            continue
        end
        X = subj_struct(sl).signals;
        % Mean across voxels (rows) -> 1×T, ensure row orientation
        row_ts = mean(double(X), 1, 'omitnan');
        row_ts = row_ts(:).';  % force 1×T
        averaged_csf_data{sl} = row_ts;
    end

    % === N×T numeric matrix with rows = slices (pad with NaNs if needed) ===
    lens = cellfun(@numel, averaged_csf_data);
    Tmax = max([lens(:); 0]);
    averaged_slices = nan(N, Tmax);
    for sl = 1:N
        ts = averaged_csf_data{sl};
        if ~isempty(ts)
            averaged_slices(sl, 1:numel(ts)) = ts;
        end
    end

    % Save one file per subject
    subject_id   = erase(files(s).name, '.mat');
    out_name     = sprintf('%s_averaged.mat', subject_id);
    out_path     = fullfile(output_dir, out_name);
    original_file = files(s).name;

    save(out_path, 'averaged_csf_data', 'averaged_slices', ...
        'subject_id', 'original_file', '-v7.3');
    fprintf('Saved %s\n', out_path);
end

fprintf('Done.\n');
