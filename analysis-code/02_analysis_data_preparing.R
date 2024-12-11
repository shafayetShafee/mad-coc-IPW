# ==============================================================================
# Setups -----------------------------------------------------------------------
# ==============================================================================

library(dplyr)
library(purrr)
library(tidyr)
library(broom)
library(naniar)
library(janitor)
library(forcats)
library(ggplot2)
library(tidytext)
library(tableone)
library(sjlabelled)

source(here::here("analysis-code/00_utils.R"))
SEED <- 234

# Reading the Joined data
joined_df <- readRDS(here::here("data/joined.rds"))


# ==============================================================================
# Calculating the MAD and CoC Variable -----------------------------------------
# ==============================================================================

mad_coc_df <- joined_df %>%
  mutate(
    # MDD calculation --------------
    egg = eq_to_one(BD8K),
    legumes = eq_to_one(BD8M),
    other_fruit = eq_to_one(BD8H),
    still_breastfed = eq_to_one(BD3),
    vit_a = eq_to_one(BD8D) | eq_to_one(BD8F) | eq_to_one(BD8G),
    grain = eq_to_one(BD8B) | eq_to_one(BD8C) | eq_to_one(BD8E),
    flesh = eq_to_one(BD8I) | eq_to_one(BD8J) | eq_to_one(BD8L),
    dairy = eq_to_one(BD7D) | eq_to_one(BD7E) | eq_to_one(BD8A) | eq_to_one(BD8N),
    mdd = (still_breastfed + grain + flesh + dairy + egg + vit_a +
      legumes + other_fruit) >= 5,

    # MMF calculation --------------
    BD7E1 = if_else(BD7E1 == 8 | is.na(BD7E1), 0, as.numeric(as.character(BD7E1))),
    BD7D1 = if_else(BD7D1 %in% c(8, 9) | is.na(BD7D1), 0, as.numeric(as.character(BD7D1))),
    BD8A1 = if_else(BD8A1 == 8 | is.na(BD8A1), 0, as.numeric(as.character(BD8A1))),
    BD9 = if_else(BD9 %in% c(8, 9) | is.na(BD9), 0, as.numeric(as.character(BD9))),
    milkfeeds = BD7E1 + BD7D1 + BD8A1,
    mmf = case_when(
      still_breastfed == 1 & CAGE >= 6 & CAGE <= 8 ~ BD9 >= 2,
      still_breastfed == 1 & CAGE >= 9 & CAGE <= 23 ~ BD9 >= 3,
      still_breastfed == 0 ~ (BD9 + milkfeeds) >= 4 & BD9 >= 1,
      TRUE ~ 0
    ),

    # MAD calculation --------------
    mad = case_when(
      still_breastfed == 1 ~ (mdd == 1 & mmf == 1),
      still_breastfed == 0 ~ (mdd == 1 & mmf == 1 & milkfeeds >= 2),
      TRUE ~ 0
    ),

    # PNC calculation -------------
    pnc_mother = case_when(
      PN22U == 1 ~ 1,
      PN22U == 2 & PN22N == 1 ~ 1, # within 2 days
      PN19 == 1 ~ 1,
      PN9 == 1 ~ 1,
      PN5 == 1 ~ 1,
      PN23X == "X" | PN23H == "H" | PN23I == "I" ~ 0,
      TRUE ~ 0
    ),
    PN23A_1 = if_else(PN23A == "A", 1, 0),
    PN23B_1 = if_else(PN23B == "B", 1, 0),
    PN23C_1 = if_else(PN23C == "C", 1, 0),
    PN23D_1 = if_else(PN23D == "D", 1, 0),
    PN23E_1 = if_else(PN23E == "E", 1, 0),
    pnc_provider = case_when(
      PN23A_1 == 1 | PN23B_1 == 1 | PN23C_1 == 1 | PN23D_1 == 1 | PN23E_1 == 1 ~ 1,
      TRUE ~ 0
    ),
    pnc_mtp = pnc_mother & pnc_provider,
    pnc_child = case_when(
      PN13U == 1 ~ 1,
      PN13U == 2 & PN13N == 1 ~ 1, # within 2 days
      PN11 == 1 ~ 1,
      PN8 == 1 ~ 1,
      PN4 == 1 ~ 1,
      PN14X == "X" | PN14H == "H" | PN14I == "I" ~ 0,
      TRUE ~ 0
    ),
    pnc_both = pnc_mother & pnc_child,
    pnc_mtp_both = pnc_mtp & pnc_child,

    # SBA calculation -------------
    MN19A_1 = if_else(MN19A == "A", 1, 0),
    MN19B_1 = if_else(MN19B == "B", 1, 0),
    MN19C_1 = if_else(MN19C == "C", 1, 0),
    MN19D_1 = if_else(MN19D == "D", 1, 0),
    MN19E_1 = if_else(MN19E == "E", 1, 0),
    sba = case_when(
      MN19A_1 == 1 | MN19B_1 == 1 | MN19C_1 == 1 | MN19D_1 == 1 | MN19E_1 == 1 ~ 1,
      TRUE ~ 0
    ),

    # ANC calculation -------------
    MN3A_1 = if_else(MN3A == "A", 1, 0),
    MN3B_1 = if_else(MN3B == "B", 1, 0),
    MN3C_1 = if_else(MN3C == "C", 1, 0),
    MN3D_1 = if_else(MN3D == "D", 1, 0),
    MN3E_1 = if_else(MN3E == "E", 1, 0),
    MN3F_1 = if_else(MN3F == "F", 1, 0),
    anc_mt = case_when(
      MN3A_1 == 1 | MN3B_1 == 1 | MN3C_1 == 1 | MN3D_1 == 1 | MN3E_1 == 1 ~ 1,
      TRUE ~ 0
    ),
    anc4 = case_when(
      MN5 <= 3 | MN2 == 2 ~ 0,
      MN5 >= 4 & MN2 != 9 ~ 1,
      TRUE ~ 0
    ),
    anc4_mt = anc_mt & anc4,

    # CoC calculations -------------
    coc_level = pnc_mother + sba + anc4_mt,
    coc = coc_level == 3
  )


# ==============================================================================
# Checking the Prevalence of CoC over Districts --------------------------------
# ==============================================================================

mad_coc_df %>%
  group_by(HH7A_ch) %>%
  dplyr::summarize(
    coc_prop = mean(coc)
  ) %>%
  ggplot(aes(forcats::fct_reorder(HH7A_ch, coc_prop), coc_prop)) +
  geom_col(color = "grey20", fill = "white") +
  labs(
    x = "District", y = "Propotion of CoC"
  ) +
  theme_publication(base_family = "Times") +
  theme(
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 90, size = 12, vjust = 0.5),
    axis.text.y = element_text(size = 18),
    axis.title = element_text(size = 24, face = "plain")
  )


# ==============================================================================
# Calculating the Covariates ---------------------------------------------------
# ==============================================================================

mad_coc_df_cleaned <- mad_coc_df %>%
  mutate(
    db2 = fct_recode(DB2, `0` = "2", `0` = "9"),
    mt1 = fct_recode(MT1, `0` = "9"),
    mt2 = fct_recode(MT2, `0` = "9"),
    mt3 = fct_recode(MT3, `0` = "9"),
    welevel = fct_recode(
      welevel,
      `0` = "0", `0` = "1", `1` = "2", `1` = "3"
    ),
    helevel = fct_recode(
      helevel,
      `0` = "0", `0` = "1", `1` = "2", `1` = "3", `0` = "9"
    ),
    place_of_res = factor(
      HH6_wm,
      levels = c(1, 2),
      labels = c("Urban", "Rural")
    ),
    wealth_index = factor(
      windex5_wm,
      levels = c(1, 2, 3, 4, 5),
      labels = c("Poorest", "Second", "Middle", "Fourth", "Richest")
    ),
    wealth_index = fct_recode(
      wealth_index,
      "poor" = "Poorest", "poor" = "Second", "middle" = "Middle",
      "rich" = "Fourth", "rich" = "Richest"
    ),
    cm11_cat = case_when(
      CM11 == 1 ~ "1",
      CM11 == 2 ~ "2",
      CM11 >= 3 ~ "3+"
    ),
    cm11_cat_fct = factor(cm11_cat, levels = c("1", "2", "3+")),
    wm_age_cat = case_when(
      WB4 >= 15 & WB4 <= 24 ~ "Younger (15-24)",
      WB4 >= 25 & WB4 <= 49 ~ "Older (25-49)",
      TRUE ~ NA_character_
    ),
    wm_age_cat_fct = factor(
      wm_age_cat,
      levels = c("Younger (15-24)", "Older (25-49)")
    ),
    mt1_num = as.numeric(as.character(MT1)),
    mt2_num = as.numeric(as.character(MT2)),
    mt3_num = as.numeric(as.character(MT3)),
    ever_used_media = (mt1_num + mt2_num + mt3_num) > 0
  ) %>%
  select(
    HH1, HH2, HH6_wm, HH7A_ch, stratum_ch, chweight, wmweight_wm,
    helevel, welevel, windex5_wm, wealth_index, cm11_cat_fct, db2,
    place_of_res, wm_age_cat_fct, WB4, ever_used_media, mdd, mmf, mad,
    coc, coc_level, pnc_mother, sba, anc4, anc_mt, anc4_mt
  )

# Checking for NULL values
mad_coc_df_cleaned %>% vis_miss()


# ==============================================================================
# Checking Distribution of Covariates over CoC ---------------------------------
# ==============================================================================

CreateTableOne(
  vars = c(
    "helevel", "welevel", "wealth_index", "cm11_cat_fct",
    "wm_age_cat_fct", "WB4", "ever_used_media", "db2", "place_of_res",
    "mad"
  ),
  factorVars = c("mad"),
  strata = "coc",
  data = mad_coc_df_cleaned,
  test = FALSE
)


# ==============================================================================
# Preparing the groups using Kmeans --------------------------------------------
# ==============================================================================

coc_prop <- mad_coc_df_cleaned %>%
  group_by(HH7A_ch) %>%
  dplyr::summarize(
    coc_prop = mean(coc)
  )

set.seed(SEED)
seed_number <- sample(200:250, 10)

kgroups <- tibble(
  k = 1:10,
  seed = seed_number
) %>%
  mutate(
    kclust = map2(
      .x = k, .y = seed,
      .f = \(x, y) {
        set.seed(y)
        kmeans(coc_prop$coc_prop, x)
      }
    ),
    tidied = map(kclust, tidy),
    glanced = map(kclust, glance),
    augmented = map(kclust, augment, coc_prop)
  )


# ==============================================================================
# Exploratory plots for Choosing the Group Numbers -----------------------------
# ==============================================================================

elbow_plot <- kgroups %>%
  unnest(cols = c(glanced)) %>%
  select(k, "Within Variance" = tot.withinss, "Between Variance" = betweenss) %>%
  pivot_longer(cols = !k, names_to = "variance_type", values_to = "value") %>%
  ggplot(aes(x = factor(k), group = variance_type)) +
  geom_line(aes(y = value), linewidth = 0.4) +
  geom_point(aes(y = value, shape = variance_type), size = 2) +
  scale_y_continuous(
    limits = c(0, 1)
  ) +
  labs(
    x = "Groups",
    y = "Variance",
    shape = NULL
  ) +
  theme_publication(base_size = 12, base_family = "Times") +
  theme(
    legend.position = "inside",
    legend.position.inside = c(0.85, 0.50),
    legend.direction = "vertical",
    legend.key.spacing.y = unit(10, "mm"),
    legend.background = element_blank(),
    legend.key = element_rect(color = "grey", linewidth = 0.4),
    legend.title = element_text(face = "plain", size = 12),
    legend.text = element_text(face = "plain", size = 12),
    panel.grid.major.x = element_blank(),
    axis.title = element_text(face = "plain", size = 12),
  )

elbow_plot

saveRDS(elbow_plot, file = here::here("data/elbow_plot_gg_obj.rds"))

kclust_group_preval <- kgroups %>%
  unnest(cols = c(tidied)) %>%
  select(k, cl_mean = x1, cluster, size) %>%
  group_by(k) %>%
  arrange(cl_mean, .by_group = TRUE) %>%
  ungroup() %>%
  ggplot(aes(x = reorder_within(cluster, cl_mean, k), y = cl_mean)) +
  geom_col(color = "gray10", fill = "white", width = 0.8) +
  geom_text(aes(label = size), nudge_y = 0.06, size = 2.5) +
  scale_x_reordered() +
  scale_y_continuous(breaks = seq(0.1, 0.5, 0.1)) +
  labs(
    x = "Group ID",
    y = "Mean Prevalence of CoC"
  ) +
  facet_wrap(~k, scales = "free_x", nrow = 2, ncol = 5) +
  theme_publication(base_size = 12, base_family = "Times") +
  theme(
    panel.grid.major.x = element_blank(),
    strip.background = element_rect(fill = "gray80"),
    strip.text = element_text(size = 9),
    axis.line.x = element_line(color = "grey50"),
    axis.line.y = element_line(color = "grey50"),
    axis.title = element_text(face = "plain", size = 12),
    axis.text.y = element_text(size = 9),
    axis.text.x = element_text(size = 9),
  )

kclust_group_preval

saveRDS(
  kclust_group_preval,
  file = here::here("data/kclust_group_preval_gg_obj.rds")
)


# ==============================================================================
# Creating the groups ----------------------------------------------------------
# ==============================================================================

# From the above graphs, We think we should consider 4 or 5 groups.
set.seed(seed_number[4])

g4_kmeans <- kmeans(coc_prop$coc_prop, centers = 4)

g4_kmeans_df <- augment(g4_kmeans, coc_prop) %>%
  rename("groups" = .cluster)


# ==============================================================================
# Checking the Prevalence per Group --------------------------------------------
# ==============================================================================

g4_kmeans_df %>%
  group_by(groups) %>%
  summarise(p = mean(coc_prop))

g4_preval_plot <- tidy(g4_kmeans) %>%
  ggplot(aes(x = fct_reorder(cluster, x1), x1)) +
  geom_col(color = "grey10", fill = "white") +
  geom_text(aes(label = size), nudge_y = 0.04) +
  labs(
    x = "Groups", y = "Mean prevalence` of CoC"
  ) +
  theme_publication(base_family = "Times") +
  theme(
    panel.grid.major.x = element_blank(),
    axis.title = element_text(face = "plain")
  )

g4_preval_plot


# ==============================================================================
# Creating the Final Analysis Data ---------------------------------------------
# ==============================================================================

analysis_df <- mad_coc_df_cleaned %>%
  left_join(g4_kmeans_df, by = join_by(HH7A_ch)) %>%
  select(
    HH1, HH7A_ch, stratum_ch, chweight, place_of_res,
    helevel, welevel, wealth_index, cm11_cat_fct, db2,
    wm_age_cat_fct, WB4, ever_used_media, mad, coc, groups
  ) %>%
  mutate(
    coc = as.numeric(coc)
  )


saveRDS(analysis_df, file = here::here("data/analysis_df.rds"))
