#!/bin/bash
set -euo pipefail

BASE="/scratch/c7201319/SNORE_MR_out"
OUT="/scratch/c7201319/SNORE_QC"

PARTICIPANTS=(9 10 6 22 14 33 43 32 8 46 64 53 21 66 52 18 23 49 51 20 63 45 57 47 42 41 5 31 35 55)

SUBPATHS=(
  "nifti_raw"
  "preprocessing/reallign"
)

VOLS=(333 1678 2800 3281)

MEAN_EPI_SUB="meanEPI"

pad6() { printf "%06d" "$1"; }

# Build padded-volume lookup set
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
  # 1) Copy selected raw + realigned volumes
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
  # 2) Copy meanEPI folder
  # -------------------------
  MEAN_SRC="${BASE}/${ID}/${MEAN_EPI_SUB}"
  if [[ -d "$MEAN_SRC" ]]; then
    echo "  [COPYDIR] meanEPI"
    mkdir -p "${OUT}/${ID}"
    cp -a "$MEAN_SRC" "${OUT}/${ID}/"
  else
    echo "  [WARN] Missing meanEPI folder"
  fi

  echo
done

echo "[DONE] QC folder built at: $OUT"