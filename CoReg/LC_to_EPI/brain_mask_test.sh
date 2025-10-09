MEAN_EPI_IN="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/38/func_mean_ua/meanua_n4_.nii"
OUT_MEAN_DIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/38/func_mean_ua"
MEAN_BASE="meanEPI" 

#bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain" -f 0.5 -g 0 -n -m
for f in 0.25 0.30 0.35 0.40 0.45; do
  bet "${MEAN_EPI_IN}" "${OUT_MEAN_DIR}/${MEAN_BASE}_brain_f${f//./}" -f $f -g 0 -n -m
done
