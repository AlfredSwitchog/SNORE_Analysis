#!/bin/bash

SRC="/Users/Richard/Documents/20260322_2_SNORE_QC"
DST="/Users/Richard/Documents/20260419_SNORE_CSF_masks"

for participant_dir in "$SRC"/*/; do
    participant=$(basename "$participant_dir")
    mask_src="$participant_dir/CSF_mask_pruning"

    [ -d "$mask_src" ] || continue

    dst_mask="$DST/$participant"
    mkdir -p "$dst_mask"

    # Prefer 3_pruned_c3*, fall back to 1_pruned_c3*
    mask=$(ls "$mask_src"/3_pruned_c3*.nii* 2>/dev/null | head -1)
    [ -z "$mask" ] && mask=$(ls "$mask_src"/1_pruned_c3*.nii* 2>/dev/null | head -1)

    if [ -n "$mask" ]; then
        cp "$mask" "$dst_mask/"
        echo "[$participant] Copied: $(basename "$mask")"
    else
        echo "[$participant] No mask found, skipping."
    fi
done