#!/bin/bash
#SBATCH --job-name=coreg_T1_to_func_array
#SBATCH --output=_errors_outputs/coreg_T1_to_func_array%A_%a.out
#SBATCH --error=_errors_outputs/coreg_T1_to_func_arry%A_%a.err
#SBATCH --time=00:10:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --array=1,3-66,101
#SBATCH --mail-user=richard.lohr@gmx.de                                 
#SBATCH --mail-type=BEGIN,END,FAIL                                      

# Load fsl + ants
module purge
module load matlab/R2023a
module load fsl
module load ants

# Base participant ID from array index
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}

# Construct Path to the Input folder
PARTICIPANT_DIR="/scratch/c7201319/SNORE_MR_out/${PARTICIPANT_ID}"

# Check if folder exists
if [[ -d "$PARTICIPANT_DIR" ]]; then
  echo "Running participant $PARTICIPANT_ID"
  ./coregT1toMean.sh "$PARTICIPANT_DIR"
else
  echo "Directory not found: $PARTICIPANT_DIR"
fi
