#!/bin/bash

# === USAGE CHECK ===
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <participant_folder>"
  echo "Example: $0 /scratch/c7201319/SNORE_MR_out/16"
  exit 1
fi

PARTICIPANT_DIR="$1"

# === Directories ===
T1_DIR="${PARTICIPANT_DIR}/T1"
FUNC_MEAN_DIR="${PARTICIPANT_DIR}/meanEPI"

# === Create CSF mask output directory ===
CSF_MASK_DIR="${PARTICIPANT_DIR}/CSF_mask"
mkdir -p "$CSF_MASK_DIR"

# === Create T1_to_func output directory ===
T1_TO_FUNC="${PARTICIPANT_DIR}/T1_to_func"
mkdir -p "$T1_TO_FUNC"

# === Find input files ===
# T1 bias-corrected (e.g. T1_n4_CR00TS031024.nii)
T1_N4=$(find "$T1_DIR" -maxdepth 1 -name "N4_brain_T1_*.nii" | head -n 1)

# c3 CSF mask (e.g. c3MFCR00TS031024-0005-00001-000001.nii)
C3_MASK=$(find "$T1_DIR" -maxdepth 1 -name "c3*.nii" | head -n 1)

# Precomputed N4 bias-corrected mean EPI
# (e.g. brain_N4_meanMFHI96BM210524-0029-00001-000001.nii.gz)
FUNC_N4=$(find "$FUNC_MEAN_DIR" -maxdepth 1 -type f -name "brain_N4_mean*.nii.gz" | head -n 1)

# === Check inputs ===
if [[ -z "$T1_N4" || ! -f "$T1_N4" ]]; then
  echo "Error: T1_n4 image not found in $T1_DIR"
  exit 1
fi

if [[ -z "$C3_MASK" || ! -f "$C3_MASK" ]]; then
  echo "Error: c3 CSF mask not found in $T1_DIR"
  exit 1
fi

if [[ -z "$FUNC_N4" || ! -f "$FUNC_N4" ]]; then
  echo "Error: N4 bias-corrected mean EPI (mean*_N4.nii) not found in $FUNC_MEAN_DIR"
  exit 1
fi

echo "Using:"
echo "  T1_N4  : $T1_N4"
echo "  C3_MASK: $C3_MASK"
echo "  FUNC_N4: $FUNC_N4"

# === Extract prefix from T1 filename ===
# Example:
# N4_brain_T1_MFHI96BM210524-0005-00001-000001.nii
# -> N4_brain_T1_MFHI96BM210524
BASENAME=$(basename "$T1_N4")
T1_PREFIX=$(echo "$BASENAME" | sed -E 's/^((N4_brain_T1_[^-]+))-[0-9]+-[0-9]+-[0-9]+\.nii$/\1/')

echo "Extracted T1 prefix: $T1_PREFIX"

# === Output naming ===
OUT_PREFIX="T1_to_func_${T1_PREFIX}_"
WARPED_C3="${CSF_MASK_DIR}/c3_in_func_space_${T1_PREFIX}.nii.gz"
BINARIZED_C3="${CSF_MASK_DIR}/c3_in_func_space_bin_${T1_PREFIX}.nii.gz"


# === registration T1 --> EPI (rigid + affine) ===
echo "Running antsRegistration (T1_n4 -> meanEPI_N4)..."
antsRegistration \
  --dimensionality 3 \
  --float 0 \
  --output ["${T1_TO_FUNC}/${OUT_PREFIX}","${T1_TO_FUNC}/${OUT_PREFIX}Warped.nii.gz","${T1_TO_FUNC}/${OUT_PREFIX}InverseWarped.nii.gz"] \
  --interpolation Linear \
  --winsorize-image-intensities [0.005,0.995] \
  --use-histogram-matching 0 \
  --initial-moving-transform ["$FUNC_N4","$T1_N4",1] \
  --transform Rigid[0.1] \
  --metric MI["$FUNC_N4","$T1_N4",1,32,Regular,0.25] \
  --convergence [1000x500x250x100,1e-6,10] \
  --shrink-factors 4x2x1x1 \
  --smoothing-sigmas 2x1x0.5x0vox \
  --transform Affine[0.1] \
  --metric MI["$FUNC_N4","$T1_N4",1,32,Regular,0.25] \
  --convergence [1000x500x250x100,1e-6,10] \
  --shrink-factors 4x2x1x1 \
  --smoothing-sigmas 2x1x0.5x0vox \
  --verbose 0

# === Apply transform to CSF mask ===
echo "Applying transform to CSF mask (c3 -> EPI space)..."
antsApplyTransforms \
  -d 3 \
  -v 0 \
  -n BSpline[4] \
  -t "${T1_TO_FUNC}/${OUT_PREFIX}0GenericAffine.mat" \
  -i "$C3_MASK" \
  -r "$FUNC_N4" \
  -o "$WARPED_C3"

echo "Done. Transformed CSF mask saved to: $WARPED_C3"

# === Binarize the transformed CSF mask ===
echo "Binarizing CSF mask with threshold 0.5..."
fslmaths "$WARPED_C3" -thr 0.5 -bin "$BINARIZED_C3"
echo "Done. Binarized CSF mask saved to: $BINARIZED_C3"
