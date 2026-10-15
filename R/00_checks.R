library(dplyr)

fail_if <- function(cond, msg) if (isTRUE(cond)) stop(msg, call. = FALSE)
warn_if <- function(cond, msg) if (isTRUE(cond)) warning(msg, call. = FALSE)

check_root <- function() {
  req_files <- c("config/countries.csv", "config/indicators.csv", "config/ilostat_indicators.csv")
  missing_files <- req_files[!file.exists(req_files)]
  fail_if(length(missing_files) > 0,
          paste("Run from the repo root. Missing:", paste(missing_files, collapse = ", ")))
  invisible(TRUE)
}

check_config <- function() {
  countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
  ilo_cfg <- read.csv("config/ilostat_indicators.csv", stringsAsFactors = FALSE)
  fail_if(anyDuplicated(countries$country_code) > 0, "Duplicate country_code in config/countries.csv")
  fail_if(any(countries$start_year > countries$end_year), "start_year after end_year in config/countries.csv")
  fail_if(anyDuplicated(ilo_cfg[, c("indicator", "sex", "classif1")]) > 0,
          "Duplicate ILOSTAT config key: joins would multiply rows")
  invisible(TRUE)
}

# Starting bounds; tune after the first run.
range_rules <- data.frame(
  variable = c("gdp_growth", "gdp_per_capita", "population", "employment_to_population"),
  lower = c(-30, 0, 0, 0),
  upper = c(30, Inf, Inf, 100),
  level = c("warning", "stop", "stop", "stop"),
  stringsAsFactors = FALSE
)

check_ranges <- function(data, rules) {
  for (i in seq_len(nrow(rules))) {
    r <- rules[i, ]
    bad <- data$variable == r$variable & !is.na(data$value) &
      (data$value < r$lower | data$value > r$upper)
    if (!any(bad)) next
    msg <- sprintf("%d %s value(s) outside [%g, %g]", sum(bad), r$variable, r$lower, r$upper)
    if (r$level == "stop") stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  }
  invisible(TRUE)
}

check_series <- function(data) {
  empty <- data |>
    group_by(variable, country_code) |>
    summarise(n_obs = sum(!is.na(value)), .groups = "drop") |>
    filter(n_obs == 0)
  fail_if(nrow(empty) > 0,
          paste("No values for:", paste(empty$country_code, empty$variable, collapse = "; ")))
  latest <- data |>
    group_by(variable, country_code) |>
    summarise(latest_na = is.na(value[which.max(year)]), .groups = "drop") |>
    filter(latest_na)
  warn_if(nrow(latest) > 0,
          paste("Latest year missing for:", paste(latest$country_code, latest$variable, collapse = "; ")))
  message("INFO: share of missing values by series:")
  print(data |> group_by(variable) |> summarise(share_missing = round(mean(is.na(value)), 3), .groups = "drop"))
  invisible(TRUE)
}
