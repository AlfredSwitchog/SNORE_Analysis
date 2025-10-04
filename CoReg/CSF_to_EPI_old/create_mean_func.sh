#!/bin/bash

# === USAGE CHECK ===
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <functional_volumes_folder>"
  echo "Example: $0 /scratch/c7201319/SNORE_MR_out/18/preproc_out"
  exit 1
fi

# === INPUT & PATH SETUP ===
FUNC_DIR="$1"
PARENT_DIR="$(dirname "$FUNC_DIR")"
MERGE_DIR="${PARENT_DIR}/func_merged"
MEAN_DIR="${PARENT_DIR}/func_mean"

MERGED_FILE="${MERGE_DIR}/merged_func.nii.gz"
MEAN_FILE="${MEAN_DIR}/mean_func.nii.gz"

# === CREATE OUTPUT FOLDERS ===
mkdir -p "$MERGE_DIR"
mkdir -p "$MEAN_DIR"

echo "Input directory: $FUNC_DIR"
echo "Merged file will be: $MERGED_FILE"
echo "Mean file will be:  $MEAN_FILE"

# === MERGE FUNCTIONAL VOLUMES ===
echo "Merging functional volumes..."
fslmerge -t "$MERGED_FILE" "$FUNC_DIR"/brain_*.nii.gz

# === CALCULATE MEAN IMAGE ===
echo "Calculating mean image..."
fslmaths "$MERGED_FILE" -Tmean "$MEAN_FILE"

echo "Done. Mean image created at: $MEAN_FILE"
