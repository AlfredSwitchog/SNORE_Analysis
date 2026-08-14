function S = sleep_scoring_load(eegDir, subjects)
% Load every EEG sleep-scoring file as one struct array.
%   S(i).id  = participant number
%   S(i).lab = string vector, one sleep stage per fMRI volume
% subjects: [] = all found, otherwise keep only those participant numbers.
%
% Labels used in these files: "Wake" "NREM1" "NREM2" "NREM3" "REM" (rarely "NA")

if nargin < 2; subjects = []; end

D = dir(fullfile(eegDir, 'P*_sleep_stage_per_TR.mat'));
assert(~isempty(D), 'No P*_sleep_stage_per_TR.mat found in %s', eegDir);

S = struct('id', {}, 'lab', {});
for i = 1:numel(D)
    tok = regexp(D(i).name, '^P(\d+)_', 'tokens', 'once');
    if isempty(tok); continue; end
    N = str2double(tok{1});
    if ~isempty(subjects) && ~ismember(N, subjects); continue; end

    E = load(fullfile(D(i).folder, D(i).name));
    if ~isfield(E, 'stage_per_TR')
        warning('P%d: no stage_per_TR, skipped.', N); continue
    end
    S(end+1) = struct('id', N, 'lab', string(E.stage_per_TR(:))); %#ok<AGROW>
end

[~, ord] = sort([S.id]);
S = S(ord);

% report which requested participants were not found
if ~isempty(subjects)
    missing = setdiff(subjects(:).', [S.id]);
    if ~isempty(missing)
        fprintf('No scoring file for: %s\n', strjoin("P" + string(missing), ', '));
    end
end
end
