-- Advanced SQL analysis
USE road_safety_analytics;

-- CTEs, window functions, percentages and comparative analysis will be added after schema validation.
-- Example pattern:
-- WITH monthly AS (
--   SELECT MONTH(Date) AS month, COUNT(*) AS collisions
--   FROM road_collision_2023 GROUP BY MONTH(Date)
-- )
-- SELECT month, collisions, LAG(collisions) OVER (ORDER BY month) AS previous_month
-- FROM monthly ORDER BY month;
