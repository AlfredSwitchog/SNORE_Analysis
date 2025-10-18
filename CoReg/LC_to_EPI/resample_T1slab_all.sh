#!/bin/bash

module purge
module load freesurfer

BASE_IN="/scratch/c7201319/SNORE_MR_out"
BASE_OUT="/scratch/c7201319/SNORE_MR_out"

for pid in $(seq 3 41); do
  IN_SLAB="${BASE_IN}/${pid}/T1_slab/t1slab_orig.nii"
  OUT_SLAB_DIR="${BASE_OUT}/${pid}/T1_slab"
  OUT_SLAB="${OUT_SLAB_DIR}/t1slab_iso1mm.nii.gz"
  REF_T1=$(ls "${BASE_IN}/${pid}/T1"/T1_MF*.nii 2>/dev/null | head -n 1)

  [[ -f "$IN_SLAB" ]] || { echo "[$pid] missing slab: $IN_SLAB"; continue; }
  [[ -n "${REF_T1:-}" ]] || { echo "[$pid] no T1_MF*.nii found in ${BASE_IN}/${pid}/T1"; continue; }

  mkdir -p "$OUT_SLAB_DIR"
  echo "[$pid] Resampling slab to 1mm using ref: $(basename "$REF_T1")"
  mri_convert -cs 1 -odt float -rl "$REF_T1" -rt cubic "$IN_SLAB" "$OUT_SLAB"

  echo "[$pid] -> $OUT_SLAB"
done

echo "Done."
