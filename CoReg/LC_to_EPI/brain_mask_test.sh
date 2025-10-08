MEAN_EPI_IN="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/func_mean_ua/meanua_n4_.nii"
OUT_MEAN_DIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/func_mean_ua"
MEAN_BASE="meanEPI" 

bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain" -f 0.5 -g 0 -n -m