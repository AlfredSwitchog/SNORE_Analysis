#!/bin/bash
#SBATCH --time=06:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=8
#SBATCH --job-name=register_LC-MNI_to_EPI
#SBATCH --output=slurm-%j.out
#SBATCH --mail-user=richard.lohr@gmx.de                                 
#SBATCH --mail-type=BEGIN,END,FAIL

# example script for using ANTs for registraiton & normalisation!
# authour: yeo-jin yi (alex; for further questions, mailto: yeo-jin.yi.15@ucl.ac.uk)

# dependencies : ANTs (https://stnava.github.io/ANTs/)

module load ants

# subject ID
ID=16

# set paths
path_parent=/scratch/c7201319/SNORE_MR_out # your root directory
path_output=/scratch/c7201319/SNORE_MRI_data_dev_out/${ID}/regis_LC_mask_to_EPI/LC_MNI_to_EPI # where should your outputs go?

mkdir -p "${path_output}"

# the space that everything should be situated in by the end of the image processing
img_reference=$path_parent/${ID}/func_mean_ua/meanua_n4_.nii # in your case, this should be the mean functional image from LN_SKEW
#img_studytemplate=$path_parent/templates/mrpet_template.nii.gz # you don't need this

# -------------------------------------------------------------------- #
# let's put MNI to mean functional image

# before everything, move MNI to an anatomical scan
img_moving=/scratch/c7201319/SNORE_LC_Masks/MNI_Space/mni_icbm152_LCmetaMask_final.nii
img_fixed=$path_parent/${ID}/T1/T1_n4_CR00TS031024.nii
antsRegistrationSyN.sh -d 3 -t s -m $img_moving -f $img_fixed -o ${path_output}/NLreg_mni2anat_ # for manual, type: antsRegistrationSyN.sh --help

# anatomical scan to functional image
img_moving=$path_parent/${ID}/T1/T1_n4_CR00TS031024.nii
img_fixed=$path_parent/${ID}/func_mean_ua/meanua_n4_.nii
antsRegistrationSyN.sh -d 3 -t r -m $img_moving -f $img_fixed -o ${path_output}/reg_anat2meanfunc_

# now, apply transformations from the above steps to move mni to mean functional. remember, -t switch indicates transformation files, and the order of input is important! you put the warps before affine matrices, and transformations closer to the destination image earlier than that related to the moving image

# MNI -> mean functional
img_moving=/scratch/c7201319/SNORE_LC_Masks/MNI_Space/mni_icbm152_LCmetaMask_final.nii
img_fixed=$img_reference

antsApplyTransforms -d 3 -v 0 -n BSpline[4] -t ${path_output}/reg_anat2meanfunc_0GenericAffine.mat -t ${path_output}/NLreg_mni2anat_1Warp.nii.gz -t ${path_output}/NLreg_mni2anat_0GenericAffine.mat -i $img_moving -r $img_fixed -o ${path_output}/NLreg_MNI_to_meanfunc.nii.gz

# the segmentations to the mean functional space
#img_moving=$path_parent/masks/mPFC.nii.gz
#img_fixed=$img_reference

#antsApplyTransforms -d 3 -v 0 -n NearestNeighbor -t ${path_output}/reg_anat2meanfunc_0GenericAffine.mat -t ${path_output}/NLreg_mni2anat_1Warp.nii.gz -t ${path_output}/NLreg_mni2anat_0GenericAffine.mat -i $img_moving -r $img_fixed -o ${path_output}/NLreg_MNI_to_meanfunc.nii.gz # always use nearest neighbor interpolation for binary images!
