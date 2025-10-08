#!/bin/bash

# load relevant modules
module purge
module load fsl

# === Inputs ===
MEAN_EPI_IN="/scratch/c7201319/SNORE_MR_out/2/func_mean_ua/meanua_n4_.nii"

# === Outputs ===
OUT_MEAN_DIR="/scratch/c7201319/SNORE_MRI_data_dev_out/2/func_mean_ua"

# Participant-agnostic base names
MEAN_BASE="meanEPI"                 # will produce meanEPI_brain_mask.nii.gz

# --- make output dirs ---
mkdir -p "${OUT_MEAN_DIR}" "${OUT_LC_DIR}"

echo "Brain-only mask from mean EPI (BET)…"
# '-m' writes *_mask.nii.gz; '-n' suppresses writing the brain-extracted image (mask only).
bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain" -f 0.5 -g 0 -n -m

echo "Created: ${OUT_MEAN_DIR}/${MEAN_BASE}_brain_mask.nii.gz"