library(tidyverse)
library(googledrive)
library(duckplyr)

# download files saved to google drive - originally from LMI website
econ_drive <- shared_drive_get("SDO Econ")

# get list of files in LMI folder
lmi_files <- drive_ls(as_id(
  "https://drive.google.com/drive/folders/1BcTlbPCqHpZ1qVgUGbrM8GUX0lGtXAMY"
))

# download files that don't already exist
map2(
  lmi_files$id,
  lmi_files$name,
  \(x, y) {
    drive_download(
      as_id(x),
      path = paste0("data/qcew_raw/lmi/", y)
    )
  }
)

# read in lmi files
qcew_lmi_raw <- read_csv_duckdb("data/qcew_raw/lmi/*.csv")
qcew_lmi_raw |> head() |> glimpse()

# get period/periodtype combinations to determine annual
qcew_lmi_raw |>
  distinct(Periodtype, Period) |>
  arrange(Periodtype, Period)

#annual appears to be periodtype 1 and period 00

qcew_lmi_industries <- qcew_lmi_raw |>
  distinct(Code, Title, Naicsector, Industry) |>
  arrange(Code)

qcew_lmi_example <- qcew_lmi_raw |>
  filter(
    Area == "000000" &
      Periodyear == 2024 &
      Period == "00" &
      Ownership == "50"
  ) |>
  glimpse() |>
  arrange(SortIndCode)

qcew_lmi_raw |>
  distinct(Areatype, Area) |>
  arrange(Areatype, Area)


qcew_lmi <- qcew_lmi_raw |>
  # filter to annual data only
  filter(Period == "00") |>
  mutate(
    county_fips = dd$right(Area, 3L)
  ) |> 
  select(
    county_fips,
    Areaname,
    Periodyear,
    Ownership,
    OwnershipDesc,
    Code,
    Title,
    Avgemp,
    Estab:Timeperiod

  )
  
compute_csv(qcew_lmi, "data/qcew_lmi.csv")
