# Custom CPI & Grocery Budget Analysis

[Monthly total grocery basket trend (2019–2024)](pictures/total_budget_change.pdf)  
*[View chart (PDF)](pictures/total_budget_change.pdf) · [Analysis framework (PDF)*](pictures/mind_map.pdf)

## Table of Contents

- [Project Introduction](#project-introduction)
  - [Code in Jupyter Notebook](#code-in-jupyter-notebook)
  - [Project Dataset](#project-dataset)
- [Objective](#objective)
- [Tools and Technologies Used](#tools-and-technologies-used)
  - [Code highlights](#code-highlights)
- [Executive Summary](#executive-summary)

## Project Introduction

This project uses **Statistics Canada** monthly average retail prices (April 2019–April 2024) to answer a simple, everyday question: *Are grocery prices really going up—and if so, what’s driving it?* I tracked a fixed “one basket” of products over five years to see how the total cost and individual categories (e.g. beef) changed over time. The analysis combines **SQL** for aggregations and window functions, **Python** (pandas, NumPy) for cleaning and transformation, and **Power BI** for interactive dashboards—so the story is both rigorous and easy to explore.

### Code in Jupyter Notebook

Link: [Grocery Budget.ipynb](Grocery%20Budget.ipynb)

### Project Dataset

- **Source**: [Statistics Canada — Monthly average retail prices for selected products](https://www150.statcan.gc.ca/t1/tbl1/en/tv.action?pid=1810024501)
- **Repo data**: [data/](data/) — includes `Monthly_average_retail_prices_for_selected_products.csv`, `increase_decrease_total_change.csv`, `pirovted_beef_data.csv`, and derived budget/change tables.
- **Visuals**: [pictures/](pictures/) — [Total budget trend (PDF)](pictures/total_budget_change.pdf), [Beef products (PDF)](pictures/beef_products.pdf), [Mind map / framework (PDF)](pictures/mind_map.pdf).

## Objective

The objective is to run a **comprehensive descriptive analysis** of Canadian grocery retail prices over a 5-year window: identify trends, month-over-month and long-term change, and which products or categories contribute most. The goal is to support **data-driven decisions** about everyday spending and budgeting—turning “I feel like prices are up” into clear numbers and visuals.

## Tools and Technologies Used


| Tools and Technologies | Documentation                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------------- |
| Languages              | [Python](https://www.python.org/)                                                        |
| Libraries              | [Pandas](https://pandas.pydata.org/) [NumPy](https://numpy.org/)                         |
| Database / SQL         | [MySQL](https://www.mysql.com/) — CTEs, window functions (LAG, ROW_NUMBER), aggregations |
| Data Visualization     | [Power BI](https://powerbi.microsoft.com/)                                               |
| Tools                  | [Jupyter](https://jupyter.org/) [VS Code](https://code.visualstudio.com/)                |


**Skill highlights:**

- **SQL (MySQL)**: Monthly total budget and month-over-month percent change (CTE + `LAG`); count of increase vs decrease months and total change ratio; product-level stats (mean, stdev, min/max and dates) using `ROW_NUMBER()` and window functions. See [sql/](sql/).
- **Python (pandas, NumPy)**: Load and clean StatCan CSV; connect to MySQL for derived metrics; compute total basket cost and period-over-period changes; pivot and analyze beef categories; prepare data for Power BI.
- **Power BI**: Interactive dashboard for monthly budget trend and beef product breakdown; DAX considered for in-tool logic; SQL used for pre-aggregation. **Report**: [Power BI — Grocery Budget](https://app.powerbi.com/groups/me/reports/a3e077d9-2fde-4a8a-a794-7316d9a58af0/8d050dd0fa73b0417722?experience=power-bi) (see page *Beef Products* for category detail).

### Code highlights

**SQL — monthly total budget and percent change** (CTE + window function). See [sql/total_budget.sql](sql/total_budget.sql).

```sql
WITH TOTAL_BUDGET AS (
    SELECT REF_DATE, ROUND(SUM(VALUE), 2) AS total
    FROM retail_price
    GROUP BY REF_DATE
    ORDER BY REF_DATE ASC
)
SELECT
    REF_DATE,
    total,
    ROUND((total / LAG(total) OVER (ORDER BY REF_DATE) - 1), 2) AS percent_change
FROM TOTAL_BUDGET
ORDER BY REF_DATE;
```

**SQL — product-level stats** (mean, stdev, min/max and dates via `ROW_NUMBER()`). See [sql/product_mean_stdev_min_max_date.sql](sql/product_mean_stdev_min_max_date.sql).

```sql
WITH cor_date AS (
    SELECT Products, VALUE, REF_DATE,
        ROW_NUMBER() OVER (PARTITION BY Products ORDER BY VALUE ASC)  AS rn_min,
        ROW_NUMBER() OVER (PARTITION BY Products ORDER BY VALUE DESC) AS rn_max
    FROM retail_price
)
SELECT a.Products,
    ROUND(AVG(a.VALUE), 3) AS mean_product_price,
    ROUND(STDDEV(a.VALUE), 3) AS stdev_product_price,
    MIN(a.VALUE) AS min_product_price,
    MIN(CASE WHEN c.rn_min = 1 THEN c.REF_DATE END) AS min_price_date,
    MAX(a.VALUE) AS max_product_price,
    MAX(CASE WHEN c.rn_max = 1 THEN c.REF_DATE END) AS max_price_date
FROM retail_price a
JOIN cor_date c ON a.Products = c.Products
GROUP BY a.Products
ORDER BY stdev_product_price;
```

**Python — pivot and period-over-period change** (pandas). From [Grocery Budget.ipynb](Grocery%20Budget.ipynb).

```python
# Pivot beef products by date and compute month-over-month % change
pivoted_data = df_beef.pivot_table(index='Date', columns='Products', values='Value')
pivoted_data['Total value'] = pivoted_data.sum(axis=1)
pivoted_data['Total value change'] = pivoted_data['Total value'].pct_change()
# Per-product percent change for drill-down and viz (e.g. Power BI)
pivoted_data['Beef rib cuts change'] = pivoted_data['Beef rib cuts'].pct_change()
pivoted_data['Beef stewing cuts change'] = pivoted_data['Beef stewing cuts'].pct_change()
# ... (striploin, top sirloin, ground beef)
pivoted_data.to_csv('pirovted_beef_data.csv', index=True)  # feed into Power BI
```

## Executive Summary

Over the **April 2019–April 2024** period, the total cost of a fixed “one basket” of grocery items increased by **28.2%**: from about **$515** to about **$660** per month. Of the 60 months in the sample, **31** saw month-over-month increases and **20** saw decreases (9 unchanged)—so the trend is clearly upward, with noticeable volatility.

**View:** [Monthly total budget and percent change (PDF)](pictures/total_budget_change.pdf)

The **monthly total budget** series shows a step-up during 2020–2021 and again in 2022–2023, with short pullbacks in between. This supports the idea that grocery spending for a fixed basket has risen in a way that matters for everyday budgeting.

**View:** [Increase vs decrease months and total change (PDF)](pictures/total_budget_change.pdf)

**Product-level analysis** (e.g. beef) shows that some categories are more volatile than others: certain cuts and products drive both the level and the variability of the basket. The SQL work in [sql/product_mean_stdev_min_max_date.sql](sql/product_mean_stdev_min_max_date.sql) summarizes mean price, standard deviation, and min/max dates by product to identify which items contribute most to overall change and risk.

**View:** [Beef product price trends (PDF)](pictures/beef_products.pdf)

**Takeaways:**

1. **Total basket cost** rose **~28%** over 5 years, with more months of increase than decrease.
2. **Month-over-month changes** are volatile; the SQL-derived increase/decrease counts and total change ratio give a clear high-level view.
3. **Category drill-down** (e.g. beef) in Power BI and in the notebook shows which products drive both level and volatility.
4. The combination of **SQL** (aggregation and windows), **Python** (ETL and prep), and **Power BI** (dashboards) turns raw StatCan data into a story that supports data-driven spending and budgeting decisions.

For full detail and reproducibility, see [Grocery Budget.ipynb](Grocery%20Budget.ipynb) and the [Power BI report](https://app.powerbi.com/groups/me/reports/a3e077d9-2fde-4a8a-a794-7316d9a58af0/8d050dd0fa73b0417722?experience=power-bi).

---

