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

# === Find input files ===
T1_IMG=$(find "$T1_DIR" -maxdepth 1 -name "T1_*.nii" | head -n 1)
C3_MASK=$(find "$T1_DIR" -maxdepth 1 -name "c3*.nii" | head -n 1)
FUNC_MEAN_IMG="${FUNC_MEAN_DIR}/mean_func.nii.gz"

# === Output naming ===
T1_BIAS_CORRECTED="T1_n4.nii"
FUNC_BIAS_CORRECTED="meanfunc_n4.nii"
T1_N4="${T1_DIR}/${T1_BIAS_CORRECTED}"
FUNC_N4="${T1_DIR}/${FUNC_BIAS_CORRECTED}"
OUT_PREFIX="T1_to_func_"
WARPED_C3="${T1_DIR}/c3_in_func_space.nii.gz"

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

echo "Running N4BiasFieldCorrection on T1 and functional mean..."
N4BiasFieldCorrection -d 3 -i "$T1_IMG" -o "$T1_N4"
N4BiasFieldCorrection -d 3 -i "$FUNC_MEAN_IMG" -o "$FUNC_N4"

echo "Running antsRegistration..."
antsRegistration \
  --dimensionality 3 \
  --float 0 \
  --output ["${T1_DIR}/${OUT_PREFIX}","${T1_DIR}/${OUT_PREFIX}Warped.nii.gz","${T1_DIR}/${OUT_PREFIX}InverseWarped.nii.gz"] \
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
   --verbose 1

# === Apply transform to CSF mask ===
echo "Applying transform to CSF mask..."
antsApplyTransforms \
  -d 3 \
  -i "$C3_MASK" \
  -r "$FUNC_N4" \
  -o "$WARPED_C3" \
  -t "${T1_DIR}/${OUT_PREFIX}1Warp.nii.gz" \
  -t "${T1_DIR}/${OUT_PREFIX}0GenericAffine.mat" \
  -n Linear

echo "Done. Transformed CSF mask saved to: $WARPED_C3"
