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

source(here::here("R/ANALYSIS/00_utils.R"))


# ==============================================================================
# Creating the Execution Function ----------------------------------------------
# ==============================================================================

calculate_grp_results <- function(
    grp_df,
    group_no,
    ps_model_formula,
    out_var = "mad",
    treat_var = "coc",
    ranef_var = "HH7A_ch",
    sampling_wts_var = "chweight",
    ps_hist_treat_label = "Received CoC",
    ps_hist_control_label = "Did not receive CoC",
    ps_hist_bins = 15,
    bal_tab_var_names = NULL,
    bootstrap_run = FALSE) {
  ps_model_vars <- base::all.vars(ps_model_formula)
  confounders <- setdiff(ps_model_vars, c(treat_var, ranef_var))

  grp_df <- grp_df %>% mutate(ones = 1)

  ps_model_wemix <- mix(
    formula = ps_model_formula,
    weights = c(sampling_wts_var, "ones"),
    data = grp_df,
    family = binomial("logit")
  )

  grp_ps_df <- grp_df %>%
    mutate(
      ps = predict(ps_model_wemix, type = "response"),
      wts = !!parse_expr(treat_var) / ps + ((1 - !!parse_expr(treat_var)) / (1 - ps)),
      chwts = !!parse_expr(sampling_wts_var) * wts
    )

  ps_formula_fixed_part <- as.formula(
    paste0(treat_var, " ~ ", paste0(confounders, collapse = " + "))
  )

  p1_raw <- grp_ps_df %>%
    filter(!!parse_expr(treat_var) == 1) %>%
    summarise(
      p1 = sum(chwts * !!parse_expr(out_var)) / sum(chwts)
    ) %>%
    pull(p1)

  p0_raw <- grp_ps_df %>%
    filter(!!parse_expr(treat_var) == 0) %>%
    summarise(
      p0 = sum(chwts * !!parse_expr(out_var)) / sum(chwts)
    ) %>%
    pull(p0)

  risk_diff_raw <- p1_raw - p0_raw
  or_raw <- (p1_raw / (1 - p1_raw)) / (p0_raw / (1 - p0_raw))
  group_wts <- sum(grp_ps_df$chwts)

  # DO NOT GENERATE THE TABLES AND PLOTS WHEN USING FOR BOOTSTRAP DATA.
  if (!bootstrap_run) {
    unwt_tableone <- tableone::CreateTableOne(
      vars = confounders,
      factorVars = c(out_var),
      strata = c(treat_var),
      data = grp_df,
      test = FALSE
    )

    unwt_ps_hist_plot <- plot_mirror_histogram(
      grp_ps_df,
      treat_var = treat_var,
      ps_var = "ps",
      treat_label = ps_hist_treat_label,
      control_label = ps_hist_control_label,
      group_no = group_no,
      bins = ps_hist_bins
    )

    wt_ps_hist_plot <- plot_mirror_histogram(
      grp_ps_df,
      treat_var = treat_var,
      ps_var = "ps",
      wt_var = "chwts",
      treat_label = ps_hist_treat_label,
      control_label = ps_hist_control_label,
      group_no = group_no,
      bins = ps_hist_bins
    )

    group_bal_tab <- bal.tab(
      ps_formula_fixed_part,
      data = grp_ps_df,
      weights = grp_ps_df$wts,
      s.weights = grp_ps_df[[sampling_wts_var]],
      s.d.denom = "pooled",
      un = TRUE,
      abs = TRUE
    )

    group_love_plot <- love.plot(
      group_bal_tab,
      line = TRUE,
      colors = c("red", "blue"),
      shapes = c("triangle filled", "circle filled"),
      size = 2,
      stars = "std",
      sample.names = c("Unweighted", "Weighted"),
      var.names = bal_tab_var_names,
      title = paste0("Group: ", group_no)
    ) +
      geom_vline(xintercept = 0.1, linetype = 2)

    message(paste0("Completed all calculations for Group", group_no))

    # Return this when `bootstrap_run` is FALSE
    return(
      tibble(
        unwt_tableone = list(unwt_tableone),
        unwt_ps_hist = list(unwt_ps_hist_plot),
        wt_ps_hist = list(wt_ps_hist_plot),
        grp_bal_tab = list(group_bal_tab),
        grp_love_plot = list(group_love_plot),
        p1_raw = p1_raw,
        p0_raw = p0_raw,
        risk_diff_raw = risk_diff_raw,
        or_raw = or_raw,
        group_wts = group_wts,
        grp_ps_df = list(grp_ps_df),
        group_no = group_no
      )
    )
  }

  # Return this when `bootstrap_run` is TRUE
  return(
    tibble(
      p1_raw = p1_raw,
      p0_raw = p0_raw,
      risk_diff_raw = risk_diff_raw,
      group_wts = group_wts,
      group_no = group_no
    )
  )
}
