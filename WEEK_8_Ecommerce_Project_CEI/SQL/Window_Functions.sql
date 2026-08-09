WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.product_name,
        ROUND(SUM(
            oi.quantity*oi.unit_price*
            (1-oi.discount_percent/100.0)
        ),2) AS total_revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id=oi.product_id
    GROUP BY p.category,p.product_id,p.product_name
)
SELECT
    category,
    product_name,
    total_revenue,
    DENSE_RANK() OVER(
        PARTITION BY category
        ORDER BY total_revenue DESC
    ) AS rank_in_category
FROM product_revenue
ORDER BY category,rank_in_category;

WITH daily_revenue AS (
    SELECT
        o.region_code,
        date(o.order_date) AS order_date,
        ROUND(SUM(
            oi.quantity*oi.unit_price*
            (1-oi.discount_percent/100.0)
        ),2) AS daily_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id=oi.order_id
    GROUP BY o.region_code,date(o.order_date)
)
SELECT
    region_code,
    order_date,
    daily_revenue,
    ROUND(
        SUM(daily_revenue) OVER(
            PARTITION BY region_code
            ORDER BY order_date
        ),2
    ) AS running_total
FROM daily_revenue
ORDER BY region_code,order_date;

WITH customer_orders AS (
    SELECT
        customer_id,
        order_id,
        date(order_date) AS order_date,
        LAG(date(order_date)) OVER(
            PARTITION BY customer_id
            ORDER BY date(order_date)
        ) AS previous_order_date
    FROM orders
    WHERE customer_id!='UNKNOWN'
)
SELECT
    customer_id,
    order_id,
    order_date,
    previous_order_date,
    julianday(order_date)-julianday(previous_order_date) AS days_gap
FROM customer_orders
ORDER BY customer_id,order_date;

WITH customer_value AS (
    SELECT
        o.customer_id,
        ROUND(SUM(
            oi.quantity*oi.unit_price*
            (1-oi.discount_percent/100.0)
        ),2) AS total_value
    FROM orders o
    JOIN order_items oi
        ON o.order_id=oi.order_id
    WHERE o.customer_id!='UNKNOWN'
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_value,
    NTILE(4) OVER(
        ORDER BY total_value DESC
    ) AS quartile
FROM customer_value
ORDER BY quartile,total_value DESC;