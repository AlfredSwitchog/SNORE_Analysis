#!/bin/bash
#SBATCH --job-name=extract_csf_signal
#SBATCH --output=extract_csf_signal_%A_%a.out
#SBATCH --error=extract_csf_signal_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load FSL
module purge
module load matlab/R2023a

#Run Script
matlab -batch "run('/scratch/c7201319/SNORE_Analysis/Analysis/CSF_signal_extraction/extract_first_5_slices.m')"