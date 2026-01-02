#!/bin/bash
#SBATCH --job-name=SNORE_preprocessing_array_test               # Job name
#SBATCH --output=job_%A_%a.out                                  # Output file (%A = job ID, %a = array task ID)
#SBATCH --error=job_%A_%a.err                                   # Error file
#SBATCH --time=00:30:00                                         # Max wall time 
#SBATCH --ntasks=1                                              # Number of tasks per job
#SBATCH --cpus-per-task=1                                       # CPUs per task
#SBATCH --mem=5G                                                # Units [K|M|G|T]
#SBATCH --array=2                                               # Array range --> specifies the range of participants
#SBATCH --mail-user=richard.lohr@gmx.de                         # set email adress for notifications
#SBATCH --mail-type=BEGIN,END,FAIL                              # Notify on start, finish, and failure

#unload currently loaded modules
module purge

#load matlab, spm module
module load matlab/R2023b
module load spm
module load fsl

# === MATLAB SPM (realign, slice time, smooth) ===
echo "Starting MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"
matlab -nodisplay -nosplash -r "SNORE_preprocessing($SLURM_ARRAY_TASK_ID); exit;"
echo "Finished MATLAB preprocessing for subject $SLURM_ARRAY_TASK_ID"

# # === FSL skull stripping ===
# # Set paths (testing env)
# BASE_DIR_OUT="/scratch/c7201319/SNORE_MRI_data_dev_out"
# SUBJ="$SLURM_ARRAY_TASK_ID"
# SCRIPT_DIR="/scratch/c7201319/SNORE_Analysis/PreProc"

# # Define input/output paths
# INPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/nifti_raw"
# OUTPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/preproc_out"

# # Call the skull stripping script
# echo "Running skull stripping for subject $SUBJ..."
# bash "$SCRIPT_DIR/nc_FSL_process/skull_stripp.sh" "$INPUT_DIR" "$OUTPUT_DIR"
# echo "BET2 skull stripping done for subject $SUBJ on $(hostname)"

# # === FSL temporal filtering ===
# # Set paths (testing env)
# INPUT_DIR_FILT=$OUTPUT_DIR
# OUTPUT_DIR_FILT="${BASE_DIR_OUT}/${SUBJ}/filt_preproc_out"

# # fslmath uses sigma instead of hz per volume (docu on hz to sigma conversion in script)
# echo "Running temporal filtering for subject $SUBJ..."
# bash "$SCRIPT_DIR/nc_FSL_process/merge_highpass.sh" "$INPUT_DIR_FILT" "$OUTPUT_DIR_FILT" 2.5 0.01
# echo "Temporal filtering done for $SUBJ... on $(hostname)"

# # Array task-specific work
# echo "Running task $SLURM_ARRAY_TASK_ID on $(hostname)"

