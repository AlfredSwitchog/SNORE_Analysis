#!/bin/bash

#Usage example: ./highpass_add_mean.sh /Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/7/func_merged

# Check if folder path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <folderpath>"
  exit 1
fi

# Folder path input
folderpath=$1

# Define the paths for the files
input_file="$folderpath/merged_func.nii"
mean_file="$folderpath/merged_mean_func.nii.gz"
output_file="$folderpath/s3ua_hp_add_mean_func.nii.gz"

#check if input file exists
if [[ ! -f "$input_file" ]]; then
  echo "Input file not found: $input_file"
  exit 1
fi

# Step 1: Calculate the mean
echo "Calculating the mean..."
fslmaths $input_file -Tmean $mean_file

# Step 2: Apply the high-pass filter and add the mean back
echo "Applying high-pass filter and adding the mean..."
fslmaths $input_file -bptf 17 -1 -add $mean_file $output_file 

# Step 3: Delete the mean file
echo "Deleting the mean file..."
rm -f $mean_file

# Confirmation message
echo "Processing complete. Output file: $output_file"


## Explanation on how the sigma is calculated

# Calculate sigma in seconds for fslmaths
# FSL's -bptf expects sigma values, not frequency --> per volume 
# I assume here the relationship of FWHM=2.3548 * sigma --> sigma = FWHM/2.3548
# sigma = cutoff period / (2 * sqrt(2 * ln(2)))
# sigma (in volumes) = (1 / cutoff_frequency) / (2 * sqrt(2 * ln(2))) / TR
# sigma (in volumes) = ((1/0.01)/ 2.3548)/2.5 = 16.9866 ~ 17
  


