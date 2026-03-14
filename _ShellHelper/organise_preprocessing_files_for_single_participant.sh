#!/bin/bash
# Organize preprocessing outputs for ONE participant

set -euo pipefail
shopt -s nullglob

ROOT="/scratch/c7201319/SNORE_MR_out"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <participant_id>"
  exit 1
fi

ID="$1"
BASE="$ROOT/$ID"

IN_SKULL="$BASE/preprocessing/skull_stripp"
IN_NIFTI="$BASE/nifti_raw"

OUT_BASE="$BASE/preprocessing"
OUT_REALIGN="$OUT_BASE/reallign"
OUT_STC="$OUT_BASE/slice_time_correction"
OUT_SMOOTH="$OUT_BASE/smooth"
OUT_MEAN="$BASE/meanEPI"

mkdir -p "$OUT_REALIGN" "$OUT_STC" "$OUT_SMOOTH" "$OUT_MEAN"

echo "Participant $ID: organizing..."

# -----------------------------
# 1) Move smoothed files
# -----------------------------
if [[ -d "$IN_SKULL" ]]; then
    files=( "$IN_SKULL"/s3brain_* )
    [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_SMOOTH"/
fi

# -----------------------------
# 2) Move slice-time corrected
# -----------------------------
if [[ -d "$IN_NIFTI" ]]; then
    files=( "$IN_NIFTI"/a_r*.nii* )
    [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_STC"/
fi

# -----------------------------
# 3) Move realigned files
# -----------------------------
if [[ -d "$IN_NIFTI" ]]; then
    files=( "$IN_NIFTI"/r*.nii* )
    [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_REALIGN"/
fi

# -----------------------------
# 4) Move mean EPI
# -----------------------------
if [[ -d "$IN_NIFTI" ]]; then
    files=( "$IN_NIFTI"/mean*.nii )
    [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_MEAN"/
fi

# -----------------------------
# 5) Move realignment parameters
# -----------------------------
if [[ -d "$IN_NIFTI" ]]; then
    files=( "$IN_NIFTI"/rp* )
    [[ ${#files[@]} -gt 0 ]] && mv "${files[@]}" "$OUT_MEAN"/
fi

echo "Participant $ID: done."
