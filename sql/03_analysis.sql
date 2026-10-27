-- Austin 311 service requests, calendar year 2025
-- Main question: where do requests wait the longest, and is service consistent across council districts?
.headers on
.mode column

-- Requests that count toward response time: closed, not duplicates
DROP VIEW IF EXISTS v_closed;
CREATE VIEW v_closed AS
SELECT * FROM sr WHERE status = 'Closed' AND days_to_close IS NOT NULL;

-- Q1. Citywide KPIs
WITH ranked AS (
    SELECT days_to_close,
           ROW_NUMBER() OVER (ORDER BY days_to_close) AS rn,
           COUNT(*) OVER () AS n
    FROM v_closed
)
SELECT (SELECT COUNT(*) FROM sr)                                         AS total_requests,
       (SELECT ROUND(100.0 * SUM(is_duplicate) / COUNT(*), 1) FROM sr)   AS pct_duplicate,
       MAX(n)                                                            AS closed_requests,
       ROUND(MAX(CASE WHEN rn = (n + 1) / 2 THEN days_to_close END), 2)  AS median_days,
       ROUND(MAX(CASE WHEN rn = CAST(n * 0.9 AS INT) THEN days_to_close END), 1) AS p90_days,
       ROUND(100.0 * SUM(days_to_close <= 1) / MAX(n), 1)               AS pct_within_1_day,
       ROUND(100.0 * SUM(days_to_close <= 7) / MAX(n), 1)               AS pct_within_7_days,
       ROUND(100.0 * SUM(days_to_close > 30) / MAX(n), 1)               AS pct_over_30_days
FROM ranked;

-- Q2. Department scorecard (median and 90th percentile days to close)
DROP TABLE IF EXISTS dept_scorecard;
CREATE TABLE dept_scorecard AS
WITH ranked AS (
    SELECT department_clean, days_to_close,
           ROW_NUMBER() OVER (PARTITION BY department_clean ORDER BY days_to_close) AS rn,
           COUNT(*)     OVER (PARTITION BY department_clean) AS n
    FROM v_closed
)
SELECT department_clean AS department,
       MAX(n) AS closed_requests,
       ROUND(100.0 * MAX(n) / (SELECT COUNT(*) FROM v_closed), 1) AS pct_of_volume,
       ROUND(MAX(CASE WHEN rn = (n + 1) / 2 THEN days_to_close END), 1) AS median_days,
       ROUND(MAX(CASE WHEN rn = CAST(n * 0.9 AS INT) THEN days_to_close END), 1) AS p90_days,
       ROUND(100.0 * SUM(days_to_close <= 7) / MAX(n), 1) AS pct_within_7_days
FROM ranked
GROUP BY department_clean
HAVING MAX(n) >= 1000;
SELECT * FROM dept_scorecard ORDER BY closed_requests DESC;

-- Q3. Request types: high volume AND slow = where a fix moves the most residents
DROP TABLE IF EXISTS type_scorecard;
CREATE TABLE type_scorecard AS
WITH ranked AS (
    SELECT request_type, department_clean, days_to_close,
           ROW_NUMBER() OVER (PARTITION BY request_type ORDER BY days_to_close) AS rn,
           COUNT(*)     OVER (PARTITION BY request_type) AS n
    FROM v_closed
)
SELECT request_type, MAX(department_clean) AS department,
       MAX(n) AS closed_requests,
       ROUND(MAX(CASE WHEN rn = (n + 1) / 2 THEN days_to_close END), 1) AS median_days,
       ROUND(MAX(CASE WHEN rn = CAST(n * 0.9 AS INT) THEN days_to_close END), 1) AS p90_days,
       ROUND(100.0 * SUM(days_to_close <= 7) / MAX(n), 1) AS pct_within_7_days,
       ROUND(SUM(days_to_close)) AS total_open_days
FROM ranked
GROUP BY request_type
HAVING MAX(n) >= 1000;

-- "Resident-days waiting": volume x time. Top 10 types account for most of the waiting.
SELECT request_type, closed_requests, median_days, p90_days, pct_within_7_days,
       total_open_days,
       ROUND(100.0 * total_open_days / (SELECT SUM(days_to_close) FROM v_closed), 1) AS pct_of_all_wait
FROM type_scorecard ORDER BY total_open_days DESC LIMIT 10;

-- Q4. Channel shift: phone vs. app/web by month
SELECT created_month,
       COUNT(*) AS requests,
       ROUND(100.0 * SUM(channel = 'Phone') / COUNT(*), 1) AS pct_phone,
       ROUND(100.0 * SUM(channel IN ('Spot311 Interface','Citizen Web Intake','Mobile Device','Mobile Created','Web','Chat')) / COUNT(*), 1) AS pct_digital
FROM sr GROUP BY created_month ORDER BY created_month;

-- Q5. Is service equal across council districts?
-- Raw averages are misleading because districts file different kinds of requests.
-- So: expected on-time rate = what the district would get if each of its requests closed at
-- the citywide rate for that request type. Gap = actual - expected.
DROP TABLE IF EXISTS district_equity;
CREATE TABLE district_equity AS
WITH type_rate AS (
    SELECT request_type, AVG(days_to_close <= 7) AS city_rate_7d
    FROM v_closed GROUP BY request_type
)
SELECT c.council_district,
       COUNT(*)                                        AS closed_requests,
       ROUND(100.0 * AVG(c.days_to_close <= 7), 1)     AS actual_pct_7d,
       ROUND(100.0 * AVG(t.city_rate_7d), 1)           AS expected_pct_7d,
       ROUND(100.0 * (AVG(c.days_to_close <= 7) - AVG(t.city_rate_7d)), 1) AS gap_pts
FROM v_closed c
JOIN type_rate t USING (request_type)
WHERE c.council_district IS NOT NULL
GROUP BY c.council_district;
SELECT * FROM district_equity ORDER BY gap_pts;

-- Q6. What was still open at year end, by age? (data pulled Oct 2026)
SELECT department_clean,
       COUNT(*) AS still_open,
       ROUND(AVG(julianday('2026-10-27') - julianday(created_at))) AS avg_age_days
FROM sr WHERE status IN ('Open','Work In Progress','Pending')
GROUP BY department_clean ORDER BY still_open DESC LIMIT 8;
