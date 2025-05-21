#!/bin/bash

# Base directory path
BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# Array of folder IDs to loop through
IDS=(7 16 21 29 36)  # <-- replace with your actual IDs

# Loop through each ID
for ID in "${IDS[@]}"; do
  TARGET_DIR="${BASE_DIR}/${ID}/filt_preproc_out"

  echo "Processing folder: ${TARGET_DIR}"

  # Find the filtered NIfTI file in the folder
  NII_FILE=$(find "$TARGET_DIR" -type f -name "filtered*.nii.gz" | head -n 1)

  if [[ -f "$NII_FILE" ]]; then
    echo "Found file: $NII_FILE"
    
    # Output prefix (inside the same folder)
    OUTPUT_PREFIX="${TARGET_DIR}/vol"

    # Run fslsplit
    fslsplit "$NII_FILE" "$OUTPUT_PREFIX" -t
    echo "Finished splitting $NII_FILE"
  else
    echo "No filtered NIfTI file found in $TARGET_DIR"
  fi

done
