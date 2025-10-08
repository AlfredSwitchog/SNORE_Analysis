#!/bin/bash

# load relevant modules
module purge
module load fsl
module load freesurfer

# === Inputs ===
MEAN_EPI_IN="/scratch/c7201319/SNORE_MRI_data_dev_out/1/nifti_raw/meanuaMFRO01GG010724-0011-00001-000001.nii"

# === Outputs ===
OUT_MEAN_DIR="/scratch/c7201319/SNORE_MRI_data_dev_out/1/func_mean_ua"
OUT_LC_DIR="/scratch/c7201319/SNORE_MRI_data_dev_out/1/LC-Mask"

# Participant-agnostic base names
MEAN_BASE="meanEPI"                 # will produce meanEPI_brain_mask.nii.gz

# --- sanity: check FSL commands exist ---
command -v bet >/dev/null 2>&1 || { echo "ERROR: FSL bet not found in PATH"; exit 1; }
command -v flirt >/dev/null 2>&1 || { echo "ERROR: FSL flirt not found in PATH"; exit 1; }
command -v fslinfo >/dev/null 2>&1 || { echo "ERROR: FSL fslinfo not found in PATH"; exit 1; }

# --- make output dirs ---
mkdir -p "${OUT_MEAN_DIR}" "${OUT_LC_DIR}"

echo "Step 1/2: Brain-only mask from mean EPI (BET)…"
# '-m' writes *_mask.nii.gz; '-n' suppresses writing the brain-extracted image (mask only).
# Remove '-n' if you ALSO want the skull-stripped mean EPI image saved.
bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain" -f 0.5 -g 0 -n -m

echo "Created: ${OUT_MEAN_DIR}/${MEAN_BASE}_brain_mask.nii.gz"
fslinfo "${OUT_MEAN_DIR}/${MEAN_BASE}_brain_mask.nii.gz" | grep -E 'dim|pixdim' || true

# -------- Step 2------------
echo "Step 2/2: Resample the neuromelaninsensitive scan..."

# Output directory and base names
OUT_T1SLAB_DIR="/scratch/c7201319/SNORE_MRI_data_dev_out/1/T1_slab"
T1SLAB_ORIG_BASE="t1slab_orig"        # after dcm2niix
T1SLAB_ISO1_BASE="t1slab_iso1mm"      # after mri_convert (1 mm iso)

# Reference image
T1MEAN_REF="/scratch/c7201319/SNORE_MR_out/1/T1/mMFHI96BM210524-0005-00001-000001.nii"

# --- sanity: required tools ---
command -v mri_convert >/dev/null 2>&1 || { echo "ERROR: FreeSurfer mri_convert not found in PATH"; exit 1; }

T1SLAB_ORIG_NII="$OUT_T1SLAB_DIR/${T1SLAB_ORIG_BASE}.nii"
[ -f "$T1SLAB_ORIG_NII" ] || { echo "ERROR: Expected NIfTI not found: $T1SLAB_ORIG_NII"; exit 1; }

T1SLAB_ISO1_NII="$OUT_T1SLAB_DIR/${T1SLAB_ISO1_BASE}.nii.gz"

# Match the reference T1 grid & geometry (recommended if available)
mri_convert -cs 1 -odt float -rl "$T1MEAN_REF" -rt cubic "$T1SLAB_ORIG_NII" "$T1SLAB_ISO1_NII"

# Quick info (optional)
if command -v fslinfo >/dev/null 2>&1; then
  echo "Resampled file info:"
  fslinfo "$T1SLAB_ISO1_NII" | grep -E 'dim|pixdim' || true
fi

echo "Created:"
echo "  - Original NIfTI:   $T1SLAB_ORIG_NII"
echo "  - Resampled (1mm):  $T1SLAB_ISO1_NII"

echo "Done."

