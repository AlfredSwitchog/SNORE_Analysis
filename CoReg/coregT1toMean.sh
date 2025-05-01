#!/bin/bash

# Exit on error
set -e

# === USAGE CHECK ===
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <T1_image> <mean_functional_image> <output_folder>"
  echo "Example: $0 T1.nii meanfunc.nii"
  exit 1
fi

# === INPUT FILES ===
T1_IMG="$1"                    # T1-weighted anatomical image (not skull stripped)
FUNC_MEAN_IMG="$2"            # Mean functional image from SPM (not skull stripped)
OUT_FOLDER="$3"

# Create output directory if it doesn't exist
mkdir -p "$OUT_FOLDER"

# === OUTPUT FILES ===
T1_BIAS_CORRECTED="T1_n4.nii"
FUNC_BIAS_CORRECTED="meanfunc_n4.nii"
OUT_PREFIX="T1_to_func_"
WARPED_T1="T1_in_func_space.nii"

# === STEP 1: Bias correction ===
echo "Running N4BiasFieldCorrection on T1 and functional mean..."
N4BiasFieldCorrection -d 3 -i "$T1_IMG" -o "${OUT_FOLDER}/${T1_BIAS_CORRECTED}"
N4BiasFieldCorrection -d 3 -i "$FUNC_MEAN_IMG" -o "${OUT_FOLDER}/${FUNC_BIAS_CORRECTED}"

#=== Set paths for biased corrected images ===
T1_N4="${OUT_FOLDER}/${T1_BIAS_CORRECTED}"
FUNC_N4="${OUT_FOLDER}/${FUNC_BIAS_CORRECTED}"

# === STEP 2: antsRegistration (rigid + affine) ===
echo "Running antsRegistration..."
antsRegistration \
  --dimensionality 3 \
  --float 0 \
  --output ["${OUT_FOLDER}/${OUT_PREFIX}","${OUT_FOLDER}/${OUT_PREFIX}Warped.nii.gz","${OUT_FOLDER}/${OUT_PREFIX}InverseWarped.nii.gz"] \
  --interpolation Linear \
  --use-histogram-matching 1 \
  --initial-moving-transform ["$FUNC_N4","$T1_N4",1] \
  --transform Rigid[0.1] \
  --metric MI["$FUNC_N4","$T1_N4",1,32,Regular,0.25] \
  --convergence [1000x500x250x100,1e-6,10] \
  --shrink-factors 8x4x2x1 \
  --smoothing-sigmas 3x2x1x0vox \
  --transform Affine[0.1] \
  --metric MI["$FUNC_N4","$T1_N4",1,32,Regular,0.25] \
  --convergence [1000x500x250x100,1e-6,10] \
  --shrink-factors 8x4x2x1 \
  --smoothing-sigmas 3x2x1x0vox \
  --transform SyN[0.1,3,0] \
  --metric MI["$FUNC_N4","$T1_N4",1,32,Regular,0.25] \
  --convergence [100x70x50x20,1e-6,10] \
  --shrink-factors 8x4x2x1 \
  --smoothing-sigmas 3x2x1x0vox


# === STEP 3: Apply transform to T1 ===
echo "Applying transform to T1..."
antsApplyTransforms \
  -d 3 \
  -i "$T1_N4" \
  -r "$FUNC_N4" \
  -o "${OUT_FOLDER}/${WARPED_T1}" \
  -t "${OUT_FOLDER}/${OUT_PREFIX}1Warp.nii.gz" \
  -t "${OUT_FOLDER}/${OUT_PREFIX}0GenericAffine.mat"

echo "Done! Output image: $WARPED_T1"
