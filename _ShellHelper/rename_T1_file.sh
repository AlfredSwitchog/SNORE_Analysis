#!/bin/bash

# === BASE DIRECTORY (modify if needed) ===
ROOT_DIR="/scratch/c7201319/SNORE_MR_out"

# === Loop through each participant folder ===
for PART_DIR in "$ROOT_DIR"/*/T1; do
  # Skip if T1 directory doesn't exist
  [[ -d "$PART_DIR" ]] || continue

  echo "Processing: $PART_DIR"

  # === Find T1 file (not starting with c, m, y, or i) ===
  T1_FILE=$(find "$PART_DIR" -maxdepth 1 -type f -name "*.nii" \
    ! -name "c*.nii" \
    ! -name "m*.nii" \
    ! -name "y*.nii" \
    ! -name "i*.nii" \
    -exec basename {} \; | head -n 1)

  if [[ -z "$T1_FILE" ]]; then
    echo "  ⚠️  No valid T1 file found."
    continue
  fi

  NEW_NAME="T1_${T1_FILE}"

  # Only rename if the new name is not already set
  if [[ "$T1_FILE" != "$NEW_NAME" ]]; then
    echo "  ✅ Renaming: $T1_FILE → $NEW_NAME"
    mv "$PART_DIR/$T1_FILE" "$PART_DIR/$NEW_NAME"
  else
    echo "  ℹ️  Already renamed: $T1_FILE"
  fi
done

echo "🎉 All done!"
