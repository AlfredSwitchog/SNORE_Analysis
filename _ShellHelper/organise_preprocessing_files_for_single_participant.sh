#!/bin/bash
# Organize preprocessing outputs for ONE participant:
# - preprocessing/skull_stripp          : brain_* from <BASE>/skull_stripp
# - preprocessing/reallign              : r*.nii* from <BASE>/nifti_raw
# - preprocessing/slice_time_correction : a_r*.nii* from <BASE>/nifti_raw
# - preprocessing/smooth                : s3brain_* from <BASE>/skull_stripp

set -euo pipefail
shopt -s nullglob

ROOT="/scratch/c7201319/SNORE_MR_out"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <participant_id>"
  exit 1
fi

ID="$1"
BASE="$ROOT/$ID"

IN_SKULL="$BASE/skull_stripp"
IN_REALIGN="$BASE/nifti_raw"
IN_STC="$BASE/nifti_raw"

OUT_BASE="$BASE/preprocessing"
OUT_SKULL="$OUT_BASE/skull_stripp"
OUT_REALIGN="$OUT_BASE/reallign"
OUT_STC="$OUT_BASE/slice_time_correction"
OUT_SMOOTH="$OUT_BASE/smooth"

if [[ ! -d "$BASE" ]]; then
  echo "Participant folder not found: $BASE"
  exit 1
fi

if [[ ! -d "$IN_SKULL" && ! -d "$IN_REALIGN" ]]; then
  echo "Participant $ID: no skull_stripp or nifti_raw input found"
  exit 1
fi

mkdir -p "$OUT_SKULL" "$OUT_REALIGN" "$OUT_STC" "$OUT_SMOOTH"

echo "Participant $ID: organizing..."

# 1) brain_* -> preprocessing/skull_stripp
if [[ -d "$IN_SKULL" ]]; then
  files=( "$IN_SKULL"/brain_* )
  [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_SKULL"/

  files=( "$IN_SKULL"/s3brain_* )
  [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_SMOOTH"/
fi

# 2) a_r*.nii* -> preprocessing/slice_time_correction
if [[ -d "$IN_STC" ]]; then
  files=( "$IN_STC"/a_r*.nii* )
  [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_STC"/
fi

# 3) r*.nii* -> preprocessing/reallign
if [[ -d "$IN_REALIGN" ]]; then
  files=( "$IN_REALIGN"/r*.nii* )
  [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_REALIGN"/
fi

echo "Participant $ID: done."
