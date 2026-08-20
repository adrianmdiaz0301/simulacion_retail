-- RFM Segmentation 
SELECT * FROM clientes_clean; 

SELECT * FROM pedidos_clean; 

WITH recency AS(
	SELECT # Recency (days since last order) 
		cc.cliente_id, 
		MAX(fecha_pedido) AS last_date_ordered,
		DATEDIFF(CURDATE(), MAX(STR_TO_DATE(fecha_pedido, '%Y-%m-%d'))) AS days_since_last_order
	FROM clientes_clean cc
	JOIN pedidos_clean pc
		ON cc.cliente_id = pc.cliente_id 
	WHERE fecha_pedido <= CURDATE() AND fecha_pedido >= '2022-01-01'
	GROUP BY cc.cliente_id 
	ORDER BY days_since_last_order DESC),  

frequency AS(
	SELECT # Frequency (orders per customer) 
		cc.cliente_id, 
		COUNT(pedido_id) AS order_count 
	FROM clientes_clean cc
	JOIN pedidos_clean pc
		ON cc.cliente_id = pc.cliente_id 
	GROUP BY cc.cliente_id
	ORDER BY order_count DESC),

monetary AS( 
	SELECT # Monetary (total revenue per customer) 
		cc.cliente_id, 
		SUM(total_pedido) AS total_order_amount
	FROM clientes_clean cc
	JOIN pedidos_clean pc
		ON cc.cliente_id = pc.cliente_id 
	GROUP BY cc.cliente_id
	ORDER BY total_order_amount DESC), 
    
aggregated_table AS(
	SELECT
		r.cliente_id, 
		days_since_last_order, 
		order_count, 
		total_order_amount
	FROM recency r
	JOIN frequency f
		ON r.cliente_id = f.cliente_id
	JOIN monetary m
		ON r.cliente_id = m.cliente_id), 
    
qt AS 
	(SELECT # Realized that I didn't need multiple CTEs but just one aggregated one as both tables contain cliente_id 
		cliente_id, 
		days_since_last_order,
			NTILE(4) OVER(ORDER BY days_since_last_order DESC) AS dslo_qt, 
		order_count, 
			NTILE(4) OVER(ORDER BY order_count ASC) AS oc_qt,
		total_order_amount,
			NTILE(4) OVER(ORDER BY total_order_amount ASC) AS toa_qt
	FROM aggregated_table
	ORDER BY days_since_last_order ASC), 

segment_t AS (
	SELECT
		cliente_id, 
		CASE
		WHEN dslo_qt = 4 AND oc_qt >= 3 AND toa_qt >= 3 THEN 'Campeon'
		WHEN dslo_qt >= 3 AND oc_qt >= 3 THEN 'Cliente Leal'
		WHEN dslo_qt = 4 AND oc_qt <= 2 THEN 'Cliente Reciente'
		WHEN dslo_qt <= 2 AND oc_qt >= 3 THEN 'En Riesgo'
		WHEN dslo_qt <= 2 AND oc_qt <= 2 AND toa_qt <= 2 THEN 'Inactivo'
		ELSE 'Intermedio'
	END AS segment
	FROM qt)

SELECT # Summary table for segment-level data 
    st.segment,
    COUNT(DISTINCT p.cliente_id) AS customer_count,
    SUM(p.total_pedido) AS total_amount_spent,
    ROUND(SUM(p.total_pedido) / COUNT(DISTINCT p.cliente_id), 2) AS revenue_per_customer
FROM pedidos_clean p
JOIN segment_t st
    ON p.cliente_id = st.cliente_id
GROUP BY st.segment
ORDER BY total_amount_spent DESC;