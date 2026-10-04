# Two-stage group-level gBOLD–CSF cross-correlation

---

## Short version

**Script:** `csf_gm_xcorr_two_stage_group.m`

**Purpose:** Test whether the global BOLD signal and the CSF signal are
correlated at a given time lag, with the participant — not the sleep epoch —
as the unit of inference.

**Method:** Two stages. Stage 1 computes the lagged correlation inside each
sleep epoch, Fisher *z*-transforms it and averages across the epochs of one
participant, giving one curve per participant. Stage 2 runs a one-sample
*t*-test across participants at each lag and corrects the *p*-values across
lags with Benjamini–Hochberg FDR.

**Inputs:** The stage-segmented CSF and gBOLD files produced by
`segment_stable_sleep_epochs.m`, one pair per participant. The sleep-stage
definition (`N2`, `N2_N3`, `N1_N2_N3`, `W`) is chosen with one switch in the
configuration and determines all folders.

**Outputs:** A group-level plot of mean correlation against lag with a ±1
standard error band and the FDR-significant lags marked, plus a results
`.mat` containing the per-participant curves, group means, *t* statistics and
raw and corrected *p*-values.

---

## Long version

Script: `csf_gm_xcorr_two_stage_group.m`

## What it does

The lagged cross-correlation between the global BOLD signal (gBOLD) and the CSF
signal is computed in two stages. The point of the two-stage design is that the
**unit of inference is the participant**, not the sleep epoch. Pooling epochs
across participants would let a participant who contributes many epochs dominate
the group result, and would treat epochs from the same person as if they were
independent observations (pseudoreplication).

### Stage 1 — within participant (estimation only)

For each participant, and separately for every sleep epoch:

1. For each lag *L* (−5 to +5 TR, i.e. −12.5 to +12.5 s), the two signals are
   shifted against each other and the Pearson correlation is computed on the
   overlapping window.
2. Each correlation is Fisher *z*-transformed: `z = atanh(r)`.
3. The *z* values are averaged across that participant's epochs, separately at
   each lag.

The result is **one cross-correlation curve per participant**. No statistical
testing happens at this stage — it is purely a data-reduction step that turns a
participant's many epochs into one estimate per lag.

Epochs are combined using inverse-variance weighting: an epoch contributes with
weight *n* − 3, where *n* is the number of overlapping samples. This is the
variance of a Fisher *z* value, so longer and therefore more reliable epochs
count more. Epoch lengths range from 36 to over 900 volumes, so equal weighting
would let very short epochs add a disproportionate amount of noise. Plain
unweighted averaging is available via one config switch.

### Stage 2 — across participants (inference)

1. At each lag, a one-sample *t*-test compares the participants' *z* values
   against zero. The degrees of freedom are therefore (number of participants − 1).
2. Because one test is run at every lag, the *p*-values are corrected across
   lags with the Benjamini–Hochberg false discovery rate (FDR) procedure at
   q = 0.05.
3. For display, the mean *z* is transformed back into a correlation with
   `r = tanh(z)`.

## How the lags are created

The convention is

```
r(L) = corr( gBOLD(t), CSF(t + L) )
```

A **positive lag means the CSF signal is taken later in time**, i.e. CSF follows
gBOLD. A negative lag means CSF leads. This is the same convention as the
existing within-epoch script, so the two analyses are directly comparable.

Shifting is done by trimming, not by padding or wrapping. For a lag of +2 volumes
the gBOLD samples 1…T−2 are paired with the CSF samples 3…T; for a lag of −2 the
reverse. Both windows keep the same length (T − |L|) and stay aligned sample by
sample. Because each correlation is computed inside a single epoch, a lag never
pairs samples across an epoch boundary — the concatenation joins are never
crossed.

### Comparing the figure with Han et al. (2021)

The lag axis in the published figures of Han and colleagues runs in the
**opposite** direction to the convention used here: their plotting script
reverses the curve before drawing it, so a positive lag in their figures
corresponds to a negative lag here. A cross-correlation curve of this shape is
close to antisymmetric, so this reverses which side of the plot carries the
negative peak, even when the underlying result is identical.

The configuration switch `flipLagAxisForDisplay` mirrors the x-axis of the
figure so that it can be placed side by side with the published one. It changes
the plot only: the computation, the values printed to the console and the saved
`.mat` are always in this script's own convention. Figures drawn with the
mirrored axis get the suffix `_HanAxis` in their file name so the two versions
cannot be confused.

The sign-unambiguous check is the correlation between the negative temporal
derivative of the gBOLD signal and the CSF signal. This has a single clear peak
close to zero lag, and it is positive in both the present data and in Han and
colleagues, confirming that the polarity of the CSF signal is the same in both
cases: the CSF signal is high while the global BOLD signal is falling.

## Why the Fisher z-transform

Correlation coefficients are bounded between −1 and +1, so their distribution is
squeezed near the edges and their variance depends on how large the correlation
is. Averaging raw *r* values is therefore slightly biased, and a *t*-test on raw
*r* violates the assumption of constant variance. The Fisher transform
`z = atanh(r)` removes both problems: *z* is approximately normally distributed
with a variance that does not depend on the size of the correlation. All
averaging and testing is done in *z* space, and only the final result is
transformed back to *r* for reporting.

## Why FDR

A separate test is run at each of the 11 lags. If every lag were tested at
p < 0.05 without correction, roughly one lag would be expected to appear
significant by chance alone even if there were no relationship at all. The
Benjamini–Hochberg procedure re-thresholds the *p*-values so that, among the lags
declared significant, only about 5 % are expected to be false positives. It does
not change how the tests are computed, only how they are thresholded.

## Inputs and outputs

Input files are the concatenated stage-segmented signals produced by
`segment_stable_sleep_epochs.m`, one CSF file and one gBOLD file per participant.
The sleep-stage definition is selected with a single switch in the configuration
(`N2`, `N2_N3`, `N1_N2_N3` or `W`), which determines all input and output folders.

Outputs are written to
`SNORE_Plots/Cross_Correlaltion/<stage>/within_epoch/group_level/`:

- a group-level plot showing the mean correlation against lag, a ±1 standard
  error band across participants, and markers on the lags that survive FDR
  correction (file name suffix `_HanAxis` if the axis was mirrored);
- a results `.mat` file containing the per-participant curves, the group means,
  the *t* statistics and the raw and FDR-corrected *p*-values, always in this
  script's own lag convention.

Participants whose CSF or gBOLD file is missing, or whose signal does not yield
a usable correlation, are reported in the console and excluded from the group
analysis.
