function len = stable_epoch_lengths(lab, targetStages, minTR)
% Lengths (in volumes) of every stable epoch in a label vector.
% A stable epoch is a maximal run of consecutive volumes whose stage is in
% targetStages and that lasts at least minTR volumes. Runs may span a
% boundary between two stages of the set, e.g. NREM2 -> NREM3.
%
% Same rule as segment_stable_sleep_epochs.m, so the counts agree.

mask = ismember(lab(:).', targetStages);      % 1 x nVolumes logical
len  = [];
if ~any(mask); return; end

d      = diff([false, mask, false]);
starts = find(d ==  1);
ends   = find(d == -1) - 1;                   % inclusive end
L      = ends - starts + 1;
len    = L(L >= minTR);
end
