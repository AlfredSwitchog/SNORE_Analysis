#!/bin/bash
set -euo pipefail

#This folder selects brain_meanEPI, c3_mask, T1 in functional space and writes into the SNORE_QC folder 
#This way we can automate the file selection for all the files that we need during pruning

BASE="/scratch/c7201319/SNORE_MR_out"
QC_BASE="/scratch/c7201319/SNORE_QC"

# === DEFINE PARTICIPANTS HERE (blank-separated list) ===
PARTICIPANTS="9 10 6 22 14 33 43 32 8 46 64 53 21 66 52 18 23 49 51 20 63 45 57 47 42 41 5 31 35 55"

for pid in $PARTICIPANTS; do
    echo "Processing participant $pid..."

    PARTICIPANT_DIR="${BASE}/${pid}"
    OUT_DIR="${QC_BASE}/${pid}/CSF_mask_pruning"

    MEAN_DIR="${PARTICIPANT_DIR}/meanEPI"
    CSF_DIR="${PARTICIPANT_DIR}/CSF_mask"
    T1FUNC_DIR="${PARTICIPANT_DIR}/T1_to_func"

    mkdir -p "$OUT_DIR"

    # === Find files ===
    mean_file=$(find "$MEAN_DIR" -maxdepth 1 -type f -name "brain_N4_mean*.nii.gz" | head -n 1 || true)
    csf_file=$(find "$CSF_DIR" -maxdepth 1 -type f -name "c3_in_func_space_bin*.nii.gz" | head -n 1 || true)
    warped_file=$(find "$T1FUNC_DIR" -maxdepth 1 -type f -name "T1_to_func_*Warped.nii.gz" | head -n 1 || true)

    # === Copy files ===
    if [[ -n "$mean_file" && -f "$mean_file" ]]; then
        cp "$mean_file" "$OUT_DIR/"
        echo "  ✔ Copied meanEPI"
    else
        echo "  ⚠ meanEPI file not found"
    fi

    if [[ -n "$csf_file" && -f "$csf_file" ]]; then
        cp "$csf_file" "$OUT_DIR/"
        echo "  ✔ Copied CSF mask"
    else
        echo "  ⚠ CSF mask file not found"
    fi

    if [[ -n "$warped_file" && -f "$warped_file" ]]; then
        cp "$warped_file" "$OUT_DIR/"
        echo "  ✔ Copied warped T1"
    else
        echo "  ⚠ T1 warped file not found"
    fi

    echo "Done with participant $pid"
    echo
done

echo "All participants processed."