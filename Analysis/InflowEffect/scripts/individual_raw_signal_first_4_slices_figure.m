% averaged_csf_data: 4x1 cell array
% Each cell contains a row vector of time-series values

figure; hold on;
numSlices = numel(averaged_csf_data);

for i = 1:numSlices
    sliceData = averaged_csf_data{i};   % time series vector
    plot(sliceData, 'LineWidth', 1.5);
end

xlabel('Time (volumes)');
ylabel('CSF signal (a.u.)');
title('Raw CSF Signal Per Slice');
legend(arrayfun(@(x) sprintf('Slice %d', x), 1:numSlices, 'UniformOutput', false));
grid on;
