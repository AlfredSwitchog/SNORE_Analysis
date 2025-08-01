#!/bin/bash
#SBATCH --job-name=SNORE_prepro_prod_job_array.slurm                    # Job name
#SBATCH --output=job_%A_%a.out                                          # Output file (%A = job ID, %a = array task ID)
#SBATCH --error=job_%A_%a.err                                           # Error file
#SBATCH --time=04:00:00                                                 # Max wall time 
#SBATCH --ntasks=1                                                      # Number of tasks per job
#SBATCH --cpus-per-task=1                                               # CPUs per task
#SBATCH --mem=30G                                                       # Units [K|M|G|T]
#SBATCH --array=30,31,32,33,34,35,37,38,39,40,41,42,43,45,46,48,49,50,51,52,53,54,55,56,57,58,59,61,62,63,65,66,101  # Array range --> specifies the range of participants
#SBATCH --mail-user=richard.lohr@gmx.de                                 # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                                      # Notify on start, finish, and failure

#unload currently loaded modules
module purge

#load matlab, spm module
module load matlab/R2023b
module load spm
module load fsl

# === MATLAB SPM (realign, slice time, smooth) ===
echo "Starting MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"
matlab -nodisplay -nosplash -r "SNORE _preprocessing($SLURM_ARRAY_TASK_ID); exit;"
echo "Finished MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"

# === FSL skull stripping ===
# Set paths (prod)
BASE_DIR_OUT="/scratch/c7201319/SNORE_MR_out"
SUBJ="$SLURM_ARRAY_TASK_ID"
SCRIPT_DIR="/scratch/c7201319/SNORE_Analysis/PreProc"

# Define input/output paths
INPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/nifti_raw"
OUTPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/preproc_out"

# Call the skull stripping script
echo "Running skull stripping for subject $SUBJ..."
bash "$SCRIPT_DIR/nc_FSL_process/skull_stripp.sh" "$INPUT_DIR" "$OUTPUT_DIR"
echo "BET2 skull stripping done for subject $SUBJ on $(hostname)"

# === FSL skull stripping ===
# Temporal filtering using FSL 
#INPUT_DIR_FILT=$OUTPUT_DIR
#OUTPUT_DIR_FILT="${BASE_DIR_OUT}/${SUBJ}/filt_preproc_out"

# fslmath uses sigma instead of hz per volume (docu on hz to sigma conversion in script)
#echo "Running temporal filtering for subject $SUBJ..."
#bash "$SCRIPT_DIR/nc_FSL_process/merge_highpass.sh" "$INPUT_DIR_FILT" "$OUTPUT_DIR_FILT" 2.5 0.01
#echo "Temporal filtering done for $SUBJ... on $(hostname)"

# Array task-specific work
#echo "Running task $SLURM_ARRAY_TASK_ID on $(hostname)"
