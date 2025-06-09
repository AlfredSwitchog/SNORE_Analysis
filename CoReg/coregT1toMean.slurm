#!/bin/bash
#SBATCH --job-name=coreg_T1_to_func_array
#SBATCH --output=mean_func_%A_%a.out
#SBATCH --error=mean_func_%A_%a.err
#SBATCH --time=00:15:00
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --array=2
#SBATCH --mail-user=richard.lohr@gmx.de                                 
#SBATCH --mail-type=BEGIN,END,FAIL                                      

# Load fsl + ants
module purge
module load matlab/R2023a
module load fsl
module load ants

# Base path where participant folders are located
BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# Get the participant number from the array index
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}
PARTICIPANT_DIR="${BASE_DIR}/${PARTICIPANT_ID}"

# Check if folder exists
if [[ -d "$PARTICIPANT_DIR" ]]; then
  echo "Running participant $PARTICIPANT_ID"
  ./coreg_T1_to_func.sh "$PARTICIPANT_DIR"
else
  echo "Directory not found: $PARTICIPANT_DIR"
fi