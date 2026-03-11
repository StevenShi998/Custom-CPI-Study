WITH cor_date AS (
    SELECT 
        Products,
        VALUE,
        REF_DATE,
        ROW_NUMBER() OVER (PARTITION BY Products ORDER BY VALUE ASC) AS rn_min,
        ROW_NUMBER() OVER (PARTITION BY Products ORDER BY VALUE DESC) AS rn_max
    FROM 
        retail_price
)
SELECT 
    a.Products,
    ROUND(AVG(a.VALUE), 3) AS mean_product_price,
    ROUND(STDDEV(a.VALUE), 3) AS stdev_product_price,
    MIN(a.VALUE) AS min_product_price,
    MIN(CASE WHEN c.rn_min = 1 THEN c.REF_DATE END) AS min_price_date,
    MAX(a.VALUE) AS max_product_price,
    MAX(CASE WHEN c.rn_max = 1 THEN c.REF_DATE END) AS max_price_date
FROM 
    retail_price a
JOIN 
    cor_date c ON a.Products = c.Products
GROUP BY 
    a.Products
ORDER BY 
    stdev_product_price;
