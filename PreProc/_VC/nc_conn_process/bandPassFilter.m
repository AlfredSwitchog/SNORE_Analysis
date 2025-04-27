% === SETUP ===
clear conn_batch;

% Paths to your smoothed functional files (4D .nii or list of 3D .nii)
func_files = {{'/full/path/to/swrf_func1.nii'}};  % double braces = 1 subject, 1 session



% === INITIALIZE SETUP ===

conn_batch.Setup.functionals = func_files;  % only functionals, no anatomicals
conn_batch.Setup.structurals = {};  % skip anatomical
conn_batch.Setup.acquisitiontype = 1;  % 1 = volumes
conn_batch.Setup.RT = TR;  % specify TR in seconds
conn_batch.Setup.nsubjects = 1;
conn_batch.Setup.nsessions = 1;
conn_batch.Setup.isnew = 1;
conn_batch.Setup.done = 1;
conn_batch.Setup.overwrite = 'Yes';

% Disable segmentation/normalization steps
conn_batch.Setup.analyses = [0];  % no analysis
conn_batch.Setup.outputfiles = [1 1 1];

% === DENOISING STEP ===
conn_batch.Denoising.filter = [0.01 Inf];  % Bandpass filter in Hz
%conn_batch.Denoising.detrending = 1;      % Linear detrending
conn_batch.Denoising.confounds.names = {}; % No confound regression
conn_batch.Denoising.done = 1;

% === RUN BATCH ===
conn_batch.done = 1;

% Execute the batch
conn_batch_run(conn_batch);
