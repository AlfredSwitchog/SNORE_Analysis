# AFNI command needs to be run inside the singularity container
# Important: header needs to be set properly for temporal operations (was missing before)

#old AFNI command
singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dBandpass 0.01 99999 /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii \
  -prefix /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_highpass_func.nii.gz \
  -dt 2.5

#new AFNI command
singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dTproject -input /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii \
  -prefix /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_highpass_func.nii \
  -stopband 0 0.0099 \
  -TR 2.5 \
  -polort 2

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

#check Nifit header
singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  nifti_tool -disp_hdr -infiles /scratch/c7201319/SNORE_MR_out/8/func_merged/merged_func.nii

singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
  3dinfo /scratch/c7201319/SNORE_MR_out/7/func_merged/merged_func.nii

#change Nifti header
singularity exec \
  -B /scratch/c7201319/ \
  /gpfs/gpfs1/sw/containers/x86_64/generic/afni/2023-07-03/afni.sif \
nifti_tool -mod_hdr -mod_field pixdim '-1.0 2.04255 2.042551 2.200001 2.5 0 0 0' -infile ./merged_func.nii -overwrite

/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/merged_s3uaMFAN99SC020724.nii

#highpass filter using FSL

# Calculate sigma in seconds for fslmaths
# FSL's -bptf expects sigma values, not frequency --> per volume 
# I assume here the relationship of FWHM=2.3548 * sigma --> sigma = FWHM/2.3548
# sigma = cutoff period / (2 * sqrt(2 * ln(2)))
# sigma (in volumes) = (1 / cutoff_frequency) / (2 * sqrt(2 * ln(2))) / TR
# sigma (in volumes) = ((1/0.01)/ 2.3548)/2.5 = 16.9866 ~ 17
SIGMA=$(echo "scale=5; (1 / $HIGHPASS_HZ) / (2 * sqrt(2 * l(2))) / $TR" | bc -l)
LOWPASS_SIGMA=-1  # No lowpass filter

echo "Applying highpass filter with sigma=${SIGMA} volumes..."
fslmaths "$MERGED_FILE" -bptf "$SIGMA" "$LOWPASS_SIGMA" "$FILTERED_FILE"


#calculate the mean from the 4d image
fslmaths input_file.nii -Tmean mean_signal.nii

#apply the filter
fslmaths /Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/merged_highpass_func.nii \
  -bptf 17 -1 /Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/fsl_merged_highpass_func.nii \
  -add mean.nii.gz output_file


  
>" -bptf  <hp_sigma> <lp_sigma> : (-t in ip.c) Bandpass temporal filtering;
>nonlinear highpass and Gaussian linear lowpass (with sigmas in volumes, not
>seconds); set either sigma<0 to skip that filter"

#Check the nifti header using FSL
fslhd /Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged/fsl_merged_highpass_func.nii
