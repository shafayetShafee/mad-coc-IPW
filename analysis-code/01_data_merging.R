# ==============================================================================
# Loading Libraries ------------------------------------------------------------
# ==============================================================================

library(dplyr)       # version 1.1.4
library(sjlabelled)  # version 1.2.0


# ==============================================================================
# Reading the MICS Survey data -------------------------------------------------
# ==============================================================================

ch_data <- sjlabelled::read_spss(here::here("mics_raw_data/ch.sav"))
wm_data <- sjlabelled::read_spss(here::here("mics_raw_data/wm.sav"))
hh_data <- sjlabelled::read_spss(here::here("mics_raw_data/hh.sav"))


# ==============================================================================
# Processing data for joining --------------------------------------------------
# ==============================================================================

ch_data %>%
  arrange(UF1, UF2, UF4, CAGE) %>%
  group_by(UF1, UF2, UF4) %>%
  mutate(young_child_order = row_number()) %>%
  ungroup() %>%
  filter(young_child_order == 1) -> youngest_ch_df

hh_data %>%
  select(HH1, HH2, helevel, HH48, HHSEX) -> hh_data_filtered


# ==============================================================================
# Joining the data -------------------------------------------------------------
# ==============================================================================

joined <- wm_data %>%
  inner_join(
    youngest_ch_df,
    by = join_by(HH1, HH2, WM3 == UF4),
    suffix = c("_wm", "_ch")
  ) %>%
  filter(CM17 == 1 & between(CAGE, 6, 23)) %>%
  left_join(
    hh_data_filtered,
    by = join_by(HH1, HH2)
  )
# only keeping child aged between 6 to 23 months and
# mother with live birth in the last two year.

saveRDS(joined, file = here::here("data/joined.rds"))
