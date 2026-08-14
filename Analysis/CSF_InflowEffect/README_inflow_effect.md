# Inflow effect — script documentation

The inflow effect is the flow-related signal enhancement in the CSF region: fresh
fluid entering the imaging volume has not yet experienced radiofrequency pulses
and therefore appears bright. Its signature is a **decay of signal amplitude**
across ascending slices, not a difference in mean signal level.

Run order:

```
1. csf_create_group_mean_per_slice.m            (compute the group mean, save it)
2. group_level_raw_signal_first_4_slices_figure.m   (plot the group mean)
3. individual_CSF_95thvs5th_first_4_slices_figure.m (per-participant amplitude)
```

Steps 2 and 3 are independent of each other. Step 2 requires step 1 to have run.

---

## 1. Group mean creation

**Script:** `CSF_raw_data_transformations/csf_create_group_mean_per_slice.m`

**Purpose:** Compute the group-level mean CSF time series for each slice once
and save it, so that plotting scripts only load the result and the average
cannot change between figures.

**Method:** Participants differ in run length, so the time series cannot be
averaged element by element. They are collected in a matrix in which shorter
runs are padded with missing values at the end, and the mean at each time point
is taken over those participants who still have data there. No interpolation and
no truncation is applied. The number of contributing participants at each time
point is stored alongside the mean. Participants whose signal is entirely
missing are skipped and reported.

**Input:** One file per participant in `SNORE_CSF_Data/20260406_Averaged_Signal`,
named `csf_p<N>_averaged.mat` and containing `averaged_slices`, a matrix of
volumes × slices. The participants entering the mean are set with an explicit
list in the configuration.

**Output:** `SNORE_CSF_Data/<yyyymmdd>_Group_Average/csf_group_mean_per_slice.mat`,
containing one structure `group_mean` with the mean per slice, the number of
contributing participants per time point, the participant list, the run lengths
and the creation date. Re-running on the same day overwrites the file.

---

## 2. Group mean figure

**Script:** `CSF_InflowEffect/scripts/group_level_raw_signal_first_4_slices_figure.m`

**Purpose:** Show the group mean CSF signal of the four bottom slices, and
document how many participants contribute to that mean over time.

**Method:** Plotting only; no computation. The saved group mean is loaded and
drawn as one line per slice against time. A second, separate figure shows the
number of contributing participants at each time point, which is needed because
the later part of the mean rests on fewer participants than the earlier part.

**Input:** The `csf_group_mean_per_slice.mat` file written by script 1. The path
is set explicitly in the configuration so that every figure names the exact
group mean it was drawn from.

**Output:** Two PNG files under
`SNORE_Plots/Inflow_Effect/<yyyymmdd>_Figures/`:
`group_level_raw_signal/group_level_raw_csf_signal.png` and
`group_level_contributing_participants/group_level_contributing_participants.png`.

---

## 3. Per-participant amplitude

**Script:** `CSF_InflowEffect/scripts/individual_CSF_95thvs5th_first_4_slices_figure.m`

**Purpose:** Quantify the strength of the inflow effect in each participant and
show how it changes across the four bottom slices.

**Method:** For each slice, the amplitude of the signal is expressed as the ratio
of its 95th to its 5th percentile over time, following Fultz et al. (2019). The
measure captures how far the signal swings between its quiet and its active
moments: a signal that barely changes has a ratio close to one, a strongly
fluctuating signal has a ratio well above one. Percentiles are used rather than
the minimum and maximum so that a single artefactual volume cannot dominate the
result, and a ratio is used rather than a difference so that the arbitrary image
intensity units cancel and participants become comparable. No smoothing is
applied before the quantification. Exact zeros are treated as missing values.

**Input:** The same per-participant files as script 1, in
`SNORE_CSF_Data/20260406_Averaged_Signal`. Participants are selected with a list
in the configuration; leaving it empty processes every file in the folder.

**Output:** One PNG per participant under
`SNORE_Plots/Inflow_Effect/<yyyymmdd>_Figures/all_individual_figs_95th_to_5th/`,
named after the source file, plus `individual_95th_to_5th_ratios.csv` in the same
folder containing the ratio of every participant and slice, the slice with the
largest amplitude, and whether the amplitude decreased monotonically across
slices.

---

## Requirements

MATLAB with the Statistics and Machine Learning Toolbox (`prctile`).
1 TR = 1 volume = 2.5 s.
