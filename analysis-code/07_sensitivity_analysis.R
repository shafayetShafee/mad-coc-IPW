# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(dplyr)
library(purrr)

sensitivity_data <- readRDS(here::here("data/analysis_df.rds"))

formula <- coc ~
  helevel +
    welevel +
    wealth_index +
    db2 +
    cm11_cat_fct +
    WB4 +
    ever_used_media +
    place_of_res

ps_model <- glm(
  formula = formula,
  data = sensitivity_data,
  weights = chweight,
  family = "binomial"
)

# ==============================================================================
# Generate Propensity Scores ---------------------------------------------------
# ==============================================================================
sensitivity_data <- sensitivity_data %>%
  mutate(
    ps = predict(ps_model, type = "response"),
    wt = ifelse(coc == 1, 1 / ps, 1 / (1 - ps)),
    wts = chweight * wt
  )

q0 <- weighted.mean(
  sensitivity_data$mad[sensitivity_data$coc == 0],
  w2 = sensitivity_data$w2[sensitivity_data$coc == 0]
)

q1 <- weighted.mean(
  sensitivity_data$mad[sensitivity_data$coc == 1],
  w2 = sensitivity_data$w2[sensitivity_data$coc == 1]
)


# ==============================================================================
# Fit Outcome Model ------------------------------------------------------------
# ==============================================================================
outcome_formula <- mad ~
  coc +
    place_of_res +
    helevel +
    welevel +
    wealth_index +
    cm11_cat_fct +
    db2 +
    WB4 +
    ever_used_media

fitY <- glm(
  formula = outcome_formula,
  family = binomial,
  data = sensitivity_data,
  weights = chweight
)

sense_data_0 <- sensitivity_data %>% mutate(coc = 0)
sense_data_1 <- sensitivity_data %>% mutate(coc = 1)

# ==============================================================================
# Predictions ------------------------------------------------------------------
# ==============================================================================

predY0 <- predict(fitY, newdata = sense_data_0, type = "response")
predY1 <- predict(fitY, newdata = sense_data_1, type = "response")

# ==============================================================================
# Bounds for K_1 and K_0 -------------------------------------------------------
# ==============================================================================
pred <- sensitivity_data$ps
K0min <- max(1 - pred)
K0max <- min(1 - pred + pred / predY0)
K1min <- max(pred)
K1max <- min(pred + (1 - pred) / predY1)

RRmin <- K1min / K0max * (q1 / q0)
RRmax <- K1max / K0min * (q1 / q0)
