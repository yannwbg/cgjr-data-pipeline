library(dplyr)

source("R/00_checks.R")

clean <- read.csv("data/processed/wdi_long.csv", stringsAsFactors = FALSE)
indicators <- read.csv("config/indicators.csv", stringsAsFactors = FALSE)
analytical <- distinct(clean, country_code, country_name, year)

for (variable_name in indicators$variable) {
  series <- clean |>
    filter(variable == variable_name) |>
    select(country_code, year, value)
  names(series)[names(series) == "value"] <- variable_name
  analytical <- left_join(analytical, series, by = c("country_code", "year"), relationship = "one-to-one")
}
fail_if(nrow(analytical) != nrow(distinct(clean, country_code, year)), "Merge changed the row count")
gaps <- analytical |>
  arrange(country_code, year) |>
  group_by(country_code) |>
  summarise(n_gaps = sum(diff(year) != 1), .groups = "drop")
fail_if(any(gaps$n_gaps > 0),
        paste("Year gaps within countries:", paste(gaps$country_code[gaps$n_gaps > 0], collapse = ", ")))

analytical <- analytical |>
  arrange(country_code, year) |>
  group_by(country_code) |>
  mutate(gdp_per_capita_growth = 100 * (gdp_per_capita / lag(gdp_per_capita) - 1)) |>
  ungroup()
first_year <- analytical |> group_by(country_code) |> slice(1) |> ungroup()
fail_if(any(!is.na(first_year$gdp_per_capita_growth)), "Growth computed for a first year: lag() misaligned")

write.csv(analytical, "data/processed/analytical.csv", row.names = FALSE, na = "")