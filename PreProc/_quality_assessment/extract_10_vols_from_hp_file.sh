#!/bin/bash
# Extract 10 volumes from the middle of a 4D NIfTI (nii/nii.gz)
# Usage: ./extract_mid10.sh <input_4d_nii.gz> [output_file]

set -euo pipefail

IN="$1"
OUT="${2:-}"

if [[ -z "${IN:-}" ]]; then
  echo "Usage: $0 <input_4d_nii(.gz)> [output_file]"
  exit 1
fi

if [[ ! -f "$IN" ]]; then
  echo "ERROR: Input file not found: $IN"
  exit 1
fi

NVOL="$(fslnvols "$IN")"
if [[ "$NVOL" -lt 10 ]]; then
  echo "ERROR: File has only $NVOL volumes (< 10)."
  exit 1
fi

MID=$((NVOL / 2))
START=$((MID - 5))
if [[ "$START" -lt 0 ]]; then
  START=0
fi

# Default output name: <input_basename>_mid10.nii.gz next to input
if [[ -z "$OUT" ]]; then
  DIR="$(cd "$(dirname "$IN")" && pwd)"
  BASE="$(basename "$IN")"
  BASE="${BASE%.nii.gz}"
  BASE="${BASE%.nii}"
  OUT="${DIR}/${BASE}_mid10.nii.gz"
fi

echo "Input:   $IN"
echo "NVOL:    $NVOL"
echo "Start:   $START"
echo "Length:  10"
echo "Output:  $OUT"

fslroi "$IN" "$OUT" "$START" 10

echo "Done."
