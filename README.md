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


## Directories & files descriptions

```yaml
├── Dockerfile              # Docker image build configuration
├── docker-compose.yml      # Compose setup for running the project
├── docker-compose-dev.yml  # Development compose setup
├── create_rprofile.sh      # Script to configure .Rprofile inside container

├── analysis-code/          # Reproducible analysis pipeline scripts
├── analysis-figures/       # Final manuscript-ready figures
├── data/                   # Processed datasets and analysis outputs
├── devs/                   # Developer utilities (e.g., lockfile system deps)

├── mics_raw_data/          # Instructions for obtaining raw MICS data (not included)

├── renv/                   # Project-local package library (managed by renv)
└── renv.lock               # Exact package versions for reproducibility

├── LICENSE.md              # License (CC BY 4.0)
├── README.md               # Project documentation
└── mad-coc-IPW.Rproj       # RStudio project file
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

There are two ways to reproduce the analysis:

1. Using [`renv`](https://rstudio.github.io/renv/articles/renv.html) [local installation]

2. Using [Docker Image](https://www.docker.com/) [recommended]


### Method 1 — Using renv (Local Setup)

**Prerequisites:**

- [Git](https://git-scm.com/)
- [R](https://www.r-project.org/) (version 4.4.1 recommended)
- [RStudio](https://posit.co/downloads/)

**Steps**

1. Clone the repository
   ```bash
   git clone https://github.com/shafayetShafee/mad-coc-IPW.git
   ```

2. Enter the project directory
   ```bash
   cd mad-coc-IPW/
   ```
  
3. Open the project in RStudio by clicking the file `mad-coc-IPW.Rproj`.

4. When the project loads, renv will automatically activate and install all
required packages. This may take a few minutes on first run.

5. After installation completes, you can re-run the analysis scripts located in:
`analysis-code/`

**Note on Reproducibility with `renv`:**

This project was originally developed using R version `4.4.1`. If your system uses 
a different R version, some packages may fail to install or behave differently. Therefore, 
this method may not guarantee fully reproducible results. If exact reproducibility 
is required, please use the Docker method below.


### Method 2 — Using Docker (Recommended)

**Prerequisite:** Docker installed on your system.

**Steps:**

1. Pull the pre-built image
   ```bash
   docker pull ghcr.io/shafayetshafee/mad-coc-ipw:1.0.0
   ```
   
2. Run the container either with `docker` command.
   ```bash
   docker run -d -p 8787:8787 ghcr.io/shafayetshafee/mad-coc-ipw:1.0.0
   ```

3. Open your web browser and go to: `http://localhost:8787`

4. This will open an RStudio Server session with all project dependencies already 
installed and the project pre-loaded. You can directly run the analysis scripts inside 
the container.
