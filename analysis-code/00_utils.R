# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(grid)
library(rlang)
library(scales)
library(ggplot2)
library(ggthemes)
library(ggpattern)


# ==============================================================================
# Helper functions -------------------------------------------------------------
# ==============================================================================

prop_wt <- function(.data, .var, .wt) {
  .data |>
    srvyr::as_survey_design(weights = {{ .wt }}) |>
    dplyr::group_by({{ .var }}) |>
    dplyr::summarise(
      p = srvyr::survey_prop(proportion = TRUE)
    )
}

eq_to_one <- function(x) !is.na(x) & x == 1

is_same <- function(x, y) {
  print(
    identical(
      as.numeric(x), as.numeric(y)
    )
  )
}


plot_mirror_histogram <- function(
    ps_df,
    treat_var,
    ps_var,
    wt_var = NULL,
    treat_label = NULL,
    control_label = NULL,
    group_no = NULL,
    bins = 20) {
  if (is.null(treat_label)) {
    treat_label <- "Treated People"
  }

  if (is.null(control_label)) {
    control_label <- "Untreated People"
  }

  if (is.null(bins) || is.na(bins)) {
    bins <- 20
  }

  scale_values <- setNames(
    c("stripe", "none"),
    c(treat_label, control_label)
  )

  grp_title <- paste0("Group: ", group_no)

  gg_obj <- ggplot() +
    geom_histogram_pattern(
      data = dplyr::filter(ps_df, !!parse_expr(treat_var) == 1),
      mapping = aes(
        x = .data[[ps_var]],
        weight = if (!is.null(wt_var)) .data[[wt_var]],
        pattern = treat_label
      ),
      bins = bins,
      color = "black",
      fill = "white",
      pattern_type = "stripe",
      pattern_spacing = 0.03,
      pattern_density = 0.01,
      pattern_fill = "gray20"
    ) +
    geom_histogram_pattern(
      data = dplyr::filter(ps_df, !!parse_expr(treat_var) == 0),
      mapping = aes(
        x = .data[[ps_var]], ,
        y = -after_stat(count),
        weight = if (!is.null(wt_var)) .data[[wt_var]],
        pattern = control_label
      ),
      bins = bins,
      color = "black",
      fill = "white",
      pattern_type = "none"
    ) +
    scale_x_continuous(labels = scales::label_percent()) +
    scale_y_continuous(labels = abs) +
    labs(
      title = grp_title,
      x = "Propensity Score",
      y = "Frequency",
      pattern = NULL
    ) +
    scale_pattern_manual(
      values = scale_values,
      guide = guide_legend(override.aes = list(
        pattern_spacing = 0.01, pattern_density = 0.01
      ))
    ) +
    theme_minimal(base_family = "Times") +
    theme(
      panel.grid.minor = element_blank(),
      legend.position = "top"
    )

  return(gg_obj)
}


# combined function of purrr::safely() and purrr::quietly() from
# https://github.com/tidyverse/purrr/issues/843 by @Maximilian-Stefan-Ernst
safe_and_quietly <- function(fun, ...) {
  safe_fun <- purrr::quietly(purrr::safely(fun))
  out_safe <- safe_fun(...)

  length_zero_to_na <- function(obj) {
    if (length(obj) == 0) {
      return(NA)
    } else {
      return(obj)
    }
  }

  out <-
    list(
      result = list(out_safe$result$result),
      error = out_safe$result$error,
      output = out_safe$output,
      warnings = out_safe$warnings,
      messages = out_safe$messages
    )
  if (!is.null(out$error)) {
    out$error <- conditionMessage(out$error)
  }
  out <- map(out, length_zero_to_na)
  return(out)
}


# is_valid_str <- function(x) {
#   # `> 5` to prevent "NA"
#   !is.null(x) && !is.na(x) && is.character(x) && nchar(trimws(x)) > 5
# }

# copied from: https://felixfan.github.io/formatting-plots-for-pubs/
theme_bw_publish <- function(base_size = 12, base_family = "Helvetica") {
  (
    theme_bw(base_size = base_size, base_family = base_family) +
      theme(
        panel.grid.major = element_line(linewidth = 0.5, color = "grey"),
        axis.line = element_line(linewidth = 0.7, color = "black"),
        legend.position.inside = c(0.85, 0.7),
        text = element_text(size = 14)
      )
  )
}

# copied from:
# https://github.com/koundy/ggplot_theme_Publication/blob/master/ggplot_theme_Publication-2.R
theme_publication <- function(base_size = 14, base_family = "sans") {
  (
    ggthemes::theme_foundation(base_size = base_size, base_family = base_family) +
      theme(
        plot.title = element_text(
          face = "bold", size = rel(1.2),
          hjust = 0.5, margin = margin(0, 0, 20, 0)
        ),
        text = element_text(),
        panel.background = element_rect(colour = NA),
        plot.background = element_rect(colour = NA),
        panel.border = element_rect(colour = NA),
        axis.title = element_text(face = "bold", size = rel(1)),
        axis.title.y = element_text(angle = 90, vjust = 2),
        axis.title.x = element_text(vjust = -0.2),
        axis.text = element_text(),
        axis.line.x = element_line(colour = "black"),
        axis.line.y = element_line(colour = "black"),
        axis.ticks = element_line(),
        panel.grid.major = element_line(colour = "#f0f0f0"),
        panel.grid.minor = element_blank(),
        legend.key = element_rect(colour = NA),
        legend.position = "bottom",
        legend.direction = "horizontal",
        legend.box = "vetical",
        legend.key.size = unit(0.5, "cm"),
        legend.title = element_text(face = "italic"),
        plot.margin = unit(c(10, 5, 5, 5), "mm"),
        strip.background = element_rect(colour = "#f0f0f0", fill = "#f0f0f0"),
        strip.text = element_text(face = "bold")
      ))
}
