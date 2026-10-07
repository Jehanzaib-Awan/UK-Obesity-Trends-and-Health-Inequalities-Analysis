# Data provenance

`uk_obesity_trends.csv` contains official England aggregate percentages from the Office for Health Improvement and Disparities (OHID) **Obesity, Physical Activity and Nutrition Profile, May 2026 update**. The underlying profile and source data were accessed on **7 October 2026**. The source CSVs were obtained directly through OHID’s public [Fingertips API](https://fingertips.phe.org.uk/api), not from a third-party site.

## Official indicators and downloads

| Indicator ID | Official indicator name | Official CSV endpoint |
|---|---|---|
| 93881 | Obesity prevalence in adults, (using adjusted self-reported height and weight) | [Download indicator 93881](https://fingertips.phe.org.uk/api/all_data/csv/for_one_indicator?indicator_id=93881&profile_id=32) |
| 93088 | Overweight (including obesity) prevalence in adults, (using adjusted self-reported height and weight) | [Download indicator 93088](https://fingertips.phe.org.uk/api/all_data/csv/for_one_indicator?indicator_id=93088&profile_id=32) |

The API files were filtered to `Area Code = E92000001` and `Area Name = England`, `Area Type = England`, `Sex = Persons`, and `Age = 18+ yrs`. Ten exact source period labels were retained: `2015/16`, `2016/17`, `2017/18`, `2018/19`, `2019/20`, `2020/21`, `2021/22`, `2022/23`, `2023/24`, and `2024/25`.

For the overall series, the source record has no category. For inequality data, the selected source category type is **`LSOA11 deprivation deciles within area (IMD  trend)`**, using the OHID-published category labels. They map as follows:

The API provides these inequality groups by descriptive category name rather than by numeric decile code. To follow the project brief, this CSV uses a **project-specific reverse coding** from least to most deprived. The official [English Indices of Deprivation 2025 FAQ](https://www.gov.uk/government/statistics/english-indices-of-deprivation-2025/english-indices-of-deprivation-2025-frequently-asked-questions) documents the conventional English IMD numbering as Decile 1 = most deprived and Decile 10 = least deprived. Consequently, the numeric codes below are project labels mapped from OHID's names; they are not native official IMD decile numbers.

| Project code | OHID category label | Meaning |
|---:|---|---|
| 1 | Least deprived decile | Least deprived |
| 2 | Second least deprived decile | Second least deprived |
| 3 | Third less deprived decile | Third least deprived |
| 4 | Fourth less deprived decile | Fourth least deprived |
| 5 | Fifth less deprived decile | Fifth least deprived |
| 6 | Fifth more deprived decile | Fifth most deprived |
| 7 | Fourth more deprived decile | Fourth most deprived |
| 8 | Third more deprived decile | Third most deprived |
| 9 | Second most deprived decile | Second most deprived |
| 10 | Most deprived decile | Most deprived |

The `England` overall row is included for every period with `deprivation_decile = "England"`. The requested inequality gap is calculated as project code 10 (most deprived) minus project code 1 (least deprived). The data file has 10 periods × 11 groups (England plus ten categories) = **110 rows**. The downloaded OHID `Value` field is preserved at source precision; the results file rounds reported percentages to one decimal place.

## What the measures represent

The official indicator names specify adjusted self-reported height and weight. The included adult age band is `18+ yrs`, and `Persons` is the OHID aggregate covering all sexes. The inequality series classifies areas into the named IMD groups. Project codes 1 to 10 are assigned from least to most deprived to match the requested convention; this is not the official numeric decile numbering and is not a classification of individuals by personal deprivation.

The May 2026 release page states that the adult indicators cover England through 2025 and that England inequality data are available by IMD decile. The data in this project retain the exact financial-year labels published by the profile, ending with `2024/25`.

## Limitations

These are aggregate published percentages, not individual survey records. The area-level IMD pattern cannot be interpreted as an individual-level relationship. The values are estimates based on adjusted self-reported measurements; sampling, survey methods, response, and uncertainty matter. This introductory analysis uses point estimates only, does not model uncertainty, and cannot establish that deprivation causes obesity.
