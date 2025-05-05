% select and load image
file_pth = spm_select(1, 'nii');
[pth, nm, ext] = fileparts(file_pth);
hdr = spm_vol(file_pth);
file_vol = spm_read_vols(hdr);

% create and save eroded image
file_out_vol = spm_erode(file_vol);
hdr_out = hdr;
hdr_out.fname = fullfile(pth, ['e', nm, '.nii']);
spm_write_vol(hdr_out, file_out_vol);