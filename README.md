# Growth and Jobs Data Pipeline

Participant starter for the GitHub, VS Code and Copilot hands-on exercise.
Use public aggregate data only. This starter deliberately contains four
recoverable issues: execution alone does not establish analytical correctness.

## Project purpose

This pipeline downloads public country-year indicators, cleans and merges them, and writes a GDP growth figure, a country summary table, an ILOSTAT employment-to-population figure and data checks.

- Countries: Brazil (BRA), Indonesia (IDN), Kenya (KEN) and Viet Nam (VNM), from `config/countries.csv`.
- Years: 2010 to 2023 for each country, from `config/countries.csv`.
- Data: aggregate country-year statistics only. No person-level records.

## Required software

- R: version not specified in the repository. The code uses the native pipe `|>`, which requires R 4.1.0 or later.
- R packages: `WDI` (World Bank download), `dplyr` (data handling; `relationship =` in `R/03_merge_data.R` requires dplyr 1.1.0 or later) and `ggplot2` (figures). Install with `install.packages(c("WDI", "dplyr", "ggplot2"))`.
- ILOSTAT download uses base R only (`download.file`, `gzfile`).
- Internet access to `api.worldbank.org` (via WDI) and `rplumber.ilo.org`.
- Git and a GitHub account for the submission workflow in Your Work.
- Package versions are not pinned. The repository has no `renv` lockfile.

## Setup

Open this repository folder in VS Code, install the three required R packages, set your working directory, create a branch

- Open New Terminal
- Click on "+" -> "R Terminal"
- Set your working directory by running 'setwd("your_path")' in the terminal. E.g. `setwd("<path-to-your-clone>/cgjr-data-pipeline")`
- Check the working directory by running `getwd()`
- Copy the following code then press enter: `install.packages(c("WDI", "dplyr", "ggplot2"))`
- Create and publish a branch named `first name`. E.g. `yann-branch`; do not work directly on `main`.

## File structure

```
cgjr-data-pipeline/
├── README.md
├── .gitignore                    # excludes /data/ and /outputs/
├── .github/pull_request_template.md
├── .vscode/                      # editor folder
├── config/
│   ├── countries.csv             # country codes, names, start and end years
│   ├── indicators.csv            # WDI indicator codes and variable names
│   └── ilostat_indicators.csv    # ILOSTAT download ID, data code, sex and age filter
├── data/                         # created by scripts; not in Git
│   ├── raw/                      # downloads and retrieval logs
│   └── processed/                # cleaned and merged files
├── docs/data_dictionary.md       # WDI definitions; no ILOSTAT section yet
├── Issue solutions/Solutions.md  # the four seeded issues
├── outputs/                      # figures and tables; not in Git
│   ├── figures/
│   └── tables/
├── R/
│   ├── 00_checks.R               # shared check helpers (sourced, not run directly)
│   ├── 01_download_wdi.R
│   ├── 01b_download_ilostat.R
│   ├── 02_clean_wdi.R
│   ├── 02b_clean_ilostat.R
│   ├── 03_merge_data.R
│   ├── 04_analysis.R
│   ├── 04b_plot_ilostat.R
│   └── 05_quality_checks.R
└── tests/test_pipeline.R
```

## Run order

Run from the repository root, the folder that contains `config/` and `R/`. All paths are relative, so scripts run from any other folder will fail. Check with `getwd()`.

Source the scripts in this order. Each script loads `R/00_checks.R` itself; do not source it separately.

1. `source("R/01_download_wdi.R")` writes `data/raw/wdi.csv` and `data/raw/wdi_retrieval.csv`. Needs internet access.
2. `source("R/01b_download_ilostat.R")` writes `data/raw/ilostat.csv` and `data/raw/ilostat_retrieval.csv`. Needs internet access.
3. `source("R/02_clean_wdi.R")` writes `data/processed/wdi_long.csv`. Needs step 1.
4. `source("R/02b_clean_ilostat.R")` writes `data/processed/ilostat_long.csv`. Needs step 2.
5. `source("R/03_merge_data.R")` writes `data/processed/analytical.csv`. Needs step 3.
6. `source("R/04_analysis.R")` writes `outputs/figures/gdp_growth.png` and `outputs/tables/country_summary.csv`. Needs step 5.
7. `source("R/04b_plot_ilostat.R")` writes `outputs/figures/ilostat_employment_to_population.png` and `outputs/tables/ilostat_coverage.csv`. Needs step 4.
8. `source("R/05_quality_checks.R")` runs the checks and writes no files. Needs steps 3 to 7.
9. `source("tests/test_pipeline.R")` runs the smoke and edge tests. Needs step 8, because it sources `R/05_quality_checks.R`.

To source a script, open it in the editor and click on the arrow on the top right or type source("filepath") in the terminal - for example `source("R/01_download_wdi.R")`


The scripts create their data and output directories automatically. Downloads
and generated outputs are ignored by Git (see Expected outputs). A stop or warning
from a check names the failing condition; fix it and rerun from the step that failed.
The summary is intended to describe the latest available GDP-growth observation.
Investigate warnings and failed checks, even when plots are produced.

## Data sources

| Source | Access | Series used | Stored as |
| --- | --- | --- | --- |
| World Development Indicators (World Bank) | `WDI` R package, `WDI()` call. The retrieval log records the API base `https://api.worldbank.org/v2/`. | `NY.GDP.MKTP.KD.ZG` (gdp_growth), `NY.GDP.PCAP.KD` (gdp_per_capita), `SP.POP.TOTL` (population) | `data/raw/wdi.csv` |
| ILOSTAT (International Labour Organization) | HTTP download from `https://rplumber.ilo.org/data/indicator/?id=EMP_2WAP_SEX_AGE_RT_A&ver=1.0.0&format=.csv.gz` | `EMP_2WAP_SEX_AGE_RT` (employment_to_population), sex `SEX_T`, classif1 `AGE_YTHADULT_YGE15`, unit percent | `data/raw/ilostat.csv` |

- Retrieval time: written to the `*_retrieval.csv` files at run time. Not recorded in this README.
- WDI definitions: [docs/data_dictionary.md](docs/data_dictionary.md).
- ILOSTAT definition: Not in the repository. Confirm the definition and unit for `EMP_2WAP_SEX_AGE_RT` in ILOSTAT metadata.
- Licence and terms of use: Not in the repository. Check the providers' terms before reuse.

## Expected outputs

| File | Created by | Expected content |
| --- | --- | --- |
| `data/raw/wdi.csv` | Step 1 | Raw WDI rows for the configured countries and years |
| `data/raw/wdi_retrieval.csv` | Step 1 | Source, API base URL, UTC retrieval time |
| `data/raw/ilostat.csv` | Step 2 | Raw ILOSTAT rows for the configured indicator |
| `data/raw/ilostat_retrieval.csv` | Step 2 | Source, URL base, indicator IDs, UTC retrieval time |
| `data/processed/wdi_long.csv` | Step 3 | Long format. 168 rows expected (4 countries × 14 years × 3 indicators, from configuration) |
| `data/processed/ilostat_long.csv` | Step 4 | Long format. Row count depends on ILOSTAT coverage; not stated |
| `data/processed/analytical.csv` | Step 5 | 56 rows expected (one per country-year). Columns: `country_code`, `country_name`, `year`, `gdp_growth`, `gdp_per_capita`, `population`, `gdp_per_capita_growth`. ILOSTAT is not merged. |
| `outputs/figures/gdp_growth.png` | Step 6 | GDP growth by country, 2010 to 2023 |
| `outputs/tables/country_summary.csv` | Step 6 | One row per country: latest year with GDP growth |
| `outputs/figures/ilostat_employment_to_population.png` | Step 7 | Employment-to-population ratio by country; gaps shown, not filled |
| `outputs/tables/ilostat_coverage.csv` | Step 7 | One row per country: expected and observed years, share observed, first and last observed year, missing years |

Row counts are calculated from the configuration. They have not been recorded from a run.

## Quality checks

A **Stop** halts the script. A **Warning** lets it finish and must be reviewed. **Info** is printed only.

| Step | Check | Level |
| --- | --- | --- |
| 1, 2 | Run from the repo root; required config files present | Stop |
| 1, 2 | Duplicate country codes; start year after end year; duplicate ILOSTAT config key | Stop |
| 1 | WDI returns no rows; expected columns absent; duplicate country-year rows; configured country missing | Stop |
| 2 | Download fails; response is HTML rather than CSV; zero rows; configured indicator missing | Stop |
| 3 | No rows after filtering | Stop |
| 3 | Row count differs from the expected 168 | Warning |
| 4 | Required columns absent; non-numeric time for configured countries; no rows after filtering; duplicate country-year-indicator keys; configured country absent | Stop |
| 4 | `obs_status` absent (status set to NA); non-numeric observation values; missing values | Warning |
| 4 | Rows read and kept; status counts | Info |
| 5 | Merge changes the row count; year gaps within a country; growth computed in a first year | Stop |
| 6 | Summary not one row per country at its latest year with GDP growth; summary values differ from `analytical.csv` | Stop |
| 7 | Duplicate keys; more than one unit; plot grid size wrong; not every observation plotted; not exactly one label | Stop |
| 8 | Required columns absent; year not integer; value not numeric; duplicate keys; missing WDI values | Stop (duplicates, types) / Warning (missing) |
| 8 | Values outside `range_rules`: gdp_growth outside -30 to 30 is a warning; gdp_per_capita, population, employment_to_population outside bounds are stops | Stop / Warning |
| 8 | A series with no values at all | Stop |
| 8 | Latest year missing for a country and series | Warning |
| 8 | Share of missing values by series | Info |
| 8 | Configured country absent from `wdi_long.csv`; duplicate keys in ILOSTAT or analytical files; expected output missing or empty | Stop |
| 9 | Duplicate input must raise an error; -52.3 GDP growth must raise a warning | Test failure |

The range bounds are starting values. They have not been calibrated against the data.

## Known limitations

- ILOSTAT is not merged into `analytical.csv`. `R/03_merge_data.R` joins WDI variables only.
- Only one ILOSTAT indicator is included: total sex, age 15+.
- `country_summary.csv` uses each country's latest year with GDP growth, so the years can differ by country.
- `gdp_per_capita_growth` is computed in `analytical.csv` but is not used in the figure or the summary.
- A gap in a country's years stops `R/03_merge_data.R`, because the growth calculation assumes consecutive years.
- The figures do not fill missing years. Gaps appear as breaks in the lines.
- The range bounds in `R/00_checks.R` are starting values. The code says to tune them after the first run.
- The ILOSTAT bulk file URL returned 404 during development. The script uses the rplumber endpoint instead.
- Downloads come from live APIs. Re-running later can change values.
- Data and outputs are not versioned. Regenerate them rather than committing them.
- The tests cover the baseline smoke test, duplicate keys and one range case. None covers ILOSTAT specifically.
- `docs/data_dictionary.md` does not document ILOSTAT.

## Missing information

- R version tested: Not in the repository.
- Package versions tested: Not in the repository. No lockfile.
- Whether the full sequence has run end to end on the current code: Not recorded.
- Licence and terms of use for WDI and ILOSTAT data: Not in the repository.
- ILOSTAT definition and unit confirmation: Not in the repository.
- Maintainer or contact: Not in the repository.
- Retrieval date of the stored data: Written to the retrieval files at run time; not in the README.

## Your Work

1. Explain the workflow before editing; inspect the configuration and scripts.
2. Diagnose and fix at least three issues. See Issue solution if needed.
3. Add `R/01b_download_ilostat.R` and `R/02b_clean_ilostat.R`. Use an annual
   employment-to-population ratio for total sex, age 15+ (series ID: EMP_2WAP_SEX_AGE_RT_A).
4. Filter to the configured countries and years. Keep raw files in `data/raw/`.
5. Merge using explicit country-year keys after checking uniqueness and types.
   Report matched, WDI-only and ILO-only rows before deciding on the sample.
6. Add an ILOSTAT trend plot.
7. Extend quality checks for columns, keys, types, bounds, missingness, country
   coverage.
8. Update README, `docs/data_dictionary.md` from verified code and results, including the new run order.
9. Review diffs, stage only intended files, commit with a title and explanatory
   body, push and open a pull request. Leave the PR open; do not merge.

## Files You Will Use

- `config/`: country list, years, WDI indicator definitions and ILOSTAT indicator definition.
- `R/`: download, clean, merge, analysis and quality-check scripts.
- `tests/test_pipeline.R`: baseline smoke test, duplicate-key edge test and range edge test.
- `docs/`: working data dictionary.
- `.github/pull_request_template.md`: your submission checklist.

Never commit downloaded data, generated outputs, credentials, confidential
material or person-level records. Review Source Control before every commit.
