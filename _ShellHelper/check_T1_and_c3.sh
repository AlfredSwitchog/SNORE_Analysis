#!/bin/bash

# === BASE DIRECTORY ===
ROOT_DIR="/scratch/c7201319/SNORE_MR_out"

echo "📋 Checking for T1 and c3 files in each participant's T1 folder..."

# === Collect and sort participant folders numerically ===
PARTICIPANT_DIRS=$(find "$ROOT_DIR" -mindepth 1 -maxdepth 1 -type d | sort -n)

# === Loop through each sorted participant folder ===
for PARTICIPANT_PATH in $PARTICIPANT_DIRS; do
  T1_DIR="$PARTICIPANT_PATH/T1"

  # Skip if /T1 subfolder does not exist
  [[ -d "$T1_DIR" ]] || continue

  PARTICIPANT_ID=$(basename "$PARTICIPANT_PATH")

  # Check for c3 and T1 files
  C3_FOUND=$(find "$T1_DIR" -maxdepth 1 -type f -name "c3*.nii" | head -n 1)
  T1_FOUND=$(find "$T1_DIR" -maxdepth 1 -type f -name "T1*.nii" | head -n 1)

  echo "Participant $PARTICIPANT_ID:"
  if [[ -n "$C3_FOUND" ]]; then
    echo "  ✅ c3 file found"
  else
    echo "  ❌ c3 file NOT found"
  fi

  if [[ -n "$T1_FOUND" ]]; then
    echo "  ✅ T1 file found"
  else
    echo "  ❌ T1 file NOT found"
  fi
done

echo "✅ Check complete."
