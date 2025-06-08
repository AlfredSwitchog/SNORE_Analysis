#!/bin/bash

# === USAGE CHECK ===
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <participant_folder>"
  echo "Example: $0 /scratch/c7201319/SNORE_MR_out/1/"
  exit 1
fi

PARTICIPANT_DIR="$1"
T1_DIR="${PARTICIPANT_DIR}/T1"
FUNC_MEAN_DIR="${PARTICIPANT_DIR}/func_mean"

# === Create CSF mask output directory ===
CSF_MASK_DIR="${PARTICIPANT_DIR}/CSF_mask"
mkdir -p "$CSF_MASK_DIR"

# === Create T1_to_func output directory ===
T1_TO_FUNC="${PARTICIPANT_DIR}/T1_to_func"
mkdir -p "$T1_TO_FUNC"

# ==== Check if dirs have been created ===
[[ ! -d "$CSF_MASK_DIR" || ! -d "$T1_TO_FUNC" ]] && { echo "Error: Could not create output directories."; exit 1; }

# === Find input files ===
T1_IMG=$(find "$T1_DIR" -maxdepth 1 -name "T1_*.nii" | head -n 1)
C3_MASK=$(find "$T1_DIR" -maxdepth 1 -name "c3*.nii" | head -n 1)
FUNC_MEAN_IMG="${FUNC_MEAN_DIR}/mean_func.nii.gz"

# === Extract participant code from T1 filename
BASENAME=$(basename "$T1_IMG")
PARTICIPANT_CODE=$(basename "$T1_IMG" | cut -d'_' -f2 | cut -d'-' -f1 | cut -c3-)
echo "Extracted participant code: $PARTICIPANT_CODE" 

# === Output naming ===
T1_BIAS_CORRECTED="T1_n4_${PARTICIPANT_CODE}.nii"
FUNC_BIAS_CORRECTED="meanfunc_n4_${PARTICIPANT_CODE}.nii"
T1_N4="${T1_DIR}/${T1_BIAS_CORRECTED}"
FUNC_N4="${FUNC_MEAN_DIR}/${FUNC_BIAS_CORRECTED}"
OUT_PREFIX="T1_to_func_${PARTICIPANT_CODE}_"
WARPED_C3="${CSF_MASK_DIR}/c3_in_func_space_${PARTICIPANT_CODE}.nii.gz"
BINARIZED_C3="${CSF_MASK_DIR}/c3_in_func_space_bin_${PARTICIPANT_CODE}.nii.gz"

# === Check inputs ===
if [[ ! -f "$T1_IMG" ]]; then
  echo "Error: T1 image not found in $T1_DIR"
  exit 1
fi

if [[ ! -f "$C3_MASK" ]]; then
  echo "Error: c3 CSF mask not found in $T1_DIR"
  exit 1
fi

if [[ ! -f "$FUNC_MEAN_IMG" ]]; then
  echo "Error: functional mean image not found in $FUNC_MEAN_DIR"
  exit 1
fi

# === Bias Correction for EPI and T1 ===
echo "Running N4BiasFieldCorrection on T1 and functional mean..."
N4BiasFieldCorrection -d 3 -i "$T1_IMG" -o "$T1_N4"
N4BiasFieldCorrection -d 3 -i "$FUNC_MEAN_IMG" -o "$FUNC_N4"

# === registration T1 --> EPI (riggid + affine) ===
echo "Running antsRegistration..."
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
echo "Applying transform to CSF mask..."
antsApplyTransforms \
  -d 3 \
  -v 0 \
  -n BSpline[4] \
  -t "${T1_TO_FUNC}/${OUT_PREFIX}0GenericAffine.mat" \
  -i "$C3_MASK" \
  -r "$FUNC_N4" \
  -o "$WARPED_C3" \

echo "Done. Transformed CSF mask saved to: $WARPED_C3"

# === Binarize the transformed CSF mask ===
echo "Binarizing CSF mask with threshold 0.5..."

fslmaths "$WARPED_C3" -thr 0.5 -bin "$BINARIZED_C3"

echo "Done. Binarized CSF mask saved to: $BINARIZED_C3"