#!/bin/bash

BASE="/scratch/c7201319/SNORE_MRI"
RUN_BASE="MR ep2d_bold_samba_2mm_sleep"

echo "Participants with split sleep runs:"
echo

for ID in $(ls -1 "$BASE" | sort -n); do
    PART_DIR="${BASE}/${ID}/Night"

    # Look for any folder like "MR ep2d_bold_samba_2mm_sleep-*"
    shopt -s nullglob
    splits=( "${PART_DIR}/${RUN_BASE}-"* )

    if [ ${#splits[@]} -gt 0 ]; then
        echo "Participant ${ID} has split runs:"
        for s in "${splits[@]}"; do
            echo "  $(basename "$s")"
        done
        echo
    fi
done
