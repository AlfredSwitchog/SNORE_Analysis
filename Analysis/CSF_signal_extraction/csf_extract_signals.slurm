#!/bin/bash
#SBATCH --job-name=extract_csf_signal
#SBATCH --output=extract_csf_signal_%A_%a.out
#SBATCH --error=extract_csf_signal_%A_%a.err
#SBATCH --time=00:30:00
#SBATCH --array=1,2,3,4,5,6,7,8,9,10,11,12,14,15,16,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,37,38,39,40,41,43,46,48,49,50,51,52,53,54,55,56,57,58,59,61,62,63,65,66,101
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --mem=2G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load matlab
module purge
module load matlab/R2023a

#Run Script
matlab -nodisplay -nosplash -r "extract_csf_signals($SLURM_ARRAY_TASK_ID); exit;"
