source("R/00_checks.R")

check_data <- function(data) {
  required <- c("country_code", "year", "indicator", "value")
  if (!all(required %in% names(data))) stop("Required columns are absent.")
  if (!is.integer(data$year)) stop("Year must be integer.")
  if (!is.numeric(data$value)) stop("Value must be numeric.")
  keys <- data[, c("country_code", "year", "indicator")]
  if (anyDuplicated(keys)) stop("Duplicate country-year-indicator keys.")
  if (anyNA(data$value)) warning("Missing values: investigate coverage.")
  invisible(TRUE)
}

clean <- read.csv("data/processed/wdi_long.csv", stringsAsFactors = FALSE)
check_data(clean)
check_ranges(clean, range_rules)
check_series(clean)
countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
if (!all(countries$country_code %in% clean$country_code)) {
  stop("A configured country is missing.")
}
ilostat <- read.csv("data/processed/ilostat_long.csv", stringsAsFactors = FALSE)
fail_if(anyDuplicated(ilostat[, c("country_code", "year", "indicator")]) > 0, "Duplicate keys in ilostat_long.csv")
check_ranges(ilostat, range_rules)
check_series(ilostat)
analytical <- read.csv("data/processed/analytical.csv", stringsAsFactors = FALSE)
fail_if(anyDuplicated(analytical[, c("country_code", "year")]) > 0, "Duplicate country-year in analytical.csv")
expected <- c("outputs/figures/gdp_growth.png", "outputs/tables/country_summary.csv",
              "outputs/figures/ilostat_employment_to_population.png")
if (!all(file.exists(expected))) stop("An expected output is absent.")
if (any(file.info(expected)$size == 0)) stop("An expected output is empty.")
message("INFO: wdi_long ", nrow(clean), "; analytical ", nrow(analytical), "; ilostat_long ", nrow(ilostat))
message("Baseline checks completed. Review all warnings.")