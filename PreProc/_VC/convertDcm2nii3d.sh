#!/bin/bash

# Input folder with individual DICOM files from the same time series
DICOM_FOLDER="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev/2/Night/MR ep2d_bold_samba_2mm_sleep"

# Output folder for the 3D NIfTIs
OUTPUT_FOLDER="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/2/nifti_raw"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"

# Loop over all DICOM files
for DICOM_FILE in "$DICOM_FOLDER"/*.dcm; do
  # Convert each DICOM individually to a separate 3D NIfTI
  dcm2niix -z n -s y -f "%i_%p_%t_%s" -o "$OUTPUT_FOLDER" "$DICOM_FILE"

done

echo "All DICOMs converted to separate 3D NIfTI files."
