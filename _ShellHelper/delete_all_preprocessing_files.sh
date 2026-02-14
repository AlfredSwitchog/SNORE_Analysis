#!/bin/bash
set -euo pipefail

BASE="/scratch/c7201319/SNORE_MR_out"

# ---- SETTINGS ----
DRYRUN=true   # set to false to actually delete
# ------------------

for subj_dir in "$BASE"/*; do
    # Only process numeric participant folders
    if [[ -d "$subj_dir" && "$(basename "$subj_dir")" =~ ^[0-9]+$ ]]; then
        
        PREP_DIR="$subj_dir/preprocessing"

        if [[ -d "$PREP_DIR" ]]; then
            echo "Processing participant $(basename "$subj_dir")"
            
            if $DRYRUN; then
                echo "  [DRY RUN] Would delete contents of: $PREP_DIR"
                find "$PREP_DIR" -mindepth 1
            else
                echo "  Deleting contents of: $PREP_DIR"
                rm -rf "${PREP_DIR:?}/"*
                rm -rf "${PREP_DIR:?}/".* 2>/dev/null || true
            fi
            
            echo ""
        fi
    fi
done

echo "Done."
