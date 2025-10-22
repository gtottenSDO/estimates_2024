# download QCEW data for all years
params$est_year <- 2024

# create list of download URLs
download_urls <- paste0(
  "https://data.bls.gov/cew/data/files/",
  1990:params$est_year,
  "/csv/",
  1990:params$est_year,
  "_annual_by_area.zip"
)

# create list of destination files
dest_files <- paste0(
  "data/qcew_raw/zip/",
  1990:params$est_year,
  "_annual_by_area.zip"
)

# filter out files that already exist
download_urls <- download_urls[file.exists(dest_files) == FALSE]

download.file(download_urls, dest_files, method = "libcurl")

zip_list <- list.files("data/qcew_raw/zip", full.names = TRUE)

zip_file_list <- map(zip_list, function(zip_file) {
  file_list <- unzip(zip_file, list = TRUE) |>
    filter(str_detect(Name, "Colorado")) |>
    pull(Name)

  unzip(
    zip_file,
    files = file_list,
    exdir = "data/qcew_raw/csv",
    overwrite = FALSE,
    junkpaths = TRUE
  )
})


# read file layout from qcew documentation
qcew_layout <- read_csv(
  # "https://www.bls.gov/cew/about-data/downloadable-file-layouts/annual/naics-based-annual-layout-csv.csv"
  "data/crosswalks/naics-based-annual-layout-csv.csv"
) |>
  mutate(
    duckdb_type = case_when(
      data_type == "Text" ~ "VARCHAR",
      data_type == "Date" ~ "DATE",
      data_type == "Numeric" ~ "DOUBLE",
      TRUE ~ "VARCHAR"
    )
  )


# read all files into single table
qcew_files <- list.files("data/qcew_raw/csv", full.names = TRUE)

# commented out to avoid overwriting existing table
dbRemoveTable(conn$qcew, "qcew") # remove table if it exists

qcew_db <- duckdb_read_csv(
  conn$qcew,
  name = "qcew",
  qcew_files,
  col.names = qcew_layout$field_name,
  col.types = qcew_layout$duckdb_type
)
