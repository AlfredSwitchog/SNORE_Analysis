function unzip_nii_gz(inputFolder, deleteGZ)
% unzip_nii_gz Unzips all .nii.gz files in a folder
%
%   unzip_nii_gz(inputFolder, deleteGZ)
%
%   inputFolder : path to folder containing .nii.gz files
%   deleteGZ    : logical flag (true/false) — delete .gz files after unzip if true
%
%   Example:
%       unzip_nii_gz('/path/to/data', true)

    if nargin < 2
        deleteGZ = false; % default: keep .gz files
    end

    % Find all .nii.gz files in the folder
    gzFiles = dir(fullfile(inputFolder, '*.nii.gz'));
    if isempty(gzFiles)
        fprintf('No .nii.gz files found in %s\n', inputFolder);
        return;
    end

    % Unzip each file
    for i = 1:numel(gzFiles)
        gzPath = fullfile(gzFiles(i).folder, gzFiles(i).name);
        fprintf('Unzipping %s\n', gzPath);
        gunzip(gzPath, gzFiles(i).folder);
    end

    % Optionally delete the originals
    if deleteGZ
        fprintf('Deleting original .nii.gz files...\n');
        delete(fullfile(inputFolder, '*.nii.gz'));
    end

    fprintf('Done unzipping files in %s\n', inputFolder);
end
