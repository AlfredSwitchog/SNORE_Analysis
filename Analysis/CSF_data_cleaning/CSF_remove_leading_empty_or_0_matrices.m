% ====================== CLEAN CSF RAW SIGNAL (SCRIPT) ======================
% Removes leading entries that are [] or all-zero (including nested cells)
% from the top-level 1x20 or 20x1 cell array in each csf_p*.mat file.
%
% INPUT  dir: /Users/Richard/Masterabeit_local/SNORE_CSF_Data/Raw_Signal
% OUTPUT dir: /Users/Richard/Masterabeit_local/SNORE_CSF_Data/Raw_Signal/Raw_signal_cleaned
%
% Deterministic rules:
% - Scan from index 1 upward; remove consecutive entries that are [] or all-zero.
% - "All-zero": numeric, non-empty, no NaN/Inf, and every element == 0.
% - Nested cells count as empty/all-zero only if ALL their contents are so.
% - Any non-numeric/non-cell content is treated as meaningful (=> stop trimming).
% - If all 20 entries are removed, save an empty cell with preserved orientation.
% - Preserves the original variable name and orientation (row vs column).
% ==========================================================================

% ---- Paths ----
input_dir  = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Raw_Signal';
output_dir = fullfile(input_dir, 'Raw_signal_cleaned');
if ~exist(output_dir, 'dir'), mkdir(output_dir); end

% ---- Find files ----
files = dir(fullfile(input_dir, 'csf_p*.mat'));
if isempty(files)
    warning('No files matching csf_p*.mat found in %s', input_dir);
end

for k = 1:numel(files)
    in_path  = fullfile(files(k).folder, files(k).name);
    S = load(in_path);
    var_names = fieldnames(S);

    % Identify exactly one 1x20 or 20x1 cell array variable
    is_target = false(size(var_names));
    for i = 1:numel(var_names)
        v = S.(var_names{i});
        if iscell(v)
            sz = size(v);
            if isequal(sz, [1,20]) || isequal(sz, [20,1])
                is_target(i) = true;
            end
        end
    end

    if nnz(is_target) ~= 1
        warning('File %s skipped: expected exactly one 1x20 or 20x1 cell array variable, found %d.', ...
            files(k).name, nnz(is_target));
        continue;
    end

    var_name = var_names{is_target};
    data     = S.(var_name);
    sz       = size(data);
    is_row   = (sz(1) == 1);
    N        = numel(data);

    % ---- Compute number of leading empty/all-zero entries (no functions used) ----
    lead = 0;
    for idx = 1:N
        candidate = data{idx};
        % Iterative stack-based check (equivalent to recursive): true iff ALL parts are [] or all-zero numeric.
        tf_all_empty_or_zero = true;
        stack = {candidate};

        while ~isempty(stack)
            item = stack{end};
            stack(end) = [];

            if isempty(item)
                % [] (empty numeric or empty cell) counts as empty; continue
                continue;
            elseif isnumeric(item)
                % Non-empty numeric: must be finite and exactly all zeros
                if any(isnan(item(:))) || any(isinf(item(:))) || any(item(:) ~= 0)
                    tf_all_empty_or_zero = false;
                    break;
                end
            elseif iscell(item)
                % Cell is "empty/all-zero" only if ALL its contents are so
                if ~isempty(item)
                    stack = [stack; reshape(item, [], 1)]; %#ok<AGROW>
                end
            else
                % Any other type (char, struct, etc.) counts as meaningful content
                tf_all_empty_or_zero = false;
                break;
            end
        end

        if tf_all_empty_or_zero
            lead = lead + 1;
        else
            break;
        end
    end

    % ---- Trim leading entries ----
    if lead >= N
        % All entries removed -> empty cell array with preserved orientation
        if is_row
            data_clean = cell(1, 0);
        else
            data_clean = cell(0, 1);
        end
    else
        if is_row
            data_clean = data(1, (lead+1):end);
        else
            data_clean = data((lead+1):end, 1);
        end
    end

    % ---- Save with same variable name ----
    out_path = fullfile(output_dir, files(k).name);
    tmp = struct();
    tmp.(var_name) = data_clean;
    save(out_path, '-struct', 'tmp');

    % ---- Log ----
    fprintf('[%s] Removed %d leading entries; new length = %d. Saved -> %s\n', ...
        files(k).name, lead, numel(data_clean), out_path);
end

% =============================== END OF SCRIPT =============================
