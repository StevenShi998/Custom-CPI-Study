WITH first_last_date AS (
SELECT
(SELECT total
FROM monthly_total_budget_with_percentage_change
WHERE REF_DATE = (SELECT MAX(REF_DATE) FROM monthly_total_budget_with_percentage_change)
) AS latest_total,
(SELECT total
FROM monthly_total_budget_with_percentage_change
WHERE REF_DATE = (SELECT MIN(REF_DATE) FROM monthly_total_budget_with_percentage_change)
) AS earliest_total
)

select
	sum(case when percent_change > 0 then 1 else 0 end) as increase,
    sum(case when percent_change < 0 then 1 else 0 end) as decrease,
	round((latest_total - earliest_total) / earliest_total, 3) AS total_change_ratio
from
	monthly_total_budget_with_percentage_change, first_last_date
group by
	total_change_ratio