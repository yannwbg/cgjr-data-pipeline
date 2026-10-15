source("R/00_checks.R")
check_config()
config <- read.csv("config/ilostat_indicators.csv", stringsAsFactors = FALSE)
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)

base_url <- "https://rplumber.ilo.org/data/indicator/?id="
indicators <- unique(config$indicator_id)

raw <- do.call(rbind, lapply(indicators, function(code) {
  url <- paste0(base_url, code, "&ver=1.0.0&format=.csv.gz")
  tmp <- tempfile(fileext = ".csv.gz")
  tryCatch(
    download.file(url, tmp, mode = "wb", quiet = TRUE),
    error = function(e) stop("ILOSTAT download failed for ", code, ": ", conditionMessage(e), call. = FALSE)
  )
  first_line <- readLines(gzfile(tmp), n = 1L, warn = FALSE)
  fail_if(length(first_line) == 0L || grepl("^\\s*<", first_line[1]), paste("ILOSTAT returned no CSV for", code))
  part <- read.csv(gzfile(tmp), stringsAsFactors = FALSE)
  fail_if(nrow(part) == 0L, paste("ILOSTAT returned zero rows for", code))
  part
}))
if (nrow(raw) == 0L) stop("ILOSTAT returned no observations.")
fail_if(!all(config$indicator %in% raw$indicator),
        paste("ILOSTAT download lacks:", paste(setdiff(config$indicator, raw$indicator), collapse = ", ")))

write.csv(raw, "data/raw/ilostat.csv", row.names = FALSE, na = "")
write.csv(
  data.frame(
    source = "ILOSTAT",
    source_url = base_url,
    indicator = paste(indicators, collapse = ";"),
    retrieved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  ),
  "data/raw/ilostat_retrieval.csv", row.names = FALSE
)
