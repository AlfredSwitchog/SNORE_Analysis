#!/bin/bash
#SBATCH --job-name=dcm2nii.slurm
#SBATCH --output=PreProOutput/dcm2nii_%A_%a.out
#SBATCH --error=PreProOutput/dcm2nii_%A_%a.err
#SBATCH --time=02:00:00
#SBATCH --ntasks=1
#SBATCH --mem=16G
#SBATCH --cpus-per-task=1
#SBATCH --array=1,3,17,19,22,34,47,57,60    
#SBATCH --mail-user=richard.lohr@gmx.de
#SBATCH --mail-type=BEGIN,END,FAIL

# Load MATLAB module (adjust to your cluster)
module load matlab

# Participant ID is just the array task ID
SUBJ=${SLURM_ARRAY_TASK_ID}

echo "Running DICOM->NIfTI conversion for participant: ${SUBJ}"

# Paths
DICOM_DIR="/scratch/c7201319/SNORE_MRI/${SUBJ}/Night/MR ep2d_bold_samba_2mm_sleep_merged"
OUT_DIR="/scratch/c7201319/SNORE_MR_out/${SUBJ}/nifti_raw"

# Folder where your convertDicomDir2Nifti.m lives
MATLAB_FUNC_DIR="/scratch/c7201319/SNORE_Analysis/PreProc/nc_SPM_process"

# Create output dir if it doesn't exist
mkdir -p "$OUT_DIR"

echo "DICOM dir:  $DICOM_DIR"
echo "Output dir: $OUT_DIR"
echo "MATLAB func dir: $MATLAB_FUNC_DIR"
echo

# Run MATLAB non-interactively
matlab -nodisplay -nosplash -r "try, addpath('$MATLAB_FUNC_DIR'); convertDicomDir2Nifti('$DICOM_DIR', '$OUT_DIR'); catch ME, disp(getReport(ME)); exit(1); end; exit(0);"
