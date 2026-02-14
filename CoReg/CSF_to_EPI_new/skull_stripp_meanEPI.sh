#!/bin/bash

BASE="/scratch/c7201319/SNORE_MR_out"

for p in "$BASE"/*; do
  nifti_dir="$p/nifti_raw"
  [ -d "$nifti_dir" ] || continue

  FUNC_N4=$(ls "$nifti_dir"/N4*.nii 2>/dev/null)
  [ -f "$FUNC_N4" ] || continue

  OUT_BASE="$nifti_dir/brain_$(basename "${FUNC_N4%.nii}")"

  echo "Participant $(basename "$p")"
  echo "  Input : $FUNC_N4"
  echo "  Output: ${OUT_BASE}.nii.gz (and mask)"

  bet2 "$FUNC_N4" "$OUT_BASE" -f 0.1
done
