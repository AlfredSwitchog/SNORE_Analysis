#!/bin/bash

#counts and compares how many files are in merged folder and in the individual sleep folders

BASE="/scratch/c7201319/SNORE_MRI"
RUN_BASE="MR ep2d_bold_samba_2mm_sleep"
PARTICIPANTS=(1 3 17 19 22 34 38 47 57 60 64)

echo "Checking split runs and merged counts..."
echo

shopt -s nullglob

for ID in "${PARTICIPANTS[@]}"; do
    PART_DIR="${BASE}/${ID}/Night"

    echo "Participant ${ID}:"

    # Collect all run folders
    RUN_DIRS=()

    # Base run exists?
    if [ -d "${PART_DIR}/${RUN_BASE}" ]; then
        RUN_DIRS+=("${PART_DIR}/${RUN_BASE}")
    fi

    # Check for split folders: sleep-2, sleep-3, ...
    for dir in "${PART_DIR}/${RUN_BASE}-"*; do
        if [ -d "$dir" ]; then
            RUN_DIRS+=("$dir")
        fi
    done

    if [ ${#RUN_DIRS[@]} -eq 0 ]; then
        echo "  No sleep folders found."
        echo
        continue
    fi

    # Count individual runs
    total=0
    for run in "${RUN_DIRS[@]}"; do
        count=$(find "$run" -maxdepth 1 -type f -name "*.dcm" | wc -l)
        basename=$(basename "$run")
        echo "  $basename: $count DICOM files"
        total=$((total + count))
    done

    echo "  → Total across all runs: $total DICOM files"

    # Count merged folder
    MERGED="${PART_DIR}/${RUN_BASE}_merged"
    if [ -d "$MERGED" ]; then
        merged_count=$(find "$MERGED" -maxdepth 1 -type f -name "*.dcm" | wc -l)
        echo "  Merged folder: ${merged_count} DICOM files"
    else
        echo "  Merged folder NOT found"
    fi

    echo
done
