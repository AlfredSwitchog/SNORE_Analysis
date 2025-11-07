#!/bin/bash

folder="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/nifti_raw"

echo "Cleaning files in: $folder"

# Loop through all files in the folder
for file in "$folder"/*; do
  basename=$(basename "$file")
  
  # Check if the file does NOT start with 'MF'
  if [[ ! $basename == MF* ]]; then
    echo "Deleting: $file"
    rm -f "$file"
  fi
done

echo "Cleanup complete."
