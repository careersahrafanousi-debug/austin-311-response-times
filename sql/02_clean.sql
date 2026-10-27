-- Clean 311 requests created in 2025.
-- Days to close is measured in calendar days from created to closed.
DROP TABLE IF EXISTS sr;
CREATE TABLE sr AS
SELECT
    sr_number,
    sr_type_desc                         AS request_type,
    sr_department_desc                   AS department,
    sr_method_received_desc              AS channel,
    sr_status_desc                       AS status,
    datetime(sr_created_date)            AS created_at,
    datetime(NULLIF(sr_closed_date, '')) AS closed_at,
    strftime('%Y-%m', sr_created_date)   AS created_month,
    NULLIF(sr_location_zip_code, '')     AS zip,
    NULLIF(sr_location_council_district, '') AS council_district,
    CASE WHEN sr_closed_date <> ''
         THEN julianday(sr_closed_date) - julianday(sr_created_date) END AS days_to_close,
    CASE WHEN sr_status_desc LIKE 'Duplicate%' THEN 1 ELSE 0 END AS is_duplicate
FROM raw_311
WHERE sr_status_desc <> 'CancelledTesting';
CREATE INDEX ix_sr_type ON sr(request_type);

-- The city renamed most departments around September 2025 (e.g. "Austin Police Department"
-- became "Austin Police"). Without this mapping, every department looks like two half-size teams.
DROP TABLE IF EXISTS dept_map;
CREATE TABLE dept_map (source_name TEXT PRIMARY KEY, department_clean TEXT);
INSERT INTO dept_map VALUES
 ('Transportation and Public Works',        'Transportation & Public Works'),
 ('Austin Transportation and Public Works', 'Transportation & Public Works'),
 ('Animal Services Office',                 'Animal Services'),
 ('Austin Animal Services',                 'Animal Services'),
 ('Development Services Department',        'Development Services'),
 ('Austin Development Services',            'Development Services'),
 ('Austin Police Department',               'Police (non-emergency)'),
 ('Austin Police',                          'Police (non-emergency)'),
 ('Austin Energy Department',               'Austin Energy'),
 ('Austin Energy',                          'Austin Energy'),
 ('Parks & Recreation Department',          'Parks & Recreation'),
 ('Austin Parks and Recreation',            'Parks & Recreation'),
 ('Public Health',                          'Public Health'),
 ('Austin Public Health',                   'Public Health'),
 ('Watershed Protection',                   'Watershed Protection'),
 ('Austin Watershed Protection',            'Watershed Protection'),
 ('Austin Fire Department',                 'Fire'),
 ('Austin Fire',                            'Fire'),
 ('Housing',                                'Housing'),
 ('Austin Housing',                         'Housing'),
 ('(Tara) Financial Services Depart',       'Financial Services'),
 ('Austin Financial Services',              'Financial Services'),
 ('311-Client and Information Servi',       '311 Call Center'),
 ('311-Client and Information Services',    '311 Call Center'),
 ('311-Command Center',                     '311 Call Center'),
 ('Austin Resource Recovery',               'Resource Recovery (trash/recycling)'),
 ('Austin Water',                           'Austin Water');

ALTER TABLE sr ADD COLUMN department_clean TEXT;
UPDATE sr SET department_clean = COALESCE(
    (SELECT department_clean FROM dept_map m WHERE m.source_name = sr.department), 'Other');
