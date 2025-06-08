#!/bin/bash

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# Print table header
printf "%-5s | %-10s | %-12s\n" "ID" "func_mean" "func_merged"
echo "-----------------------------"

# Sort and loop through numeric participant directories
for dir in $(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort -n); do
  participant_num=$(basename "$dir")

  # Skip non-numeric folders
  if ! [[ "$participant_num" =~ ^[0-9]+$ ]]; then
    continue
  fi

  mean_path="${BASE_DIR}/${participant_num}/func_mean/mean_func.nii.gz"
  merged_path="${BASE_DIR}/${participant_num}/func_merged/merged_func.nii.gz"

  mean_status="❌"
  merged_status="❌"

  [[ -f "$mean_path" ]] && mean_status="✅"
  [[ -f "$merged_path" ]] && merged_status="✅"

  # Print participant row
  printf "%-5s | %-10s | %-12s\n" "$participant_num" "$mean_status" "$merged_status"
done
