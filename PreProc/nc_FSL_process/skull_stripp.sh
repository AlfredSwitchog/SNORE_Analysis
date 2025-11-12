#!/bin/bash

# Usage: ./skull_stripp.sh /path/to/input /path/to/output

# Check for required arguments
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 /path/to/input /path/to/output"
  exit 1
fi

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through all files starting with "r" and ending in .nii or .nii.gz --> files after realignment
for FILE in "$INPUT_DIR"/r*.nii; do
  # Get base filename without extension
  BASENAME=$(basename "$FILE")
  BASENAME_NOEXT="${BASENAME%%.*}"  # Remove everything after first dot

  OUTPUT_FILE="${OUTPUT_DIR}/brain_${BASENAME_NOEXT}.nii"

  echo "Skull stripping $FILE → $OUTPUT_FILE"
  
  # Run FSL's bet2 with -f 0.3
  bet2 "$FILE" "$OUTPUT_FILE" -f 0.3
done

echo "Skull stripping complete. Output saved in $OUTPUT_DIR"
