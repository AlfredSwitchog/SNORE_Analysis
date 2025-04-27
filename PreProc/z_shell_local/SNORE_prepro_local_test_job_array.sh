#!/bin/bash

# Path to your base data directory
BASE_DIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev"
BASE_DIR_OUT="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out"
SCRIPT_DIR="/Users/Richard/Masterabeit_local/Scripts/SNORE_PreProc/nc_FSL_process"


# Define a custom list of subject IDs
SUBJECTS=(1 2)

#make skull_stripp.sh executable
chmod +x $SCRIPT_DIR/skull_stripp.sh


for SUBJ in "${SUBJECTS[@]}"; do

  echo "Processing participant $SUBJ..."

  # Run your MATLAB script, passing the participant number
  matlab -nodisplay -nosplash -r "SNORE_preprocessing($SUBJ); exit;"

  echo "MATLAB preprocessing done for participant $SUBJ"

  # Skull stripping using FSL's bet2
  # Usage: ./skull_stripp.sh /path/to/input /path/to/output
  INPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/nifti_raw"
  OUTPUT_DIR="${BASE_DIR_OUT}/${SUBJ}/preproc_out"

  $SCRIPT_DIR/skull_stripp.sh "$INPUT_DIR" "$OUTPUT_DIR"

  echo "BET2 skull stripping done for participant $SUBJ"
  
  # Temporal filtering using FSL 
  # Usage: ./merge_highpass.sh /path/to/input_folder /path/to/output_folder TR highpass_cutoff_Hz
  INPUT_DIR_FILT=$OUTPUT_DIR
  OUTPUT_DIR_FILT="${BASE_DIR_OUT}/${SUBJ}/filt_preproc_out"

  # fslmath uses sigma instead of hz per volume (docu on hz to sigma conversion in script)
  $SCRIPT_DIR/merge_highpass.sh "$INPUT_DIR_FILT" "$OUTPUT_DIR_FILT" 2.5 0.01

done

echo "Processing complete for all participants!"
