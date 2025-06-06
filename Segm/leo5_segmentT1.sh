#!/bin/bash
#SBATCH --job-name=segmentT1
#SBATCH --output=job_%A_%a.out                                          # Output file (%A = job ID, %a = array task ID)
#SBATCH --error=job_%A_%a.err                                           # Error file
#SBATCH --time=00:00:10                    # Time limit (hh:mm:ss)
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --cpus-per-task=1                 # Number of CPU cores per task
#SBATCH --mem=500M                           # Memory per node
#SBATCH --array=30                        # Participant ID (use array for multiple)
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

# Load required modules (customize based on your environment)
module load matlab

# Extract participant ID from SLURM_ARRAY_TASK_ID
PARTICIPANT_ID=${SLURM_ARRAY_TASK_ID}

# Run MATLAB function
matlab -nodisplay -nosplash -r "try, segmentT1($PARTICIPANT_ID); catch e, disp(getReport(e)), exit(1); end; exit(0);"