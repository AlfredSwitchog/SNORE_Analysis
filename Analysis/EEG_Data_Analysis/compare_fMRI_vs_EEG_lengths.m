%% ============================================================
%  Compare fMRI length vs EEG-label length, per participant
%  ------------------------------------------------------------
%  For every participant that has an averaged CSF file, print:
%    - fMRI_vol : number of fMRI volumes  (rows of averaged_slices)
%    - EEG_TRs  : number of labelled TRs   (numel of stage_per_TR)
%    - diff     : EEG_TRs - fMRI_vol       (and the same in seconds)
%  A positive diff means the EEG scoring outlasts the scan (usually
%  fine, the surplus is at the tail). A NEGATIVE diff means the fMRI
%  has MORE volumes than there are labels -> those volumes cannot be
%  labelled and the alignment must be checked (e.g. split/unmerged
%  runs). 1 TR = 1 volume = 2.5 s.
%
%  Output is printed to the command window only. Nothing is saved.
% ============================================================

%% ---------------- CONFIG ----------------
csfDir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
eegDir = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_converted_to_fMRI';
TR     = 2.5;                 % seconds per volume / TR
bigSurplusTR = 24;            % > this many surplus TRs (=60 s) -> flag for review

%% ---------------- COLLECT + SORT BY SUBJECT NUMBER ----------------
csfFiles = dir(fullfile(csfDir, 'csf_p*_averaged.mat'));
assert(~isempty(csfFiles), 'No csf_p*_averaged.mat files in %s', csfDir);

subjNums = nan(numel(csfFiles),1);
for i = 1:numel(csfFiles)
    tok = regexp(csfFiles(i).name, 'csf_p(\d+)_averaged', 'tokens', 'once');
    if ~isempty(tok); subjNums(i) = str2double(tok{1}); end
end
keep      = ~isnan(subjNums);
csfFiles  = csfFiles(keep);
subjNums  = subjNums(keep);
[subjNums, ord] = sort(subjNums);
csfFiles  = csfFiles(ord);

%% ---------------- COMPARE + PRINT ----------------
fprintf('\nfMRI (CSF averaged) length vs EEG stage_per_TR length   (1 TR = %.1f s)\n', TR);
fprintf('%s\n', repmat('=',1,78));
fprintf('%-7s %9s %9s %16s %9s   %s\n', 'Subj','fMRI_vol','EEG_TRs','diff(EEG-fMRI)','sec','note');
fprintf('%s\n', repmat('-',1,78));

nBoth = 0; missingEEG = strings(0,1); flagged = strings(0,1);

for i = 1:numel(csfFiles)
    N = subjNums(i);

    % ---- fMRI length (orientation-proof: timepoints is the long dimension) ----
    Cs = load(fullfile(csfDir, csfFiles(i).name));
    if isfield(Cs, 'averaged_slices')
        nF = max(size(Cs.averaged_slices));
    else
        nF = 0;                       % fallback: largest numeric array
        fn = fieldnames(Cs);
        for k = 1:numel(fn)
            v = Cs.(fn{k});
            if isnumeric(v); nF = max(nF, max(size(v))); end
        end
    end

    % ---- EEG label length ----
    eegPath = fullfile(eegDir, sprintf('P%d_sleep_stage_per_TR.mat', N));
    if exist(eegPath, 'file') ~= 2
        fprintf('%-7s %9d %9s %16s %9s   %s\n', sprintf('P%d',N), nF, '-', '-', '-', 'EEG file missing');
        missingEEG(end+1) = "P"+N; %#ok<AGROW>
        continue
    end
    Es = load(eegPath);
    if isfield(Es, 'stage_per_TR')
        nE = numel(Es.stage_per_TR);
    else
        nE = numel(Es.time_TR);       % fallback, same length
    end

    % ---- compare ----
    d    = nE - nF;
    note = '';
    if d < 0
        note = 'fMRI LONGER than EEG -> volumes cannot be labelled';
        flagged(end+1) = "P"+N; %#ok<AGROW>
    elseif d > bigSurplusTR
        note = sprintf('EEG much longer (>%g s) -> check run/alignment', bigSurplusTR*TR);
        flagged(end+1) = "P"+N; %#ok<AGROW>
    end
    fprintf('%-7s %9d %9d %16d %9.1f   %s\n', sprintf('P%d',N), nF, nE, d, d*TR, note);
    nBoth = nBoth + 1;
end

%% ---------------- SUMMARY ----------------
fprintf('%s\n', repmat('-',1,78));
fprintf('Compared %d participant(s) present in both folders.\n', nBoth);
if ~isempty(missingEEG)
    fprintf('CSF present but EEG missing : %s\n', strjoin(cellstr(missingEEG), ', '));
end
if ~isempty(flagged)
    fprintf('FLAGGED for review         : %s\n', strjoin(cellstr(unique(flagged,'stable')), ', '));
else
    fprintf('No participants flagged.\n');
end
fprintf('\nReminder: a clean match needs (a) the same start/trigger alignment and\n');
fprintf('(b) one continuous run. Negative diffs usually mean split/unmerged runs.\n\n');
