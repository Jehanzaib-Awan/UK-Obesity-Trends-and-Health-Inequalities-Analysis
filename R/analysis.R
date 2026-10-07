# UK Obesity Trends and Health Inequalities Analysis
# Run from the project root: Rscript R/analysis.R

# 1. Load packages ---------------------------------------------------------
library(tidyverse)
library(DBI)
library(RSQLite)

# 2. Load the compact OHID aggregate data ---------------------------------
data_file <- file.path("data", "uk_obesity_trends.csv")
obesity_raw <- readr::read_csv(
  data_file,
  col_types = cols(
    year = col_character(),
    deprivation_decile = col_character(),
    obesity_prevalence = col_double(),
    overweight_obesity_prevalence = col_double()
  ),
  show_col_types = FALSE
)

# 3. Basic data QA ---------------------------------------------------------
cat("Variable types:\n")
print(vapply(obesity_raw, class, character(1)))

missing_by_variable <- vapply(obesity_raw, function(x) sum(is.na(x)), integer(1))
cat("\nMissing values by variable:\n")
print(missing_by_variable)

duplicate_pairs <- sum(duplicated(obesity_raw[c("year", "deprivation_decile")]))
cat("\nDuplicate year/decile combinations:", duplicate_pairs, "\n")

expected_years <- c("2015/16", "2016/17", "2017/18", "2018/19", "2019/20",
                    "2020/21", "2021/22", "2022/23", "2023/24", "2024/25")
expected_deciles <- c("England", as.character(1:10))
indicator_names <- c("obesity_prevalence", "overweight_obesity_prevalence")

cat("\nYears present:\n")
print(unique(obesity_raw$year))
cat("Decile values present (England is the overall record):\n")
print(sort(unique(obesity_raw$deprivation_decile)))
cat("\nIndicator ranges (percent):\n")
print(obesity_raw %>% summarise(across(all_of(indicator_names),
                                      list(min = ~min(.x), max = ~max(.x)))))

if (any(missing_by_variable > 0)) stop("Missing values found in the analysis dataset.")
if (duplicate_pairs > 0) stop("Duplicate year/decile combinations found.")
if (!setequal(unique(obesity_raw$year), expected_years)) stop("The expected OHID periods are not all present.")
if (!setequal(unique(obesity_raw$deprivation_decile), expected_deciles)) stop("England or one or more deprivation deciles are missing.")
if (nrow(obesity_raw) != length(expected_years) * length(expected_deciles)) {
  stop("Unexpected number of year/decile rows; expected 10 periods x 11 groups.")
}
if (any(as.matrix(obesity_raw[indicator_names]) < 0 | as.matrix(obesity_raw[indicator_names]) > 100)) {
  stop("An indicator value falls outside the 0-100 percent range.")
}

# Ensure each year has exactly one England row and one row for every decile.
rows_per_year <- obesity_raw %>% count(year)
if (any(rows_per_year$n != length(expected_deciles))) stop("A year does not have all 11 required records.")

# 4. Cleaning and ordering -------------------------------------------------
obesity_data <- obesity_raw %>%
  filter(if_all(everything(), ~ !is.na(.x))) %>%
  distinct(year, deprivation_decile, .keep_all = TRUE) %>%
  mutate(
    year = factor(year, levels = expected_years),
    deprivation_decile = factor(deprivation_decile, levels = expected_deciles)
  ) %>%
  arrange(year, deprivation_decile)

# 5. Load into SQLite and execute the simple SQL query --------------------
con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
on.exit(DBI::dbDisconnect(con), add = TRUE)
DBI::dbWriteTable(con, "obesity_data", obesity_data, overwrite = TRUE)
sql_query <- paste(readLines(file.path("sql", "analysis.sql"), warn = FALSE), collapse = "\n")
analysis_data <- DBI::dbGetQuery(con, sql_query) %>%
  mutate(
    year = factor(year, levels = expected_years),
    deprivation_decile = factor(deprivation_decile, levels = expected_deciles)
  ) %>%
  as_tibble()
if (nrow(analysis_data) != 110L) stop("The SQL extraction did not return all 110 observations.")

# 6. Split England overall and IMD decile records -------------------------
england_data <- analysis_data %>%
  filter(deprivation_decile == "England") %>%
  arrange(year)

decile_data <- analysis_data %>%
  filter(deprivation_decile != "England") %>%
  mutate(deprivation_decile = factor(as.character(deprivation_decile), levels = as.character(1:10))) %>%
  arrange(year, deprivation_decile)

if (nrow(england_data) != length(expected_years)) stop("England trend rows are incomplete.")
if (nrow(decile_data) != length(expected_years) * 10L) stop("IMD decile rows are incomplete.")

# 7. Descriptive summaries and deprivation gap -----------------------------
first_year <- expected_years[[1]]
latest_year <- expected_years[[length(expected_years)]]

gap_data <- decile_data %>%
  select(year, deprivation_decile, obesity_prevalence) %>%
  pivot_wider(names_from = deprivation_decile, values_from = obesity_prevalence) %>%
  mutate(deprivation_gap = .data[["10"]] - .data[["1"]]) %>%
  select(year, least_deprived = `1`, most_deprived = `10`, deprivation_gap) %>%
  arrange(year)

first_england <- england_data %>% filter(year == first_year) %>% pull(obesity_prevalence)
last_england <- england_data %>% filter(year == latest_year) %>% pull(obesity_prevalence)
england_change_pp <- last_england - first_england
first_gap <- gap_data %>% filter(year == first_year) %>% pull(deprivation_gap)
last_gap <- gap_data %>% filter(year == latest_year) %>% pull(deprivation_gap)
gap_change_pp <- last_gap - first_gap
latest_least <- gap_data %>% filter(year == latest_year) %>% pull(least_deprived)
latest_most <- gap_data %>% filter(year == latest_year) %>% pull(most_deprived)

# 8. Three figures ---------------------------------------------------------
theme_set(theme_minimal(base_size = 12))

figure_england <- ggplot(england_data, aes(x = year, y = obesity_prevalence, group = 1)) +
  geom_line(linewidth = 0.9, colour = "#28666E") +
  geom_point(size = 2.2, colour = "#28666E") +
  scale_y_continuous(limits = c(0, 45), breaks = seq(0, 45, 5),
                     expand = expansion(mult = c(0, 0.02))) +
  labs(
    title = "Adult obesity prevalence in England",
    subtitle = "Adults aged 18 and over; OHID financial-year labels",
    x = "Survey period", y = "Prevalence (%)",
    caption = "Source: OHID Obesity, Physical Activity and Nutrition Profile, May 2026 update"
  ) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
ggsave(file.path("outputs", "obesity_trend_england.png"), figure_england,
       width = 9, height = 5.5, dpi = 300, bg = "white")

latest_decile_data <- decile_data %>% filter(year == latest_year)
figure_deciles <- ggplot(latest_decile_data,
                         aes(x = deprivation_decile, y = obesity_prevalence, group = 1)) +
  geom_line(linewidth = 0.8, colour = "#28666E") +
  geom_point(size = 3, colour = "#8C2F39") +
  scale_y_continuous(limits = c(0, 45), breaks = seq(0, 45, 5),
                     expand = expansion(mult = c(0, 0.02))) +
  scale_x_discrete(drop = FALSE) +
  labs(
    title = paste("Adult obesity prevalence by project-coded deprivation group, England,", latest_year),
    subtitle = "Project code 1 = least deprived category; code 10 = most deprived category",
    x = "OHID deprivation category (project code)", y = "Prevalence (%)",
    caption = "Source: OHID Obesity, Physical Activity and Nutrition Profile, May 2026 update"
  )
ggsave(file.path("outputs", "obesity_by_deprivation.png"), figure_deciles,
       width = 9, height = 5.5, dpi = 300, bg = "white")

figure_gap <- ggplot(gap_data, aes(x = year, y = deprivation_gap, group = 1)) +
  geom_line(linewidth = 0.9, colour = "#8C2F39") +
  geom_point(size = 2.2, colour = "#8C2F39") +
  scale_y_continuous(expand = expansion(mult = c(0.08, 0.12))) +
  labs(
    title = "Adult obesity inequality gap over time",
    subtitle = "Most deprived project code (10) minus least deprived project code (1)",
    x = "Survey period", y = "Difference in prevalence (percentage points)",
    caption = "Source: OHID Obesity, Physical Activity and Nutrition Profile, May 2026 update"
  ) +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
ggsave(file.path("outputs", "obesity_inequality_gap.png"), figure_gap,
       width = 9, height = 5.5, dpi = 300, bg = "white")

# 9. Write results directly from the CSV calculations ---------------------
round1 <- function(x) sprintf("%.1f", x)
interpretation <- if (england_change_pp > 0) {
  "England adult obesity prevalence in the latest period was higher than in the first period."
} else if (england_change_pp < 0) {
  "England adult obesity prevalence in the latest period was lower than in the first period."
} else {
  "England adult obesity prevalence was unchanged between the first and last selected periods."
}
if (last_gap > 0) {
  interpretation <- paste(interpretation, "The most deprived OHID category (project code 10) had a higher reported prevalence than the least deprived category (project code 1) in the latest period, showing a descriptive deprivation gradient.")
}

result_lines <- c(
  "UK Obesity Trends and Health Inequalities Analysis",
  "",
  paste0("Data periods analysed: ", length(expected_years)),
  paste0("Period labels: ", first_year, " to ", latest_year, " (labels retained as published by OHID)"),
  "Population: England residents aged 18 years and over; Persons (both sexes)",
  "",
  "England overall obesity trend:",
  paste0("First period (", first_year, "): ", round1(first_england), "%"),
  paste0("Latest period (", latest_year, "): ", round1(last_england), "%"),
  paste0("Change from first to latest period: ", sprintf("%+.1f", england_change_pp), " percentage points"),
  "",
  paste0("Latest-period least deprived group (project code 1, ", latest_year, "): ", round1(latest_least), "%"),
  paste0("Latest-period most deprived group (project code 10, ", latest_year, "): ", round1(latest_most), "%"),
  paste0("Deprivation gap in latest period (project code 10 minus code 1): ", round1(last_gap), " percentage points"),
  paste0("Deprivation gap in first period (project code 10 minus code 1, ", first_year, "): ", round1(first_gap), " percentage points"),
  paste0("Change in the deprivation gap, first to latest period: ", sprintf("%+.1f", gap_change_pp), " percentage points"),
  "",
  "Interpretation:",
  interpretation,
  "These are descriptive differences in published aggregate estimates. They show an area-level pattern and do not establish that deprivation causes obesity.",
  "",
  "Source: OHID Obesity, Physical Activity and Nutrition Profile, May 2026 update; adult indicator IDs 93881 and 93088.",
  "Decile numbers follow the project brief: 1 = least deprived and 10 = most deprived; this is reverse to conventional English IMD numeric deciles.",
  "Obesity percentages and calculated gaps are displayed to one decimal place; gap and change calculations use the unrounded downloaded values."
)
writeLines(result_lines, file.path("results", "results.txt"))
cat(paste(result_lines, collapse = "\n"), "\n")
