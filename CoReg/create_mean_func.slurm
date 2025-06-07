#!/bin/bash
#SBATCH --job-name=mean_func_array
#SBATCH --output=mean_func_%A_%a.out
#SBATCH --error=mean_func_%A_%a.err
#SBATCH --time=00:30:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --array=1-66,101
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load FSL
module load fsl

# Base participant ID from array index
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}

# Construct path to the functional directory
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}/preproc_out"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $PARTICIPANT_ID"
  ./create_mean_func.sh "$FUNC_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi
