#!/bin/bash

SRC_BASE="/scratch/c7201319/SNORE_MR_out_2"
DST_BASE="/scratch/c7201319/SNORE_MR_out"

for subjdir in "$SRC_BASE"/*/; do
    participant=$(basename "$subjdir")

    src_nifti="${subjdir}nifti_raw"
    dst_nifti="${DST_BASE}/${participant}/nifti_raw"

    # Skip if source nifti_raw doesn't exist
    if [ ! -d "$src_nifti" ]; then
        echo "No nifti_raw folder for participant ${participant}, skipping."
        continue
    fi

    # Make sure destination exists
    mkdir -p "$dst_nifti"

    echo "Copying MF*.nii for participant ${participant}..."

    # Copy only files starting with MF and ending with .nii
    # (aMF*.nii won't match this pattern)
    find "$src_nifti" -maxdepth 1 -type f -name 'MF*.nii' -print -exec cp -n {} "$dst_nifti"/ \;
done

#find /scratch/c7201319/SNORE_MR_out_2/nifti_raw -maxdepth 1 -type f -name 'MF*.nii' -print -exec cp -n {} "$dst_nifti"/ \;
