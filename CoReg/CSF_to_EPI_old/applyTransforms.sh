#!/bin/bash

# Usage: ./applyTransforms.sh /path/to/input_folder /path/to/c3_mask.nii.gz

# Check arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /path/to/input_folder /path/to/c3_mask.nii.gz"
  exit 1
fi

INPUT_FOLDER="$1"
C3_MASK="$2"

# Input files
REF_IMAGE="${INPUT_FOLDER}/meanfunc_n4.nii"
WARP="${INPUT_FOLDER}/T1_to_func_1Warp.nii.gz"
AFFINE="${INPUT_FOLDER}/T1_to_func_0GenericAffine.mat"

# Validate files
for FILE in "$REF_IMAGE" "$WARP" "$AFFINE" "$C3_MASK"; do
  if [ ! -f "$FILE" ]; then
    echo "Error: Required file $FILE not found."
    exit 2
  fi
done

# Get the participant code from the c3 mask filename
BASENAME=$(basename "$C3_MASK")
PREFIX_WITH_ID=$(echo "$BASENAME" | sed -E 's/^(c3[^-]+)-.*$/\1/')
OUTPUT_MASK="${INPUT_FOLDER}/${PREFIX_WITH_ID}_in_func_space.nii.gz"

# Apply the transformation
echo "Applying transforms to $C3_MASK → $OUTPUT_MASK"
antsApplyTransforms -d 3 \
  -i "$C3_MASK" \
  -r "$REF_IMAGE" \
  -t "$WARP" \
  -t "$AFFINE" \
  -n Linear \
  -o "$OUTPUT_MASK" \
  --verbose

echo "Transformation complete. Output saved to: $OUTPUT_MASK"
echo "Transform done. Now binarizing... "

# Binarize the mask
BIN_FILE="${OUTPUT_MASK%.nii*}_bin.nii.gz"
fslmaths "$OUTPUT_MASK" -thr 0.5 -bin "$BIN_FILE"

echo "Binarized mask saved as $BIN_FILE"
