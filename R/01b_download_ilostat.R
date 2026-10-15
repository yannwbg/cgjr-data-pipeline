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
  read.csv(gzfile(tmp), stringsAsFactors = FALSE)
}))
if (nrow(raw) == 0L) stop("ILOSTAT returned no observations.")

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
