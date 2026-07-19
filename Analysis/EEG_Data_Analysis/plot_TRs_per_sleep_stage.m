%% ============================================================
%  Per-participant grouped bar chart of sleep-stage TR statistics
%  ------------------------------------------------------------
%  INPUT  : sleep_stage_summary_per_participant.mat (struct "summary"
%           produced by summarize_sleep_stages_per_TR.m).
%
%  OUTPUT : one PNG per participant. Each figure is a grouped bar chart
%           with one group per sleep stage and TWO columns per group:
%             (1) n_TRs_per_stage          - total # of TRs in that stage
%             (2) longest_TRs_consecutive  - longest run of consecutive
%                                            TRs in that stage
%           The "NA" boundary label is omitted (see dropStages).
%
%           1 TR = 2.5 s.
% ============================================================

%% ---------------- CONFIG ----------------
summaryFile = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/EEG_Data_Analysis/sleep_stage_summary_per_participant.mat';
outFolder   = '/Users/Richard/Masterabeit_local/SNORE_Plots/EEG_Plots/TRs_per_sleep_stage_per_participant';
dropStages  = "NA";     % stage label(s) to exclude from the plots
dpi         = 200;      % PNG resolution

if ~exist(outFolder, 'dir'); mkdir(outFolder); end

%% ---------------- LOAD ----------------
S = load(summaryFile);
assert(isfield(S, 'summary'), 'No variable "summary" in %s', summaryFile);
summary = S.summary;

% Stage order taken from the summary legend, minus the dropped label(s)
stages = string(summary.stages);
stages = stages(~ismember(stages, dropStages));
assert(~isempty(stages), 'No stages left to plot after dropping: %s', strjoin(dropStages, ', '));

% Participant IDs (already in numeric order in the summary)
pids = string(summary.participants);

fprintf('Plotting %d participant(s) over %d stage(s): %s\n', ...
    numel(pids), numel(stages), strjoin(stages, ', '));

%% ---------------- PLOT PER PARTICIPANT ----------------
for i = 1:numel(pids)
    pid = char(pids(i));
    P   = summary.(pid);

    counts  = zeros(1, numel(stages));
    longest = zeros(1, numel(stages));
    for s = 1:numel(stages)
        fn = char(stages(s));
        counts(s)  = P.n_TRs_per_stage.(fn);
        longest(s) = P.longest_TRs_consecutive.(fn);
    end

    fig = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 900 500]);

    X = categorical(cellstr(stages));
    X = reordercats(X, cellstr(stages));     % keep canonical stage order
    Y = [counts(:), longest(:)];             % nStages x 2  -> grouped bars

    b = bar(X, Y, 'grouped');
    b(1).FaceColor = [0.20 0.45 0.70];       % TRs in stage
    b(2).FaceColor = [0.85 0.55 0.20];       % longest consecutive

    % Numeric labels above non-zero bars (guarded for older MATLAB releases)
    try
        for k = 1:numel(b)
            xe  = b(k).XEndPoints;
            ye  = b(k).YEndPoints;
            lab = string(ye);
            lab(ye == 0) = "";
            text(xe, ye, lab, 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'bottom', 'FontSize', 7);
        end
    catch
        % older MATLAB without XEndPoints: skip labels
    end

    ylabel('Number of TRs  (1 TR = 2.5 s)');
    xlabel('Sleep stage');
    title(sprintf('%s  -  TRs per sleep stage   (total TRs = %d)', pid, P.total_TRs), ...
          'Interpreter', 'none');
    legend({'TRs in stage', 'Longest consecutive TRs'}, 'Location', 'northeast');
    box off;
    ax = gca; ax.YGrid = 'on'; ax.XGrid = 'off';
    ylim([0, max(1, max(Y(:)) * 1.12)]);     % headroom for the labels

    outPng = fullfile(outFolder, sprintf('%s_TRs_per_sleep_stage.png', pid));
    try
        exportgraphics(fig, outPng, 'Resolution', dpi);
    catch
        print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
    end
    close(fig);
end

fprintf('Done. Saved %d PNG(s) to:\n  %s\n', numel(pids), outFolder);
