if (!file.exists("R/00_checks.R")) stop("Run from the repo root.", call. = FALSE)
source("R/00_checks.R")
check_root()
check_config()

library(WDI)

countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
indicators <- read.csv("config/indicators.csv", stringsAsFactors = FALSE)
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

raw <- WDI(
  country = countries$country_code,
  indicator = indicators$indicator,
  start = min(countries$start_year),
  end = max(countries$end_year),
  extra = FALSE
)
if (nrow(raw) == 0L) stop("WDI returned no observations.")
required <- c("iso3c", "country", "year", indicators$indicator)
if (!all(required %in% names(raw))) stop("Expected WDI columns are absent.")
fail_if(anyDuplicated(raw[, c("iso3c", "year")]) > 0, "Duplicate country-year rows in WDI download")
missing_wdi <- setdiff(countries$country_code, raw$iso3c)
fail_if(length(missing_wdi) > 0, paste("WDI returned no rows for:", paste(missing_wdi, collapse = ", ")))

write.csv(raw, "data/raw/wdi.csv", row.names = FALSE, na = "")
write.csv(
  data.frame(
    source = "World Development Indicators",
    source_url = "https://api.worldbank.org/v2/",
    retrieved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  "data/raw/wdi_retrieval.csv", row.names = FALSE
)