#!/bin/bash
#
# SNORE MRI Preprocessing QC Summary
#
# This script scans all numeric participant folders inside:
#   /scratch/c7201319/SNORE_MR_out
#
# For each participant, it:
#   - Counts NIfTI files (.nii / .nii.gz) in:
#       • nifti_raw (non-recursive)
#       • skull_stripp (non-recursive)
#   - Automatically detects all subfolders inside preprocessing/
#   - Counts NIfTI files recursively inside each preprocessing subfolder
#
# It then prints a formatted summary table with:
#   - One row per participant
#   - File counts for each preprocessing stage
#   - A QC column ("OK" or "X")
#
# QC logic:
#   The QC column is "OK" if all preprocessing subfolders contain
#   the same number of NIfTI files, otherwise "X".
#
# Purpose:
#   Quick consistency check of preprocessing output across subjects
#   to detect missing or incomplete processing steps.

ROOT="/scratch/c7201319/SNORE_MR_out"

# ---------- helpers ----------
count_flat() {
  local dir="$1"
  [ -d "$dir" ] || { echo 0; return; }
  find "$dir" -maxdepth 1 -type f \( -name "*.nii" -o -name "*.nii.gz" \) | wc -l
}

count_recursive() {
  local dir="$1"
  [ -d "$dir" ] || { echo 0; return; }
  find "$dir" -type f \( -name "*.nii" -o -name "*.nii.gz" \) | wc -l
}

# ---------- discover preprocessing subfolders ----------
PREP_SUBS=$(
  find "$ROOT" -maxdepth 3 -type d -name preprocessing 2>/dev/null \
  | while read -r p; do
      find "$p" -mindepth 1 -maxdepth 1 -type d -printf "%f\n"
    done \
  | sort -u
)

# Convert to array
readarray -t PREP_ARR <<< "$PREP_SUBS"

# ---------- header ----------
printf "%10s | %9s | %12s" "Participant" "nifti_raw" "skull_stripp"
for sub in "${PREP_ARR[@]}"; do
  printf " | %20s" "prep/$sub"
done
printf " | %4s\n" "QC"

# ---------- underline ----------
printf -- "%10s-+-%9s-+-%12s" "----------" "---------" "------------"
for _ in "${PREP_ARR[@]}"; do
  printf -- "-+-%20s" "--------------------"
done
printf -- "-+-%4s\n" "----"

# ---------- per participant ----------
for ID in $(ls -1 "$ROOT" | grep -E '^[0-9]+$' | sort -n); do
  BASE="$ROOT/$ID"
  PREP="$BASE/preprocessing"

  printf "%10s | %9d | %12d" \
    "$ID" \
    "$(count_flat "$BASE/nifti_raw")" \
    "$(count_flat "$BASE/skull_stripp")"

  PREP_COUNTS=()

  for sub in "${PREP_ARR[@]}"; do
    c="$(count_recursive "$PREP/$sub")"
    PREP_COUNTS+=("$c")
    printf " | %20d" "$c"
  done

  # QC check: are all preprocessing counts identical?
  QC_OK="OK"
  if [ "${#PREP_COUNTS[@]}" -gt 1 ]; then
    ref="${PREP_COUNTS[0]}"
    for v in "${PREP_COUNTS[@]}"; do
      if [ "$v" -ne "$ref" ]; then
        QC_OK="X"
        break
      fi
    done
  fi

  printf " | %4s\n" "$QC_OK"
done

