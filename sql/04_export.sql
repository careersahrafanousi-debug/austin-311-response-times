-- Export tables for Tableau (aggregated so the files stay small)
.headers on
.mode csv
.output output/requests_by_month_type.csv
SELECT created_month, department_clean AS department, request_type, channel, council_district,
       COUNT(*) AS requests,
       SUM(status = 'Closed') AS closed,
       SUM(is_duplicate) AS duplicates,
       SUM(CASE WHEN status = 'Closed' AND days_to_close <= 7 THEN 1 ELSE 0 END) AS closed_within_7d,
       ROUND(SUM(CASE WHEN status = 'Closed' THEN days_to_close ELSE 0 END), 2) AS total_days_to_close
FROM sr
GROUP BY 1, 2, 3, 4, 5;
.output output/department_scorecard.csv
SELECT * FROM dept_scorecard ORDER BY closed_requests DESC;
.output output/request_type_scorecard.csv
SELECT * FROM type_scorecard ORDER BY total_open_days DESC;
.output output/district_equity.csv
SELECT * FROM district_equity ORDER BY CAST(council_district AS INT);
.output stdout
