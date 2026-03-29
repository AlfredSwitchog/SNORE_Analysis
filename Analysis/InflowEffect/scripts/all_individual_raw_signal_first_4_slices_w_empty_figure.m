% === CONFIG ===
data_dir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260329_Averaged_Signal';
out_dir  = '/Users/Richard/Masterabeit_local/SNORE_Plots/20260329_Figures';

if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

% === Find all participant files ===
files = dir(fullfile(data_dir, '*.mat'));

for f = 1:length(files)

    file_path = fullfile(data_dir, files(f).name);
    fprintf('Processing %s\n', files(f).name);

    % Load data
    S = load(file_path);

    if ~isfield(S, 'averaged_csf_data')
        warning('Skipping %s (no averaged_csf_data)', files(f).name);
        continue;
    end

    averaged_csf_data = S.averaged_csf_data;

    % === Plot ===
    figure('Visible','off'); hold on;

    numSlices = numel(averaged_csf_data);

    for i = 1:numSlices
        sliceData = averaged_csf_data{i};
        plot(sliceData, 'LineWidth', 1.5);
    end

    xlabel('Time (volumes)');
    ylabel('CSF signal (a.u.)');
    title(sprintf('Raw CSF Signal - %s', files(f).name), 'Interpreter','none');

    legend(arrayfun(@(x) sprintf('Slice %d', x), 1:numSlices, 'UniformOutput', false));
    grid on;

    % === Save figure ===
    [~, name, ~] = fileparts(files(f).name);
    saveas(gcf, fullfile(out_dir, [name '.png']));

    close;
end

disp('All plots created.');