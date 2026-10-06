"""
UK ROAD COLLISION ANALYTICS — 2023
Python end-to-end analysis file

SOURCE:
dft-road-casualty-statistics-collision-2023.csv

RULE:
Every analysis section starts with the business question and explains
why the code is being used. Run this file from the repository root.
"""

# ============================================================
# 0. IMPORT LIBRARIES
# ============================================================
# BUSINESS QUESTION:
# What tools do we need to audit, clean and analyse the collision data?
#
# WHY ARE WE DOING THIS?
# pandas handles tabular data, numpy supports numerical checks,
# matplotlib/seaborn support exploratory visual analysis, and pathlib
# keeps the file path portable across machines.

from pathlib import Path
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

pd.set_option("display.max_columns", None)
pd.set_option("display.max_rows", 100)

DATA_PATH = Path("dft-road-casualty-statistics-collision-2023.csv")
CLEANED_PATH = Path("road_collision_2023_cleaned.csv")

# ============================================================
# 1. LOAD THE RAW DATA
# ============================================================
# BUSINESS QUESTION:
# Can we load the official 2023 collision dataset correctly?
#
# WHY ARE WE DOING THIS?
# The raw CSV is the single source of truth. We first load it without
# changing the records so every later transformation can be audited.

df = pd.read_csv(DATA_PATH, low_memory=False)

print("Dataset loaded successfully.")
print("Rows:", df.shape[0])
print("Columns:", df.shape[1])

# Expected raw size for this project: 104,258 rows and 44 columns.

# ============================================================
# 2. UNDERSTAND THE DATASET STRUCTURE
# ============================================================
# BUSINESS QUESTION:
# What fields are available and what type of data does each field contain?
#
# WHY ARE WE DOING THIS?
# We need to distinguish identifiers, numeric measures, coded categories,
# dates/times and geographic fields before choosing analytical methods.

print("\nColumn names:")
print(df.columns.tolist())

print("\nData types:")
print(df.dtypes)

print("\nFirst five rows:")
print(df.head())

print("\nLast five rows:")
print(df.tail())

# ============================================================
# 3. CHECK DATASET SIZE AND BASIC STATISTICS
# ============================================================
# BUSINESS QUESTION:
# What is the scale and numerical profile of the raw dataset?
#
# WHY ARE WE DOING THIS?
# Basic descriptive statistics help detect unexpected ranges before cleaning.

print("\nDataset shape:", df.shape)
print("\nNumerical summary:")
print(df.describe().T)

# ============================================================
# 4. CHECK DUPLICATE COLLISION RECORDS
# ============================================================
# BUSINESS QUESTION:
# Are duplicate collision records present?
#
# WHY ARE WE DOING THIS?
# Duplicate collisions would inflate KPIs and trend analysis.
# We check both full-row duplicates and the collision identifier.

print("\nFull-row duplicates:", df.duplicated().sum())
print("Duplicate collision_index values:", df["collision_index"].duplicated().sum())

# ============================================================
# 5. CHECK MISSING VALUES
# ============================================================
# BUSINESS QUESTION:
# Which columns contain missing values and how significant are they?
#
# WHY ARE WE DOING THIS?
# Missing data can affect calculations, but missing does not automatically
# mean that the entire collision record should be deleted.

missing = pd.DataFrame({
    "missing_count": df.isna().sum(),
    "missing_percent": (df.isna().mean() * 100).round(2)
}).sort_values("missing_count", ascending=False)

print("\nMissing-value report:")
print(missing[missing["missing_count"] > 0])

# ============================================================
# 6. CHECK UNIQUE VALUES IN IMPORTANT CODED FIELDS
# ============================================================
# BUSINESS QUESTION:
# What coded categories exist in the main analytical dimensions?
#
# WHY ARE WE DOING THIS?
# STATS19 contains coded fields. Understanding the codes prevents us from
# treating a code such as -1 as a normal business category.

coded_columns = [
    "collision_severity", "day_of_week", "road_type", "speed_limit",
    "junction_control", "light_conditions", "weather_conditions",
    "road_surface_conditions", "urban_or_rural_area",
    "did_police_officer_attend_scene_of_accident", "trunk_road_flag"
]

for col in coded_columns:
    print(f"\n{col}:")
    print(df[col].value_counts(dropna=False).sort_index())

# ============================================================
# 7. VALIDATE DATE RANGE
# ============================================================
# BUSINESS QUESTION:
# Does the dataset actually represent collisions recorded during 2023?
#
# WHY ARE WE DOING THIS?
# A time-series project must confirm that the date field is valid and
# belongs to the intended analysis period.

df["date_parsed"] = pd.to_datetime(df["date"], dayfirst=True, errors="coerce")

print("\nInvalid dates:", df["date_parsed"].isna().sum())
print("Minimum date:", df["date_parsed"].min())
print("Maximum date:", df["date_parsed"].max())

# ============================================================
# 8. VALIDATE TIME VALUES
# ============================================================
# BUSINESS QUESTION:
# Are collision times valid enough for hourly/time-period analysis?
#
# WHY ARE WE DOING THIS?
# Peak-hour analysis depends on correctly parsed time values.

df["time_parsed"] = pd.to_datetime(df["time"], format="%H:%M", errors="coerce")

print("\nInvalid times:", df["time_parsed"].isna().sum())

# ============================================================
# 9. CHECK NUMERIC VALIDITY
# ============================================================
# BUSINESS QUESTION:
# Are vehicles, casualties, speed limits and coordinates within sensible ranges?
#
# WHY ARE WE DOING THIS?
# Impossible negative counts or clearly invalid ranges can distort analysis.
# We flag them before deciding whether any record needs correction.

numeric_checks = {
    "number_of_vehicles": lambda s: s < 1,
    "number_of_casualties": lambda s: s < 1,
    "speed_limit": lambda s: s < 0,
}

for col, rule in numeric_checks.items():
    bad = rule(df[col]).sum()
    print(f"{col} invalid records:", bad)

print("\nSpeed limits present:")
print(sorted(df["speed_limit"].dropna().unique()))

print("\nVehicle count range:", df["number_of_vehicles"].min(),
      "to", df["number_of_vehicles"].max())
print("Casualty count range:", df["number_of_casualties"].min(),
      "to", df["number_of_casualties"].max())

# ============================================================
# 10. CHECK COORDINATE COMPLETENESS
# ============================================================
# BUSINESS QUESTION:
# How complete are the geographic coordinates?
#
# WHY ARE WE DOING THIS?
# Location analysis requires coordinates, but missing coordinates should
# not cause otherwise valid collision records to be removed.

coordinate_columns = ["location_easting_osgr", "location_northing_osgr",
                      "longitude", "latitude"]

print("\nMissing geographic values:")
print(df[coordinate_columns].isna().sum())

# ============================================================
# 11. REMOVE ONLY TRUE DUPLICATES
# ============================================================
# BUSINESS QUESTION:
# Should duplicate rows be removed before analysis?
#
# WHY ARE WE DOING THIS?
# Exact duplicate records would double-count collisions. We remove only
# exact duplicates rather than deleting records because of missing fields.

before = len(df)
df = df.drop_duplicates().copy()
after = len(df)

print(f"Rows before duplicate removal: {before}")
print(f"Rows after duplicate removal:  {after}")
print(f"Rows removed: {before - after}")

# ============================================================
# 12. CREATE BUSINESS-FRIENDLY DATE FEATURES
# ============================================================
# BUSINESS QUESTION:
# Can we convert the date into useful business-analysis dimensions?
#
# WHY ARE WE DOING THIS?
# Month, quarter, weekday and weekend indicators make trends easier to
# analyse in Python, SQL and Power BI.

df["year"] = df["date_parsed"].dt.year
df["month_number"] = df["date_parsed"].dt.month
df["month_name"] = df["date_parsed"].dt.strftime("%B")
df["quarter"] = "Q" + df["date_parsed"].dt.quarter.astype("Int64").astype(str)
df["day_name"] = df["date_parsed"].dt.day_name()
df["is_weekend"] = df["date_parsed"].dt.dayofweek.isin([5, 6]).astype(int)

# ============================================================
# 13. CREATE HOUR AND TIME PERIOD
# ============================================================
# BUSINESS QUESTION:
# When during the day do collisions occur most frequently?
#
# WHY ARE WE DOING THIS?
# Hourly and broad time-period analysis can help identify periods where
# traffic-management or prevention resources may need more attention.

df["hour"] = df["time_parsed"].dt.hour

def classify_time_period(hour):
    if pd.isna(hour):
        return "Unknown"
    hour = int(hour)
    if 0 <= hour < 6:
        return "Night"
    if 6 <= hour < 12:
        return "Morning"
    if 12 <= hour < 17:
        return "Afternoon"
    if 17 <= hour < 21:
        return "Evening"
    return "Late Evening"

df["time_period"] = df["hour"].apply(classify_time_period)

# ============================================================
# 14. CREATE BUSINESS-FRIENDLY LABELS
# ============================================================
# BUSINESS QUESTION:
# Can coded values be translated into labels that are easier to analyse?
#
# WHY ARE WE DOING THIS?
# Numeric codes are useful for storage, but readable labels are better for
# charts, SQL outputs, dashboards and interviews.

severity_map = {
    1: "Fatal",
    2: "Serious",
    3: "Slight"
}

day_map = {
    1: "Sunday",
    2: "Monday",
    3: "Tuesday",
    4: "Wednesday",
    5: "Thursday",
    6: "Friday",
    7: "Saturday"
}

urban_rural_map = {
    1: "Urban",
    2: "Rural",
    3: "Unallocated"
}

df["severity_label"] = df["collision_severity"].map(severity_map).fillna("Unknown")
df["day_of_week_label"] = df["day_of_week"].map(day_map).fillna("Unknown")
df["urban_rural_label"] = df["urban_or_rural_area"].map(urban_rural_map).fillna("Unknown")

# ============================================================
# 15. CREATE A SEVERE-COLLISION FLAG
# ============================================================
# BUSINESS QUESTION:
# How can we consistently identify collisions involving fatal or serious injury?
#
# WHY ARE WE DOING THIS?
# Fatal and serious collisions are the highest-priority severity outcomes,
# so combining them creates a useful risk KPI without changing the source data.

df["is_severe"] = df["collision_severity"].isin([1, 2]).astype(int)

# ============================================================
# 16. RECHECK THE CLEANED DATASET
# ============================================================
# BUSINESS QUESTION:
# Did cleaning and feature engineering preserve the collision records?
#
# WHY ARE WE DOING THIS?
# The row count should remain stable unless a documented data-quality rule
# removes records. This protects us from accidental data loss.

print("\nFinal row count:", len(df))
print("Final column count:", len(df.columns))
print("Remaining exact duplicates:", df.duplicated().sum())

# ============================================================
# 17. BUSINESS QUESTION:
# How many total collisions occurred in 2023?
#
# WHY ARE WE DOING THIS?
# Total collisions are the primary volume KPI for the project.
# ============================================================

total_collisions = df["collision_index"].nunique()
print("\nTotal collisions:", total_collisions)

# ============================================================
# 18. BUSINESS QUESTION:
# How are collisions distributed by severity?
#
# WHY ARE WE DOING THIS?
# Collision count alone does not describe safety impact. Severity shows
# how much of the collision volume resulted in fatal, serious or slight injury.
# ============================================================

severity_summary = (
    df.groupby("severity_label")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .sort_values("collisions", ascending=False)
)

severity_summary["collision_share_pct"] = (
    severity_summary["collisions"] / total_collisions * 100
).round(2)

print("\nSeverity summary:")
print(severity_summary)

# ============================================================
# 19. BUSINESS QUESTION:
# What is the monthly collision trend?
#
# WHY ARE WE DOING THIS?
# Monthly trends help identify seasonal or operational changes during 2023.
# ============================================================

monthly = (
    df.groupby(["month_number", "month_name"])
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .reset_index()
      .sort_values("month_number")
)

print("\nMonthly trend:")
print(monthly)

# ============================================================
# 20. BUSINESS QUESTION:
# Which days of the week have the most collisions?
#
# WHY ARE WE DOING THIS?
# Day-level patterns can support road-safety planning and resource allocation.
# ============================================================

day_summary = (
    df.groupby("day_of_week_label")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .reindex(day_map.values())
)

print("\nDay-of-week analysis:")
print(day_summary)

# ============================================================
# 21. BUSINESS QUESTION:
# What are the peak collision hours?
#
# WHY ARE WE DOING THIS?
# Hourly concentration can indicate periods where traffic control,
# enforcement or preventive interventions may have greater value.
# ============================================================

hourly = (
    df.groupby("hour")
      .agg(collisions=("collision_index", "nunique"))
      .reset_index()
      .sort_values("collisions", ascending=False)
)

print("\nTop collision hours:")
print(hourly.head(10))

# ============================================================
# 22. BUSINESS QUESTION:
# Which broad time periods have the highest collision volume?
#
# WHY ARE WE DOING THIS?
# Broad periods are easier to communicate in dashboards than 24 individual hours.
# ============================================================

period_summary = (
    df.groupby("time_period")
      .agg(collisions=("collision_index", "nunique"))
      .sort_values("collisions", ascending=False)
)

print("\nTime-period analysis:")
print(period_summary)

# ============================================================
# 23. BUSINESS QUESTION:
# Are collisions more common in urban or rural areas?
#
# WHY ARE WE DOING THIS?
# Urban and rural environments have different road, traffic and intervention
# characteristics, so resource planning should compare them separately.
# ============================================================

urban_rural = (
    df.groupby("urban_rural_label")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .sort_values("collisions", ascending=False)
)

print("\nUrban vs rural:")
print(urban_rural)

# ============================================================
# 24. BUSINESS QUESTION:
# How does collision severity differ between urban and rural areas?
#
# WHY ARE WE DOING THIS?
# A location with fewer collisions can still be higher risk if severe outcomes
# represent a larger share of its collisions.
# ============================================================

severity_location = pd.crosstab(
    df["urban_rural_label"],
    df["severity_label"],
    normalize="index"
).mul(100).round(2)

print("\nSeverity mix by urban/rural (%):")
print(severity_location)

# ============================================================
# 25. BUSINESS QUESTION:
# Which speed limits have the highest collision volume?
#
# WHY ARE WE DOING THIS?
# Speed limit is a key road-environment factor. Comparing collision volume
# across speed limits identifies where the collision burden is concentrated.
# ============================================================

speed_summary = (
    df.groupby("speed_limit")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .reset_index()
      .sort_values("collisions", ascending=False)
)

print("\nSpeed-limit analysis:")
print(speed_summary)

# ============================================================
# 26. BUSINESS QUESTION:
# Does collision severity vary by speed limit?
#
# WHY ARE WE DOING THIS?
# Volume and severity are different questions. This cross-tab checks whether
# higher-speed environments have a different severity mix.
# ============================================================

speed_severity = pd.crosstab(
    df["speed_limit"],
    df["severity_label"],
    normalize="index"
).mul(100).round(2)

print("\nSeverity mix by speed limit (%):")
print(speed_severity)

# ============================================================
# 27. BUSINESS QUESTION:
# Which weather conditions are associated with the most collisions?
#
# WHY ARE WE DOING THIS?
# Weather can affect visibility, road grip and driver behaviour, so it is
# useful for identifying conditions where additional caution may be required.
# ============================================================

weather_summary = (
    df.groupby("weather_conditions")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .sort_values("collisions", ascending=False)
)

print("\nWeather-condition analysis:")
print(weather_summary)

# ============================================================
# 28. BUSINESS QUESTION:
# Which road-surface conditions have the highest collision volume?
#
# WHY ARE WE DOING THIS?
# Road surface condition is another environmental risk factor and should be
# compared with collision severity rather than examined only by volume.
# ============================================================

surface_summary = (
    df.groupby("road_surface_conditions")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .sort_values("collisions", ascending=False)
)

print("\nRoad-surface analysis:")
print(surface_summary)

# ============================================================
# 29. BUSINESS QUESTION:
# What is the relationship between number of vehicles and casualties?
#
# WHY ARE WE DOING THIS?
# Multi-vehicle collisions may have different casualty patterns from
# single-vehicle collisions, so this is a useful operational comparison.
# ============================================================

vehicle_summary = (
    df.groupby("number_of_vehicles")
      .agg(collisions=("collision_index", "nunique"),
           casualties=("number_of_casualties", "sum"))
      .reset_index()
)

vehicle_summary["casualties_per_collision"] = (
    vehicle_summary["casualties"] / vehicle_summary["collisions"]
).round(2)

print("\nVehicles involved analysis:")
print(vehicle_summary.sort_values("collisions", ascending=False).head(15))

# ============================================================
# 30. BUSINESS QUESTION:
# Which combinations of severity and time period contain the most collisions?
#
# WHY ARE WE DOING THIS?
# Risk is often driven by combinations of factors, not one variable alone.
# This creates a practical severity-by-time view for operational planning.
# ============================================================

severity_time = (
    df.groupby(["time_period", "severity_label"])
      .agg(collisions=("collision_index", "nunique"))
      .reset_index()
      .sort_values("collisions", ascending=False)
)

print("\nSeverity by time period:")
print(severity_time)

# ============================================================
# 31. BUSINESS QUESTION:
# Which day-and-time combinations have the highest collision volume?
#
# WHY ARE WE DOING THIS?
# Combining weekday and time period can identify more specific operational
# windows than analysing either dimension independently.
# ============================================================

day_time = (
    df.groupby(["day_of_week_label", "time_period"])
      .agg(collisions=("collision_index", "nunique"))
      .reset_index()
      .sort_values("collisions", ascending=False)
)

print("\nTop day/time combinations:")
print(day_time.head(15))

# ============================================================
# 32. BUSINESS QUESTION:
# Which conditions have the highest severe-collision rate?
#
# WHY ARE WE DOING THIS?
# A high collision count is not automatically a high-risk condition.
# Severe-collision rate helps distinguish volume from potential impact.
# ============================================================

risk_by_weather = (
    df.groupby("weather_conditions")
      .agg(
          collisions=("collision_index", "nunique"),
          severe_collisions=("is_severe", "sum")
      )
)

risk_by_weather["severe_rate_pct"] = (
    risk_by_weather["severe_collisions"] /
    risk_by_weather["collisions"] * 100
).round(2)

print("\nSevere-collision rate by weather code:")
print(risk_by_weather.sort_values("severe_rate_pct", ascending=False))

# ============================================================
# 33. BUSINESS QUESTION:
# Are there meaningful differences in collision volume and severity by month?
#
# WHY ARE WE DOING THIS?
# A monthly table containing both total and severe collisions gives a more
# complete picture than volume alone.
# ============================================================

monthly_risk = (
    df.groupby(["month_number", "month_name"])
      .agg(
          collisions=("collision_index", "nunique"),
          severe_collisions=("is_severe", "sum")
      )
      .reset_index()
      .sort_values("month_number")
)

monthly_risk["severe_rate_pct"] = (
    monthly_risk["severe_collisions"] /
    monthly_risk["collisions"] * 100
).round(2)

print("\nMonthly volume and severity:")
print(monthly_risk)

# ============================================================
# 34. BUSINESS QUESTION:
# Can we visually identify the monthly collision trend?
#
# WHY ARE WE DOING THIS?
# A chart makes temporal patterns easier to interpret and later reproduce
# in Power BI.
# ============================================================

plt.figure(figsize=(12, 5))
sns.lineplot(data=monthly, x="month_name", y="collisions", marker="o")
plt.title("Monthly Road Collisions — 2023")
plt.xlabel("Month")
plt.ylabel("Collisions")
plt.xticks(rotation=45)
plt.tight_layout()
plt.show()

# ============================================================
# 35. BUSINESS QUESTION:
# Can we visually compare collision severity?
#
# WHY ARE WE DOING THIS?
# A severity chart quickly communicates the distribution of fatal, serious
# and slight collisions to a business audience.
# ============================================================

severity_plot = severity_summary.reindex(["Fatal", "Serious", "Slight"]).reset_index()

plt.figure(figsize=(8, 5))
sns.barplot(data=severity_plot, x="severity_label", y="collisions")
plt.title("Collision Severity Distribution — 2023")
plt.xlabel("Severity")
plt.ylabel("Collisions")
plt.tight_layout()
plt.show()

# ============================================================
# 36. BUSINESS QUESTION:
# Can we visually compare urban and rural collision volume?
#
# WHY ARE WE DOING THIS?
# This supports a simple management-level comparison of where collision
# volume is concentrated.
# ============================================================

plt.figure(figsize=(8, 5))
sns.barplot(
    data=urban_rural.reset_index(),
    x="urban_rural_label",
    y="collisions"
)
plt.title("Collisions by Urban/Rural Area — 2023")
plt.xlabel("Area Type")
plt.ylabel("Collisions")
plt.tight_layout()
plt.show()

# ============================================================
# 37. EXPORT THE CLEANED DATA
# ============================================================
# BUSINESS QUESTION:
# Can we create one consistent cleaned dataset for SQL and Power BI?
#
# WHY ARE WE DOING THIS?
# Python, MySQL and Power BI must use the same analytical source.
# Exporting one cleaned CSV prevents the source mismatch experienced in
# the previous project.

df.to_csv(CLEANED_PATH, index=False)

print(f"\nCleaned dataset exported to: {CLEANED_PATH}")
print("Cleaned rows:", len(df))
print("Cleaned columns:", len(df.columns))

# ============================================================
# 38. FINAL RECONCILIATION CHECK
# ============================================================
# BUSINESS QUESTION:
# Does the exported dataset preserve the collision population?
#
# WHY ARE WE DOING THIS?
# This is the final checkpoint before loading the data into MySQL and Power BI.
# The same collision count should be used across all downstream tools.

exported = pd.read_csv(CLEANED_PATH, low_memory=False)

print("\nFINAL VALIDATION")
print("Python dataframe rows:", len(df))
print("Exported CSV rows:", len(exported))
print("Python unique collisions:", df["collision_index"].nunique())
print("Exported unique collisions:", exported["collision_index"].nunique())

assert len(df) == len(exported), "Row-count mismatch after CSV export."
assert df["collision_index"].nunique() == exported["collision_index"].nunique(),     "Collision-count mismatch after CSV export."

print("Validation passed: Python and exported CSV are consistent.")
