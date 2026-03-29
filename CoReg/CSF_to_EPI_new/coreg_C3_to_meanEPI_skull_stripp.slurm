#!/bin/bash
#SBATCH --job-name=coreg_T1_to_func_array
#SBATCH --output=_errors_outputs/coreg_T1_to_func_array%A_%a.out
#SBATCH --error=_errors_outputs/coreg_T1_to_func_arry%A_%a.err
#SBATCH --time=00:05:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1
#SBATCH --array=1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,45,46,47,48,49,50,51,52,53,54,56,57,58,59,60,61,62,63,64,65,66,101
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
  ./coreg_C3_to_meanEPI_skull_stripp.sh "$PARTICIPANT_DIR"
else
  echo "Directory not found: $PARTICIPANT_DIR"
fi
