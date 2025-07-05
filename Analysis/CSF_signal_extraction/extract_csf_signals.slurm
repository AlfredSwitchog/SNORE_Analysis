#!/bin/bash
#SBATCH --job-name=extract_csf_signal
#SBATCH --output=extract_csf_signal_%A_%a.out
#SBATCH --error=extract_csf_signal_%A_%a.err
#SBATCH --time=00:10:00
#SBATCH --array=1
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