#!/bin/bash
#SBATCH --job-name=merge_highpass_add_mean_array
#SBATCH --output=./_output_errors/merge_highpass_add_mean_%A_%a.out
#SBATCH --error=./_output_errors/merge_highpass_add_mean%A_%a.err
#SBATCH --time=00:30:00
#SBATCH --mem=20G
#SBATCH --cpus-per-task=1
#SBATCH --array=16
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load FSL
module purge
module load matlab/R2023a
module load fsl

# Base participant ID from array index
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}

# Construct path to the functional directory
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}/preprocessing/smooth"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $PARTICIPANT_ID"
  ./merge_highpass_add_mean.sh "$FUNC_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi
