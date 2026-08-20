SELECT * FROM pedidos_clean; 

SELECT * FROM detalle_pedidos_clean; 

SELECT * FROM productos_clean; 

-- Deliverable #1 - MoM revenue trend with %
WITH monthly_metrics AS (
	SELECT
		SUM(total_pedido) AS current_month_value, 
		DATE_FORMAT(fecha_pedido, '%Y-%m') AS report_month
	FROM pedidos_clean
    GROUP BY DATE_FORMAT(fecha_pedido, '%Y-%m')), 
    
monthly_with_lag AS (
    SELECT
        report_month,
        current_month_value,
        LAG(current_month_value) OVER (ORDER BY report_month) AS prior_month_value
    FROM monthly_metrics
)

SELECT
    report_month,
    current_month_value,
    prior_month_value,
    ROUND(100.0 * (current_month_value - prior_month_value) 
          / NULLIF(prior_month_value, 0), 2) AS mom_growth_pct
FROM monthly_with_lag
WHERE report_month >= '2022-01-01'
ORDER BY report_month;

-- Deliverable #2 - Top 10 products by total revenue 
SELECT # Checking to make sure totals add up (verifying cleaning process) 
	dp.pedido_id, 
    pc.pedido_id, 
    subtotal, 
    total_pedido
FROM detalle_pedidos_clean dp 
JOIN pedidos_clean pc 
	ON dp.pedido_id = pc.pedido_id 
WHERE dp.pedido_id = 5001 AND pc.pedido_id = 5001; 

SELECT
	nombre_producto, 
    SUM(total_pedido) AS total_revenue
FROM productos_clean AS pc1
JOIN detalle_pedidos_clean dpc
	ON pc1.producto_id = dpc.producto_id 
JOIN pedidos_clean pc2
	ON dpc.pedido_id = pc2.pedido_id 
GROUP BY nombre_producto
ORDER BY total_revenue DESC
LIMIT 10; 
    
-- Deliverable #3 - Revenue breakdown by category w/ %
WITH category_totals AS (
    SELECT
        categoria, 
        SUM(total_pedido) AS total_revenue
    FROM productos_clean pc1
    JOIN detalle_pedidos_clean dpc 
		ON pc1.producto_id = dpc.producto_id
    JOIN pedidos_clean pc2 
		ON dpc.pedido_id = pc2.pedido_id 
    GROUP BY categoria)
    
SELECT
    IF(GROUPING(categoria) = 1, 'Total', categoria) AS categoria,
    SUM(total_revenue) AS total_revenue, 
    ROUND((SUM(total_revenue) / SUM(SUM(total_revenue)) OVER ()) * 200, 2) AS percentage_of_total
FROM category_totals
GROUP BY categoria WITH ROLLUP
ORDER BY 
    GROUPING(categoria) ASC, 
    total_revenue DESC;
    
SELECT
	categoria, 
    AVG(descuento_aplicado) * 100 AS avg_dct, 
    SUM(total_pedido) AS total_rev
FROM productos_clean pc1
JOIN detalle_pedidos_clean AS dpc
	ON pc1.producto_id = dpc.producto_id 
JOIN pedidos_clean pc2
	ON dpc.pedido_id = pc2.pedido_id 
GROUP BY categoria
ORDER BY avg_dct DESC; 