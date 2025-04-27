% ============================================================
% Script Name:    script_name.m
% Author:         Richard
% Date:           2025-02-11
% Description:    Briefly describe what the script does.
% Inputs:         List input parameters or files (if any).
% Outputs:        List output variables, files, or figures.
% Dependencies:   List required toolboxes, functions, or files.
% Usage:          Example usage, if applicable.
% ============================================================

%% Initialize SPM
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

%% Output Directory
matlabbatch{1}.spm.tools.physio.save_dir = {'/Users/Richard/MatLAB/Conversion_resp_puls/data/p32/p32_physio_output/p32_physio_output_sleep'};

%% log-files
matlabbatch{1}.spm.tools.physio.log_files.vendor = 'Siemens';
matlabbatch{1}.spm.tools.physio.log_files.cardiac = {'/Users/Richard/MatLAB/Conversion_resp_puls/data/p32/p32_physio_input/DO04DK021224_physio_sleep.puls'}; %.puls file here or .ecg?
matlabbatch{1}.spm.tools.physio.log_files.respiration = {'/Users/Richard/MatLAB/Conversion_resp_puls/data/p32/p32_physio_input/DO04DK021224_physio_sleep.resp'}; %.resp file here

%Inputs that I don't understand

%Q: Relative time between log-file and header of dcom volume 
% --> how can we check the header of dcom volume?
matlabbatch{1}.spm.tools.physio.log_files.scan_timing = {'/Users/Richard/MatLAB/Conversion_resp_puls/data/p32/p32_DICOM_sleep/MR000000.dcm'}; %Sabrinas Input:  you need to choose the first volume (i.e., first nifti image of the functional scans)
matlabbatch{1}.spm.tools.physio.log_files.sampling_interval = []; %Question: How do we know this?
matlabbatch{1}.spm.tools.physio.log_files.relative_start_acquisition = [];
matlabbatch{1}.spm.tools.physio.log_files.align_scan = 'last'; 

%% scan_timing - sqpar
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nslices = 72;
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.NslicesPerBeat = [];
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.TR = 2.5; % in secs
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Ndummies = 0; %Q Richard: How do we know this? We have 3594 nifti files, are the dummy scans included? N scanns = 3594 - 5 dummy scanns = 3589?
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nscans = 3594; %This number can be determined by checking how many .nii/.dcm files are present for a certain session
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.onset_slice = 36; %Middle slice --> nslices/2
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.time_slice_to_slice = [] ; %in Manual_Tutorial.pdf we have sqpar.TR / sqpar.Nslices; --> Whats the slice to slice?
matlabbatch{1}.spm.tools.physio.scan_timing.sqpar.Nprep = [];

%% scan_timing - sync
%matlabbatch{1}.spm.tools.physio.scan_timing.sync.scan_timing_log = struct([]); %this line is from the example from Github
matlabbatch{1}.spm.tools.physio.scan_timing.sync.nominal = struct([]);

%% preproc - cardiac
matlabbatch{1}.spm.tools.physio.preproc.cardiac.modality = 'PPU'; % Q Richard: PPU or ECG?
matlabbatch{1}.spm.tools.physio.preproc.cardiac.filter.no = struct([]);
matlabbatch{1}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.min = 0.4;
matlabbatch{1}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.file = 'initial_cpulse_kRpeakfile.mat';
matlabbatch{1}.spm.tools.physio.preproc.cardiac.initial_cpulse_select.auto_matched.max_heart_rate_bpm = 90; %Other scripts set this to 120
matlabbatch{1}.spm.tools.physio.preproc.cardiac.posthoc_cpulse_select.off = struct([]);

%% preproc - respiration
matlabbatch{1}.spm.tools.physio.preproc.respiratory.filter.passband = [0.01 2];
matlabbatch{1}.spm.tools.physio.preproc.respiratory.despike = false;

%% model
matlabbatch{1}.spm.tools.physio.model.output_multiple_regressors = 'multiple_regressors.txt';
matlabbatch{1}.spm.tools.physio.model.output_physio = 'physio.mat';
matlabbatch{1}.spm.tools.physio.model.orthogonalise = 'none';
matlabbatch{1}.spm.tools.physio.model.censor_unreliable_recording_intervals = false;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.c = 3;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.r = 4;
matlabbatch{1}.spm.tools.physio.model.retroicor.yes.order.cr = 1;
matlabbatch{1}.spm.tools.physio.model.rvt.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.hrv.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.noise_rois.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.movement.no = struct([]);
matlabbatch{1}.spm.tools.physio.model.other.no = struct([]);


%% verbose
matlabbatch{1}.spm.tools.physio.verbose.level = 2; % 2 = more detailed figures
matlabbatch{1}.spm.tools.physio.verbose.fig_output_file = 'PhysIO_output.jpg';
matlabbatch{1}.spm.tools.physio.verbose.use_tabs = true;


%Execute the batch
spm_jobman('run', matlabbatch);
