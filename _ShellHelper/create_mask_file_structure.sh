#!/bin/bash
set -euo pipefail

# Function: Collects mask files in one Folder structure, so you only move the masks to Leo5 folder

SRC_BASE="/Users/Richard/Documents/20260322_2_SNORE_QC"
DST_BASE="/Users/Richard/Documents/20260329_SNORE_CSF_masks"

for participant_dir in "$SRC_BASE"/*; do

    # skip if not directory
    [ -d "$participant_dir" ] || continue

    pid=$(basename "$participant_dir")

    echo "Processing participant $pid..."

    SRC_MASK_DIR="$participant_dir/CSF_mask_pruning"
    DST_MASK_DIR="$DST_BASE/$pid/CSF_mask_pruning"

    # create destination folder
    mkdir -p "$DST_MASK_DIR"

    # find pruned masks
    mask_files=$(find "$SRC_MASK_DIR" -maxdepth 1 -type f -name "*pruned*.nii.gz" 2>/dev/null || true)

    if [[ -z "$mask_files" ]]; then
        echo "  ⚠ No pruned mask found"
        continue
    fi

    for file in $mask_files; do
        cp "$file" "$DST_MASK_DIR/"
        echo "  ✔ Copied $(basename "$file")"
    done

    echo "Done with participant $pid"
    echo
done

echo "All masks copied."