#!/bin/bash

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

for PARTICIPANT_DIR in "$BASE_DIR"/*/; do
  PARTICIPANT_ID=$(basename "$PARTICIPANT_DIR")

  # Skip non-numeric directories
  if [[ ! "$PARTICIPANT_ID" =~ ^[0-9]+$ ]]; then
    continue
  fi

  RAW_DIR="${PARTICIPANT_DIR}nifti_raw"
  DEST_DIR="${PARTICIPANT_DIR}func_mean_ua"

  # Find file with "mean" in name
  MEAN_FILE=$(find "$RAW_DIR" -maxdepth 1 -type f -name "*mean*.nii*" | head -n 1)

  if [[ -f "$MEAN_FILE" ]]; then
    mkdir -p "$DEST_DIR"
    cp "$MEAN_FILE" "$DEST_DIR"
    echo "✅ Copied mean file for participant $PARTICIPANT_ID to func_mean_ua/"
  else
    echo "⚠️  No mean file found for participant $PARTICIPANT_ID"
  fi
done
