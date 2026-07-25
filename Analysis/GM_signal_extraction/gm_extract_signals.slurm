#!/bin/bash
#SBATCH --job-name=gm_extract_signal
#SBATCH --output=_Output_Errors/gm_extract_signal_%A_%a.out
#SBATCH --error=_Output_Errors/gm_extract_signal_%A_%a.err
#SBATCH --time=00:05:00
#SBATCH --array=1,2,3,4,5,6,7,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,101
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load matlab
module purge
module load matlab/R2023a

#Run Script
matlab -nodisplay -nosplash -r "gm_extract_signals($SLURM_ARRAY_TASK_ID); exit;"
