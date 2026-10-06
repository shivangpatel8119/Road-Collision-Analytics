/*
UK ROAD COLLISION ANALYTICS — 2023
SQL end-to-end business analysis

SOURCE:
road_collision_2023_cleaned.csv

IMPORTANT:
Run the database/table setup first. Then import the cleaned CSV.
The exact column names below correspond to the Python output.
Every section contains:
1) BUSINESS QUESTION
2) WHY ARE WE DOING THIS?
3) SQL QUERY
*/

-- ============================================================
-- 0. CREATE DATABASE
-- ============================================================
-- BUSINESS QUESTION:
-- Where should the road-collision analysis data be stored?
--
-- WHY ARE WE DOING THIS?
-- A dedicated database keeps this project separate and makes the
-- analysis reproducible.

CREATE DATABASE IF NOT EXISTS road_safety_analytics;
USE road_safety_analytics;

-- ============================================================
-- 1. CREATE TABLE
-- ============================================================
-- BUSINESS QUESTION:
-- How can we store the cleaned collision dataset in a structured table?
--
-- WHY ARE WE DOING THIS?
-- SQL analysis requires a consistent relational table with suitable
-- data types for identifiers, dates, categories and measures.

DROP TABLE IF EXISTS road_collision_2023;

CREATE TABLE road_collision_2023 (
    collision_index VARCHAR(50) PRIMARY KEY,
    collision_year INT,
    collision_ref_no VARCHAR(50),
    location_easting_osgr DOUBLE,
    location_northing_osgr DOUBLE,
    longitude DOUBLE,
    latitude DOUBLE,
    police_force INT,
    collision_severity INT,
    number_of_vehicles INT,
    number_of_casualties INT,
    date VARCHAR(20),
    day_of_week INT,
    time VARCHAR(10),
    local_authority_district INT,
    local_authority_ons_district VARCHAR(100),
    local_authority_highway VARCHAR(100),
    local_authority_highway_current VARCHAR(100),
    first_road_class INT,
    first_road_number INT,
    road_type INT,
    speed_limit INT,
    junction_detail_historic INT,
    junction_detail INT,
    junction_control INT,
    second_road_class INT,
    second_road_number INT,
    pedestrian_crossing_human_control_historic INT,
    pedestrian_crossing_physical_facilities_historic INT,
    pedestrian_crossing INT,
    light_conditions INT,
    weather_conditions INT,
    road_surface_conditions INT,
    special_conditions_at_site INT,
    carriageway_hazards_historic INT,
    carriageway_hazards INT,
    urban_or_rural_area INT,
    did_police_officer_attend_scene_of_accident INT,
    trunk_road_flag INT,
    lsoa_of_accident_location VARCHAR(100),
    enhanced_severity_collision INT,
    collision_injury_based INT,
    collision_adjusted_severity_serious DOUBLE,
    collision_adjusted_severity_slight DOUBLE,
    date_parsed DATE,
    time_parsed DATETIME,
    year INT,
    month_number INT,
    month_name VARCHAR(20),
    quarter VARCHAR(5),
    day_name VARCHAR(20),
    is_weekend INT,
    hour INT,
    time_period VARCHAR(20),
    severity_label VARCHAR(20),
    day_of_week_label VARCHAR(20),
    urban_rural_label VARCHAR(20),
    is_severe INT
);

-- ============================================================
-- 2. LOAD THE CLEANED CSV
-- ============================================================
-- BUSINESS QUESTION:
-- How do we move the validated Python dataset into SQL for business analysis?
--
-- WHY ARE WE DOING THIS?
-- SQL gives us relational querying, CTEs, aggregations and window functions.
-- Import the file exported by Python, not the original raw CSV.

-- Example:
-- LOAD DATA LOCAL INFILE 'C:/path/to/road_collision_2023_cleaned.csv'
-- INTO TABLE road_collision_2023
-- FIELDS TERMINATED BY ','
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- ============================================================
-- 3. BUSINESS QUESTION:
-- Did SQL receive the same number of collision records as Python?
--
-- WHY ARE WE DOING THIS?
-- This is the most important reconciliation check. It prevents the
-- source mismatch problem seen in the previous project.
-- ============================================================

SELECT
    COUNT(*) AS sql_rows,
    COUNT(DISTINCT collision_index) AS unique_collisions
FROM road_collision_2023;

-- Expected project-level reference:
-- Python raw dataset = 104,258 rows.
-- If no records were removed during cleaning, cleaned rows should also be 104,258.

-- ============================================================
-- 4. BUSINESS QUESTION:
-- Are duplicate collision IDs present after SQL import?
--
-- WHY ARE WE DOING THIS?
-- collision_index should identify one collision. Duplicate IDs could
-- inflate every KPI and grouped analysis.
-- ============================================================

SELECT
    collision_index,
    COUNT(*) AS record_count
FROM road_collision_2023
GROUP BY collision_index
HAVING COUNT(*) > 1;

-- ============================================================
-- 5. BUSINESS QUESTION:
-- What is the overall collision volume?
--
-- WHY ARE WE DOING THIS?
-- Total collisions are the primary project KPI.
-- ============================================================

SELECT COUNT(DISTINCT collision_index) AS total_collisions
FROM road_collision_2023;

-- ============================================================
-- 6. BUSINESS QUESTION:
-- How many casualties were recorded?
--
-- WHY ARE WE DOING THIS?
-- Collision count measures events; casualty count measures human impact.
-- ============================================================

SELECT SUM(number_of_casualties) AS total_casualties
FROM road_collision_2023;

-- ============================================================
-- 7. BUSINESS QUESTION:
-- What is the average number of vehicles and casualties per collision?
--
-- WHY ARE WE DOING THIS?
-- These measures describe the typical collision structure and provide
-- context for multi-vehicle and casualty analysis.
-- ============================================================

SELECT
    ROUND(AVG(number_of_vehicles), 2) AS avg_vehicles_per_collision,
    ROUND(AVG(number_of_casualties), 2) AS avg_casualties_per_collision
FROM road_collision_2023;

-- ============================================================
-- 8. BUSINESS QUESTION:
-- What is the collision distribution by severity?
--
-- WHY ARE WE DOING THIS?
-- Severity separates collision volume from safety impact.
-- ============================================================

SELECT
    severity_label,
    COUNT(DISTINCT collision_index) AS collisions,
    ROUND(
        COUNT(DISTINCT collision_index) * 100.0 /
        (SELECT COUNT(DISTINCT collision_index) FROM road_collision_2023), 2
    ) AS collision_share_pct
FROM road_collision_2023
GROUP BY severity_label
ORDER BY collisions DESC;

-- ============================================================
-- 9. BUSINESS QUESTION:
-- How many fatal, serious and slight collisions occurred?
--
-- WHY ARE WE DOING THIS?
-- This gives direct management-level severity KPIs.
-- ============================================================

SELECT
    COUNT(DISTINCT CASE WHEN severity_label = 'Fatal' THEN collision_index END) AS fatal_collisions,
    COUNT(DISTINCT CASE WHEN severity_label = 'Serious' THEN collision_index END) AS serious_collisions,
    COUNT(DISTINCT CASE WHEN severity_label = 'Slight' THEN collision_index END) AS slight_collisions
FROM road_collision_2023;

-- ============================================================
-- 10. BUSINESS QUESTION:
-- What percentage of collisions were severe (fatal or serious)?
--
-- WHY ARE WE DOING THIS?
-- A severe-collision rate is more useful for risk analysis than raw
-- severe counts alone.
-- ============================================================

SELECT
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_collision_rate_pct
FROM road_collision_2023;

-- ============================================================
-- 11. BUSINESS QUESTION:
-- How do collisions trend month by month?
--
-- WHY ARE WE DOING THIS?
-- Monthly trends identify seasonal or operational changes during 2023.
-- ============================================================

SELECT
    month_number,
    month_name,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY month_number, month_name
ORDER BY month_number;

-- ============================================================
-- 12. BUSINESS QUESTION:
-- Which months have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Ranking helps identify periods with the greatest collision burden.
-- ============================================================

SELECT
    month_name,
    COUNT(DISTINCT collision_index) AS collisions
FROM road_collision_2023
GROUP BY month_number, month_name
ORDER BY collisions DESC;

-- ============================================================
-- 13. BUSINESS QUESTION:
-- Which days of the week have the most collisions?
--
-- WHY ARE WE DOING THIS?
-- Day-level patterns can support targeted road-safety planning.
-- ============================================================

SELECT
    day_of_week_label,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY day_of_week, day_of_week_label
ORDER BY day_of_week;

-- ============================================================
-- 14. BUSINESS QUESTION:
-- Which hours have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Peak hours can indicate periods where traffic management and
-- prevention resources may be most useful.
-- ============================================================

SELECT
    hour,
    COUNT(DISTINCT collision_index) AS collisions
FROM road_collision_2023
GROUP BY hour
ORDER BY collisions DESC;

-- ============================================================
-- 15. BUSINESS QUESTION:
-- Which broad time periods have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Time periods are easier to communicate in a dashboard than 24 separate hours.
-- ============================================================

SELECT
    time_period,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY time_period
ORDER BY collisions DESC;

-- ============================================================
-- 16. BUSINESS QUESTION:
-- Are collisions more common on weekdays or weekends?
--
-- WHY ARE WE DOING THIS?
-- This compares two operationally meaningful groups of days.
-- ============================================================

SELECT
    CASE WHEN is_weekend = 1 THEN 'Weekend' ELSE 'Weekday' END AS day_group,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY is_weekend
ORDER BY collisions DESC;

-- ============================================================
-- 17. BUSINESS QUESTION:
-- How are collisions split between urban and rural areas?
--
-- WHY ARE WE DOING THIS?
-- Urban and rural roads have different traffic and infrastructure
-- characteristics, so resource planning should compare them.
-- ============================================================

SELECT
    urban_rural_label,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY urban_rural_label
ORDER BY collisions DESC;

-- ============================================================
-- 18. BUSINESS QUESTION:
-- What is the severity mix within urban and rural collisions?
--
-- WHY ARE WE DOING THIS?
-- A lower collision volume does not necessarily mean lower risk.
-- Severity share provides a more meaningful comparison.
-- ============================================================

SELECT
    urban_rural_label,
    severity_label,
    COUNT(DISTINCT collision_index) AS collisions,
    ROUND(
        COUNT(DISTINCT collision_index) * 100.0 /
        SUM(COUNT(DISTINCT collision_index)) OVER (
            PARTITION BY urban_rural_label
        ), 2
    ) AS severity_share_within_area_pct
FROM road_collision_2023
GROUP BY urban_rural_label, severity_label
ORDER BY urban_rural_label, collisions DESC;

-- ============================================================
-- 19. BUSINESS QUESTION:
-- Which speed limits contain the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Speed limit is an important road-environment factor. This identifies
-- where collision volume is concentrated.
-- ============================================================

SELECT
    speed_limit,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY speed_limit
ORDER BY collisions DESC;

-- ============================================================
-- 20. BUSINESS QUESTION:
-- How does severity vary across speed limits?
--
-- WHY ARE WE DOING THIS?
-- Volume alone cannot show risk. This compares the severity mix at
-- different speed limits.
-- ============================================================

SELECT
    speed_limit,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY speed_limit
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 21. BUSINESS QUESTION:
-- Which weather conditions have the most collisions?
--
-- WHY ARE WE DOING THIS?
-- Weather can influence visibility, grip and driver behaviour.
-- We first identify collision volume by condition.
-- ============================================================

SELECT
    weather_conditions,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY weather_conditions
ORDER BY collisions DESC;

-- ============================================================
-- 22. BUSINESS QUESTION:
-- Which weather conditions have the highest severe-collision rate?
--
-- WHY ARE WE DOING THIS?
-- The most common weather condition is not necessarily the most severe.
-- Rate helps separate frequency from potential impact.
-- ============================================================

SELECT
    weather_conditions,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY weather_conditions
HAVING COUNT(DISTINCT collision_index) >= 100
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 23. BUSINESS QUESTION:
-- Which road-surface conditions have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Road-surface condition can affect vehicle control and stopping distance.
-- This identifies where collision volume is concentrated.
-- ============================================================

SELECT
    road_surface_conditions,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY road_surface_conditions
ORDER BY collisions DESC;

-- ============================================================
-- 24. BUSINESS QUESTION:
-- Does road-surface condition change the severe-collision rate?
--
-- WHY ARE WE DOING THIS?
-- This checks whether certain surface conditions are associated with
-- a different severity profile.
-- ============================================================

SELECT
    road_surface_conditions,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY road_surface_conditions
HAVING COUNT(DISTINCT collision_index) >= 100
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 25. BUSINESS QUESTION:
-- How does collision severity vary by time period?
--
-- WHY ARE WE DOING THIS?
-- Combining time and severity identifies periods that deserve attention
-- beyond simple collision volume.
-- ============================================================

SELECT
    time_period,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY time_period
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 26. BUSINESS QUESTION:
-- Which day/time combinations have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- This gives a more operationally specific view than day or time alone.
-- ============================================================

SELECT
    day_of_week_label,
    time_period,
    COUNT(DISTINCT collision_index) AS collisions
FROM road_collision_2023
GROUP BY day_of_week, day_of_week_label, time_period
ORDER BY collisions DESC
LIMIT 15;

-- ============================================================
-- 27. BUSINESS QUESTION:
-- Which road types have the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Road design/type can influence traffic behaviour and exposure.
-- This identifies where collision volume is concentrated.
-- ============================================================

SELECT
    road_type,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY road_type
ORDER BY collisions DESC;

-- ============================================================
-- 28. BUSINESS QUESTION:
-- Does road type affect severe-collision rate?
--
-- WHY ARE WE DOING THIS?
-- This checks risk severity rather than only collision frequency.
-- ============================================================

SELECT
    road_type,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY road_type
HAVING COUNT(DISTINCT collision_index) >= 100
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 29. BUSINESS QUESTION:
-- How many vehicles are involved in the typical collision?
--
-- WHY ARE WE DOING THIS?
-- Vehicle involvement helps distinguish single-vehicle from multi-vehicle
-- collision patterns.
-- ============================================================

SELECT
    number_of_vehicles,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties,
    ROUND(
        SUM(number_of_casualties) * 1.0 /
        COUNT(DISTINCT collision_index), 2
    ) AS casualties_per_collision
FROM road_collision_2023
GROUP BY number_of_vehicles
ORDER BY collisions DESC;

-- ============================================================
-- 30. BUSINESS QUESTION:
-- Are multi-vehicle collisions more likely to be severe?
--
-- WHY ARE WE DOING THIS?
-- This directly compares collision severity between single-vehicle
-- and multi-vehicle events.
-- ============================================================

SELECT
    CASE
        WHEN number_of_vehicles = 1 THEN 'Single Vehicle'
        ELSE 'Multiple Vehicles'
    END AS vehicle_group,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY vehicle_group
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 31. BUSINESS QUESTION:
-- Which police forces record the highest collision volume?
--
-- WHY ARE WE DOING THIS?
-- Police-force level comparison can show geographic variation in
-- collision burden and support resource planning.
-- ============================================================

SELECT
    police_force,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties
FROM road_collision_2023
GROUP BY police_force
ORDER BY collisions DESC;

-- ============================================================
-- 32. BUSINESS QUESTION:
-- Which police forces have the highest severe-collision rate?
--
-- WHY ARE WE DOING THIS?
-- High collision volume and high severity are different problems.
-- This identifies areas with a larger severe-outcome proportion.
-- ============================================================

SELECT
    police_force,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY police_force
HAVING COUNT(DISTINCT collision_index) >= 100
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 33. BUSINESS QUESTION:
-- What percentage of all collisions occurs in each month?
--
-- WHY ARE WE DOING THIS?
-- Percentage makes monthly comparisons easier even when management
-- compares different groups or periods.
-- ============================================================

SELECT
    month_number,
    month_name,
    COUNT(DISTINCT collision_index) AS collisions,
    ROUND(
        COUNT(DISTINCT collision_index) * 100.0 /
        SUM(COUNT(DISTINCT collision_index)) OVER (), 2
    ) AS share_of_year_pct
FROM road_collision_2023
GROUP BY month_number, month_name
ORDER BY month_number;

-- ============================================================
-- 34. BUSINESS QUESTION:
-- What is the monthly rank of collision volume?
--
-- WHY ARE WE DOING THIS?
-- A window function demonstrates how SQL can rank periods without
-- losing the underlying monthly detail.
-- ============================================================

WITH monthly_collisions AS (
    SELECT
        month_number,
        month_name,
        COUNT(DISTINCT collision_index) AS collisions
    FROM road_collision_2023
    GROUP BY month_number, month_name
)
SELECT
    month_number,
    month_name,
    collisions,
    DENSE_RANK() OVER (ORDER BY collisions DESC) AS collision_volume_rank
FROM monthly_collisions
ORDER BY collision_volume_rank;

-- ============================================================
-- 35. BUSINESS QUESTION:
-- What are the top day/time operational windows by collision volume?
--
-- WHY ARE WE DOING THIS?
-- CTE + ranking produces a concise list of the highest-volume
-- operational windows for management review.
-- ============================================================

WITH day_time AS (
    SELECT
        day_of_week_label,
        time_period,
        COUNT(DISTINCT collision_index) AS collisions
    FROM road_collision_2023
    GROUP BY day_of_week, day_of_week_label, time_period
),
ranked AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY collisions DESC) AS volume_rank
    FROM day_time
)
SELECT *
FROM ranked
WHERE volume_rank <= 10
ORDER BY volume_rank;

-- ============================================================
-- 36. BUSINESS QUESTION:
-- Which severity categories contribute the largest casualty burden?
--
-- WHY ARE WE DOING THIS?
-- Severity count and casualty count are related but not identical.
-- This shows both event volume and human impact.
-- ============================================================

SELECT
    severity_label,
    COUNT(DISTINCT collision_index) AS collisions,
    SUM(number_of_casualties) AS casualties,
    ROUND(
        SUM(number_of_casualties) * 1.0 /
        COUNT(DISTINCT collision_index), 2
    ) AS casualties_per_collision
FROM road_collision_2023
GROUP BY severity_label
ORDER BY casualties DESC;

-- ============================================================
-- 37. BUSINESS QUESTION:
-- Which urban/rural and severity combinations have the highest volume?
--
-- WHY ARE WE DOING THIS?
-- This identifies the intersection of location type and severity,
-- useful for prioritising interventions.
-- ============================================================

SELECT
    urban_rural_label,
    severity_label,
    COUNT(DISTINCT collision_index) AS collisions
FROM road_collision_2023
GROUP BY urban_rural_label, severity_label
ORDER BY collisions DESC;

-- ============================================================
-- 38. BUSINESS QUESTION:
-- Which speed-limit and urban/rural combinations have the highest severe rate?
--
-- WHY ARE WE DOING THIS?
-- Risk may vary by both road environment and speed setting, so a
-- two-dimensional analysis can reveal patterns hidden in single variables.
-- ============================================================

SELECT
    urban_rural_label,
    speed_limit,
    COUNT(DISTINCT collision_index) AS collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_rate_pct
FROM road_collision_2023
GROUP BY urban_rural_label, speed_limit
HAVING COUNT(DISTINCT collision_index) >= 100
ORDER BY severe_rate_pct DESC;

-- ============================================================
-- 39. BUSINESS QUESTION:
-- What is the collision trend by month and severity?
--
-- WHY ARE WE DOING THIS?
-- This produces the core dataset for a stacked/clustered Power BI
-- monthly severity visual.
-- ============================================================

SELECT
    month_number,
    month_name,
    severity_label,
    COUNT(DISTINCT collision_index) AS collisions
FROM road_collision_2023
GROUP BY month_number, month_name, severity_label
ORDER BY month_number, severity_label;

-- ============================================================
-- 40. BUSINESS QUESTION:
-- What final KPI set should be reconciled with Power BI?
--
-- WHY ARE WE DOING THIS?
-- One final query gives us the authoritative SQL numbers that should
-- match the Power BI source after import.
-- ============================================================

SELECT
    COUNT(DISTINCT collision_index) AS total_collisions,
    COUNT(DISTINCT CASE WHEN severity_label = 'Fatal' THEN collision_index END) AS fatal_collisions,
    COUNT(DISTINCT CASE WHEN severity_label = 'Serious' THEN collision_index END) AS serious_collisions,
    COUNT(DISTINCT CASE WHEN severity_label = 'Slight' THEN collision_index END) AS slight_collisions,
    COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END) AS severe_collisions,
    ROUND(
        COUNT(DISTINCT CASE WHEN is_severe = 1 THEN collision_index END)
        * 100.0 / COUNT(DISTINCT collision_index), 2
    ) AS severe_collision_rate_pct,
    SUM(number_of_casualties) AS total_casualties,
    ROUND(AVG(number_of_vehicles), 2) AS avg_vehicles,
    ROUND(AVG(number_of_casualties), 2) AS avg_casualties
FROM road_collision_2023;

-- ============================================================
-- END OF SQL ANALYSIS
-- ============================================================
-- FINAL PROJECT RULE:
-- Do not manually type insight numbers into README or Power BI.
-- Run the queries, use the actual results, and document only findings
-- supported by the dataset.
