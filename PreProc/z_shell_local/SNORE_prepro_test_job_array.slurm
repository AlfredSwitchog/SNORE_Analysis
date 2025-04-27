#!/bin/bash
#SBATCH --job-name=SNORE_preprocessing_array_test               # Job name
#SBATCH --output=job_%A_%a.out                                  # Output file (%A = job ID, %a = array task ID)
#SBATCH --error=job_%A_%a.err                                   # Error file
#SBATCH --time=22:30:00                                         # Max wall time 
#SBATCH --ntasks=1                                              # Number of tasks per job
#SBATCH --cpus-per-task=1                                       # CPUs per task
#SBATCH --mem=210G                                              # Units [K|M|G|T]
#SBATCH --array=2-6                                             # Array range --> specifies the range of participants
#SBATCH --mail-user=richard.alfred.lohr@student.uibk.ac.at      # set email adress for notifications
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


# === FSL skull stripping ===
# Set paths (testing env)
BASE_DIR_OUT="/scratch/c7201319/SNORE_MRI_data_dev_out"
SUBJ="$SLURM_ARRAY_TASK_ID"
SCRIPT_DIR="/scratch/c7201319/SNORE_PreProc"

# Define input/output paths
INPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/nifti_raw"
OUTPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/preproc_out"

# Call the skull stripping script
echo "Running skull stripping for subject $SUBJ..."
bash "$SCRIPT_DIR/skull_stripp.sh" "$INPUT_DIR" "$OUTPUT_DIR"
echo "BET2 skull stripping done for subject $SUBJ on $(hostname)"

# Temporal filtering using FSL 
# Usage: ./merge_highpass.sh /path/to/input_folder /path/to/output_folder TR highpass_cutoff_Hz
INPUT_DIR_FILT=$OUTPUT_DIR
OUTPUT_DIR_FILT="${BASE_DIR_OUT}/${SUBJ}/filt_preproc_out"

# fslmath uses sigma instead of hz per volume (docu on hz to sigma conversion in script)
$SCRIPT_DIR/merge_highpass.sh "$INPUT_DIR_FILT" "$OUTPUT_DIR_FILT" 2.5 0.01

# Array task-specific work
echo "Running task $SLURM_ARRAY_TASK_ID on $(hostname)"

