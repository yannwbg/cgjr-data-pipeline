library(dplyr)
library(ggplot2)

source("R/00_checks.R")

analytical <- read.csv("data/processed/analytical.csv", stringsAsFactors = FALSE)
countries <- read.csv("config/countries.csv", stringsAsFactors = FALSE)
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

chart <- ggplot(analytical, aes(year, gdp_growth, colour = country_name)) +
  geom_line(na.rm = FALSE) +
  labs(
    title = "GDP Growth by Country", x = "Year", y = "Annual growth (%)",
    colour = "Country", caption = "Source: World Bank, World Development Indicators."
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave("outputs/figures/gdp_growth.png", chart, width = 8, height = 5, dpi = 150)

summary_table <- analytical |>
  filter(!is.na(gdp_growth)) |>
  arrange(country_code, desc(year)) |>
  group_by(country_code, country_name) |>
  slice(1) |>
  ungroup() |>
  select(country_code, country_name, year, gdp_growth)
expected_year <- analytical |>
  filter(!is.na(gdp_growth)) |>
  group_by(country_code) |>
  summarise(latest = max(year), .groups = "drop")
chk <- inner_join(summary_table, expected_year, by = "country_code")
fail_if(nrow(chk) != nrow(countries) || any(chk$year != chk$latest),
        "Summary must have one row per country at its latest year with data")
chk2 <- inner_join(summary_table, analytical, by = c("country_code", "year"))
fail_if(nrow(chk2) != nrow(summary_table) || any(abs(chk2$gdp_growth.x - chk2$gdp_growth.y) > 1e-9),
        "Summary values disagree with analytical.csv")
write.csv(summary_table, "outputs/tables/country_summary.csv", row.names = FALSE)