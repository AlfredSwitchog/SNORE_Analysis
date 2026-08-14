%% ============================================================
%  Per-participant CSF inflow amplitude: 95th / 5th percentile per slice
%  ------------------------------------------------------------
%  One figure per participant, showing how the amplitude of the CSF
%  signal changes across the four bottom slices.
%
%  Amplitude is quantified as the ratio of the 95th to the 5th percentile
%  of the signal over time, following Fultz et al. (2019). Percentiles
%  rather than min/max, so a single artefact volume cannot dominate; a
%  ratio rather than a difference, so the arbitrary image intensity units
%  cancel and participants become comparable.
%
%  The inflow effect shows up as a DECAY of this ratio across ascending
%  slices, not as a difference in mean signal level.
%
%  No smoothing is applied: smoothing shrinks exactly the spread that is
%  being measured.
%
%  Requires the Statistics and Machine Learning Toolbox (prctile).
%
%  1 TR = 1 volume = 2.5 s.
% ============================================================

clear; clc;

%% ---------------- CONFIG ----------------
dataDir   = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260406_Averaged_Signal';
filePat   = 'csf_p%d_averaged.mat';   % %d is replaced by the participant number
globPat   = 'csf_p*_averaged.mat';    % used when subjects is empty
signalVar = 'averaged_slices';        % T x nSlice (one column per slice)

% Participants to plot. [] = every csf_p*_averaged.mat found in dataDir.
% Otherwise a list of participant numbers, e.g. [6 8 22 49]
subjects  = [6 8 14 18 20 21 22 23 31 32 33 35 41 42 43 45 47 49 51 52 53 55 57 63 64 66];

slicesToEval = 1:4;   % the four bottom slices

savePng  = true;
savePdf  = false;
saveCsv  = true;      % table of all ratios, participants x slices
plotRoot = '/Users/Richard/Masterabeit_local/SNORE_Plots/Inflow_Effect';
dpi      = 300;

% Figures go to   <plotRoot>/<yyyymmdd>_Figures/<subDir>/<source name>.png
% Only the dated folder carries the date; running again on the same day
% overwrites the previous figures.
subDir  = 'all_individual_figs_95th_to_5th';
csvName = 'individual_95th_to_5th_ratios.csv';

%% ---------------- OUTPUT FOLDER ----------------
outDir = fullfile(plotRoot, ...
                  sprintf('%s_Figures', char(datetime('now','Format','yyyyMMdd'))), ...
                  subDir);
if (savePng || savePdf || saveCsv) && ~exist(outDir, 'dir'); mkdir(outDir); end

%% ---------------- COLLECT PARTICIPANTS ----------------
if isempty(subjects)
    D = dir(fullfile(dataDir, globPat));
    subjects = [];
    for i = 1:numel(D)
        tok = regexp(D(i).name, 'p(\d+)_', 'tokens', 'once');
        if ~isempty(tok); subjects(end+1) = str2double(tok{1}); end %#ok<SAGROW>
    end
    subjects = sort(subjects);
end
subjects = subjects(:).';

fprintf('\n=========== CSF 95th/5th PERCENTILE RATIO ===========\n');
fprintf('Data dir : %s\n', dataDir);
fprintf('Output   : %s\n', outDir);
fprintf('Slices   : %d..%d\n', slicesToEval(1), slicesToEval(end));
fprintf('Subjects : %d requested\n', numel(subjects));
fprintf('=====================================================\n\n');

nSlice = numel(slicesToEval);
ratios = nan(numel(subjects), nSlice);
usedID = nan(1, numel(subjects));

%% ---------------- PER-PARTICIPANT LOOP ----------------
fprintf('%-7s %s\n', 'Subj', 'ratio per slice');
fprintf('%s\n', repmat('-',1,58));

for k = 1:numel(subjects)
    N = subjects(k);
    f = fullfile(dataDir, sprintf(filePat, N));
    if exist(f, 'file') ~= 2
        fprintf('P%-6d file not found -> skipped\n', N);
        continue
    end
    S = load(f, signalVar);
    if ~isfield(S, signalVar)
        fprintf('P%-6d no "%s" in file -> skipped\n', N, signalVar);
        continue
    end
    X = S.(signalVar);
    if size(X,1) < size(X,2); X = X.'; end     % time is the long dimension

    % ---- ratio per slice ----
    for j = 1:nSlice
        s = slicesToEval(j);
        if s > size(X,2)
            fprintf('P%-6d slice %d does not exist -> skipped\n', N, s);
            continue
        end
        ts = X(:, s);
        ts(ts == 0) = NaN;                     % treat exact zeros as missing
        ts = ts(isfinite(ts));
        if numel(ts) < 2; continue; end

        p95 = prctile(ts, 95);     % Statistics and Machine Learning Toolbox
        p5  = prctile(ts,  5);
        if p5 > 0
            ratios(k, j) = p95 / p5;
        end
    end

    if all(isnan(ratios(k,:)))
        fprintf('P%-6d no valid data in any slice -> no figure\n', N);
        continue
    end
    usedID(k) = N;

    fprintf('P%-6d %s\n', N, sprintf('%8.3f', ratios(k,:)));

    % ---- figure ----
    fh = figure('Visible','off', 'Color','w', 'Position',[100 100 620 460]);
    plot(slicesToEval, ratios(k,:), '-o', 'LineWidth',2, ...
         'MarkerFaceColor',[0.15 0.35 0.70], 'Color',[0.15 0.35 0.70]);
    xlabel('Slice (1 = bottom of the imaging volume)');
    ylabel('95th / 5th percentile ratio');
    title(sprintf('P%d  -  CSF signal amplitude across slices %d-%d', ...
                  N, slicesToEval(1), slicesToEval(end)));
    xticks(slicesToEval); xlim([slicesToEval(1)-0.3 slicesToEval(end)+0.3]);
    yl = ylim; ylim([min(1, yl(1)) yl(2)]);    % 1 = no variation at all
    yline(1, 'k:', 'HandleVisibility','off');
    grid off;

    [~, name] = fileparts(f);                  % e.g. csf_p49_averaged
    base = fullfile(outDir, name);
    if savePng; exportgraphics(fh, [base '.png'], 'Resolution', dpi); end
    if savePdf; exportgraphics(fh, [base '.pdf']); end
    close(fh);
end

%% ---------------- SUMMARY ----------------
ok = ~isnan(usedID);
fprintf('%s\n', repmat('-',1,58));
fprintf('%d participant(s) plotted, %d skipped.\n\n', sum(ok), sum(~ok));

R  = ratios(ok, :);
ID = usedID(ok).';

if ~isempty(R)
    [~, peakSlice] = max(R, [], 2, 'omitnan');
    mono = all(diff(R, 1, 2) <= 0, 2);         % ratio decreasing across slices

    fprintf('slice with the largest amplitude:\n');
    for s = 1:nSlice
        n = sum(peakSlice == s);
        if n > 0
            fprintf('   slice %d : %2d participant(s)\n', slicesToEval(s), n);
        end
    end
    fprintf('amplitude decreases monotonically across all slices: %d/%d\n\n', ...
            sum(mono), numel(mono));

    if saveCsv
        Tb = array2table(R, 'VariableNames', ...
                         compose('Slice%d', slicesToEval(:).').');
        Tb = addvars(Tb, ID, 'Before', 1, 'NewVariableNames', 'Participant');
        Tb = addvars(Tb, slicesToEval(peakSlice).', mono, ...
                     'NewVariableNames', {'PeakSlice','MonotoneDecay'});
        csvPath = fullfile(outDir, csvName);
        writetable(Tb, csvPath);
        fprintf('Ratio table saved to: %s\n', csvPath);
    end
end
fprintf('Figures saved to: %s\n\nDone.\n', outDir);
