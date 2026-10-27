# Tableau dashboard

Data source: `output/requests_by_month_type.csv` (one row per month / department / type / channel / district), plus the three scorecard files.

**Calculated fields**
- `% Closed in 7 Days` = `SUM([Closed Within 7d]) / SUM([Closed])`
- `Avg Days to Close` = `SUM([Total Days To Close]) / SUM([Closed])`

**Sheets**
1. **Monthly volume** - Columns: `Created Month`. Rows: `SUM(Requests)`. Color: `Department` (top 6, group the rest).
2. **Wait time by request type** - From `request_type_scorecard.csv`. Rows: `Request Type` (top 10). Columns: `Total Open Days`. Label with `Median Days`.
3. **District equity** - From `district_equity.csv`. Columns: `Council District`. Rows: `Actual Pct 7d` and `Expected Pct 7d` side by side. Optional: load the City of Austin council district shapefile for a map colored by `Gap Pts`.
4. **Department scorecard** - Table of department, closed requests, median days, 90th percentile days, % within 7 days.

**Dashboard:** KPI tiles (298,920 requests, 1.1 day median, 78.6% closed in 7 days), then sheets 1 and 2, then 3 and 4. Filters: Department, Channel, Month.

Published version: _add your Tableau Public link here_
