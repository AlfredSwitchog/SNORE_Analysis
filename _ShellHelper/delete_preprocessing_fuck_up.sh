#!/bin/bash
set -euo pipefail

ROOT="/scratch/c7201319/SNORE_MR_out"

DRYRUN=false   # set to false to actually delete

for subj in "$ROOT"/*; do
    ID="$(basename "$subj")"

    # process numeric participant folders only
    if [[ -d "$subj" && "$ID" =~ ^[0-9]+$ ]]; then
        RAW="$subj/nifti_raw"

        if [[ -d "$RAW" ]]; then
            echo "Participant $ID"

            FILES=$(find "$RAW" -maxdepth 1 -type f \
                \( -name "a_a_r*nii" -o -name "a_r*nii" -o -name "r*nii" -o -name "rp*txt" -o -name "mean*nii" \))

            if [[ -n "$FILES" ]]; then
                if $DRYRUN; then
                    echo "  [DRY RUN] Would delete:"
                    echo "$FILES"
                else
                    echo "$FILES" | xargs rm -f
                    echo "  Deleted."
                fi
            else
                echo "  No matching files."
            fi
            echo ""
        fi
    fi
done

echo "Done."
