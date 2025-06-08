#!/bin/bash

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

for dir in "$BASE_DIR"/*; do
  participant_num=$(basename "$dir")

  # Skip non-numeric folders
  if ! [[ "$participant_num" =~ ^[0-9]+$ ]]; then
    continue
  fi

  mean_file="${dir}/func_mean/mean_func.nii.gz"
  merged_file="${dir}/func_merged/merged_func.nii.gz"

  if [[ -f "$mean_file" ]]; then
    echo "Deleting $mean_file"
    rm "$mean_file"
  fi

  if [[ -f "$merged_file" ]]; then
    echo "Deleting $merged_file"
    rm "$merged_file"
  fi
done
