#!/bin/bash

T1_IMG="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/T1/MFCR00TS031024-0005-00001-000001.nii"
T1_SLAB="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/T1_slab/t1slab_orig.nii"
WORKDIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/regis_LC_mask_to_EPI/T1Slab_to_T1_test_4"


mkdir -p "${WORKDIR}"

antsRegistrationSyN.sh \
  -d 3 \
  -t r \
  -n 3 \
  -m "${T1_SLAB}" \
  -f "${T1_IMG}" \
  -o "${WORKDIR}/coreg_T1slab_to_T1_"


#Line from Alex: both also work
#alex@Alexs-MacBook-Pro-2024:~$ antsRegistrationSyN.sh -d 3 -t r -n 3 -m /Users/alex/Dropbox/paperwriting/coreg/requests/RL_ticket061/t1slab_orig.nii -f /Users/alex/Dropbox/paperwriting/coreg/requests/RL_ticket061/MFCR00TS031024-0005-00001-000001.nii -o /Users/alex/Dropbox/paperwriting/coreg/requests/RL_ticket061/Lreg_slab2wb_
#antsRegistrationSyN.sh -d 3 -t r -n 3 -m /Users/Richard/Downloads/t1slab_orig.nii -f /Users/Richard/Downloads/MFCR00TS031024-0005-00001-000001.nii -o /Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/regis_LC_mask_to_EPI/T1Slab_to_T1_test_3/Lreg_slab2wb_


