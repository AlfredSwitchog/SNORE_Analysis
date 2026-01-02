#!/bin/bash

# Usage:
# ./count_prefix_files_from_example.sh <example_subfolder> <prefix>
#
# Example:
# ./count_prefix_files_from_example.sh /scratch/c7201319/SNORE_MR_out/1/nifti_raw MF

if [ $# -ne 2 ]; then
    echo "Usage: $0 <example_subfolder> <prefix>"
    exit 1
fi

EXAMPLE_SUBFOLDER="$1"
PREFIX="$2"

if [ ! -d "$EXAMPLE_SUBFOLDER" ]; then
    echo "ERROR: Example subfolder not found: $EXAMPLE_SUBFOLDER"
    exit 1
fi

# Deduce paths
SUBFOLDER_NAME=$(basename "$EXAMPLE_SUBFOLDER")          # nifti_raw
PARENT_PART_DIR=$(dirname "$EXAMPLE_SUBFOLDER")          # .../SNORE_MR_out/1
BASE_DIR=$(dirname "$PARENT_PART_DIR")                    # .../SNORE_MR_out

echo "Base directory:  $BASE_DIR"
echo "Subfolder name:  $SUBFOLDER_NAME"
echo "Filename prefix: $PREFIX"
echo

shopt -s nullglob

# 🔑 Get participant directories sorted numerically
PARTICIPANTS=$(ls -1 "$BASE_DIR" | grep -E '^[0-9]+$' | sort -n)

for ID in $PARTICIPANTS; do
    TARGET_DIR="${BASE_DIR}/${ID}/${SUBFOLDER_NAME}"

    if [ ! -d "$TARGET_DIR" ]; then
        echo "Participant ${ID}: ${SUBFOLDER_NAME} NOT found"
        continue
    fi

    count=$(find "$TARGET_DIR" -maxdepth 1 -type f -name "${PREFIX}*" | wc -l)
    echo "Participant ${ID}: ${count} files"
done
