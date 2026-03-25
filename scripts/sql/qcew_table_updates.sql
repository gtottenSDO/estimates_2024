
CREATE OR REPLACE
TABLE firm_listing AS
SELECT
	*
FROM
(
	(
	SELECT
		*
	FROM
		(
		SELECT
			"year",
			qcew_views.t_equi.seasid,
			qcew_views.t_equi.naics AS naics6_code,
			qcew_views.t_equi.own_code,
			qcew_views.t_equi.county_fips,
			"first"(LGLNM) AS lglname,
			"first"(TRDNM) AS trdname,
			"first"(concat_ws(', ', PL_ADD1, PL_ADD2)) AS pl_add,
			"first"(PL_CITY) AS pl_city,
			"first"(PL_STATE) AS pl_state,
			"first"(PL_ZIP) AS pl_zip,
			sum(qcew_views.t_equi.AVG_EMP_ANNUAL_SHARE) AS avg_emp_annual,
			sum(qcew_views.t_equi.TOTAL_WAGES) AS tot_wages_annual,
			sum(qcew_views.t_equi.TAX_WAGES) AS tax_wages_annual,
			'00' AS naics0_code
		FROM
			qcew_views.t_equi
		GROUP BY
			"year",
			qcew_views.t_equi.seasid,
			qcew_views.t_equi.naics,
			qcew_views.t_equi.own_code,
			qcew_views.t_equi.county_fips,
			naics0_code
			)
UNION
	(
	SELECT 
		"year",
		pre2013annual.equisesakey AS seasid,
		pre2013annual.naics AS naics6_code,
		pre2013annual.own_code,
		pre2013annual.cnty AS county_fips,
		lglname,
		trdname,
		pl_add1 AS pl_add,
		pl_city,
		pl_state,
		pl_zip,
		avg_emp AS avg_emp_annual,
		total_wages tot_wages_annual,
		NULL AS tax_wages_annual,
		'00' AS naics0_code
	FROM
		pre2013annual
		)
)
NATURAL JOIN 
xwalks.xwalk_qcew_naics_year
NATURAL JOIN 
(SELECT COLUMNS('naics._code|sector_code|_year') FROM xwalks.xwalks_qcew_naics )
);

CREATE OR REPLACE TABLE qcew_emp AS
SELECT 
		"year",
		lvl,
		county_fips,
		own_code,
		naics_code AS naics,
		sum(AVG_EMP_ANNUAL) AS employment,
		sum(TOT_WAGES_ANNUAL) AS wages,
		max(avg_emp_annual) AS largest_firm,
		count() AS total_firms
FROM (
 (
UNPIVOT firm_listing ON 
COLUMNS('naics._code|sector_code')
INTO
	NAME naics_lvl
	VALUE naics_code
) 
NATURAL JOIN xwalks.naics_levels)
GROUP BY
		"year",
		lvl,
		county_fips,
		own_code,
		naics
ORDER BY
	county_fips,
	"year",
	lvl,
	own_code,
	naics;