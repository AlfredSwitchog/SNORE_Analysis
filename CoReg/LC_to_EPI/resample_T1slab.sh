#!/bin/bash

# load relevant modules
module purge
module load freesurfer


# Output directory and base names
OUT_T1SLAB_DIR="/scratch/c7201319/SNORE_MRI_data_dev_out/2/T1_slab"
IN_T1SLAB_DIR="/scratch/c7201319/SNORE_MR_out/2/T1_slab"
T1SLAB_ORIG_BASE="t1slab_orig"        
T1SLAB_ISO1_BASE="t1slab_iso1mm"      # after mri_convert (1 mm iso)


# Reference image
T1MEAN_REF="/scratch/c7201319/SNORE_MR_out/2/T1/T1_MFSI96LL110624-0005-00001-000001.nii" 

# --- sanity: required tools ---
command -v mri_convert >/dev/null 2>&1 || { echo "ERROR: FreeSurfer mri_convert not found in PATH"; exit 1; }

T1SLAB_ORIG_NII="$IN_T1SLAB_DIR/${T1SLAB_ORIG_BASE}.nii"
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

