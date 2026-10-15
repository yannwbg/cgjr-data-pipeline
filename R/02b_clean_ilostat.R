library(dplyr)

source("R/00_checks.R")

raw <- read.csv("data/raw/ilostat.csv", stringsAsFactors = FALSE)
countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
config <- read.csv("config/ilostat_indicators.csv", stringsAsFactors = FALSE)
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

required <- c("indicator", "ref_area", "sex", "classif1", "time", "obs_value", "source")
if (!all(required %in% names(raw))) {
  stop("Expected ILOSTAT columns are absent: ", paste(setdiff(required, names(raw)), collapse = ", "))
}
if (!"obs_status" %in% names(raw)) {
  warning("ILOSTAT obs_status is absent from the download; status is set to NA.")
  raw$obs_status <- NA_character_
}

in_scope <- raw$ref_area %in% countries$country_code
fail_if(any(is.na(suppressWarnings(as.integer(raw$time[in_scope])))),
        "Non-numeric ILOSTAT time for configured countries")
warn_if(any(is.na(suppressWarnings(as.numeric(raw$obs_value))) & !is.na(raw$obs_value)),
        "Non-numeric ILOSTAT obs_value entries will become NA")

clean <- raw |>
  rename(country_code = ref_area, year = time, source_detail = source, status = obs_status) |>
  filter(country_code %in% countries$country_code) |>
  inner_join(config, by = c("indicator", "sex", "classif1")) |>
  inner_join(countries[, c("country_code", "country_name", "start_year", "end_year")],
             by = "country_code") |>
  mutate(
    year = as.integer(year),
    value = suppressWarnings(as.numeric(obs_value)),
    source = "ILOSTAT"
  ) |>
  filter(year >= start_year, year <= end_year) |>
  select(country_code, country_name, year, indicator, variable, value, unit,
         source, source_detail, status) |>
  arrange(country_code, year, indicator)

if (nrow(clean) == 0L) {
  stop("No ILOSTAT rows match the configured countries, years, indicator, sex and age. Check config/ilostat_indicators.csv.")
}
if (anyDuplicated(clean[, c("country_code", "year", "indicator")])) {
  stop("Duplicate ILOSTAT country-year-indicator keys.")
}
missing_countries <- setdiff(countries$country_code, clean$country_code)
if (length(missing_countries) > 0L) {
  stop("Configured countries absent from ILOSTAT: ", paste(missing_countries, collapse = ", "))
}
if (anyNA(clean$value)) warning("Missing ILOSTAT values: investigate coverage.")

message("INFO: ILOSTAT rows read ", nrow(raw), ", kept ", nrow(clean))
print(table(clean$status, useNA = "ifany"))
write.csv(clean, "data/processed/ilostat_long.csv", row.names = FALSE, na = "")
