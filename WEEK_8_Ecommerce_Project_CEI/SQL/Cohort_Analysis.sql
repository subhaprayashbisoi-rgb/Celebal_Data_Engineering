WITH customer_cohort AS (
    SELECT
        customer_id,
        strftime('%Y-%m',registration_date) AS cohort_month
    FROM customers
    WHERE customer_id!='UNKNOWN'
),
customer_orders AS (
    SELECT DISTINCT
        customer_id,
        strftime('%Y-%m',order_date) AS order_month
    FROM orders
    WHERE customer_id!='UNKNOWN'
),
cohort_activity AS (
    SELECT
        c.customer_id,
        c.cohort_month,
        o.order_month,
        (
            (
                CAST(strftime('%Y',o.order_month||'-01') AS INTEGER)
                -
                CAST(strftime('%Y',c.cohort_month||'-01') AS INTEGER)
            )*12
            +
            (
                CAST(strftime('%m',o.order_month||'-01') AS INTEGER)
                -
                CAST(strftime('%m',c.cohort_month||'-01') AS INTEGER)
            )
        ) AS month_number
    FROM customer_cohort c
    JOIN customer_orders o
        ON c.customer_id=o.customer_id
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_customers
    FROM customer_cohort
    GROUP BY cohort_month
),
retention AS (
    SELECT
        cohort_month,
        month_number,
        COUNT(DISTINCT customer_id) AS customers_ordered
    FROM cohort_activity
    WHERE month_number BETWEEN 0 AND 3
    GROUP BY cohort_month,month_number
)
SELECT
    r.cohort_month,
    r.month_number,
    r.customers_ordered,
    c.cohort_customers,
    ROUND(
        100.0*r.customers_ordered/c.cohort_customers,
        2
    ) AS retention_rate
FROM retention r
JOIN cohort_size c
    ON r.cohort_month=c.cohort_month
ORDER BY r.cohort_month,r.month_number;

SELECT
    p1.product_name AS product_a,
    p2.product_name AS product_b,
    COUNT(DISTINCT oi1.order_id) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2
    ON oi1.order_id=oi2.order_id
    AND oi1.product_id<oi2.product_id
JOIN products p1
    ON oi1.product_id=p1.product_id
JOIN products p2
    ON oi2.product_id=p2.product_id
GROUP BY
    oi1.product_id,
    oi2.product_id,
    p1.product_name,
    p2.product_name
ORDER BY times_bought_together DESC;