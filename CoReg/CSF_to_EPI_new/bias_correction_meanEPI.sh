#!/bin/bash

BASE="/scratch/c7201319/SNORE_MR_out"

for p in "$BASE"/*; do
  nifti_dir="$p/nifti_raw"
  [ -d "$nifti_dir" ] || continue

  FUNC_MEAN_IMG=$(ls "$nifti_dir"/mean*.nii 2>/dev/null)
  [ -f "$FUNC_MEAN_IMG" ] || continue

  FUNC_N4="$(dirname "$FUNC_MEAN_IMG")/N4_$(basename "$FUNC_MEAN_IMG")"

  echo "Processing $(basename "$p")"
  echo "  Input : $FUNC_MEAN_IMG"
  echo "  Output: $FUNC_N4"

  N4BiasFieldCorrection \
    -d 3 \
    -i "$FUNC_MEAN_IMG" \
    -o "$FUNC_N4"
done

