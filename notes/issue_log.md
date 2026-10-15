# Issue Log

## WDI download fails when sourced outside the project folder

- **Cause:** `R/01_download_wdi.R` reads `config/countries.csv` and `config/indicators.csv` using paths relative to the current working directory. The workspace terminal was in the parent `Module 4` folder, not `cgjr-data-pipeline`.
- **Minimal fix:** Set the R working directory to the `cgjr-data-pipeline` folder before sourcing the script. No download or transformation code change is needed.
- **Verification 1:** From `cgjr-data-pipeline`, source `R/01_download_wdi.R`. It completed and refreshed `data/raw/wdi.csv` and `data/raw/wdi_retrieval.csv`.
- **Verification 2:** From the parent `Module 4` folder, source `cgjr-data-pipeline/R/01_download_wdi.R`. It failed as expected because the relative path `config/countries.csv` was not found.
- **Status:** Root cause reproduced; rerunning from the project folder is the applicable fix. Existing processed and analysis outputs are not written by this downloader.

## Pipeline correction verification

- **Cleaner:** Reran `R/02_clean_wdi.R`; confirmed `wdi_long.csv` is nonempty and has no duplicate country-year-indicator keys. **Passed.**
- **Growth calculation:** Reran `R/03_merge_data.R`. Output inspection confirmed first-year growth is missing and Brazil's 2022 value is 2.646315%, matching the 2021-to-2022 calculation. R diagnostics report no errors. The first combined assertion helper failed in its `ave()` first-year check, so that helper result is not counted as a pass.
- **Latest-observation summary:** Changed the selection to descending year within country. The attempted rerun returned no terminal output, and `country_summary.csv` still showed 2010. **Not validated; output appears stale.**
- **Duplicate-key validation:** Changed duplicate-key handling from warning to error to match the edge-test expectation. The pipeline test run was skipped at the user's direction. Editor diagnostics show no errors in the changed R files; runtime behavior remains unverified.