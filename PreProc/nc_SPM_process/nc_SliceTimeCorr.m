%%********************************%%
% Slice Time correction
% NC 14/12/17
%
% data: lists of scans
% nslcies: nb of slices
% TR : volume TR in [s]
% order: 1 for ascending (default)
%        -1 for descending
%        0 for other
% slice_time: vector of slice timings in [ms]
% (interleave not implemented)
%********************************%%
function nc_SliceTimeCorr(data,nslices,TR, sliceTimingFile)

matlabbatch{1}.spm.temporal.st.scans = {data}; %data as cellstr
matlabbatch{1}.spm.temporal.st.nslices = nslices; %read from config section
matlabbatch{1}.spm.temporal.st.tr = TR;
matlabbatch{1}.spm.temporal.st.ta = 2.4125;
matlabbatch{1}.spm.temporal.st.so = sliceTimingFile; %individual slice timing information
matlabbatch{1}.spm.temporal.st.refslice = nslices/2; %reference slice is the middle slice
matlabbatch{1}.spm.temporal.st.prefix = 'a';

spm_jobman('run', matlabbatch);
clear matlabbatch
end