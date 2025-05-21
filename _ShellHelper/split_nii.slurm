#!/bin/bash
#SBATCH --job-name=split_nii
#SBATCH --output=split_nii_%j.out
#SBATCH --error=split_nii_%j.err
#SBATCH --time=00:30:00          # Wall time (hh:mm:ss)
#SBATCH --mem=4G                 # Memory requested
#SBATCH --cpus-per-task=1        # Number of CPU cores
#SBATCH --mail-type=END,FAIL     # Email notification on job end/fail
#SBATCH --mail-user=richard.lohr@gmx.de  # Set your email here

# Load FSL (adjust depending on your environment)
module load fsl

# Run your script
bash split_nii.sh
