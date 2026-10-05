# UK Road Collision Analytics — 2023

## Business Problem
Road collisions create significant safety, operational, and resource-allocation challenges. This project analyzes UK road collision data for 2023 to identify patterns in collision frequency and severity and translate them into data-driven road-safety insights.

## Objective
- Identify when collisions are most frequent.
- Understand collision severity patterns.
- Examine relationships between collisions and road, environmental, temporal, and location-related factors.
- Compare urban and rural collision patterns where available.
- Identify high-risk conditions and support practical recommendations.
- Build a reproducible workflow from raw data to SQL analysis and Power BI reporting.

## Dataset
Source: UK Department for Transport road casualty statistics

Raw file: `dft-road-casualty-statistics-collision-2023.csv`

The raw dataset is the source of truth. Column definitions and analytical rules will be confirmed from the actual file during the data-audit stage.

## Tools
- Python — pandas, NumPy, matplotlib
- MySQL — data validation and business analysis
- Power BI — interactive reporting and DAX
- GitHub — version control and documentation

## Workflow
Raw CSV -> Python Data Audit -> Cleaning & Validation -> Feature Engineering -> EDA -> Cleaned CSV -> MySQL Validation & Analysis -> Power BI -> Insights & Recommendations

## Data Quality Principle
The same validated dataset must flow through every stage. Row counts and key identifiers will be checked between Python, the processed CSV, MySQL, and Power BI to prevent unexplained data mismatches.

## Key Business Questions
1. How many collisions occurred in 2023?
2. Which months and days have the highest collision frequency?
3. Which time periods show the greatest concentration of collisions?
4. How are collisions distributed by severity?
5. How do urban and rural areas differ?
6. How does collision severity vary across speed limits?
7. Which weather and road-surface conditions are most common?
8. Which combinations of conditions are associated with higher severity?

## Project Status
In progress — data audit and analytical development.

## Repository Structure
- `data/raw/` — raw source data
- `data/processed/` — validated/cleaned analytical data
- `notebooks/` — Python analysis
- `sql/` — MySQL setup and analysis
- `powerbi/` — Power BI report
- `reports/` — documentation and findings

## Disclaimer
This is an analytical portfolio project. Findings describe patterns in the available 2023 collision records and should not automatically be interpreted as causal relationships.
