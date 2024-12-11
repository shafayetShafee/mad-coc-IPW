# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(tidyr)
library(dplyr)
library(purrr)
library(broom)
library(coxed)
library(ggplot2)
library(tidytext)
library(patchwork)

grps_result_df <- readRDS(here::here("data/groups_result.rds"))

fig_path <- here::here("analysis-figures/")

plot_design <- "
AA
BC
DE
"


# ==============================================================================
# Preparing the K-Means Clustering Variance Elbow plot -------------------------
# ==============================================================================

elbow_plot_gg_obj <- readRDS(here::here("data/elbow_plot_gg_obj.rds"))

ggsave(
  filename = paste0(fig_path, "Figure-1.pdf"),
  plot = elbow_plot_gg_obj,
  width = 6,
  height = 4,
  dpi = 800
)

ggsave(
  filename = paste0(fig_path, "shafayet_khan_shafee_figure_01.eps"),
  plot = elbow_plot_gg_obj,
  device = "eps",
  width = 6,
  height = 4,
  dpi = 800,
  family="Times"
)



# ==============================================================================
# Preparing the Mean prevalence of CoC for different # of K-means Centroid -----
# ==============================================================================

kclust_group_preval_gg_obj <- readRDS(
  here::here("data/kclust_group_preval_gg_obj.rds")
)

ggsave(
  filename = paste0(fig_path, "Figure-2.pdf"),
  plot = kclust_group_preval_gg_obj,
  width = 8,
  height = 4,
  dpi = 800
)

ggsave(
  filename = paste0(fig_path, "shafayet_khan_shafee_figure_02.eps"),
  plot = kclust_group_preval_gg_obj,
  device = "eps",
  width = 8,
  height = 4,
  dpi = 800,
  family="Times"
)


# ==============================================================================
# Preparing the PS mirror histogram plots --------------------------------------
# ==============================================================================

grps_result_df %>%
  arrange(group_no) %>%
  pull(wt_ps_hist) -> wt_ps_hist_list

guide_area() +
  wt_ps_hist_list[[1]] +
  wt_ps_hist_list[[2]] +
  wt_ps_hist_list[[3]] +
  wt_ps_hist_list[[4]] +
  plot_layout(
    guides = "collect",
    axis_titles = "collect",
    design = plot_design,
    heights = c(1, 4.5, 4.5)
  ) &
  guides(
    pattern = guide_legend(
      reverse = TRUE,
      override.aes = list(
        pattern_spacing = 0.01,
        pattern_density = 0.01
      )
    )
  ) &
  theme(
    legend.position = "top",
    legend.text = element_text(face = "plain", size = 12),
    legend.key.spacing.x = unit(5, "mm"),
    legend.key = element_rect(linewidth = 1),
    axis.title = element_text(face = "plain", size = 12),
    axis.title.x = element_text(margin = margin(10)),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 10),
  ) -> wt_ps_hist_plot

ggsave(
  filename = paste0(fig_path, "Figure-3.pdf"),
  plot = wt_ps_hist_plot,
  width = 7,
  height = 5,
  dpi = 800
)

ggsave(
  filename = paste0(fig_path, "shafayet_khan_shafee_figure_03.eps"),
  plot = wt_ps_hist_plot,
  device = "eps",
  width = 7,
  height = 5,
  dpi = 800,
  family="Times"
)


# ==============================================================================
# Preparing the love (Covariance balance) plot ---------------------------------
# ==============================================================================

grps_result_df %>%
  arrange(group_no) %>%
  pull(grp_love_plot) -> grp_love_plot_list

guide_area() +
  grp_love_plot_list[[1]] +
  grp_love_plot_list[[2]] +
  grp_love_plot_list[[3]] +
  grp_love_plot_list[[4]] +
  plot_layout(
    guides = "collect",
    axis_titles = "collect",
    design = plot_design,
    heights = c(1, 4.5, 4.5)
  ) &
  theme(
    text = element_text(family = "Times"),
    plot.title = element_text(hjust = 0),
    legend.position = "top",
    legend.title = element_blank(),
    legend.margin = margin(r = 50),
    legend.key.size = unit(20, units = "pt"),
    legend.text = element_text(size = 12),
    axis.text.y = element_text(size = 10),
    axis.text.x = element_text(size = 10),
    axis.title.x = element_text(
      size = 12,
      margin = margin(t = 10)
    )
  ) -> grp_love_plot

ggsave(
  filename = paste0(fig_path, "Figure-4.pdf"),
  plot = grp_love_plot,
  width = 7,
  height = 6,
  dpi = 800
)

ggsave(
  filename = paste0(fig_path, "shafayet_khan_shafee_figure_04.eps"),
  plot = grp_love_plot,
  device = "eps",
  width = 7,
  height = 6,
  dpi = 800,
  family="Times"
)


# ==============================================================================
# Calculating the overall ATE (Risk Difference) --------------------------------
# ==============================================================================

ate_estimate <- grps_result_df %>%
  summarise(
    ATE = sum(risk_diff_raw * group_wts) / sum(group_wts)
  ) %>%
  pull(ATE)

print(ate_estimate)


# ==============================================================================
# Calculating Bootstrap SE -----------------------------------------------------
# ==============================================================================

boot_ate_estimates <- readRDS(
  here::here("data/boot_ate_estimates_new_1000.rds")
)

bootstrap_df <- tibble(ate_est = boot_ate_estimates)

boot_se <- bootstrap_df %>%
  summarise(
    boot_mean = mean(ate_est),
    boot_se = sd(ate_est)
  )

print(boot_se)


# ==============================================================================
# Calculating Non-param Boot CI ------------------------------------------------
# ==============================================================================

# bias corrected boot CI
bca_ci <- coxed::bca(bootstrap_df$ate_est)

ALPHA <- 0.05

est_ci_table <- tibble(
  ate_est = ate_estimate,
  lower = quantile(bootstrap_df$ate_est, ALPHA / 2),
  upper = quantile(bootstrap_df$ate_est, 1 - (ALPHA / 2)),
  bca_lower = bca_ci[1],
  bca_upper = bca_ci[2],
) %>%
  bind_cols(boot_se)

est_ci_table

saveRDS(est_ci_table, here::here("data/est_ci_table.rds"))


# ==============================================================================
# Preparing the Bootstrapped ATE Density plot ----------------------------------
# ==============================================================================

boot_est_hist <-
  bootstrap_df %>%
  ggplot(aes(ate_est)) +
  geom_density(fill = "grey95", color = "black") +
  geom_vline(xintercept = 0, color = "red", linetype = "dotted", linewidth = 1) +
  geom_vline(
    xintercept = as.numeric(est_ci_table["bca_lower"]),
    color = "blue", linetype = "longdash", linewidth = 0.8
  ) +
  geom_vline(
    xintercept = as.numeric(est_ci_table["bca_upper"]),
    color = "blue", linetype = "longdash", linewidth = 0.8
  ) +
  labs(
    x = "ATE",
    y = "Density"
  ) +
  theme_bw(base_family = "Times") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_blank(),
    axis.text = element_text(size = 10),
    axis.title.y = element_text(size = 12),
    axis.title.x = element_text(
      margin = margin(t = 10),
      size = 12
      )
  )

print(boot_est_hist)

ggsave(
  filename = paste0(fig_path, "Figure-5.pdf"),
  plot = boot_est_hist,
  width = 5,
  height = 4,
  dpi = 800
)

ggsave(
  filename = paste0(fig_path, "shafayet_khan_shafee_figure_05.eps"),
  plot = boot_est_hist,
  device = "eps",
  width = 5,
  height = 4,
  dpi = 800,
  family="Times"
)

# ==============================================================================
# SUPPLEMENTARY ----------------------------------------------------------------
# ==============================================================================

grps_result_df %>%
  arrange(group_no) %>%
  pull(unwt_ps_hist) -> unwt_ps_hist_list

unwt_hist_comb_plot <-
  guide_area() +
    unwt_ps_hist_list[[1]] +
    unwt_ps_hist_list[[2]] +
    unwt_ps_hist_list[[3]] +
    unwt_ps_hist_list[[4]] +
    plot_layout(
      guides = "collect",
      axis_titles = "collect",
      design = plot_design,
      heights = c(1, 4.5, 4.5)
    ) &
    theme(
      legend.position = "top"
    )

print(unwt_hist_comb_plot)
