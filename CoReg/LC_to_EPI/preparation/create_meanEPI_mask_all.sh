#!/bin/bash

# --- Load FSL ---
module purge
module load fsl

# --- Base directory containing participant subfolders ---
BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# --- Loop through participant folders ---
for pid in $(seq 1 41); do
    MEAN_EPI_IN="${BASE_DIR}/${pid}/func_mean_ua/meanua_n4_.nii"
    OUT_MEAN_DIR="${BASE_DIR}/${pid}/func_mean_ua"
    MEAN_BASE="meanEPI"

    if [ -f "$MEAN_EPI_IN" ]; then
        echo "[$(date +'%H:%M:%S')] Processing participant ${pid}..."
        mkdir -p "${OUT_MEAN_DIR}"
        bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain" -f 0.5 -g 0 -n -m
        echo "Created: ${OUT_MEAN_DIR}/${MEAN_BASE}_brain_mask.nii.gz"
    else
        echo "[$(date +'%H:%M:%S')] Skipping participant ${pid} (no meanua_n4_.nii found)."
    fi
done

echo "All participants processed."
