#!/bin/bash

module purge
module load fsl

BASE_DIR="/scratch/c7201319/SNORE_MR_out"

for pid in $(seq 1 41); do
    IN_MASK="${BASE_DIR}/${pid}/func_mean_ua/meanEPI_brain_mask.nii.gz"
    OUT_MASK="${BASE_DIR}/${pid}/func_mean_ua/meanEPI_brain_mask_erode.nii.gz"

    if [ -f "$IN_MASK" ]; then
        echo "[$(date +'%H:%M:%S')] Eroding mask for participant ${pid}..."
        fslmaths "$IN_MASK" -ero "$OUT_MASK"
        echo "  → Created: $OUT_MASK"
    else
        echo "[$(date +'%H:%M:%S')] Skipping participant ${pid}: mask not found."
    fi
done

echo "All participants processed."
