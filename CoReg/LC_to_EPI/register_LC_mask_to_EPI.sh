#!/bin/bash

# -------- Config: set the participant ID --------
PID=1

# -------- Paths (edit only if your layout differs) --------
BASE_OUT="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/${PID}"
BASE_SLAB="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/${PID}"
LC_MASK="/Users/Richard/Masterabeit_local/SNORE_LC-Masks/combined_elsi_masks"

EPI_MEAN="${BASE_OUT}/func_mean_ua/meanua_n4_.nii"                         # fixed image
EPI_MASK="${BASE_OUT}/func_mean_ua/meanEPI_brain_mask_erode.nii.gz"        # fixed mask (use non-eroded if you prefer)
T1_IMG="$(ls "${BASE_OUT}/T1"/T1_n4_*.nii | head -n 1)"                     # moving for T1->EPI
SLAB_ISO="${BASE_SLAB}/T1_slab/t1slab_iso1mm.nii.gz"                       # moving for slab->T1
LCMASK_SLAB="${LC_MASK}/${PID}_combined_LCmask.nii"                 # LC mask in slab/original space (binary)

WORKDIR="${BASE_OUT}/regis_LC_mask_to_EPI"
OUT_LC_IN_EPI="${BASE_OUT}/regis_LC_mask_to_EPI/LCmask_in_EPI.nii.gz"

mkdir -p "${WORKDIR}"

# -------- Load ANTs --------
#module purge
#module load ants

echo "[1/3] T1 -> EPI (rigid), using EPI brain mask as fixed mask..."
antsRegistrationSyN.sh \
  -d 3 \
  -t r \
  -m "${T1_IMG}" \
  -f "${EPI_MEAN}" \
  -x "${EPI_MASK}" \
  -o "${WORKDIR}/coreg_T1_to_meanEPI_"

# Produces: ${WORKDIR}/coreg_T1_to_meanEPI_0GenericAffine.mat

echo "[2/3] t1slab (1mm) -> T1 (rigid)..."
antsRegistrationSyN.sh \
  -d 3 \
  -t r \
  -m "${SLAB_ISO}" \
  -f "${T1_IMG}" \
  -o "${WORKDIR}/coreg_T1slab_to_T1_"

# Produces: ${WORKDIR}/coreg_T1slab_to_T1_0GenericAffine.mat

# Order of applying the transforms: T1_slab -> T1 -> EPI 
echo "[3/3] Apply transforms to LC mask (NearestNeighbor) -> EPI space..."
antsApplyTransforms \
  -d 3 -v 0 \
  -n NearestNeighbor \
  -i "${LCMASK_SLAB}" \
  -r "${EPI_MEAN}" \
  -t "${WORKDIR}/coreg_T1_to_meanEPI_0GenericAffine.mat" \
  -t "${WORKDIR}/coreg_T1slab_to_T1_0GenericAffine.mat" \
  -o "${OUT_LC_IN_EPI}"

echo "Done. Wrote: ${OUT_LC_IN_EPI}"
