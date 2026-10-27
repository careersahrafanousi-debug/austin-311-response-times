# Charts for the README. Reads the CSVs produced by sql/04_export.sql
import pandas as pd, matplotlib.pyplot as plt
plt.rcParams.update({"font.size":11,"axes.spines.top":False,"axes.spines.right":False,"axes.titleweight":"bold","axes.titlelocation":"left"})
BLUE, ORANGE, GRAY = "#4E79A7", "#F28E2B", "#BAB0AC"
t = pd.read_csv("output/request_type_scorecard.csv").head(8).iloc[::-1]
ax = t.plot.barh(x="request_type", y="total_open_days", color=[ORANGE if i>=5 else GRAY for i in range(len(t))], legend=False, figsize=(9.5,4.5))
ax.set_title("3 request types = 1/3 of all wait time")
ax.set_xlabel("Total days requests stayed open (2025)"); ax.set_ylabel("")
ax.xaxis.set_major_formatter(lambda x,p: f"{x/1000:.0f}K"); plt.tight_layout(); plt.savefig("images/wait_days_by_type.png", dpi=150); plt.close()

d = pd.read_csv("output/district_equity.csv").sort_values("actual_pct_7d")
fig, ax = plt.subplots(figsize=(8,4.5))
x = range(len(d))
ax.bar([i-0.2 for i in x], d.actual_pct_7d, 0.4, color=BLUE, label="Actual % closed in 7 days")
ax.bar([i+0.2 for i in x], d.expected_pct_7d, 0.4, color=GRAY, label="Expected for its request mix")
ax.set_xticks(list(x)); ax.set_xticklabels([f"D{int(c)}" for c in d.council_district])
ax.set_ylim(70, 86); ax.set_ylabel("% closed within 7 days")
ax.set_title("District gaps disappear once request mix is accounted for")
ax.legend(frameon=False, loc="upper left"); plt.tight_layout(); plt.savefig("images/district_equity.png", dpi=150)
