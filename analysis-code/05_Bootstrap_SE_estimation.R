# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(dplyr)
library(purrr)

source(here::here("R/ANALYSIS/03_effect_estimation_function.R"))
analysis_df <- readRDS(here::here("data/analysis_df.rds"))


# ==============================================================================
# Calculating SE using Bootstrap -----------------------------------------------
# ==============================================================================

full_formula_ps <- coc ~ helevel + welevel + wealth_index + db2 + cm11_cat_fct +
  WB4 + ever_used_media + place_of_res + (1 | HH7A_ch)

unique_clusters <- unique(analysis_df$HH1)

SEED <- 234
BOOT_ITER <- 2000
set.seed(SEED)


boot_results <- map_dfr(1:BOOT_ITER, ~ {
  # Sample clusters with replacement
  sampled_clusters <- sample(
    unique_clusters, length(unique_clusters),
    replace = TRUE
  )

  # creating resampled data
  resamp_df <- map_dfr(sampled_clusters, ~ {
    analysis_df %>% filter(HH1 == .x)
  })

  coc_prop_df <- resamp_df %>%
    group_by(HH7A_ch) %>%
    summarize(
      coc_prop = mean(coc)
    )

  g4_kmeans <- kmeans(coc_prop_df$coc_prop, centers = 4)

  g4_kmeans_df <- augment(g4_kmeans, coc_prop_df) %>%
    rename("groups" = .cluster)

  resamp_df <- resamp_df %>%
    select(-groups) %>%
    left_join(g4_kmeans_df, by = join_by(HH7A_ch))

  resamp_df_grouped <- resamp_df %>%
    group_by(groups) %>%
    nest()

  res <- map2_dfr(
    .x = resamp_df_grouped$data,
    .y = resamp_df_grouped$groups,
    .f = ~ safe_and_quietly(
      fun = calculate_grp_results,
      grp_df = .x,
      group_no = .y,
      ps_model_formula = full_formula_ps,
      out_var = "mad",
      treat_var = "coc",
      ranef_var = "HH7A_ch",
      sampling_wts_var = "chweight",
      bootstrap_run = TRUE
    )
  )

  # extraction ---------------------------------
  res_result <- res$result
  res_messages <- res$messages
  res_warnings <- res$warnings
  res_error <- res$error

  # account for error -------------------------
  msg_prob_detected <- any(!is.na(res_messages))
  warning_detected <- any(!is.na(res_warnings))
  error_detected <- any(!is.na(res_error))

  if (msg_prob_detected) {
    message(paste0(res_messages, collapse = "\n"))
  }

  if (warning_detected) {
    message(paste0(res_warnings, collapse = "\n"))
  }

  if (error_detected) {
    message(paste0(res_error, collapse = "\n"))
    return(
      tibble(
        resamp_res_data = list(resamp_df_grouped),
        ate_est = NA
      )
    )
  } else {
    resamp_res <- bind_rows(res_result)

    ate_estimate <- resamp_res %>%
      summarise(
        ATE = sum(risk_diff_raw * group_wts) / sum(group_wts)
      ) %>%
      pull(ATE)

    message(paste0("Completed Bootstrap Iteration: ", .x))

    return(
      tibble(
        resamp_res_data = list(resamp_res),
        ate_est = ate_estimate
      )
    )
  }
})


# ==============================================================================
# Preparing and storing the bootstrapped results -------------------------------
# ==============================================================================

boot_ate_estimates <- boot_results %>%
  filter(!is.na(ate_est)) %>%
  slice(1:1000) %>%
  pull(ate_est)

saveRDS(boot_results, here::here("data/boot_ate_estimates.rds"))
