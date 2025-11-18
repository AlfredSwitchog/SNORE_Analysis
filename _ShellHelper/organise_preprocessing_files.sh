#!/bin/bash
# Organize preprocessing outputs into folders:
# - preprocessing/skull_stripp          : files starting with brain_* from BASE/skull_stripp
# - preprocessing/reallign              : files r*.nii* from BASE/nifti_raw_2
# - preprocessing/slice_time_correction : files a_brain_*.nii* from BASE/skull_stripp
# - preprocessing/smoothing             : files s3a_* from BASE/skull_stripp

set -e

# === CONFIG ===
BASE="/scratch/c7201319/SNORE_MR_out/16"
IN_SKULL="${BASE}/skull_stripp"
IN_REALIGN="${BASE}/nifti_raw_2"
OUT_BASE="${BASE}/preprocessing"

OUT_SKULL="${OUT_BASE}/skull_stripp"
OUT_REALIGN="${OUT_BASE}/reallign"
OUT_STC="${OUT_BASE}/slice_time_correction"
OUT_SMOOTH="${OUT_BASE}/smooth"

# Create output directories
mkdir -p "$OUT_SKULL" "$OUT_REALIGN" "$OUT_STC" "$OUT_SMOOTH"

# Make globs that don't match expand to nothing (avoids errors if no files)
shopt -s nullglob

echo "Organizing files from:"
echo "  skull_stripp -> $OUT_SKULL, $OUT_STC, $OUT_SMOOTH"
echo "  nifti_raw_2  -> $OUT_REALIGN"
echo

# 1) brain_*  -> preprocessing/skull_stripp
echo "Moving brain_* to $OUT_SKULL"
mv "$IN_SKULL"/brain_* "$OUT_SKULL"/ 2>/dev/null || true

# 2) a_brain_*.nii* -> preprocessing/slice_time_correction
echo "Moving a_brain_*.nii* to $OUT_STC"
mv "$IN_SKULL"/a_brain_*.nii* "$OUT_STC"/ 2>/dev/null || true

# 3) s3a_* -> preprocessing/smooth
echo "Moving s3a_* to $OUT_SMOOTH"
mv "$IN_SKULL"/s3a_* "$OUT_SMOOTH"/ 2>/dev/null || true

# 4) r*.nii* from nifti_raw_2 -> preprocessing/reallign
echo "Moving r*.nii* from nifti_raw_2 to $OUT_REALIGN"
mv "$IN_REALIGN"/r*.nii* "$OUT_REALIGN"/ 2>/dev/null || true
mv "$IN_REALIGN"/mean*.nii* "$OUT_REALIGN"/ 2>/dev/null || true #mean EPI also moved


echo
echo "Done. Output structure:"
echo "  $OUT_SKULL"
echo "  $OUT_REALIGN"
echo "  $OUT_STC"
echo "  $OUT_SMOOTH"
