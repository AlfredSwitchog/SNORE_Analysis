# Step 1: T1 --> EPI (skull stripped) without brainmask 
antsRegistrationSyN.sh \
  -d 3 \
  -t r \
  -m "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/T1/T1_n4_CR00TS031024.nii" \
  -f "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/preprocessing/reallign/brain_meanMFCR00TS031024-0010-00001-000001_N4.nii" \
  -o "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/LC_to_EPI/T1_to_EPI_test_1/coreg_T1_to_meanEPI_"

  # Step 2: T1 Slab (not resampled) --> T1
  antsRegistrationSyN.sh \
  -d 3 \
  -t r \
  -m "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/T1_slab/t1slab_orig.nii" \
  -f ""/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/T1/T1_n4_CR00TS031024.nii"" \
  -o "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/LC_to_EPI/T1_to_EPI_test_1/coreg_T1slab_to_T1_"

  # Order of applying the transforms: T1_slab -> T1 -> EPI 
echo "[3/3] Apply transforms to LC mask (NearestNeighbor) -> EPI space..."
antsApplyTransforms \
  -d 3 -v 0 \
  -n NearestNeighbor \
  -i "/Users/Richard/Masterabeit_local/SNORE_LC-Masks/combined_elsi_masks/16_combined_LCmask.nii" \
  -r "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/preprocessing/reallign/meanMFCR00TS031024-0010-00001-000001_N4.nii" \
  -t "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/LC_to_EPI/T1_to_EPI_test_1/coreg_T1_to_meanEPI_0GenericAffine.mat" \
  -t "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/LC_to_EPI/T1_to_EPI_test_1/coreg_T1slab_to_T1_0GenericAffine.mat" \
  -o "/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/16/LC_to_EPI/regis_LC_mask_to_EPI/LCmask_in_EPI.nii.gz"

  


