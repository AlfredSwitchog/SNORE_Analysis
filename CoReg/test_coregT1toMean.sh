

# ===== Change this base dir for new test =====
BASE_DIR="/Users/Richard/Masterabeit_local/SNORE_RegistrationTest/6_test1"

# ==== Prefixes and Codes =====
OUT_PREFIX="T1_to_func_RO01GG010724_"
PARTICIPANT_CODE="RO01GG010724"

# ==== Set Paths ====
T1_N4="${BASE_DIR}/T1/T1_n4_RO01GG010724.nii"
C3_MASK="${BASE_DIR}/T1/c3MFRO01GG010724-0005-00001-000001.nii"
FUNC_N4="${BASE_DIR}/func_mean_ua/n4_meanuaMFRO01GG010724.nii"
T1_TO_FUNC="${BASE_DIR}/T1_to_func"
CSF_MASK_DIR="${BASE_DIR}/CSF_mask"
WARPED_C3="${CSF_MASK_DIR}/c3_in_func_space_${PARTICIPANT_CODE}.nii.gz"
BINARIZED_C3="${CSF_MASK_DIR}/c3_in_func_space_bin_${PARTICIPANT_CODE}.nii.gz"

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