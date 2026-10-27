-- sqlite3 austin311.db < sql/01_load.sql
-- Source: https://data.austintexas.gov/resource/xwdj-i9he.csv?$where=sr_created_date between '2025-01-01' and '2025-12-31T23:59:59'&$limit=400000
.mode csv
DROP TABLE IF EXISTS raw_311;
.import data/austin311_2025.csv raw_311
