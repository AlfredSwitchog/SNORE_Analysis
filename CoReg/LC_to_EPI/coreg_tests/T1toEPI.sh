#!/bin/bash

# -------- Config: set the participant ID --------
PID=1

# -------- Paths (edit only if your layout differs) --------
BASE_OUT="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/${PID}"
T1_IMG="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/T1/T1_n4_HI96BM210524.nii"
EPI_MEAN="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/func_mean_ua/meanua_n4_.nii"
EPI_MASK="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/func_mean_ua/meanEPI_brain_mask_erode.nii.gz"
WORKDIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/regis_LC_mask_to_EPI/T1_to_EPI_test_2"

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