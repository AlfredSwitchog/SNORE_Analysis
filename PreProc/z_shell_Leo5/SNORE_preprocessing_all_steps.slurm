#!/bin/bash
#SBATCH --job-name=SNORE_preprocessing_all_steps.slurm                  # Job name
#SBATCH --output=PreProOutput/job_%A_%a.out                             # Output file (%A = job ID, %a = array task ID)
#SBATCH --error=PreProOutput/job_%A_%a.err                              # Error file
#SBATCH --time=08:30:00                                                 # Max wall time 
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --cpus-per-task=1                                               # CPUs per task
#SBATCH --mem=70G                                                       # Units [K|M|G|T]
#SBATCH --array=2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,101 # Array range --> specifies the range of participants
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

#unload currently loaded modules
module purge

#load matlab, spm module
module load matlab/R2023b
module load spm
module load fsl

# === MATLAB SPM (realign, slice time) ===
echo "Starting MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"

MATLAB_CODE_DIR="/scratch/c7201319/SNORE_Analysis/PreProc/z_shell_Leo5"

matlab -nodisplay -nosplash -r "try; addpath('$MATLAB_CODE_DIR'); SNORE_preprocessing_realign_STC($SLURM_ARRAY_TASK_ID); catch ME; disp(getReport(ME,'extended')); exit(1); end; exit(0);"

echo "Finished MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"

# === FSL (skull stripping) ===
# Construct path to the functional directory
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/$SLURM_ARRAY_TASK_ID/nifti_raw" 
OUT_DIR="/scratch/c7201319/SNORE_MR_out/$SLURM_ARRAY_TASK_ID/preprocessing/skull_stripp"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $SLURM_ARRAY_TASK_ID"
  /scratch/c7201319/SNORE_Analysis/PreProc/nc_FSL_process/skull_stripp.sh "$FUNC_DIR" "$OUT_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi

# === MATLAB SPM (smooth) ===
echo "Starting MATLAB smoothing for subject $SLURM_ARRAY_TASK_ID"
matlab -nodisplay -nosplash -r "try; addpath('$MATLAB_CODE_DIR'); SNORE_preprocessing_S3($SLURM_ARRAY_TASK_ID); catch ME; disp(getReport(ME,'extended')); exit(1); end; exit(0);"
echo "Finished MATLAB smoothing for subject $SLURM_ARRAY_TASK_ID"

# === Organise preprocessing files ===
echo "Starting to reorganise preprocessing files for subject $SLURM_ARRAY_TASK_ID"
/scratch/c7201319/SNORE_Analysis/_ShellHelper/organise_preprocessing_files_for_single_participant.sh "$SLURM_ARRAY_TASK_ID"
echo "Finished reorganising preprocessing files for subject $SLURM_ARRAY_TASK_ID"

# === FSL (merge, highpass add mean back) ===
# Construct path to the functional directory
FUNC_DIR="/scratch/c7201319/SNORE_MR_out/$SLURM_ARRAY_TASK_ID/preprocessing/smooth"

# Check if directory exists
if [[ -d "$FUNC_DIR" ]]; then
  echo "Processing participant $SLURM_ARRAY_TASK_ID"
  /scratch/c7201319/SNORE_Analysis/PreProc/nc_FSL_process/merge_highpass_add_mean.sh "$FUNC_DIR"
else
  echo "Directory not found: $FUNC_DIR"
fi

# === Final message ===
echo "Preprocessing done for participant $SLURM_ARRAY_TASK_ID"


