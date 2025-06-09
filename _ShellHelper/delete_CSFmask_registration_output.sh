#!/bin/bash

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# Loop over all directories with numeric names (participants)
for PARTICIPANT_DIR in "$BASE_DIR"/*/; do
  # Ensure it's a number (participant folder)
  PARTICIPANT_ID=$(basename "$PARTICIPANT_DIR")
  if [[ "$PARTICIPANT_ID" =~ ^[0-9]+$ ]]; then
    echo "Processing participant $PARTICIPANT_ID..."

    for SUBFOLDER in "CSF_mask" "T1_to_func"; do
      TARGET_DIR="${PARTICIPANT_DIR}${SUBFOLDER}"
      if [[ -d "$TARGET_DIR" ]]; then
        echo "  Deleting files in: $TARGET_DIR"
        rm -f "${TARGET_DIR}"/*
      else
        echo "  Skipping: $TARGET_DIR does not exist"
      fi
    done
  fi
done
