#!/bin/bash

# Participants 1..70 
PARTICIPANTS=($(seq 2 70))

# Where convert_nm_to_nii.m lives
SCRIPT_DIR="/scratch/c7201319/SNORE_Analysis/_ShellHelper/"

#load modules
module load matlab

for pid in "${PARTICIPANTS[@]}"; do
  echo "Converting participant ${pid}..."
  matlab -batch "addpath('$SCRIPT_DIR'); convert_nm_to_nii($pid);"
done

echo "All done."
