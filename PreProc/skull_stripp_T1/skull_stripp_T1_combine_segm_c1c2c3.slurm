#!/bin/bash
#SBATCH --job-name=brainT1
#SBATCH --output=brainT1_%j.out
#SBATCH --error=brainT1_%j.err
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

set -euo pipefail

# ============================================================
# USER SETTINGS
# ============================================================

#unload currently loaded modules
module purge

#load matlab, spm module
module load matlab/R2023b
module load spm

BASE="/scratch/c7201319/SNORE_MR_out"
MATLAB_FUNC_DIR="/scratch/c7201319/SNORE_Analysis/PreProc/nc_SPM_process"
THR="0.2"

# EXACTLY what you asked for
participant_ids=2,3,4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,101

# ============================================================
# INTERNAL SETUP
# ============================================================

# Convert comma-separated list -> array
IFS=',' read -r -a PARTICIPANTS <<< "$participant_ids"

echo "[INFO] Participants: ${PARTICIPANTS[*]}"
echo

# ============================================================
# MAIN LOOP
# ============================================================

for pid in "${PARTICIPANTS[@]}"; do
  t1_dir="${BASE}/${pid}/T1"

  if [[ ! -d "$t1_dir" ]]; then
    echo "[WARN] Participant ${pid}: missing folder (skipping)"
    continue
  fi

  mapfile -t t1_files < <(find "$t1_dir" -maxdepth 1 -type f -name "T1_MF*.nii" | sort)

  if [[ ${#t1_files[@]} -eq 0 ]]; then
    echo "[WARN] Participant ${pid}: no T1_MF*.nii found (skipping)"
    continue
  elif [[ ${#t1_files[@]} -gt 1 ]]; then
    echo "[WARN] Participant ${pid}: multiple T1_MF*.nii found (skipping)"
    printf "       %s\n" "${t1_files[@]}"
    continue
  fi

  t1_file="${t1_files[0]}"
  echo "[INFO] Participant ${pid}: processing"
  echo "       T1: $t1_file"

  matlab -nodisplay -nosplash -nodesktop -r \
    "try, addpath('${MATLAB_FUNC_DIR}'); nc_make_brainmask_from_c123('${t1_file}', ${THR}); catch ME, disp(getReport(ME,'extended')); exit(1); end; exit(0);"

  echo
done

echo "[DONE] All participants processed."