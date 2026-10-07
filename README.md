# UK Obesity Trends and Health Inequalities Analysis

## 1. Overview

This junior-level public-health data analysis examines adult obesity prevalence in England over time and compares prevalence across areas grouped by Index of Multiple Deprivation (IMD) decile. It uses only published aggregate values from the official Office for Health Improvement and Disparities (OHID) Obesity, Physical Activity and Nutrition Profile. It does not contain individual records.

## 2. Research Questions

1. How has adult obesity prevalence changed in England over time?
2. How does adult obesity prevalence differ between the least and most deprived areas?
3. Has the gap between the least and most deprived groups changed over time?

## 3. Data Source

The primary source is the [OHID Obesity, Physical Activity and Nutrition Profile](https://fingertips.phe.org.uk/profile/obesity-physical-activity-nutrition). The analysis uses the **May 2026 update**, published 6 May 2026. The [release page](https://www.gov.uk/government/statistics/obesity-physical-activity-and-nutrition-profile-may-2026-update) reports adult obesity and overweight (including obesity) data for England through 2025, with England inequality data by IMD decile. No later profile release was identified when this project was prepared (7 October 2026).

The two published indicator names are:

- `Obesity prevalence in adults, (using adjusted self-reported height and weight)` — OHID indicator ID **93881**.
- `Overweight (including obesity) prevalence in adults, (using adjusted self-reported height and weight)` — OHID indicator ID **93088**.

Both are filtered to England, `Persons`, and the age group `18+ yrs`. The source CSVs were downloaded from the official [Fingertips API](https://fingertips.phe.org.uk/api); the indicator-specific download URLs and extraction filters are recorded in [`data/README.md`](data/README.md).

The data cover ten financial-year periods, **2015/16 through 2024/25**. Those period labels are kept exactly as published by OHID. The OHID export gives named deprivation categories; following the project brief, they are **project-coded** so `1` means least deprived and `10` means most deprived. **This is the reverse of conventional English IMD numeric coding**, where official Decile 1 is most deprived and Decile 10 least deprived ([official IMD 2025 FAQ](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2025/english-indices-of-deprivation-2025-frequently-asked-questions)). The numbers in this project's CSV are therefore recoded labels, not the source's native numeric decile values. England overall rows are stored as `deprivation_decile = "England"`.

## 4. Variables

| Variable | Description |
|---|---|
| `year` | Official OHID financial-year period, 2015/16–2024/25 |
| `deprivation_decile` | `England` for the overall England estimate, or `1` (least deprived) through `10` (most deprived) |
| `obesity_prevalence` | OHID adult obesity prevalence percentage |
| `overweight_obesity_prevalence` | OHID adult overweight (including obesity) prevalence percentage |

The CSV contains **110 aggregate observations**: ten years for England overall and ten years for each of ten deprivation deciles. Values are retained at the precision provided by OHID’s downloadable CSV. No individual-level, simulated, or estimated records were added.

## 5. Methodology

**OHID → SQL extraction → R cleaning/QA → descriptive analysis → inequality comparison → visualisation → interpretation**

The compact dataset was extracted from the two official OHID indicator CSVs. The category labels were mapped to deciles 1–10, preserving the England overall series separately. R checks variable types, missing values, duplicate year/decile combinations, expected years and deciles, percentage ranges, and the number of records in each year. SQL selects complete rows and sorts by year and deprivation group. R calculates the England trend and the annual deprivation gap:

> **Deprivation gap = obesity prevalence in the most deprived decile (10) − obesity prevalence in the least deprived decile (1)**

Changes and gaps are expressed in percentage points. Results are displayed to one decimal place, while calculations use the unrounded values in the official source CSV. No inferential tests or causal models are used.

## 6. SQL Analysis

[`sql/analysis.sql`](sql/analysis.sql) selects the four required fields, excludes missing records, restricts groups to England overall or deciles 1–10, and orders records by year and deprivation decile. The R script executes this query against an in-memory SQLite database.

## 7. R Analysis

[`R/analysis.R`](R/analysis.R) uses `tidyverse`, `DBI`, and `RSQLite` to read and validate the compact CSV, load it into SQLite, execute the SQL query, calculate descriptive trends and gaps, generate exactly three PNG figures, and write [`results/results.txt`](results/results.txt).

Run it from the project root:

```sh
Rscript R/analysis.R
```

If needed, install the packages in R with:

```r
install.packages(c("tidyverse", "DBI", "RSQLite"))
```

## 8. Results

The R-generated results use the OHID values in the CSV. Across the ten periods, the England overall adult obesity estimate was **22.6% in 2015/16** and **26.6% in 2024/25**, a first-to-last change of **+4.0 percentage points**.

In 2024/25, the reported prevalence was **20.0%** in the least deprived group (project code 1) and **37.6%** in the most deprived group (project code 10). The requested project-coded gap was **17.6 percentage points** in 2024/25, compared with **14.1 points** in 2015/16. Thus, the gap increased by **3.5 percentage points** between the first and last periods. These calculated values are also recorded in `results/results.txt`.

This is a descriptive pattern in aggregate estimates. It indicates a higher reported prevalence in the most deprived area group, not that deprivation causes obesity.

## 9. Visualisations

The R script generates exactly three figures in `outputs/`:

1. [`obesity_trend_england.png`](outputs/obesity_trend_england.png) — England adult obesity prevalence by financial year.
2. [`obesity_by_deprivation.png`](outputs/obesity_by_deprivation.png) — obesity prevalence across the project-coded deprivation groups 1–10 in the latest period.
3. [`obesity_inequality_gap.png`](outputs/obesity_inequality_gap.png) — the project code 10 minus project code 1 gap over time.

## 10. Limitations

- The data are **aggregate published percentages**, not individual-level records. Findings about an area-level decile cannot be assumed to describe every person in that decile.
- The analysis is observational and descriptive. It does not establish causation; other demographic, social, behavioural, and environmental factors may contribute to the observed differences.
- The indicator is based on adjusted self-reported height and weight. Survey design, reporting, sample size, and uncertainty can affect estimates; this simple project uses point estimates and does not analyse confidence intervals.
- IMD is an **area-level** measure of relative deprivation, not a measure of an individual’s personal circumstances.
- The series uses ten financial-year estimates. Year labels are survey periods, not point measurements at a single date.

## 11. Conclusion

In the OHID May 2026 data, England’s adult obesity prevalence was higher in 2024/25 than in 2015/16. A descriptive deprivation gradient was also present in the latest period, with the most deprived OHID category (project code 10) reporting higher prevalence than the least deprived category (project code 1). The difference between those two groups was larger in the first and last periods compared here. These area-level patterns should be interpreted cautiously and do not establish a causal relationship.
