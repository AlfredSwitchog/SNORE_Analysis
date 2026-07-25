#!/bin/bash
# ============================================================
#  build_SNORE_QC_GM_mask.sh
#  Assemble a small QC set for selected participants.
#  Based on build_SNORE_QC_raw_realigned_only.sh, extended to also
#  copy the binarised GM (c1) mask in functional space.
#
#  Per participant it collects:
#    - GM_mask/ : the binarised c1 mask (c1_in_func_space_bin_...nii.gz)
#    - meanEPI/ : the complete folder
#    - nifti_raw/ : the 4 selected volumes
#    - preprocessing/reallign/ : the same 4 selected volumes
#
#  Runs on the cluster (paths under /scratch). Copy the OUT folder to
#  your local machine afterwards.
# ============================================================
set -euo pipefail

# ---------------- CONFIG ----------------
BASE="/scratch/c7201319/SNORE_MR_out"
OUT="/scratch/c7201319/SNORE_QC/SNORE_QC_c1_mask"        # output QC folder (change if desired)

PARTICIPANTS=(33 23 31)

# raw + realigned volume folders (only the selected volumes are copied)
SUBPATHS=(
  "nifti_raw"
  "preprocessing/reallign"
)
VOLS=(333 1678 2800 3281)                        # same volumes as the example script

MEAN_EPI_SUB="meanEPI"                           # copied as a whole folder

# Binarised GM (c1) mask in functional space. The trailing session code
# differs per participant, so it is matched with a glob (the "bin" variant
# only, not the non-binarised c1_in_func_space_N4_... file).
GM_MASK_SUB="GM_mask"
GM_MASK_GLOB="c1_in_func_space_bin_N4_brain_T1_*.nii.gz"

pad6() { printf "%06d" "$1"; }

# Build padded-volume lookup set (e.g. " 000333 001678 002800 003281 ")
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
  # 1) Selected raw + realigned volumes
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
      if   [[ "$stem" == *.nii.gz ]]; then stem="${stem%.nii.gz}"
      elif [[ "$stem" == *.nii ]];    then stem="${stem%.nii}"
      else continue; fi

      pv="${stem: -6}"                           # last 6 chars = padded volume number
      if [[ "$PVSET" == *" $pv "* ]]; then
        echo "  [COPY] ${SUB}: $bn"
        cp -p "$f" "$DST_DIR/"
        copied_any=1
      fi
    done < <(find "$SRC_DIR" -maxdepth 1 -type f \( -name "*-??????.nii" -o -name "*-??????.nii.gz" \) | sort)

    [[ "$copied_any" -eq 1 ]] || echo "  [INFO] ${SUB}: no matches for requested volumes"
  done

  # -------------------------
  # 2) meanEPI folder (whole)
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
  # 3) Binarised GM (c1) mask
  # -------------------------
  GM_SRC_DIR="${BASE}/${ID}/${GM_MASK_SUB}"
  DST_GM="${OUT}/${ID}/${GM_MASK_SUB}"
  mkdir -p "$DST_GM"

  gm_copied=0
  shopt -s nullglob
  for m in "${GM_SRC_DIR}/"${GM_MASK_GLOB}; do
    echo "  [COPY] GM_mask: $(basename "$m")"
    cp -p "$m" "$DST_GM/"
    gm_copied=1
  done
  shopt -u nullglob
  [[ "$gm_copied" -eq 1 ]] || echo "  [WARN] No GM mask matching '${GM_MASK_GLOB}' in ${GM_SRC_DIR}"

  echo
done

echo "[DONE] QC folder built at: $OUT"
