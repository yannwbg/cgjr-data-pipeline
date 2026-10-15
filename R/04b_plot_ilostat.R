library(dplyr)
library(ggplot2)

ilostat <- read.csv("data/processed/ilostat_long.csv", stringsAsFactors = FALSE)
countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
config <- read.csv("config/ilostat_indicators.csv", stringsAsFactors = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

if (anyDuplicated(ilostat[, c("country_code", "year", "indicator")])) {
  stop("Duplicate ILOSTAT keys: the plot would be misleading.")
}
if (length(unique(ilostat$unit)) != 1L) stop("Expected one unit for the ILOSTAT indicator.")

years <- seq(min(countries$start_year), max(countries$end_year))
plot_data <- expand.grid(country_code = countries$country_code, year = years,
                         stringsAsFactors = FALSE) |>
  left_join(countries[, c("country_code", "country_name")], by = "country_code") |>
  left_join(ilostat[, c("country_code", "year", "value")], by = c("country_code", "year"))

y_label <- paste0(unique(config$label), " (", unique(ilostat$unit), ")")
caption_text <- paste0(
  "Source: ILOSTAT, International Labour Organization. Indicator ",
  paste(unique(config$indicator), collapse = ", "), " (",
  paste(unique(config$sex), collapse = ", "), ", ",
  paste(unique(config$classif1), collapse = ", "),
  "). Gaps mark years with no observation."
)
caption_text <- paste(strwrap(caption_text, width = 90), collapse = "\n")

chart <- ggplot(plot_data, aes(year, value, colour = country_name, group = country_name)) +
  geom_line(na.rm = FALSE) +
  geom_point(size = 1.2, na.rm = TRUE) +
  scale_x_continuous(breaks = seq(min(years), max(years), by = 2)) +
  labs(
    title = "Employment-to-population ratio by country",
    subtitle = paste0(min(years), "-", max(years), ". Descriptive; no causal interpretation."),
    x = "Year", y = y_label, colour = "Country", caption = caption_text
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")

ggsave("outputs/figures/ilostat_employment_to_population.png", chart, width = 8, height = 5, dpi = 150)
