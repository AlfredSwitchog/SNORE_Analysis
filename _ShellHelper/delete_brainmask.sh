#!/bin/bash

# Base directory
BASE_DIR="/scratch/c7201319/SNORE_MR_out"

# Loop over participant folders (assuming they are numeric)
for SUBJ_DIR in "$BASE_DIR"/*; do
    if [[ -d "$SUBJ_DIR" ]]; then
        MASK_GZ="$SUBJ_DIR/func_mean_ua/meanEPI_brain_mask.nii.gz"
        MASK_NII="$SUBJ_DIR/func_mean_ua/meanEPI_brain_mask.nii"

        # Delete compressed mask if it exists
        if [[ -f "$MASK_GZ" ]]; then
            echo "Deleting: $MASK_GZ"
            #rm "$MASK_GZ"
        fi

        # Delete uncompressed mask if it exists
        if [[ -f "$MASK_NII" ]]; then
            echo "Deleting: $MASK_NII"
            #rm "$MASK_NII"
        fi
    fi
done
