#!/bin/bash
#SBATCH --job-name=merge_fmri
#SBATCH --output=merge_fmri_%j.log
#SBATCH --time=00:10:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G

# --- Load FSL ---
module purge
module load fsl

# --- Move to your participant's functional folder ---
cd /scratch/c7201319/SNORE_MR_out/16/nifti_raw || { echo "❌ Directory not found"; exit 1; }

echo "Merging functional volumes with prefix ua* ..."
fslmerge -t ua_4D.nii.gz ua*.nii

echo "✅ Done: created ua_4D.nii.gz"
