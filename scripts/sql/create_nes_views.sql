CREATE OR REPLACE VIEW econ.estimates_prop_county AS
SELECT "q01".*
FROM (
  SELECT
    "vintage" AS "year",
    "county" AS "county_fips",
    "LHS"."naics",
    CASE WHEN ("LHS"."naics" = '10') THEN '0' ELSE "lvl" END AS "lvl",
    "nestab" AS "prop",
    "nrcptot" AS "inc",
    "nestab_f" AS "f_prop",
    "nrcptot_f" AS "f_inc"
  FROM (
    SELECT
      "estimates_nes_raw".*,
      CASE WHEN ("industry_code" = '00') THEN '10' WHEN NOT ("industry_code" = '00') THEN "industry_code" END AS "naics"
    FROM "econ"."estimates_nes_raw"
  ) AS "LHS"
  LEFT JOIN "xwalk"."naics_long_year"
    ON (
      "LHS"."vintage" = "naics_long_year"."year" AND
      "LHS"."naics" = "naics_long_year"."naics"
    )
) AS "q01"
ORDER BY "year", "county_fips", "naics"

CREATE OR REPLACE VIEW econ.estimates_prop AS
SELECT
  "year",
  "area_type",
  "area_id",
  "lvl",
  "naics",
  SUM("prop") AS "prop",
  SUM("inc") AS "inc",
  count("f_prop") AS "f_prop",
  count("f_inc") AS "f_inc"
FROM (
  SELECT "LHS".*, "area_type", "area_id"
  FROM (
    SELECT "estimates_prop_county".*
    FROM "econ"."estimates_prop_county"
    WHERE ("lvl" IN ('0', '2', '3'))
  ) AS "LHS"
  LEFT JOIN "xwalk"."area_county"
    ON ("LHS"."county_fips" = "area_county"."county_fips")
) AS "q01"
GROUP BY "year", "area_type", "area_id", "lvl", "naics"
ORDER BY "year", "area_id", "naics"

