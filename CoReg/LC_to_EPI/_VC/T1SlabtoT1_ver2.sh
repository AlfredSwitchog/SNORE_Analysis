#!/bin/bash
#set -euo pipefail

T1_IMG="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/T1/T1_n4_HI96BM210524.nii"
SLAB_ISO="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/T1_slab/t1slab_iso1mm.nii.gz"
WORKDIR="/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/1/regis_LC_mask_to_EPI/T1Slab_to_T1_test_2"
#mkdir -p "$WORKDIR"

# Preflight (prove files exist *to this shell*)
#ls -l "$T1_IMG" "$SLAB_ISO"

# 1) Initialization with antsAI
antsAI -d 3 \
 -m MI[$T1_IMG,$SLAB_ISO,32,Regular,0.2] \
 -t Rigid[0.1] -s 2 -g 10 \
 -o $WORKDIR/initRigid.mat

# 2) Rigid registration using that init
#antsRegistration -d 3 \
#  -r "$WORKDIR/initRigid.mat" \
#  -m MI["$T1_IMG","$SLAB_ISO",1,32,Regular,0.2] \
#  -t Rigid[0.1] \
#  -c [1000x500x250,1e-6,10] -s 4x2x1 -f 6x4x2 \
#  -o ["$WORKDIR/SLABtoT1_","$WORKDIR/SLABtoT1_Warped.nii.gz","$WORKDIR/SLABtoT1_InverseWarped.nii.gz"]