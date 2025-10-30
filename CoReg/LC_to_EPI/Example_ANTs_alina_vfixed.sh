#!/bin/bash
#$ -S /bin/bash
#$ -l h_rt=168:00:00,h_vmem=8G,mem_free=8G
#$ -q work.q
# the above are specifications for SGE qsub. remove if you're doing your analyses on your local mac

# example script for using ANTs for registraiton & normalisation!
# authour: yeo-jin yi (alex; for further questions, mailto: yeo-jin.yi.15@ucl.ac.uk)

# dependencies : ANTs (https://stnava.github.io/ANTs/)

# subject ID
ID=YQH350

# set paths
path_parent=/Users/alex/images # your root directory
path_output=$path_parent/${ID}/reg # where should your outputs go?

# the space that everything should be situated in by the end of the image processing
img_reference=$path_parent/${ID}/func/meanfunc.nii.gz # in your case, this should be the mean functional image from LN_SKEW
#img_studytemplate=$path_parent/templates/mrpet_template.nii.gz # you don't need this

# -------------------------------------------------------------------- #
# let's put MNI to mean functional image

# before everything, move MNI to an anatomical scan
img_moving=$path_parent/templates/mni_icbm152.nii.gz
img_fixed=$path_parent/${ID}/func/t1w_corrected.nii.gz
antsRegistrationSyN.sh -d 3 -t s -m $img_moving -f $img_fixed -o ${path_output}/NLreg_mni2anat_ # for manual, type: antsRegistrationSyN.sh --help

# anatomical scan to functional image
img_moving=$path_parent/${ID}/func/t1w_corrected.nii.gz
img_fixed=$path_parent/${ID}/func/meanfunc.nii.gz
antsRegistrationSyN.sh -d 3 -t r -m $img_moving -f $img_fixed -o ${path_output}/reg_anat2meanfunc_

# now, apply transformations from the above steps to move mni to mean functional. remember, -t switch indicates transformation files, and the order of input is important! you put the warps before affine matrices, and transformations closer to the destination image earlier than that related to the moving image

# MNI -> mean functional
img_moving=$path_parent/templates/mni_icbm152.nii.gz
img_fixed=$img_reference

antsApplyTransforms -d 3 -v 0 -n BSpline[4] -t ${path_output}/reg_anat2meanfunc_0GenericAffine.mat -t ${path_output}/NLreg_mni2anat_1Warp.nii.gz -t ${path_output}/NLreg_mni2anat_0GenericAffine.mat -i $img_moving -r $img_fixed -o ${path_output}/NLreg_MNI_to_meanfunc.nii.gz

# the segmentations to the mean functional space
img_moving=$path_parent/masks/mPFC.nii.gz
img_fixed=$img_reference

antsApplyTransforms -d 3 -v 0 -n NearestNeighbor -t ${path_output}/reg_anat2meanfunc_0GenericAffine.mat -t ${path_output}/NLreg_mni2anat_1Warp.nii.gz -t ${path_output}/NLreg_mni2anat_0GenericAffine.mat -i $img_moving -r $img_fixed -o ${path_output}/NLreg_MNI_to_meanfunc.nii.gz # always use nearest neighbor interpolation for binary images!
