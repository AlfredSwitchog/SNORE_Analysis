%% ============================================================
%  Per-participant sleep-stage summary from per-TR scoring
%  ------------------------------------------------------------
%  INPUT  : the per-subject .mat files produced by
%           TimePointLabeling_v2.m, i.e. each file
%           "P<n>_sleep_stage_per_TR.mat" containing the variable
%           stage_per_TR (Kx1 string, one label per TR, VERBATIM).
%
%  OUTPUT : ONE .mat file containing ONE struct called "summary".
%           For every participant P<n>:
%             summary.P<n>.n_TRs_per_stage.<Stage>          -> # TRs in that stage
%             summary.P<n>.longest_TRs_consecutive.<Stage>  -> longest run of
%                                                              consecutive TRs in
%                                                              that stage
%             summary.P<n>.total_TRs                         -> total # of TRs
%             summary.P<n>.source_mat                        -> source .mat path
%           Plus two top-level helper fields:
%             summary.stages        -> stage label order used (1xS string)
%             summary.participants  -> participant IDs, numeric order (1xP string)
%
%  Stage labels are kept VERBATIM (Wake / NREM1 / NREM2 / NREM3 / REM /
%  Undefined / Unknown / ...). No normalisation is applied. Every
%  participant gets the SAME set of stage fields (the union across all
%  files); stages that never occur for a participant are reported as 0.
% ============================================================

%% ---------------- CONFIG ----------------
inFolder    = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
outFolder   = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/EEG_Data_Analysis';
outFile     = fullfile(outFolder, 'sleep_stage_summary_per_participant.mat');
filePattern = 'P*_sleep_stage_per_TR.mat';

if ~exist(outFolder, 'dir'); mkdir(outFolder); end

%% ---------------- FIND FILES ----------------
D = dir(fullfile(inFolder, filePattern));
assert(~isempty(D), 'No files matching "%s" in %s', filePattern, inFolder);
fprintf('Found %d participant file(s) in %s\n', numel(D), inFolder);

%% ---------------- PASS 1: read each file ----------------
nP        = numel(D);
pidNum    = zeros(nP,1);          % numeric subject id (for sorting)
pidStr    = strings(nP,1);        % "P10" etc.
stageVecs = cell(nP,1);           % verbatim stage labels per TR
srcPaths  = strings(nP,1);
allStages = strings(0,1);         % running union of stage labels

for i = 1:nP
    fp = fullfile(D(i).folder, D(i).name);
    S  = load(fp);
    assert(isfield(S, 'stage_per_TR'), ...
        'Variable "stage_per_TR" not found in %s', D(i).name);

    stages = string(S.stage_per_TR(:));          % Kx1 verbatim labels

    tok = regexp(D(i).name, '^P(\d+)', 'tokens', 'once');
    assert(~isempty(tok), 'Cannot parse subject number from %s', D(i).name);

    pidNum(i)    = str2double(tok{1});
    pidStr(i)    = "P" + tok{1};
    stageVecs{i} = stages;
    srcPaths(i)  = string(fp);
    allStages    = [allStages; unique(stages)];  %#ok<AGROW>
end

% Canonical, dataset-wide stage ordering (every participant uses this set)
stageOrder = order_stages(allStages);

% Sort participants by numeric id so output is tidy
[~, order] = sort(pidNum);
pidNum    = pidNum(order);
pidStr    = pidStr(order);
stageVecs = stageVecs(order);
srcPaths  = srcPaths(order);

%% ---------------- PASS 2: build the summary struct ----------------
summary               = struct();
summary.stages        = stageOrder;          % legend / column order
summary.participants  = pidStr(:).';         % 1xP string row

for i = 1:nP
    stages = stageVecs{i};
    pid    = pidStr(i);

    counts  = struct();
    longest = struct();

    for s = 1:numel(stageOrder)
        st    = stageOrder(s);
        fname = safe_fieldname(st);           % all real labels are already valid
        mask  = (stages == st);

        counts.(fname)  = sum(mask);          % how many TRs in this stage
        longest.(fname) = longest_run(mask);  % longest consecutive run of TRs
    end

    summary.(pid).n_TRs_per_stage         = counts;
    summary.(pid).longest_TRs_consecutive = longest;
    summary.(pid).total_TRs               = numel(stages);
    summary.(pid).source_mat              = srcPaths(i);

    fprintf('  %-5s : %d TRs across %d stage label(s)\n', ...
        pid, numel(stages), nnz(structfun(@(x) x>0, counts)));
end

%% ---------------- SAVE (one .mat, one struct) ----------------
save(outFile, 'summary');
fprintf('\nSaved summary for %d participant(s) to:\n  %s\n', nP, outFile);

%% ======================= HELPERS ===========================
function m = longest_run(mask)
    % Longest run of TRUE values in a logical vector.
    mask = logical(mask(:).');
    if ~any(mask)
        m = 0; return
    end
    dd        = diff([false, mask, false]);
    runStarts = find(dd ==  1);
    runEnds   = find(dd == -1);
    m         = max(runEnds - runStarts);
end

function ord = order_stages(stages)
    % Put the known sleep stages first in a sensible order, then append any
    % other labels (e.g. "NA") alphabetically. Output is a 1xS string row.
    pref   = ["Wake","NREM1","NREM2","NREM3","REM","Undefined","Unknown","NA"];
    stages = unique(string(stages(:).'));
    ord    = strings(1,0);
    for p = pref
        if any(stages == p); ord(end+1) = p; end %#ok<AGROW>
    end
    rest = sort(setdiff(stages, ord));
    ord  = [ord, rest(:).'];
end

function f = safe_fieldname(label)
    % Use the verbatim label as the struct field name when it is already a
    % valid MATLAB identifier; otherwise sanitise it (and warn) so the script
    % never crashes on an unexpected label.
    label = char(label);
    if ~isempty(regexp(label, '^[A-Za-z][A-Za-z0-9_]*$', 'once'))
        f = label;
    else
        f = matlab.lang.makeValidName(label);
        warning('Stage label "%s" is not a valid field name; stored as "%s".', label, f);
    end
end
