# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(dplyr)
library(purrr)
library(tidyr)
library(cobalt)
library(ggplot2)
library(WeMix)
library(broom.mixed)

source(here::here("analysis-code/03_effect_estimation_function.R"))

analysis_df <- readRDS(here::here("data/analysis_df.rds"))


# ==============================================================================
# Calculating Group Specific Effect Estimate -----------------------------------
# ==============================================================================

analysis_df_grouped <- analysis_df %>%
  group_by(groups) %>%
  nest()

full_formula_ps <- coc ~
  helevel +
    welevel +
    wealth_index +
    db2 +
    cm11_cat_fct +
    WB4 +
    ever_used_media +
    place_of_res +
    (1 | HH7A_ch)

love_plot_var_names <- c(
  helevel = "HHE: >= Secondary",
  welevel = "ME: >= Secondary",
  wealth_index_poor = "WI: Poor",
  wealth_index_middle = "WI: Middle",
  wealth_index_rich = "WI: Rich",
  db2 = "Wanted Last Child",
  cm11_cat_fct_1 = "CEB: 1",
  cm11_cat_fct_2 = "CEB: 2",
  `cm11_cat_fct_3+` = "CEB: 3+",
  `WB4` = "Mother's Age",
  ever_used_media = "Ever Used Media",
  place_of_res_Rural = "Place of Residence"
)


# ==============================================================================
# Collect the Group Specific plots, tables and Estimates -----------------------
# ==============================================================================

tictoc::tic()
res <- map2_dfr(
  .x = analysis_df_grouped$data,
  .y = analysis_df_grouped$groups,
  .f = ~ calculate_grp_results(
    grp_df = .x,
    group_no = .y,
    ps_model_formula = full_formula_ps,
    out_var = "mad",
    treat_var = "coc",
    ranef_var = "HH7A_ch",
    sampling_wts_var = "chweight",
    ps_hist_treat_label = "Received CoC",
    ps_hist_control_label = "Did not receive CoC",
    ps_hist_bins = 15,
    bal_tab_var_names = love_plot_var_names,
    bootstrap_run = FALSE
  )
)
tictoc::toc()

saveRDS(res, file = here::here("data/groups_result.rds"))

# ==============================================================================
# Calculating the overall ATE (Risk Difference) --------------------------------
# ==============================================================================

ate_estimate <- res %>%
  summarise(
    ATE = sum(risk_ratio_raw * group_wts) / sum(group_wts)
  ) %>%
  pull(ATE)

print(ate_estimate)
