#!/bin/bash
#SBATCH --job-name=gbold_zscore
#SBATCH --output=_Output_Errors/gbold_zscore_%A_%a.out
#SBATCH --error=_Output_Errors/gbold_zscore_%A_%a.err
#SBATCH --time=00:10:00
#SBATCH --array=1,2,3,4,5,6,7,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,101
#SBATCH --ntasks=1
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-user=richard.lohr@gmx.de
#SBATCH --mail-type=BEGIN,END,FAIL

# Load MATLAB
module purge
module load matlab/R2023a

# Run script
matlab -nodisplay -nosplash -r "gbold_z_score_correct($SLURM_ARRAY_TASK_ID); exit;"
