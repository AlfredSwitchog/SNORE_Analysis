%% ============================================================
% Expand EEG 30s scoring epochs onto a 2.5s grid (no fMRI needed)
% - Input: folder with per-subject CSVs, filenames like P1_..., P17_..., etc.
% - Output: one .MAT per subject: "Pn_sleep_stage_per_TR.mat"
%   containing stage_per_TR (Kx1 string), time_TR (Kx1 double),
%   TR, eegLeadsSeconds, and source_csv.
% ============================================================

%% ---------------- CONFIG ----------------
inFolder            = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_cleaned';
outFolder           = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';     % change if you want MATs elsewhere
TR                  = 2.5;          % seconds
eegLeadsSeconds     = 2.5;          % start grid at 2.5 s (fMRI t=0)
filePattern         = 'P*.csv';     % filenames begin with P<number>
subjects_to_process = [];           % [] = all subjects; or list e.g. [1 5 12]

%% ---------------- FIND FILES ----------------
D = dir(fullfile(inFolder, filePattern));
assert(~isempty(D), 'No CSV files matching "%s" in %s', filePattern, inFolder);

fprintf('Found %d scoring file(s) in %s\n', numel(D), inFolder);

for i = 1:numel(D)
    csvPath = fullfile(D(i).folder, D(i).name);

    % Extract subject number from filename start: 'P<number>'
    tok = regexp(D(i).name, '^P(\d+)', 'tokens', 'once');
    if isempty(tok)
        warning('Skipping file without leading P<number>: %s', D(i).name);
        continue
    end
    subjNum = str2double(tok{1});

    % ---- Filtering by subject list ----
    if ~isempty(subjects_to_process) && ~ismember(subjNum, subjects_to_process)
        fprintf('Skipping subject %d (not in subjects_to_process)\n', subjNum);
        continue
    end

    % ---- Read scoring (start,end,stage) ----
    tbl = read_scoring_table(csvPath);
    assert(height(tbl) >= 1, 'Empty scoring table: %s', csvPath);

    % ---- Build EEG-clock TR grid starting at 2.5s (fMRI t=0), strict < end_N ----
    lastEnd = tbl.end(end);
    if lastEnd <= eegLeadsSeconds
        warning('Subject %d: last end (%.3f) <= lead (%.3f). Nothing to write.', subjNum, lastEnd, eegLeadsSeconds);
        stage_per_TR = strings(0,1);
        time_TR      = zeros(0,1);
    else
        K = floor((lastEnd - eegLeadsSeconds)/TR) + 1;  % include 2.5,5.0,..., < lastEnd
        time_TR = eegLeadsSeconds + (0:K-1)' * TR;
        stage_per_TR = strings(K,1);
        stage_per_TR(:) = "NA";
        epsTol = 1e-9;

        for r = 1:height(tbl)
            k_min = ceil( (tbl.start(r) - eegLeadsSeconds) / TR ) + 1;
            k_max = floor((tbl.end(r)   - epsTol           - eegLeadsSeconds) / TR ) + 1;
            k_min = max(k_min, 1);
            k_max = min(k_max, K);
            if k_min <= k_max
                stage_per_TR(k_min:k_max) = tbl.stage(r);
            end
        end
    end

    % ---- Save per subject ----
    outName = sprintf('P%d_sleep_stage_per_TR.mat', subjNum);
    outPath = fullfile(outFolder, outName);
    source_csv = string(csvPath); %#ok<NASGU>
    save(outPath, 'stage_per_TR', 'time_TR', 'TR', 'eegLeadsSeconds', 'source_csv');

    fprintf('Saved %s  (K = %d rows)\n', outPath, numel(stage_per_TR));
end

fprintf('Done.\n');

%% ======================= HELPER ===========================
function tbl = read_scoring_table(pathToCsv)
    lines = readlines(pathToCsv);
    if isempty(lines)
        error('read_scoring_table: file is empty: %s', pathToCsv);
    end

    headerIdx = NaN; delim = ',';
    for j = 1:numel(lines)
        L = strtrim(lines(j));
        if L == "", continue, end
        cComma = count(L, ","); cSemi = count(L, ";");
        if cComma==0 && cSemi==0, continue, end
        thisDelim = iff(cSemi > cComma, ';', ',');
        toks = split(L, [",",";"]);
        toks = lower(strtrim(toks));
        canon = regexprep(toks, '[^a-z0-9]+', '');
        if any(canon=="start") && any(canon=="end") && any(canon=="stage")
            headerIdx = j; delim = thisDelim; break
        end
    end
    if isnan(headerIdx)
        error('No header row with start/end/stage in %s', pathToCsv);
    end

    opts = detectImportOptions(pathToCsv, 'Delimiter', delim);
    try, opts.VariableNamingRule = 'preserve'; catch, end
    if isprop(opts,'VariableNamesLine'), opts.VariableNamesLine = headerIdx; end
    if isprop(opts,'DataLines'),         opts.DataLines        = [headerIdx+1, Inf]; end

    try
        T = readtable(pathToCsv, opts, 'TextType','string', 'PreserveVariableNames', true);
    catch
        try
            T = readtable(pathToCsv, opts, 'PreserveVariableNames', true);
        catch
            T = readtable(pathToCsv, opts);
        end
    end

    vn  = string(T.Properties.VariableNames);
    cvn = lower(regexprep(strtrim(vn), '[^a-z0-9]+', ''));
    iS  = find(cvn=="start",1); iE = find(cvn=="end",1); iG = find(cvn=="stage",1);
    assert(~isempty(iS) && ~isempty(iE) && ~isempty(iG), 'Missing start/end/stage in %s', pathToCsv);

    start_s = T.(vn(iS)); if ~isnumeric(start_s), start_s = str2double(string(start_s)); end
    end_s   = T.(vn(iE)); if ~isnumeric(end_s),   end_s   = str2double(string(end_s));   end
    stage   = string(T.(vn(iG))); % verbatim

    tbl = table(start_s(:), end_s(:), stage(:), 'VariableNames', {'start','end','stage'});
    tbl = sortrows(tbl,'start');

    tol = 1e-8;
    assert(all(tbl.end > tbl.start - tol), 'Each interval must have end > start: %s', pathToCsv);
    assert(issorted(tbl.start),            'Start times must be sorted: %s', pathToCsv);
end

function out = iff(cond, a, b), if cond, out = a; else, out = b; end, end
