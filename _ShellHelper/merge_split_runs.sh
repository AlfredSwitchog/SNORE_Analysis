#!/bin/bash

# Usage: ./merge_split_runs.sh <participant_id> <num_sleep_dirs>
# Example: ./merge_split_runs.sh 1 3
# For 3 dirs:
#   MR ep2d_bold_samba_2mm_sleep
#   MR ep2d_bold_samba_2mm_sleep-2
#   MR ep2d_bold_samba_2mm_sleep-3

set -euo pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 <participant_id> <num_sleep_dirs>"
    exit 1
fi

PARTICIPANT="$1"
NUM_SPLITS="$2"

if ! [[ "$NUM_SPLITS" =~ ^[0-9]+$ ]] || [ "$NUM_SPLITS" -lt 1 ]; then
    echo "ERROR: <num_sleep_dirs> must be a positive integer"
    exit 1
fi

# 🔧 Adjust base path if needed
BASE="/scratch/c7201319/SNORE_MRI"

# If "Night" is always part of the path, keep this:
PART_DIR="${BASE}/${PARTICIPANT}/Night"

RUN_BASE_NAME="MR ep2d_bold_samba_2mm_sleep"
MERGED_DIR="${PART_DIR}/${RUN_BASE_NAME}_merged"

echo "Participant: ${PARTICIPANT}"
echo "Base dir:   ${PART_DIR}"
echo "Merged dir: ${MERGED_DIR}"
echo "Number of split dirs: ${NUM_SPLITS}"
echo

# --- 1) First run (without suffix) ---

RUN1_DIR="${PART_DIR}/${RUN_BASE_NAME}"

echo "Checking first run: ${RUN1_DIR}"
if [ ! -d "$RUN1_DIR" ]; then
    echo "ERROR: Run 1 directory not found: $RUN1_DIR"
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

BN=$(basename "$LAST_FILE")     # e.g. MR001178.dcm
NUM_STR=${BN#MR}                # 001178.dcm
NUM_STR=${NUM_STR%.dcm}         # 001178
WIDTH=${#NUM_STR}               # number of digits (e.g. 6)
LAST_INDEX=$((10#$NUM_STR))     # numeric value (avoid octal)
NEXT_INDEX=$((LAST_INDEX + 1))

echo "Last file after run 1: $BN (index $LAST_INDEX, width $WIDTH)"
echo "Starting additional runs at index: $NEXT_INDEX"
echo

shopt -s nullglob

# --- 2) Process split runs 2 .. NUM_SPLITS ---

for (( i=2; i<=NUM_SPLITS; i++ )); do
    RUN_DIR="${PART_DIR}/${RUN_BASE_NAME}-${i}"
    echo "Processing split run ${i}: ${RUN_DIR}"

    if [ ! -d "$RUN_DIR" ]; then
        echo "ERROR: Expected split directory not found: $RUN_DIR"
        exit 1
    fi

    FILES=( "$RUN_DIR"/MR*.dcm )

    if [ ${#FILES[@]} -eq 0 ]; then
        echo "  WARNING: No MR*.dcm files found in $RUN_DIR, skipping."
        continue
    fi

    # Ensure deterministic order
    IFS=$'\n' FILES_SORTED=( $(printf '%s\n' "${FILES[@]}" | sort) )
    unset IFS

    for FILE in "${FILES_SORTED[@]}"; do
        printf -v NEW_NUM "%0${WIDTH}d" "$NEXT_INDEX"
        NEW_NAME="MR${NEW_NUM}.dcm"

        # Copy or move:
        cp "$FILE" "${MERGED_DIR}/${NEW_NAME}"
        # If you want to MOVE instead of copy, use:
        # mv "$FILE" "${MERGED_DIR}/${NEW_NAME}"

        echo "  $(basename "$FILE") -> ${NEW_NAME}"

        NEXT_INDEX=$((NEXT_INDEX + 1))
    done

    echo
done

echo "Done. Merged run saved in:"
echo "  $MERGED_DIR"
