#!/bin/bash

# Usage: ./merge_split_runs.sh <participant_id>
# Example: ./merge_split_runs.sh 9

set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <participant_id>"
    exit 1
fi

PARTICIPANT="$1"

# Adjust this base path if needed
BASE="/scratch/c7201319/SNORE_MRI"

PART_DIR="${BASE}/${PARTICIPANT}"

RUN1_DIR="${PART_DIR}/Night/MR ep2d_bold_samba_2mm_sleep"
RUN2_DIR="${PART_DIR}/Night/MR ep2d_bold_samba_2mm_sleep-2"
MERGED_DIR="${PART_DIR}/Night/MR ep2d_bold_samba_2mm_sleep_merged"

echo "Participant: ${PARTICIPANT}"
echo "Run 1 dir:   ${RUN1_DIR}"
echo "Run 2 dir:   ${RUN2_DIR}"
echo "Merged dir:  ${MERGED_DIR}"
echo

# Basic checks
if [ ! -d "$RUN1_DIR" ]; then
    echo "ERROR: Run 1 directory not found: $RUN1_DIR"
    exit 1
fi

if [ ! -d "$RUN2_DIR" ]; then
    echo "ERROR: Run 2 directory not found: $RUN2_DIR"
    exit 1
fi

mkdir -p "$MERGED_DIR"

echo "Copying first run into merged folder..."
cp "${RUN1_DIR}"/MR*.dcm "$MERGED_DIR"/

# Find the last file in the merged folder (from run 1) in lexical order
LAST_FILE=$(ls "$MERGED_DIR"/MR*.dcm | sort | tail -n 1)

if [ -z "${LAST_FILE:-}" ]; then
    echo "ERROR: No MR*.dcm files found in merged folder after copying run 1."
    exit 1
fi

BN=$(basename "$LAST_FILE")          # e.g. MR001090.dcm
NUM_STR=${BN#MR}                     # 001090.dcm
NUM_STR=${NUM_STR%.dcm}              # 001090
WIDTH=${#NUM_STR}                    # number of digits
LAST_INDEX=$((10#$NUM_STR))          # numeric value (avoid octal)
NEXT_INDEX=$((LAST_INDEX + 1))

echo "Last file after run 1: $BN (index $LAST_INDEX, width $WIDTH)"
echo "Starting run 2 at index: $NEXT_INDEX"
echo

echo "Renaming and copying second run into merged folder..."

# Loop over run 2 files in sorted order
for FILE in $(ls "$RUN2_DIR"/MR*.dcm | sort); do
    printf -v NEW_NUM "%0${WIDTH}d" "$NEXT_INDEX"
    NEW_NAME="MR${NEW_NUM}.dcm"

    # Copy or move (currently copy for safety)
    cp "$FILE" "${MERGED_DIR}/${NEW_NAME}"

    # If you really want to MOVE instead of copy, use this instead:
    # mv "$FILE" "${MERGED_DIR}/${NEW_NAME}"

    echo "  $(basename "$FILE") -> ${NEW_NAME}"

    NEXT_INDEX=$((NEXT_INDEX + 1))
done

echo
echo "Done. Merged run saved in:"
echo "  $MERGED_DIR"
