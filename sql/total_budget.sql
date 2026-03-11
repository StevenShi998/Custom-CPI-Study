WITH TOTAL_BUDGET AS (
	select
		REF_DATE,
		round(sum(VALUE),2) AS total
	from
		retail_price
	group by
	REF_DATE
	order by
	REF_DATE ASC
)

SELECT
	REF_DATE,
    total,
    round((total / LAG(total) OVER(ORDER BY REF_DATE) - 1), 2) AS percent_change
FROM 
	TOTAL_BUDGET
GROUP BY
	REF_DATE
order by
	REF_DATE