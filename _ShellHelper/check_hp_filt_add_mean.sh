#!/bin/bash

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

echo "Checking for presence of 's3ua_hp_add_mean_func.nii.gz' in each participant's func_merged directory:"
echo

# Loop over all numeric directories in BASE_DIR
for dir in "$BASE_DIR"/*/; do
  # Extract participant number from the folder path
  participant=$(basename "$dir")

  # Skip if not a number
  if ! [[ "$participant" =~ ^[0-9]+$ ]]; then
    continue
  fi

  FUNC_DIR="${BASE_DIR}/${participant}/func_merged"
  TARGET_FILE="${FUNC_DIR}/s3ua_hp_add_mean_func.nii.gz"

  if [[ -f "$TARGET_FILE" ]]; then
    echo "Participant ${participant}: ✅ Found"
  else
    echo "Participant ${participant}: ❌ Missing"
  fi
done
