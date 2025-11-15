#!/bin/bash
# Merge all NIfTIs in a folder, high-pass filter with mean added back, and write to ../preprocessing/highpass
# Usage: ./merge_highpass_add_mean.sh <input_folder>

set -e

IN_DIR="$1"
if [[ -z "$IN_DIR" ]]; then
  echo "Usage: $0 <input_folder>"
  exit 1
fi

# Determine the preprocessing base (one level up)
PREPROC_DIR="$(dirname "$IN_DIR")"

# Output folder inside preprocessing
OUT_DIR="${PREPROC_DIR}/highpass"
mkdir -p "$OUT_DIR"

# Grab the first functional file to infer the prefix (everything up to the first '-')
FIRST_FILE="$(find "$IN_DIR" -maxdepth 1 -type f -name 's3a_brain_r*.nii*' | sort | head -n 1)"
if [[ -z "$FIRST_FILE" ]]; then
  echo "No files matching s3a_brain_r*.nii* found in: $IN_DIR"
  exit 1
fi

BASE="$(basename "$FIRST_FILE")"
PREFIX="${BASE%%-*}"  # e.g., s3a_brain_rMFCR00TS031024

MERGED="${OUT_DIR}/${PREFIX}_merged.nii.gz"
MEAN="${OUT_DIR}/${PREFIX}_mean.nii.gz"
HP_OUT="${OUT_DIR}/hp_${PREFIX}.nii.gz"

echo "Input folder:   $IN_DIR"
echo "Using prefix:   $PREFIX"
echo "Output folder:  $OUT_DIR"
echo "Merged file:    $MERGED"
echo "Mean file:      $MEAN"
echo "Highpass file:  $HP_OUT"

# 1) Merge all volumes
echo "Merging volumes..."
fslmerge -t "$MERGED" "$IN_DIR"/s3a_brain_r*.nii*

# 2) Compute mean
echo "Computing mean..."
fslmaths "$MERGED" -Tmean "$MEAN"

# 3) High-pass filter and add mean back
#    Note: -bptf takes sigma (in volumes). Example value 17 here.
echo "High-pass filtering and adding mean back..."
fslmaths "$MERGED" -bptf 17 -1 -add "$MEAN" "$HP_OUT"

# 4) Delete mean
echo "Removing temporary mean file..."
rm -f "$MEAN"

echo "Done."
echo "Kept:   $MERGED"
echo "Output: $HP_OUT"
