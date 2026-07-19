% === CONFIG ===
data_dir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260329_Raw_Signals';

% === Get all participant files ===
files = dir(fullfile(data_dir, '*.mat'));
nParticipants = numel(files);
nSlices = 4;

% Preallocate
zero_counts = zeros(nParticipants, nSlices);
nan_counts  = zeros(nParticipants, nSlices);
participant_names = strings(nParticipants, 1);

% === Loop through files ===
for f = 1:nParticipants
    file_path = fullfile(data_dir, files(f).name);
    S = load(file_path);

    participant_names(f) = erase(files(f).name, '.mat');

    slice_data_struct = S.slice_data_struct;

    for s = 1:nSlices
        signals = slice_data_struct(s).signals;

        zero_counts(f, s) = sum(signals(:) == 0);
        nan_counts(f, s)  = sum(isnan(signals(:)));
    end
end

% === Plot: one subplot per slice, zeros and NaNs side by side ===
figure;

for s = 1:nSlices
    subplot(nSlices, 1, s);
    bar([zero_counts(:, s), nan_counts(:, s)]);
    title(sprintf('Slice %d', s));
    ylabel('Count');
    legend({'Zeros', 'NaNs'});
    xticks(1:nParticipants);
    xticklabels(participant_names);
    xtickangle(45);
end

xlabel('Participants');