%% ============================================================
%  TOY EXAMPLE: state vs flow, and what the derivative does
%  ------------------------------------------------------------
%  Three curves over one 20 s oscillation (0.05 Hz):
%
%    1. gBOLD              - a STATE (proxy for blood volume)
%    2. CSF inflow         - a FLOW  (what the CSF signal measures)
%    3. -d(gBOLD)/dt       - the gBOLD signal turned into a FLOW,
%                            i.e. the signal used in the derivative
%                            cross-correlation
%
%  There is NO delay anywhere in this model. Even so:
%    gBOLD        peaks at t =  5 s
%    CSF inflow   peaks at t = 10 s      -> 5 s apart = a quarter cycle
%    -d(gBOLD)/dt peaks at t = 10 s      -> coincides with CSF inflow
%
%  That is the whole point of the derivative analysis: comparing a state
%  with a flow always produces an apparent offset, whereas comparing two
%  flows does not, so the peak of the cross-correlation moves to lag 0.
%
%  NOTE: the derivative is shown scaled to unit amplitude so that all
%  three curves are visible on one axis. Scaling does not affect a
%  correlation, so this changes nothing about the analysis.
% ============================================================

%% ---------------- CONFIG ----------------
period  = 20;      % s, one cycle of the modelled oscillation (0.05 Hz)
TR      = 2.5;     % s, sampling interval, matching the fMRI acquisition
outDir  = '/Users/Richard/Masterabeit_local/SNORE_Analysis/Analysis/Cross_Correlation';
savePng = true;
dpi     = 200;

%% ---------------- SIGNALS ----------------
tFine = linspace(0, period, 1000);              % smooth curves for the lines
tS    = 0:TR:period;                            % sampled points, one per volume

gBOLD = @(t) sin(2*pi*t/period);                % STATE  (blood volume proxy)
csf   = @(t) -cos(2*pi*t/period);               % FLOW   (measured CSF inflow)
dNeg  = @(t) -cos(2*pi*t/period);               % FLOW   (-d(gBOLD)/dt, unit-scaled)

tPeakG = period/4;                              %  5 s - gBOLD maximum
tPeakF = period/2;                              % 10 s - inflow maximum

%% ---------------- PRINT THE TABLE ----------------
fprintf('\n t (s)             :'); fprintf('%7.1f', tS);
fprintf('\n gBOLD (state)     :'); fprintf('%+7.2f', gBOLD(tS));
fprintf('\n CSF inflow (flow) :'); fprintf('%+7.2f', csf(tS));
fprintf('\n -d(gBOLD)/dt      :'); fprintf('%+7.2f', dNeg(tS));
fprintf('\n\n gBOLD        peaks at t = %.1f s\n', tPeakG);
fprintf(' CSF inflow   peaks at t = %.1f s   (%.1f s later = quarter cycle)\n', ...
        tPeakF, tPeakF - tPeakG);
fprintf(' -d(gBOLD)/dt peaks at t = %.1f s   (coincides with CSF inflow)\n\n', tPeakF);

%% ---------------- PLOT ----------------
colG = [0.15 0.35 0.70];      % blue   - gBOLD, the state
colF = [0.85 0.33 0.10];      % orange - CSF inflow, the measured flow
colD = [0.20 0.60 0.25];      % green  - -d(gBOLD)/dt, the computed flow

fig = figure('Color','w', 'Position',[100 100 940 500]);
hold on;

yline(0, 'k-', 'HandleVisibility','off');

% vertical guides at the two peak times
xline(tPeakG, ':', 'Color',colG, 'LineWidth',1.2, 'HandleVisibility','off');
xline(tPeakF, ':', 'Color',[0.45 0.45 0.45], 'LineWidth',1.2, 'HandleVisibility','off');

% the three curves; the computed flow is dashed and lies on top of the
% measured flow, because in this idealised model the two are identical
plot(tFine, gBOLD(tFine), '-',  'Color',colG, 'LineWidth',2, ...
     'DisplayName','gBOLD  (state: blood volume)');
plot(tFine, csf(tFine),   '-',  'Color',colF, 'LineWidth',2.6, ...
     'DisplayName','CSF inflow  (measured flow)');
plot(tFine, dNeg(tFine),  '--', 'Color',colD, 'LineWidth',1.8, ...
     'DisplayName','-d(gBOLD)/dt  (gBOLD as a flow)');

% sampled volumes, to show the 2.5 s acquisition grid
plot(tS, gBOLD(tS), 'o', 'Color',colG, 'MarkerFaceColor',colG, ...
     'MarkerSize',5, 'HandleVisibility','off');
plot(tS, csf(tS),   'o', 'Color',colF, 'MarkerFaceColor',colF, ...
     'MarkerSize',5, 'HandleVisibility','off');

% mark the peaks
plot(tPeakG, gBOLD(tPeakG), '^', 'Color',colG, 'MarkerFaceColor',colG, ...
     'MarkerSize',10, 'HandleVisibility','off');
plot(tPeakF, csf(tPeakF),   '^', 'Color',colF, 'MarkerFaceColor',colF, ...
     'MarkerSize',10, 'HandleVisibility','off');
text(tPeakG, 1.12, sprintf('gBOLD peak\nt = %.0f s', tPeakG), ...
     'Color',colG, 'HorizontalAlignment','center', 'FontSize',9);
text(tPeakF, 1.12, sprintf('both flows peak\nt = %.0f s', tPeakF), ...
     'Color',[0.35 0.35 0.35], 'HorizontalAlignment','center', 'FontSize',9);

% arrow spanning the quarter cycle
yArrow = -1.24;
plot([tPeakG tPeakF], [yArrow yArrow], '-', 'Color',[0.35 0.35 0.35], ...
     'LineWidth',1.2, 'HandleVisibility','off');
plot(tPeakG, yArrow, '<', 'Color',[0.35 0.35 0.35], ...
     'MarkerFaceColor',[0.35 0.35 0.35], 'MarkerSize',6, 'HandleVisibility','off');
plot(tPeakF, yArrow, '>', 'Color',[0.35 0.35 0.35], ...
     'MarkerFaceColor',[0.35 0.35 0.35], 'MarkerSize',6, 'HandleVisibility','off');
text(mean([tPeakG tPeakF]), yArrow-0.10, ...
     sprintf('%.0f s = quarter cycle  (state vs flow)', tPeakF-tPeakG), ...
     'Color',[0.35 0.35 0.35], 'HorizontalAlignment','center', ...
     'VerticalAlignment','top', 'FontSize',9);

hold off;
xlabel('Time (s)');
ylabel('Amplitude (arbitrary units)');
title(sprintf(['State vs flow over a %.0f s oscillation - ' ...
               'no delay in the model'], period), 'Interpreter','none');
xticks(tS); xlim([0 period]); ylim([-1.62 1.38]);
legend('Location','southeast', 'Box','off');
grid off;

%% ---------------- SAVE ----------------
if savePng
    if ~exist(outDir, 'dir'); mkdir(outDir); end
    outPng = fullfile(outDir, 'toy_example_state_vs_flow.png');
    try
        exportgraphics(fig, outPng, 'Resolution', dpi);
    catch
        print(fig, outPng, '-dpng', sprintf('-r%d', dpi));
    end
    fprintf('Plot saved to: %s\n', outPng);
end
