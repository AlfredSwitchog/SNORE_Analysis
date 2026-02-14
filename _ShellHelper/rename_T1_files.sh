#!/bin/bash

#throwaway script to rename some missing T1 files

set -euo pipefail

BASE="/scratch/c7201319/SNORE_MR_out"

# Only these participants need renaming
participant_ids=16,42,47,60,64

IFS=',' read -r -a PIDS <<< "$participant_ids"

for pid in "${PIDS[@]}"; do
  t1_dir="${BASE}/${pid}/T1"

  if [[ ! -d "$t1_dir" ]]; then
    echo "[WARN] ${pid}: T1 folder not found"
    continue
  fi

  cd "$t1_dir"

  # Find MF*.nii but NOT already prefixed with T1_
  mapfile -t files < <(ls MF*.nii 2>/dev/null | grep -v '^T1_')

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "[INFO] ${pid}: no MF*.nii to rename"
    continue
  elif [[ ${#files[@]} -gt 1 ]]; then
    echo "[WARN] ${pid}: multiple MF*.nii found, skipping"
    printf "       %s\n" "${files[@]}"
    continue
  fi

  old="${files[0]}"
  new="T1_${old}"

  echo "[RENAME] ${pid}: ${old} → ${new}"
  mv "$old" "$new"
done

echo "[DONE]"
