#!/bin/bash
set -euo pipefail

BASE="/scratch/c7201319/SNORE_MR_out"

DRYRUN=false   #set to false to actually delete

for subj_dir in "$BASE"/*; do
    # Only numeric participant folders
    if [[ -d "$subj_dir" && "$(basename "$subj_dir")" =~ ^[0-9]+$ ]]; then
        
        TARGET="$subj_dir/meanEPI"
        [[ -d "$TARGET" ]] || continue

        echo "Participant $(basename "$subj_dir")"

        shopt -s nullglob
        files=("$TARGET"/N4* "$TARGET"/brain_N4*)
        shopt -u nullglob

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "  [INFO] No matching files"
            continue
        fi

        for f in "${files[@]}"; do
            if $DRYRUN; then
                echo "  [DRYRUN] Would delete: $f"
            else
                echo "  [DELETE] $f"
                rm -f "$f"
            fi
        done

        echo
    fi
done

echo "[DONE]"