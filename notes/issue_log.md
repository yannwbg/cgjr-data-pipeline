# Issue log

## Duplicate country-year-indicator keys in baseline checks

- **Cause:** `R/02_clean_wdi.R` appended the first cleaned observation to the
  data a second time before writing `wdi_long.csv`.
- **Fix:** Removed that append. `check_data()` in `R/05_quality_checks.R` now
  stops on duplicate keys, matching the existing duplicate-key edge test.
- **Verification:**
  - `Rscript R\02_clean_wdi.R` — passed.
  - `Rscript R\03_merge_data.R` — passed.
  - `Rscript R\04_analysis.R` — passed.
  - `Rscript R\05_quality_checks.R` — passed; baseline checks completed with no
    duplicate-key warning.
  - `Rscript tests\test_pipeline.R` — passed; smoke test and duplicate-key edge
    test passed.
  - `Rscript -e "x <- read.csv('data/processed/wdi_long.csv'); keys <- x[c('country_code','year','indicator')]; if (anyDuplicated(keys)) stop('Duplicate keys remain'); cat('Duplicate-key verification passed:', nrow(x), 'rows, 0 duplicate keys.\n')"` — passed; 168 rows, 0 duplicate keys.
- **Environment note:** The installed `dplyr` and `ggplot2` packages reported
  that they were built under R 4.4.3; the scripts still completed successfully.
