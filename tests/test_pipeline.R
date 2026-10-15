source("R/05_quality_checks.R")

clean <- read.csv("data/processed/wdi_long.csv", stringsAsFactors = FALSE)
stopifnot(nrow(clean) > 0L, isTRUE(check_data(clean)))
outputs <- c("outputs/figures/gdp_growth.png", "outputs/tables/country_summary.csv")
stopifnot(all(file.exists(outputs)), all(file.info(outputs)$size > 0))
message("Smoke test passed.")

fixture <- data.frame(
  country_code = c("BRA", "BRA"), year = c(2020L, 2021L),
  indicator = c("NY.GDP.MKTP.KD.ZG", "NY.GDP.MKTP.KD.ZG"),
  value = c(-3.3, 4.8)
)
stopifnot(isTRUE(check_data(fixture)))
invalid <- rbind(fixture, fixture[1, ])
duplicate_rejected <- tryCatch(
  { check_data(invalid); FALSE },
  error = function(condition) TRUE
)
if (!duplicate_rejected) stop("Edge test failed: duplicate input must raise an error.")
message("Duplicate-key edge test passed.")

range_fixture <- data.frame(variable = "gdp_growth", value = -52.3)
range_warned <- tryCatch(
  { check_ranges(range_fixture, range_rules); FALSE },
  warning = function(condition) TRUE
)
if (!range_warned) stop("Range edge test failed: -52.3 growth must raise a warning.")
message("Range edge test passed.")