## =========================================================================
#  CSF-gBOLD coupling across vigilance states: linear mixed-effects model
#  -------------------------------------------------------------------------
#  Input : coupling_long.csv   (written by export_lmm_long.m)
#  Model : z ~ stage + (1 | subject), fitted at one lag
#
#  Run section by section. Output also goes to lmm_output.txt.
#  If you abort partway and the console goes quiet, run  sink()  once.
## =========================================================================

# install.packages(c("lme4", "lmerTest", "emmeans", "pbkrtest"))
library(lmerTest)    # loads lme4 and adds p-values to it
library(emmeans)
library(pbkrtest)    # needed for Kenward-Roger

set.seed(1)          # the mvt contrast adjustment samples


## 1. Paths, settings, log ------------------------------------------------

csv    <- "/Users/Richard/Masterabeit_local/SNORE_Plots/Cross_Correlaltion/lmm/coupling_long.csv"
outDir <- dirname(csv)
LAG         <- -5.0            # primary lag, matches the paired NREM-vs-W test
LAG_COMPARE <- c(-7.5, -2.5)   # neighbours, for the sensitivity check in section 9

sink(file.path(outDir, "lmm_output.txt"), split = TRUE)


## 2. Read ----------------------------------------------------------------

d <- read.csv(csv)
d$subject <- factor(d$subject)
d$stage   <- factor(d$stage, levels = c("W", "N1", "N2", "N3"))   # W = reference

stopifnot(!any(is.na(d$z)))
cat("GM pipeline:", unique(d$gm_pipeline), "\n")
cat("weighting  :", unique(d$weighting), "\n")
cat("rows       :", nrow(d), "\n\n")


## 3. The analysis slice --------------------------------------------------
#  One row per participant x stage. There is no replication inside a cell,
#  so a random intercept is the only random effect the data can support.

dL <- subset(d, lag_s == LAG)
cat(sprintf("lag %+.1f s: %d rows, %d participants\n\n",
            LAG, nrow(dL), nlevels(dL$subject)))


## 4. Descriptives and missing cells --------------------------------------
#  N3 is missing in the participants who never reached N3. The model handles
#  the unbalance; it does not make those participants comparable.

print(data.frame(n       = tapply(dL$z,       dL$stage, length),
                 minutes = round(tapply(dL$minutes, dL$stage, sum)),
                 mean_r  = round(tapply(dL$r,       dL$stage, mean), 3)))

print(table(dL$subject, dL$stage))     # 0 marks a missing cell


## 5. Primary model -------------------------------------------------------

m <- lmer(z ~ stage + (1 | subject), data = dL)

print(anova(m, ddf = "Kenward-Roger"))
print(summary(m, ddf = "Kenward-Roger"))

v <- as.data.frame(VarCorr(m))
cat("\nICC:", round(v$vcov[1] / sum(v$vcov), 3), "\n\n")


## 6. Planned contrasts ---------------------------------------------------
#  Three stages against wake, plus N2 against N3: the descending limb of the
#  inverted U, which the W comparisons alone cannot show. Coefficients are in
#  level order W, N1, N2, N3. One family, one mvt adjustment over all four.

em  <- emmeans(m, ~ stage, lmer.df = "kenward-roger")
ctr <- contrast(em, list("N1 - W"  = c(-1, 1, 0,  0),
                         "N2 - W"  = c(-1, 0, 1,  0),
                         "N3 - W"  = c(-1, 0, 0,  1),
                         "N2 - N3" = c( 0, 0, 1, -1)),
                adjust = "mvt")

print(em)
print(summary(ctr, infer = TRUE))      # more negative = stronger coupling


## 7. Non-linearity across depth ------------------------------------------
#  Orthogonal trends over W < N1 < N2 < N3. Polynomial contrasts assume
#  equally spaced levels, so a significant quadratic means "inverted U across
#  the ordered sequence", not a curve on a metric axis.

ctr_poly <- contrast(em, "poly", adjust = "none")
print(ctr_poly)


## 8. Sensitivity: inverse-variance weights -------------------------------
#  var(z) ~ 1/(n - 3), rescaled to mean 1. The raw counts sum to ~48000 and
#  Kenward-Roger would read that as the information in the data, returning
#  denominator df in the millions. Rescaling changes no point estimate.

dL$w <- (dL$n_volumes - 3) / mean(dL$n_volumes - 3)
m_w  <- lmer(z ~ stage + (1 | subject), data = dL, weights = w)
em_w <- emmeans(m_w, ~ stage, lmer.df = "kenward-roger")

print(anova(m_w, ddf = "Kenward-Roger"))
print(em_w)
print(contrast(em_w, list("N1 - W"  = c(-1, 1, 0,  0),
                          "N2 - W"  = c(-1, 0, 1,  0),
                          "N3 - W"  = c(-1, 0, 0,  1),
                          "N2 - N3" = c( 0, 0, 1, -1)),
               adjust = "mvt"))


## 9. Sensitivity: neighbouring lags --------------------------------------

for (L in sort(c(LAG, LAG_COMPARE))) {
  dd <- subset(d, lag_s == L)
  mm <- lmer(z ~ stage + (1 | subject), data = dd)
  a  <- anova(mm, ddf = "Kenward-Roger")
  q  <- summary(contrast(emmeans(mm, ~ stage, lmer.df = "kenward-roger"),
                         "poly", adjust = "none"))
  cat(sprintf("lag %+5.1f s   stage F = %5.2f, p = %.1e   quadratic p = %.1e\n",
              L, a$`F value`, a$`Pr(>F)`, q$p.value[q$contrast == "quadratic"]))
}
cat("\n")


## 10. Diagnostics --------------------------------------------------------
#  The model assumes one residual variance for all four stages.

par(mfrow = c(1, 2))
plot(fitted(m), resid(m), xlab = "fitted", ylab = "residual"); abline(h = 0, lty = 2)
qqnorm(resid(m)); qqline(resid(m))
par(mfrow = c(1, 1))

print(round(tapply(resid(m), dL$stage, sd), 3))
print(shapiro.test(resid(m)))


## 11. Write and close ----------------------------------------------------

write.csv(as.data.frame(em),       file.path(outDir, "emmeans.csv"),        row.names = FALSE)
write.csv(as.data.frame(ctr),      file.path(outDir, "contrasts_planned.csv"), row.names = FALSE)
write.csv(as.data.frame(ctr_poly), file.path(outDir, "contrasts_poly.csv"), row.names = FALSE)

sink()
