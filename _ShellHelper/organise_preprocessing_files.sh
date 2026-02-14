#!/bin/bash
# Organize preprocessing outputs into folders for ALL participants:
# - preprocessing/skull_stripp          : brain_* from <BASE>/skull_stripp
# - preprocessing/reallign              : r*.nii* from <BASE>/nifti_raw
# - preprocessing/slice_time_correction : a_r*.nii* from <BASE>/nifti_raw
# - preprocessing/smoothing             : s3brain_* from <BASE>/skull_stripp

set -u  # error on unset vars, but don't exit on nonzero commands

ROOT="/scratch/c7201319/SNORE_MR_out"

# Make globs that don't match expand to nothing
shopt -s nullglob

for BASE in "$ROOT"/*; do
  [ -d "$BASE" ] || continue
  ID="$(basename "$BASE")"

  IN_SKULL="$BASE/skull_stripp"
  IN_REALIGN="$BASE/nifti_raw"
  IN_STC="$BASE/nifti_raw"

  OUT_BASE="$BASE/preprocessing"
  OUT_SKULL="$OUT_BASE/skull_stripp"
  OUT_REALIGN="$OUT_BASE/reallign"
  OUT_STC="$OUT_BASE/slice_time_correction"
  OUT_SMOOTH="$OUT_BASE/smooth"

  # Skip participants that don't have the expected inputs at all
  if [ ! -d "$IN_SKULL" ] && [ ! -d "$IN_REALIGN" ]; then
    echo "Participant $ID: skipping (no skull_stripp or nifti_raw)"
    continue
  fi

  mkdir -p "$OUT_SKULL" "$OUT_REALIGN" "$OUT_STC" "$OUT_SMOOTH"

  echo "Participant $ID: organizing..."

  # 1) brain_*  -> preprocessing/skull_stripp
  if [ -d "$IN_SKULL" ]; then
    mv "$IN_SKULL"/brain_* "$OUT_SKULL"/ 2>/dev/null || true
    mv "$IN_SKULL"/s3brain_* "$OUT_SMOOTH"/ 2>/dev/null || true
  fi

  # 2) a_r*.nii* -> preprocessing/slice_time_correction
  if [ -d "$IN_STC" ]; then
    mv "$IN_STC"/a_r*.nii* "$OUT_STC"/ 2>/dev/null || true
  fi

  # 3) r*.nii* -> preprocessing/reallign
  if [ -d "$IN_REALIGN" ]; then
    mv "$IN_REALIGN"/r*.nii* "$OUT_REALIGN"/ 2>/dev/null || true
    # mv "$IN_REALIGN"/mean*.nii* "$OUT_REALIGN"/ 2>/dev/null || true
  fi
done

echo "Done."
