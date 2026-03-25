CREATE SCHEMA IF NOT EXISTS qcew_views;
-- qcew.qcew_views.t_equi source

CREATE OR REPLACE
VIEW qcew_views.t_equi AS
SELECT
	EIN,
	CAST("YEAR" AS DOUBLE) AS "year",
	CAST("Quarter" AS DOUBLE) AS qtr,
	concat(UI_ACCT_NUM, RUN) AS seasid,
	UI_ACCT_NUM,
	RUN,
	LGLNM,
	TRDNM,
	PL_ADD1,
	PL_ADD2,
	PL_CITY,
	PL_STATE,
	PL_ZIP,
	naics,
	OWN_CODE,
	CNTY AS county_fips,
	LATITUDE,
	LONGITUDE,
	CAST(M1EMP AS DOUBLE) AS m1emp,
	CAST(M2EMP AS DOUBLE) AS m2emp,
	CAST(M3EMP AS DOUBLE) AS m3emp,
	(((CAST(M1EMP AS DOUBLE) + CAST(M2EMP AS DOUBLE)) + CAST(M3EMP AS DOUBLE)) / 3) AS avg_emp,
	(AVG_EMP / 4) AS avg_emp_annual_share,
	CAST(TOTAL_WAGES AS DOUBLE) AS total_wages,
	CAST(TAX_WAGES AS DOUBLE) AS tax_wages
FROM
	qcew
WHERE
	((county_fips != '900')
		AND ("Quarter" IN (1, 2, 3, 4)));


CREATE OR REPLACE VIEW qcew_views.private_emp AS
SELECT 
"year",
lvl,
county_fips,
naics,
employment,
wages,
largest_firm,
total_firms
FROM qcew_emp 
WHERE own_code == 5;

CREATE OR REPLACE VIEW
qcew_views.public_emp AS
SELECT
"year",
lvl,
county_fips,
naics,
sum(employment) AS employment,
sum(wages) AS wages,
max(largest_firm) AS largest_firm,
sum(total_firms) AS total_firms
FROM (
SELECT
"year",
lvl,
county_fips,
CASE WHEN lvl == '1' THEN '1001' ELSE '0' END || repeat(own_code, CAST(lvl AS integer) - 1) AS naics,
employment,
wages,
largest_firm,
total_firms
FROM qcew_emp 
WHERE NOT (own_code == 5 OR own_code == 0)
)
GROUP BY
	"year",
	lvl,
	county_fips,
	naics
ORDER BY "year", lvl, county_fips, naics;


CREATE OR REPLACE VIEW
qcew_views.total_emp AS
(SELECT
"year",
0 AS lvl,
county_fips,
'10' AS naics,
sum(employment) AS employment,
sum(wages) AS wages,
max(largest_firm) AS largest_firm,
sum(total_firms) AS total_firms
FROM
(SELECT * FROM
qcew_emp WHERE lvl == 1)
GROUP BY
	"year",
	county_fips)
ORDER BY "year", lvl, county_fips, naics;

CREATE OR REPLACE VIEW
qcew_views.all_emp AS
SELECT * FROM
private_emp 
UNION 
SELECT * FROM 
public_emp
UNION
SELECT * FROM
total_emp
ORDER BY "year", lvl, county_fips, naics;

-- qcew.qcew_views.estimates_emp source

CREATE OR REPLACE VIEW qcew_views.estimates_emp AS
SELECT
    "year",
    area_type,
    area_id,
    lvl,
    naics,
    CAST(sum(employment) AS INTEGER) AS employment,
    sum(wages) AS wages,
    CAST(max(largest_firm) AS INTEGER) AS largest_firm,
    sum(total_firms) AS total_firms
FROM
    (
    SELECT
        *
    FROM
        xwalks.area_county
    NATURAL INNER JOIN qcew_views.all_emp
    WHERE
        (NOT ((county_fips = '900')
            AND ("year" = 2006))))
GROUP BY
    "year",
    lvl,
    area_type,
    area_id,
    naics
ORDER BY
    "year",
    lvl,
    area_id,
    naics;



  
CREATE OR REPLACE VIEW qcew_views.estimates_emp AS
SELECT
	"year",
	lvl,
	area_type,
	area_id,
	naics,
	CAST(sum(employment) AS INTEGER) AS employment,
	sum(wages) AS wages,
	CAST(max(largest_firm) AS INTEGER) AS largest_firm,
	sum(total_firms) AS total_firms
FROM
(
SELECT * FROM
xwalks.area_county
NATURAL JOIN qcew_views.all_emp
WHERE NOT (county_fips == '900' AND year == 2006)
)
GROUP BY
	"year",
	lvl,
	area_type,
	area_id,
	naics
ORDER BY "year", lvl, area_id, naics;
 
-- check estimates_emp totals by lvl
SELECT 
	"year",
	"lvl",
	area_type,
	CAST(sum(employment) AS INTEGER) AS employment,
	sum(wages) AS wages,
	CAST(max(largest_firm) AS INTEGER) AS largest_firm,
	sum(total_firms) AS total_firms
FROM qcew_views.estimates_emp 
GROUP BY 
	"year",
	"lvl",
	area_type
ORDER BY "year", "lvl", area_type;