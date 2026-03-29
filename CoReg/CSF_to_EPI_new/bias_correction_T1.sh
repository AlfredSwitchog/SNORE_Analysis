#!/bin/bash

BASE="/scratch/c7201319/SNORE_MR_out"

for p in "$BASE"/*; do
  T1_dir="$p/T1"
  [ -d "$T1_dir" ] || continue

  T1_image=$(ls "$T1_dir"/brain_T1*.nii 2>/dev/null)
  [ -f "$T1_image" ] || continue

  T1_N4="$(dirname "$T1_image")/N4_$(basename "$T1_image")"

  echo "Processing $(basename "$p")"
  echo "  Input : $T1_image"
  echo "  Output: $T1_N4"

  N4BiasFieldCorrection \
    -d 3 \
    -i "$T1_image" \
    -o "$T1_N4"
done