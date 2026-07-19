% === CONFIG ===
data_dir = '/Users/Richard/Masterabeit_local/SNORE_CSF_Data/20260329_Raw_Signals';

% === Get all participant files ===
files = dir(fullfile(data_dir, '*.mat'));

for f = 1:numel(files)
    file_path = fullfile(data_dir, files(f).name);
    S = load(file_path);

    if ~isfield(S, 'slice_data_struct')
        warning('Skipping %s (no slice_data_struct found)', files(f).name);
        continue;
    end

    slice_data_struct = S.slice_data_struct;
    has_empty_slice = false;

    for s = 1:numel(slice_data_struct)
        if isempty(slice_data_struct(s).signals)
            has_empty_slice = true;
            break;
        end
    end

    if has_empty_slice
        fprintf('%s\n', erase(files(f).name, '.mat'));
    end
end