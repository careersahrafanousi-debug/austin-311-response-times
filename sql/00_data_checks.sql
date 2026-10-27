.headers on
.mode column
-- 1. Duplicate request numbers?
SELECT COUNT(*) rows, COUNT(DISTINCT sr_number) unique_requests FROM sr;
-- 2. Status mix
SELECT status, COUNT(*) n FROM sr GROUP BY status ORDER BY n DESC;
-- 3. Closed before created (bad timestamps)?
SELECT SUM(days_to_close < 0) negative_durations, SUM(days_to_close IS NULL AND status = 'Closed') closed_no_date FROM sr;
-- 4. Missing location
SELECT SUM(council_district IS NULL) no_district, ROUND(100.0*SUM(council_district IS NULL)/COUNT(*),1) pct FROM sr;
