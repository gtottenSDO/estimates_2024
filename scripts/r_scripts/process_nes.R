library(tidyverse)
library(DBI)
library(RPostgres)
library(dbplyr)
library(censusapi)
library(sdodemog)


conn_pg <- connect_to_sdo_db()

# load crosswalk for NAICS codes
xwalk_naics_years <- tbl(conn_pg, Id(schema = "xwalk", table = "naics_long_year"))

# get available years using censusapi
nes_info <- listCensusApis() |>
  filter(name == "nonemp")

nes_yrs_raw <- nes_info |>
  pull(vintage)


# load NES variables for most recent year
nes_vars <- listCensusMetadata(
  name = "nonemp",
  vintage = max(nes_yrs_raw),
  type = "variables"
)

fn_get_nes_data <- function(vintage) {
  # get list of variables for vintage
  nes_vars <- listCensusMetadata(
    name = "nonemp",
    vintage = vintage,
    type = "variables"
  ) |>
    filter(
      is.na(predicateOnly) &
        !(name %in% c("STATE", "COUNTY"))
    ) |>
    pull(name)

  # get NES data for a given year
  data <- getCensus(
    name = "nonemp",
    vintage = vintage,
    vars = nes_vars,
    region = "county:*",
    regionin = "state:08"
  ) |>
    mutate(
      vintage = vintage,
      .before = 1
    ) |>
    # rename variables to lowercase
    rename_with(tolower) |>
    # rename naics to match QCEW
    rename_with(
      ~"naics",
      matches("naics\\d{2,4}_")
    )

  return(data)
}

nes_raw <- tbl(conn_pg, Id(schema = "econ", table = "estimates_nes_raw"))

nes_yrs_db <- nes_raw |>
  pull(vintage) |>
  unique()

nes_yrs_qry <- nes_info |>
  select(vintage) |>
  filter(vintage >= 2000 & !(vintage %in% nes_yrs_db)) |>
  pull(vintage) |>
  unique()


# Create table of relevant NES data
nes_data <- nes_raw |>
  mutate(
    area_id = paste0(state, county),
    naics = if_else(
      industry_code == "00",
      "10",
      industry_code
    )
  ) |> 
  left_join(
    xwalk_naics_years, by = c("vintage" = "year", "naics")
  ) |>
  select(
    year = vintage,
    area_id,
    naics = industry_code,
    prop = nestab,
    inc = nrcptot,
    f_prop = nestab_f,
    f_inc = nrcptot_f
  ) |> 
  distinct() |> 
  arrange(year, area_id, naics) |> 
  show_query()

nes_county <- tbl(conn_pg, Id(schema = "econ", table = "estimates_prop_county"))

xwalk_region <- tbl(conn_pg, Id(schema = "xwalk", table = "area_county"))

nes_region <- nes_county |> 
  filter(lvl %in% c("0", "2", "3")) |>
  left_join(
    xwalk_region, by = "county_fips"
  ) |> 
  summarize(
    prop = sum(prop),
    inc = sum(inc),
    f_prop = count(f_prop),
    f_inc = count(f_inc),
    .by = c(year, area_type, area_id, lvl, naics)
  ) |> 
  arrange(year, area_id, naics) |>
  show_query()
