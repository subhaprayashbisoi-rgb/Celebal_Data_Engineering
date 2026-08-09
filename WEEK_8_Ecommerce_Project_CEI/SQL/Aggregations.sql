SELECT
    p.category,
    ROUND(SUM(
        oi.quantity * oi.unit_price *
        (1 - oi.discount_percent / 100.0)
    ),2) AS total_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

SELECT
    c.customer_id,
    c.customer_name,
    ROUND(SUM(
        oi.quantity * oi.unit_price *
        (1 - oi.discount_percent / 100.0)
    ),2) AS total_order_value
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id,c.customer_name
ORDER BY total_order_value DESC
LIMIT 10;

SELECT
    strftime('%Y-%m',order_date) AS month,
    COUNT(*) AS order_count
FROM orders
GROUP BY strftime('%Y-%m',order_date)
ORDER BY month;

SELECT
    c.customer_id,
    c.customer_name
FROM customers c
JOIN orders o
    ON c.customer_id=o.customer_id
GROUP BY c.customer_id,c.customer_name
HAVING SUM(
    CASE WHEN o.status='DELIVERED' THEN 1 ELSE 0 END
)=0;

SELECT
    p.product_id,
    p.product_name,
    SUM(CASE WHEN oi.quantity>0 THEN oi.quantity ELSE 0 END) AS purchases,
    ABS(SUM(CASE WHEN oi.quantity<0 THEN oi.quantity ELSE 0 END)) AS returns
FROM products p
JOIN order_items oi
    ON p.product_id=oi.product_id
GROUP BY p.product_id,p.product_name
HAVING returns>purchases
ORDER BY returns DESC;

SELECT
    p.category,
    ABS(SUM(
        CASE WHEN oi.quantity<0 THEN oi.quantity ELSE 0 END
    )) AS returned_items,
    SUM(ABS(oi.quantity)) AS total_items,
    ROUND(
        100.0*ABS(SUM(
            CASE WHEN oi.quantity<0 THEN oi.quantity ELSE 0 END
        ))/NULLIF(SUM(ABS(oi.quantity)),0),
        2
    ) AS return_rate_percent
FROM products p
JOIN order_items oi
    ON p.product_id=oi.product_id
GROUP BY p.category
ORDER BY return_rate_percent DESC;