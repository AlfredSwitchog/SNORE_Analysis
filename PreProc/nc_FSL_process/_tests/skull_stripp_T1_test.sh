#!/usr/bin/env bash
# Usage:
#   skull_stripp_T1_test.sh T1.nii.gz output_dir
#
# Runs BET2 for several -f values, saving skull-stripped images + masks.

set -e

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 T1.nii.gz output_dir"
  exit 1
fi

IN_T1="$1"
OUTDIR="$2"

mkdir -p "$OUTDIR"

F_VALUES=(0.05 0.10 0.20 0.30)

BASE=$(basename "$IN_T1")
BASE=${BASE%.nii.gz}
BASE=${BASE%.nii}

SUMMARY="$OUTDIR/bet2_summary.tsv"
echo -e "f_value\tmask\tbrain_volume_mm3" > "$SUMMARY"

for f in "${F_VALUES[@]}"; do
  tag="${f/./p}"    # convert 0.25 → 0p25 for file names
  OUT_PREFIX="${OUTDIR}/${BASE}_f${tag}"

  echo "BET2 with -f $f ..."
  bet2 "$IN_T1" "${OUT_PREFIX}" -f "$f"

  MASK="${OUT_PREFIX}_mask.nii.gz"

done

echo
echo "Done. Summary written to: $SUMMARY"
echo "Inspect outputs in:       $OUTDIR"
echo
echo "Example to view:"
echo "  fsleyes $IN_T1 ${OUTDIR}/${BASE}_f0p25.nii.gz &"
