#!/bin/bash
#SBATCH --job-name=highpass_add_mean_array
#SBATCH --output=./_output_errors/highpass_add_mean_%A_%a.out
#SBATCH --error=./_output_errors/highpass_add_mean_%A_%a.err
#SBATCH --time=00:30:00
#SBATCH --mem=20G
#SBATCH --cpus-per-task=1
#SBATCH --array=2,3,4,6,8,9,10,11,12,14,15,16,20,21,23,24,25,26,27,28,29,30,32,33,37,38,39,40,41,43,46,49,50,52,54,56,57,58,59,62,63,65,66,101
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load FSL
module purge
module load matlab/R2023a
module load fsl

# Base participant ID from array index
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}

# Construct path to the functional directory
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}/func_merged"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $PARTICIPANT_ID"
  ./highpass_add_mean.sh "$FUNC_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi
