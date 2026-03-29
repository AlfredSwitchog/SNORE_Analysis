#!/bin/bash
#SBATCH --job-name=csf_extract_signal
#SBATCH --output=Output_Errors/csf_extract_signal_%A_%a.out
#SBATCH --error=Output_Errors/csf_extract_signal_%A_%a.err
#SBATCH --time=00:15:00
#SBATCH --array=9,10,6,22,14,33,43,32,8,46,64,53,21,66,52,18,23,49,51,20,63,45,57,47,42,41,5,31,35,55
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load matlab
module purge
module load matlab/R2023a

#Run Script
matlab -nodisplay -nosplash -r "csf_extract_signals($SLURM_ARRAY_TASK_ID); exit;"
