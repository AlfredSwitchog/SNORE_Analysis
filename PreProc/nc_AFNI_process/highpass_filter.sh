# The order of commands is important. The input file needs to be unzipped. 
# AFNI command needs to be run inside the singularity container

singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dBandpass 0.01 99999 /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii \
  -prefix /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_highpass_func.nii.gz \
  -dt 2.0