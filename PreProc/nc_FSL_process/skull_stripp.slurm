#!/bin/bash
#SBATCH --job-name=skull_stripp
#SBATCH --output=skull_stripp_%A_%a.out
#SBATCH --error=skull_stripp_%A_%a.err
#SBATCH --time=02:00:00
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
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}/nifti_raw_2"
OUT_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}/skull_stripp"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $PARTICIPANT_ID"
  ./skull_stripp.sh "$FUNC_DIR" "$OUT_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi
