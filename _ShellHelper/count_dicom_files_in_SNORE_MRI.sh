#!/bin/bash

# Function: count DICOM files and compare with NIfTI conversion folder

DICOM_BASE="/scratch/c7201319/SNORE_MRI"
NIFTI_BASE="/scratch/c7201319/SNORE_MR_out"

RUN_BASE="MR ep2d_bold_samba_2mm_sleep"
RUN_MERGED="${RUN_BASE}_merged"

shopt -s nullglob

############################################
# 1. Determine which participants to use
############################################

if [ "$1" == "subset" ]; then
    shift
    PARTICIPANTS=("$@")
    echo "Running on SUBSET of participants: ${PARTICIPANTS[*]}"
    echo
else
    echo "Running on ALL participants found in $DICOM_BASE"
    PARTICIPANTS=($(ls -1 "$DICOM_BASE" | sort -n))
    echo "Found participants: ${PARTICIPANTS[*]}"
    echo
fi

############################################
# 2. Loop over selected participants
############################################

for ID in "${PARTICIPANTS[@]}"; do
    PART_DIR="${DICOM_BASE}/${ID}/Night"

    # Skip if Night folder doesn't exist
    if [ ! -d "$PART_DIR" ]; then
        echo "Participant ${ID}: Night folder NOT found"
        echo
        continue
    fi

    MERGED_DIR="${PART_DIR}/${RUN_MERGED}"
    BASE_DIR="${PART_DIR}/${RUN_BASE}"

    # Choose which DICOM folder to analyze
    if [ -d "$MERGED_DIR" ]; then
        SRC_DIR="$MERGED_DIR"
        SRC_LABEL="merged"
    elif [ -d "$BASE_DIR" ]; then
        SRC_DIR="$BASE_DIR"
        SRC_LABEL="base"
    else
        echo "Participant ${ID}: No DICOM folder found (${RUN_MERGED} or ${RUN_BASE}), skipping."
        echo
        continue
    fi

    # Count DICOM files
    dicom_count=$(find "$SRC_DIR" -maxdepth 1 -type f -name '*.dcm' | wc -l)

    # Count NIfTI files
    NIFTI_DIR="${NIFTI_BASE}/${ID}/nifti_raw"
    if [ -d "$NIFTI_DIR" ]; then
        nifti_count=$(find "$NIFTI_DIR" -maxdepth 1 -type f | wc -l)
    else
        nifti_count="N/A (nifti_raw not found)"
    fi

    echo "Participant ${ID}:"
    echo "  DICOM folder (${SRC_LABEL}): $SRC_DIR"
    echo "    -> DICOM files (*.dcm): $dicom_count"
    echo "  NIfTI folder: $NIFTI_DIR"
    echo "    -> NIfTI files: $nifti_count"
    echo
done
