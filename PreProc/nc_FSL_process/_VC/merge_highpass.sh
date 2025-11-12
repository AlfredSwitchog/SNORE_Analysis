#!/bin/bash

# Usage: ./merge_highpass.sh /path/to/input_folder /path/to/output_folder TR highpass_cutoff_Hz

# Arguments
INPUT_DIR="$1"        # Folder with 3D .nii or .nii.gz files
OUTPUT_DIR="$2"       # Folder where merged and filtered files will be saved
TR="$3"               # Repetition time in seconds (e.g., 2.5)
HIGHPASS_HZ="$4"      # Highpass frequency cutoff in Hz (e.g., 0.01)

# Check if all arguments are provided
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 /path/to/input_folder /path/to/output_folder TR highpass_cutoff_Hz"
  exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Find first file to extract identifier
FIRST_FILE=$(ls "$INPUT_DIR"/*.nii* | sort | head -n 1)

# Extract the middle part between "brain_" and the first dash
# Example: brain_s3uaMFRO01GG010724-0011-00001-000001.nii.gz -> s3uaMFRO01GG010724
IDENTIFIER=$(basename "$FIRST_FILE" | sed -E 's/brain_([^-]+)-.*/\1/')

# Define output filenames
MERGED_FILE="${OUTPUT_DIR}/merged_${IDENTIFIER}.nii.gz"
FILTERED_FILE="${OUTPUT_DIR}/filtered_${IDENTIFIER}.nii.gz"

echo "Identifier extracted: $IDENTIFIER"
echo "Merged output: $MERGED_FILE"
echo "Filtered output: $FILTERED_FILE"

# Create a temporary sorted file list
FILELIST=$(mktemp)
ls "$INPUT_DIR"/*.nii* | sort > "$FILELIST"

echo "Merging volumes from $INPUT_DIR..."
fslmerge -t "$MERGED_FILE" $(cat "$FILELIST")

# Calculate sigma in seconds for fslmaths
# FSL's -bptf expects sigma values, not frequency --> per volume 
# I assume here the relationship of FWHM=2.3548 * sigma --> sigma = FWHM/2.3548
# sigma = cutoff period / (2 * sqrt(2 * ln(2)))
# sigma (in volumes) = (1 / cutoff_frequency) / (2 * sqrt(2 * ln(2))) / TR
# sigma (in volumes) = ((1/0.01)/ 2.3548)/2.5 = 16.9866 ~ 17
SIGMA=$(echo "scale=5; (1 / $HIGHPASS_HZ) / (2 * sqrt(2 * l(2))) / $TR" | bc -l)
LOWPASS_SIGMA=-1  # No lowpass filter

echo "Applying highpass filter with sigma=${SIGMA} volumes..."
fslmaths "$MERGED_FILE" -bptf "$SIGMA" "$LOWPASS_SIGMA" "$FILTERED_FILE"

# Clean up temporary file
rm "$FILELIST"

echo "Done."
echo "Merged file:   $MERGED_FILE"
echo "Filtered file: $FILTERED_FILE"
