# The order of commands is important. The input file needs to be unzipped. 
# AFNI command needs to be run inside the singularity container
# -dt flag set the TR 
#Upward bound needs to be set in order for AFNI to work but 99999 basically lets every low-frequency pass --> essentially highpass filter

#Set TR in Header explicitly (was missing before)


singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dBandpass 0.01 99999 /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii \
  -prefix /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_highpass_func.nii.gz \
  -dt 2.5

#Convert back to nifti like this 
singularity exec -B /scratch/c7201319 \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dAFNItoNIFTI -prefix /scratch/c7201319/SNORE_MR_out/7/func_merged/func_highpass_merged.nii \
  /scratch/c7201319/SNORE_MR_out/7/func_merged/bandpass+tlrc

#check the result
singularity exec -B /scratch/c7201319 \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif 3dinfo -tr /scratch/c7201319/SNORE_MR_out/7/func_merged/bandpass.nii

  singularity exec -B /scratch/c7201319 \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif 3dinfo /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii

  fslhd /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii
  /scratch/c7201319/SNORE_MRI/7/Night/MR ep2d_bold_samba_2mm_sleep

