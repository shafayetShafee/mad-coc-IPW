# Reproducibility Materials

[![R version](https://img.shields.io/badge/R-4.4.1-blue.svg)](https://cran.r-project.org/)
[![Reproducible Environment: renv](https://img.shields.io/badge/reproducible%20environment-renv-lightgreen.svg)](https://rstudio.github.io/renv/)
[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-orange.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Formatted with air v0.7.1](https://img.shields.io/badge/formatted%20with-air%200.7.1-purple)](https://github.com/posit-dev/air)
[![Docker Image](https://img.shields.io/badge/docker-ghcr.io/shafayetshafee/mad--coc--ipw-blue?logo=docker)](https://ghcr.io/shafayetshafee/mad-coc-ipw)

This repository contains the data and analysis code associated with the manuscript:

> Shafee SK, Sium MNI, Sarker B, Islam R (2025) Investigating the causal effect of maternal 
continuum of care on child’s minimum acceptable diet: A multilevel approach using partially 
pooled propensity score weighting. PLOS One, 20(10): e0335972. https://doi.org/10.1371/journal.pone.0335972


## Directory Structure

```yaml
analysis-code/        # Scripts used to prepare data and run the analysis
analysis-figures/     # Final figures used in the manuscript
data/                 # Processed analysis datasets and stored outputs
mics_raw_data/        # Information on acquiring raw MICS data (not included here)
renv/ and renv.lock   # Reproducible R environment setup
mad-coc-IPW.Rproj     # R project file
LICENSE.md            # License
```

**Note:** Raw MICS data required for steps 01–02 is not included. Instructions are
provided in [`mics_raw_data/README.md`](mics_raw_data/README.md).


## Analysis-code files descriptions

```yaml
analysis-code/
  00_utils.R                      # Helper functions
  01_data_merging.R               # Merge and initial processing
  02_analysis_data_preparing.R    # Final analysis dataset creation
  03_effect_estimation_function.R # Effect estimation function
  04_effect_estimation.R          # Effect estimation
  05_Bootstrap_SE_estimation.R    # Bootstrap standard errors
  06_prepare_results.R            # Result summaries and tables
  07_sensitivity_analysis.R       # Sensitivity analyses
```

## Steps to reproduce the study findings


