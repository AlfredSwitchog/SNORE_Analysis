%% ============================================================
%  Classic hypnogram per participant
%  ------------------------------------------------------------
%  INPUT  : SNORE_EEG/SCORING_files_cleaned/P*.csv
%           (30 s scoring epochs; columns: clock start time, start, end, stage)
%
%  PLOT   : classic hypnogram - x axis = time (minutes), y axis = sleep
%           stage ordered top->bottom as Wake, REM, NREM1, NREM2, NREM3.
%           REM is highlighted in red. Undefined / Unknown epochs are
%           left empty (a gap in the trace).
%
%  OUTPUT : one PNG per participant ->
%           SNORE_Plots/EEG_Plots/Hypnograms/P<n>_hypnogram.png
% ============================================================

%% ---------------- CONFIG ----------------
inFolder    = '/Users/Richard/Masterabeit_local/SNORE_EEG/SCORING_files_cleaned';
outFolder   = '/Users/Richard/Masterabeit_local/SNORE_Plots/EEG_Plots/Hypnograms';
filePattern = 'P*.csv';
dpi         = 200;

% y-levels (top -> bottom). Undefined/Unknown -> NaN (left empty)
yTicksVal   = [1 2 3 4 5];
yTickLabel  = {'NREM3','NREM2','NREM1','REM','Wake'};
REM_LEVEL   = 4;

if ~exist(outFolder, 'dir'); mkdir(outFolder); end

%% ---------------- FIND FILES ----------------
D = dir(fullfile(inFolder, filePattern));
assert(~isempty(D), 'No files matching "%s" in %s', filePattern, inFolder);
fprintf('Found %d scoring file(s).\n', numel(D));

%% ---------------- PLOT PER PARTICIPANT ----------------
for i = 1:numel(D)
    tok = regexp(D(i).name, '^P(\d+)', 'tokens', 'once');
    if isempty(tok); warning('No leading P<num>: %s (skipped)', D(i).name); continue; end
    N = str2double(tok{1});

    [startS, endS, stage] = read_scores(fullfile(D(i).folder, D(i).name));
    xs = startS(:) / 60;            % minutes
    xe = endS(:)   / 60;
    lv = stage_to_level(stage(:));  % NaN for Undefined/Unknown/other

    % ---- classic stair trace: each epoch = horizontal at its level,
    %      neighbours joined by verticals (NaN epochs create gaps) ----
    X = reshape([xs, xe].', [], 1);
    Y = reshape([lv, lv].', [], 1);

    fig = figure('Visible','off', 'Color','w', 'Position',[100 100 1100 380]);
    plot(X, Y, 'k', 'LineWidth', 1); hold on;

    % ---- REM highlight (red horizontal segments) ----
    isR = (lv == REM_LEVEL);
    if any(isR)
        sR = xs(isR); eR = xe(isR); z = nan(numel(sR),1);
        xr = reshape([sR, eR, z].', [], 1);
        yr = reshape([REM_LEVEL+z*0, REM_LEVEL+z*0, z].', [], 1);
        plot(xr, yr, 'r', 'LineWidth', 2.5);
    end
    hold off;

    ylim([0.5 5.5]); yticks(yTicksVal); yticklabels(yTickLabel);
    xlim([0, max(xe)]);
    xlabel('Time (min)'); ylabel('Sleep stage');
    title(sprintf('P%d - Hypnogram', N), 'Interpreter','none');
    ax = gca; ax.YGrid = 'on'; ax.XGrid = 'off'; box off;

    outPng = fullfile(outFolder, sprintf('P%d_hypnogram.png', N));
    try
        exportgraphics(fig, outPng, 'Resolution', dpi);
    catch
        print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
    end
    close(fig);
end

fprintf('Done. Saved hypnogram(s) to:\n  %s\n', outFolder);

%% ======================= HELPERS ===========================
function [startS, endS, stage] = read_scores(csvPath)
    T   = readtable(csvPath, 'Delimiter', ',', ...
                    'VariableNamingRule','preserve', 'TextType','string');
    vn  = string(T.Properties.VariableNames);
    cvn = regexprep(lower(strtrim(vn)), '[^a-z0-9]+', '');
    iS  = find(cvn=="start",1); iE = find(cvn=="end",1); iG = find(cvn=="stage",1);
    assert(~isempty(iS) && ~isempty(iE) && ~isempty(iG), ...
        'start/end/stage column not found in %s', csvPath);
    startS = double(T.(vn(iS)));
    endS   = double(T.(vn(iE)));
    stage  = string(T.(vn(iG)));
end

function lv = stage_to_level(stage)
    % Wake=5, REM=4, NREM1=3, NREM2=2, NREM3=1; anything else (Undefined,
    % Unknown, NA, ...) -> NaN so it is left empty in the plot.
    s  = regexprep(lower(strtrim(stage)), '[^a-z0-9]+', '');   % lower FIRST, then strip
    lv = nan(size(s));
    lv(s=="wake"  | s=="w")  = 5;
    lv(s=="rem")             = 4;
    lv(s=="nrem1" | s=="n1") = 3;
    lv(s=="nrem2" | s=="n2") = 2;
    lv(s=="nrem3" | s=="n3") = 1;
end
