%paths
maskFile = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/29/mean_image/meanEPI_test_mask.nii';
volFile = '/Users/Richard/Masterabeit_local/SNORE_MRI_data_dev_out/29/rMFHE97CF261124-0007-02800-002800.nii';


% Read image and mask
V  = spm_vol(volFile);
Vm = spm_vol(maskFile);

Y = spm_read_vols(V);
M = spm_read_vols(Vm);

% Make mask logical
M = M > 0;

% Extract all voxel values inside the mask
values = Y(M);

disp('First extracted values:')
disp(values(1:min(20,end)))

% Find slices where the mask exists
maskSlices = find(squeeze(any(any(M,1),2)));

disp('Slices where mask exists:')
disp(maskSlices)

%% Look at the first slice of a volume that is clipped
slice_number = 1;
first_sliceVals = Y(:,:,slice_number);
first_sliceMask = M(:,:,slice_number);
first_maskedVals = sliceVals(sliceMask); %this is the crucial line that shows that the first slices has signal

%% Find slices where masked region contains nonzero signal
signalSlices = [];

for z = maskSlices'
    sliceVals = Y(:,:,z);
    sliceMask = M(:,:,z);
    maskedVals = sliceVals(sliceMask);

    if any(maskedVals ~= 0)
        signalSlices(end+1) = z;
    end
end

disp('Slices with nonzero signal inside mask:')
disp(signalSlices)
