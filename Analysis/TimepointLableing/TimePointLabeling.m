%% ============================================================
%  Label fMRI timepoints with sleep stage (W / N1 / N2 / N3)
%  Assumptions (updated):
%   - all_subjects: 1×N cell, each {i} is (slices×1) cell of 1×T_i numeric
%     where all slices in the same subject have equal length T_i,
%     but T_i can differ across subjects.
%   - TR = 2.5 s
%   - EEG leads fMRI by 2.5 s  -> fMRI t=0 aligns to EEG t=+2.5 s
%   - CSV has columns: clock start time, start, end, stage
%  Outputs created in workspace:
%   - time_s                        : T_first×1 (EEG-clock times) for first subject’s first slice
%   - stage_per_timepoint           : T_first×1 labels for first subject’s first slice
%   - time_s_by_subject             : 1×N cell; {s} is T_s×1 EEG-clock times
%   - stage_per_timepoint_by_subject: 1×N cell; {s} is T_s×1 labels
%   - stage_flags_by_subject        : 1×N cell; {s} is [nSlices_s × T_s] string matrix
% =============================================================

%% --------------- CONFIG ----------------
all_subjects_path  = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/Merged_Data/csf_mean_per_slice_pre_subject.mat';
csvFile            = '/Users/Richard/Masterabeit_local/EEG/SCORING/';  % can be a single CSV file OR a folder containing per-subject CSVs
TR                 = 2.5;                  % seconds
eegLeadsSeconds    = 2.5;                  % EEG starts earlier by 2.5 s
outOfRangeLabel    = "NA";                 % label for out-of-range volumes
requireSameT       = true;                 % enforce same T within each subject

%% --------------- LOAD / CHECK fMRI SHAPE ---------------
Si = load(all_subjects_path);
assert(isfield(Si,'averaged_csf_data'), 'Variable "averaged_csf_data" not found in %s', all_subjects_path);
all_subjects = Si.averaged_csf_data;

assert(exist('all_subjects','var')==1, ...
    'Variable "all_subjects" must exist in the workspace.');

assert(iscell(all_subjects) && isvector(all_subjects), ...
    '"all_subjects" should be a 1×N cell array (one cell per subject).');

nSubjects = numel(all_subjects);
assert(nSubjects>=1, 'all_subjects appears empty.');

% Inspect first subject & slice
firstSubj = all_subjects{1};
assert(iscell(firstSubj) && size(firstSubj,2)==1, ...
    'Each subject should be a (slices×1) cell array.');

nSlices_1 = size(firstSubj,1);
assert(nSlices_1>=1, 'First subject has no slices.');

T_first = numel(firstSubj{1});
assert(T_first>=1, 'First slice has no timepoints.');

% Type checks + same-length per subject (no cross-subject constraint)
for s = 1:nSubjects
    subjCell = all_subjects{s};
    assert(iscell(subjCell) && size(subjCell,2)==1, ...
        'Subject %d entry must be a (slices×1) cell array.', s);
    nSlices_s = size(subjCell,1);
    assert(nSlices_s>=1, 'Subject %d has no slices.', s);
    if requireSameT
        T_s = numel(subjCell{1});
        for r = 2:nSlices_s
            assert(isvector(subjCell{r}) && isnumeric(subjCell{r}), ...
                'Subject %d slice %d is not numeric.', s, r);
            assert(numel(subjCell{r}) == T_s, ...
                'Within-subject length mismatch: subject %d slice %d has %d vols, expected %d.', ...
                s, r, numel(subjCell{r}), T_s);
        end
    end
end

%% --------------- DISCOVER / ASSIGN SCORING FILES ----------------
% Accept either a file path or a folder path in csvFile
isFolder = isfolder(csvFile);
if isFolder
    D = dir(fullfile(csvFile, '*.csv'));
    assert(~isempty(D), 'No CSV files found in folder: %s', csvFile);
    filePaths = arrayfun(@(d) fullfile(d.folder, d.name), D, 'UniformOutput', false);

    % Try to map by subject index using numbers in filenames (e.g., P2, _02_)
    fileNums = nan(numel(filePaths),1);
    for i = 1:numel(filePaths)
        [~,fname,~] = fileparts(filePaths{i});
        tok = regexp(fname, '(?i)\D?(\d+)\D?', 'tokens', 'once'); % first number in name
        if ~isempty(tok)
            fileNums(i) = str2double(tok{1});
        end
    end
    filesForSubject = strings(1, nSubjects);

    % Natural sort fallback order
    [~, natOrder] = sort_nat(cellfun(@(p) string(p), filePaths, 'UniformOutput', false));

    for s = 1:nSubjects
        idx = find(fileNums == s, 1, 'first'); % direct numeric match (preferred)
        if isempty(idx)
            % fallback by natural order position
            if s <= numel(natOrder)
                idx = natOrder(s);
            else
                error('Not enough scoring files for %d subjects. Found %d files.', nSubjects, numel(filePaths));
            end
        end
        filesForSubject(s) = string(filePaths{idx});
    end
    fprintf('Scoring file assignment:\n');
    for s = 1:nSubjects
        fprintf('  Subject %d  <--  %s\n', s, filesForSubject(s));
    end

else
    % Single file: use same scoring for all subjects
    filesForSubject = repmat(string(csvFile), 1, nSubjects);
    fprintf('Using single scoring file for all %d subjects: %s\n', nSubjects, csvFile);
end

%% --------------- PER-SUBJECT LABELING ----------------
stage_flags_by_subject         = cell(1, nSubjects);  % {s}: [nSlices_s × T_s] string matrix
time_s_by_subject              = cell(1, nSubjects);  % {s}: T_s×1 EEG-clock times
stage_per_timepoint_by_subject = cell(1, nSubjects);  % {s}: T_s×1 labels

for s = 1:nSubjects
    subjCell  = all_subjects{s};
    nSlices_s = size(subjCell,1);
    T_s       = numel(subjCell{1});

    % ---------- Read scoring for this subject ----------
    tbl = read_scoring_table(char(filesForSubject(s)));

    % Precompute discretize edges once (left-closed, right-open)
    edges = [tbl.start; tbl.end(end)];

    % ---------- Build times and map ----------
    t_fmri_s   = (0:T_s-1)' * TR;      % fMRI clock
    time_eeg_s = t_fmri_s + eegLeadsSeconds;

    bin_s   = discretize(time_eeg_s, edges);   % NaN = out of range
    labels_s = strings(T_s,1); labels_s(:) = outOfRangeLabel;
    inRange = ~isnan(bin_s);
    labels_s(inRange) = tbl.stage(bin_s(inRange));

    % Store
    time_s_by_subject{s}              = time_eeg_s;
    stage_per_timepoint_by_subject{s} = labels_s;
    stage_flags_by_subject{s}         = repmat(labels_s.', nSlices_s, 1);
end

%% --------------- BACKWARD-COMPATIBLE FIRST-SUBJECT OUTPUTS ---------------
time_s               = time_s_by_subject{1};
stage_per_timepoint  = stage_per_timepoint_by_subject{1};

%% --------------- SUMMARY (across all subjects) ---------------
all_labels_vector = strings(0,1);
for s = 1:nSubjects
    all_labels_vector = [all_labels_vector; stage_per_timepoint_by_subject{s}(:)]; %#ok<AGROW>
end
[labels_unique, ~, idxu] = unique(all_labels_vector);
counts = accumarray(idxu, 1);
disp('Stage counts across all subjects:');
disp(table(labels_unique, counts));

disp('First 20 volume labels (first subject):');
disp(stage_per_timepoint(1:min(20, numel(stage_per_timepoint))).');

%% ======================= HELPERS ===========================
function tbl = read_scoring_table(pathToCsv)
    % Read and normalize a scoring CSV into columns: start, end, stage
    opts = detectImportOptions(pathToCsv, 'NumHeaderLines', 0);
    opts.VariableNamingRule = 'modify';
    scoreTbl = readtable(pathToCsv, opts);

    v = lower(string(scoreTbl.Properties.VariableNames));
    req = ["start","end","stage"];
    assert(all(ismember(req, v)), ...
        'CSV %s must contain columns: start, end, stage (in seconds).', pathToCsv);

    start_s = scoreTbl.(scoreTbl.Properties.VariableNames{find(v=="start",1)});
    end_s   = scoreTbl.(scoreTbl.Properties.VariableNames{find(v=="end",1)});
    stage   = scoreTbl.(scoreTbl.Properties.VariableNames{find(v=="stage",1)});

    if ~isnumeric(start_s), start_s = str2double(string(start_s)); end
    if ~isnumeric(end_s),   end_s   = str2double(string(end_s));   end
    stage = normalizeStageStr(string(stage));

    tbl = table(start_s(:), end_s(:), stage(:), 'VariableNames', {'start','end','stage'});
    tbl = sortrows(tbl,'start');

    assert(all(tbl.end > tbl.start), 'Scoring %s: each interval must have end > start.', pathToCsv);
    assert(issorted(tbl.start), 'Scoring %s: start times must be sorted.', pathToCsv);
end

function out = normalizeStageStr(in)
    % Map common variants to canonical labels
    s = lower(strtrim(string(in)));
    out = strings(size(s));
    for i = 1:numel(s)
        si = s(i);
        if si == "" || ismissing(si)
            out(i) = "NA";
            continue
        end
        if contains(si, "wake") || si == "w"
            out(i) = "W";
        elseif si == "n1" || contains(si, "stage 1") || si == "s1"
            out(i) = "N1";
        elseif si == "n2" || contains(si, "stage 2") || si == "s2"
            out(i) = "N2";
        elseif si == "n3" || contains(si, "stage 3") || si == "s3" || contains(si,"sws")
            out(i) = "N3";
        elseif contains(si, "rem") || si == "r"
            out(i) = "R";
        else
            out(i) = upper(string(in(i)));
        end
    end
end

function [sortedNames, order] = sort_nat(names)
    % Natural sort for filenames (numbers in order: 2 < 10).
    % Input: cellstr or string array
    if isstring(names), names = cellstr(names); end
    keys = regexprep(names, '(\d+)', '${sprintf(''%010d'', str2double($1))}');
    [~, order] = sort(keys);
    sortedNames = names(order);
end
