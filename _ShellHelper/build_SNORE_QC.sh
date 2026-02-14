#!/bin/bash
set -euo pipefail

BASE="/scratch/c7201319/SNORE_MR_out"
OUT="/scratch/c7201319/SNORE_QC"

PARTICIPANTS=(4 29 38 49 58)

SUBPATHS=(
  "nifti_raw"
  "preprocessing/skull_stripp"
  "preprocessing/reallign"
  "preprocessing/slice_time_correction"
  "preprocessing/smooth"
)

VOLS=(333 1678 2800 3281)

MEAN_EPI_SUB="meanEPI"

HIGHPASS_SUB="preprocessing/highpass"
HIGHPASS_OUT_SUB="preprocessing/highpass_extracted"

pad6() { printf "%06d" "$1"; }

module load fsl

if ! command -v fslroi >/dev/null 2>&1; then
  echo "[ERROR] fslroi not found. Please load FSL (e.g. module load fsl)."
  exit 1
fi

# Build padded-volume lookup set (for copying 3D files)
PVSET=" "
for v in "${VOLS[@]}"; do
  if [[ "$v" =~ ^[0-9]+$ ]]; then
    PVSET+="$(pad6 "$v") "
  else
    echo "[WARN] Volume '$v' is not an integer (ignored)"
  fi
done

for ID in "${PARTICIPANTS[@]}"; do
  echo "Participant $ID"

  # -------------------------
  # 1) Copy selected volumes (3D files where filename ends with -000123)
  # -------------------------
  for SUB in "${SUBPATHS[@]}"; do
    SRC_DIR="${BASE}/${ID}/${SUB}"
    [[ -d "$SRC_DIR" ]] || { echo "  [WARN] Missing folder: $SRC_DIR"; continue; }

    DST_DIR="${OUT}/${ID}/${SUB}"
    mkdir -p "$DST_DIR"

    copied_any=0

    while IFS= read -r f; do
      [[ -n "$f" ]] || continue

      bn="$(basename "$f")"
      stem="$bn"
      if [[ "$stem" == *.nii.gz ]]; then
        stem="${stem%.nii.gz}"
      elif [[ "$stem" == *.nii ]]; then
        stem="${stem%.nii}"
      else
        continue
      fi

      pv="${stem: -6}"
      if [[ "$PVSET" == *" $pv "* ]]; then
        echo "  [COPY] ${SUB}: $bn"
        cp -p "$f" "$DST_DIR/"
        copied_any=1
      fi
    done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -name "*-??????.nii" -o -name "*-??????.nii.gz" \) | sort)

    [[ "$copied_any" -eq 1 ]] || echo "  [INFO] ${SUB}: no matches for requested volumes"
  done

  # -------------------------
  # 2) Copy entire meanEPI
  # -------------------------
  MEAN_SRC="${BASE}/${ID}/${MEAN_EPI_SUB}"
  if [[ -d "$MEAN_SRC" ]]; then
    echo "  [COPYDIR] meanEPI"
    mkdir -p "${OUT}/${ID}"
    cp -a "$MEAN_SRC" "${OUT}/${ID}/"
  else
    echo "  [WARN] Missing meanEPI folder"
  fi

  # -------------------------
  # 3) Extract highpass volumes using FSL (no merge)
  # -------------------------
  HP_DIR="${BASE}/${ID}/${HIGHPASS_SUB}"
  if [[ ! -d "$HP_DIR" ]]; then
    echo "  [WARN] Missing highpass folder: $HP_DIR"
    echo
    continue
  fi

  shopt -s nullglob
  hp_files=(
    "$HP_DIR"/hp_s3brain_a_rMF*.nii.gz
    "$HP_DIR"/hp_s3brain_a_rMF*.nii
    "$HP_DIR"/hp_*MF*.nii.gz
    "$HP_DIR"/hp_*MF*.nii
  )
  shopt -u nullglob

  if [[ ${#hp_files[@]} -eq 0 ]]; then
    echo "  [WARN] No highpass file found in $HP_DIR"
    echo "         Tried: hp_s3brain_a_rMF*.nii(.gz) and hp_*MF*.nii(.gz)"
    echo
    continue
  fi

  # pick newest if multiple
  HP_4D="$(ls -1t "${hp_files[@]}" 2>/dev/null | head -n 1)"
  if [[ -z "$HP_4D" || ! -f "$HP_4D" ]]; then
    echo "  [WARN] Could not resolve a valid highpass file in $HP_DIR"
    echo
    continue
  fi

  HP_OUT_DIR="${OUT}/${ID}/${HIGHPASS_OUT_SUB}"
  mkdir -p "$HP_OUT_DIR"

  echo "  [INFO] Highpass source: $HP_4D"

  # Optional but very useful: check number of volumes
  nvols="$(fslnvols "$HP_4D" 2>/dev/null || echo "")"
  if [[ -n "$nvols" ]]; then
    echo "  [INFO] Highpass nvols: $nvols"
  fi

  for v in "${VOLS[@]}"; do
    [[ "$v" =~ ^[0-9]+$ ]] || continue

    pv="$(pad6 "$v")"

    # Assuming your requested volumes are 1-based; FSL is 0-based
    start=$(( v - 1 ))
    if (( start < 0 )); then
      echo "  [WARN] Volume $v -> negative index (skipping)"
      continue
    fi

    if [[ -n "$nvols" ]] && (( start >= nvols )); then
      echo "  [WARN] Requested volume $v out of range (1..$nvols), skipping"
      continue
    fi

    out_vol="${HP_OUT_DIR}/vol_${pv}_$(basename "$HP_4D")"
    echo "  [FSLROI] volume $v (idx $start) -> $(basename "$out_vol")"
    fslroi "$HP_4D" "$out_vol" "$start" 1
  done

  echo
done

echo "[DONE] QC folder built at: $OUT"