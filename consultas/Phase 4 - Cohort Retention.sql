-- Deliverable #1 - Cohort month 
SELECT
	DATE_FORMAT(fecha_registro, '%Y-%m') AS month_registration, 
    COUNT(DISTINCT cliente_id) AS client_count
FROM clientes_clean
GROUP BY DATE_FORMAT(fecha_registro, '%Y-%m'); 

-- Deliverable #2 - Purchase activity by cohort and month bucket
SELECT
	DATE_FORMAT(fecha_registro, '%Y-%m') AS month_registration, 
    COUNT(DISTINCT cc.cliente_id) AS client_count, 
    TIMESTAMPDIFF(MONTH, fecha_registro, fecha_pedido) AS month_diff
FROM clientes_clean cc
JOIN pedidos_clean pc	
	ON cc.cliente_id = pc.cliente_id 
GROUP BY month_registration, month_diff
HAVING month_diff BETWEEN 0 AND 3
ORDER BY month_registration, month_diff;

-- Deliverable #3 -  Pivoted retention counts
WITH month_info AS(
    SELECT
		cc.cliente_id, 
		DATE_FORMAT(fecha_registro, '%Y-%m') AS month_registration, 
		TIMESTAMPDIFF(MONTH, fecha_registro, fecha_pedido) AS month_diff
	FROM clientes_clean cc
	JOIN pedidos_clean pc	
		ON cc.cliente_id = pc.cliente_id
	HAVING month_diff BETWEEN 0 AND 3
	ORDER BY month_registration ASC) 

SELECT
	month_registration, 
    COUNT(DISTINCT CASE WHEN month_diff = 0 THEN cliente_id END) AS m0, 
    COUNT(DISTINCT CASE WHEN month_diff = 1 THEN cliente_id END) AS m1, 
    COUNT(DISTINCT CASE WHEN month_diff = 2 THEN cliente_id END) AS m2, 
    COUNT(DISTINCT CASE WHEN month_diff = 3 THEN cliente_id END) AS m3 
FROM month_info
GROUP BY month_registration; 

-- Deliverable #4 -  Retention percentage table
WITH CombinedBase AS(
    SELECT
        cc.cliente_id, 
        DATE_FORMAT(cc.fecha_registro, '%Y-%m') AS cohort_month, 
        TIMESTAMPDIFF(MONTH, cc.fecha_registro, pc.fecha_pedido) AS month_diff
    FROM clientes_clean cc
    LEFT JOIN pedidos_clean pc 
        ON cc.cliente_id = pc.cliente_id
        AND TIMESTAMPDIFF(MONTH, cc.fecha_registro, pc.fecha_pedido) BETWEEN 0 AND 3),

RawCounts AS(
    SELECT
        cohort_month,
        COUNT(DISTINCT cliente_id) AS cohort_size, 
        COUNT(DISTINCT CASE WHEN month_diff = 0 THEN cliente_id END) AS m0,
        COUNT(DISTINCT CASE WHEN month_diff = 1 THEN cliente_id END) AS m1, 
        COUNT(DISTINCT CASE WHEN month_diff = 2 THEN cliente_id END) AS m2, 
        COUNT(DISTINCT CASE WHEN month_diff = 3 THEN cliente_id END) AS m3
    FROM CombinedBase
    GROUP BY cohort_month)

SELECT 
    cohort_month,
    cohort_size,
    m0, m1, m2, m3,
    ROUND((m0 / cohort_size) * 100, 2) AS m0_pct,
    ROUND((m1 / cohort_size) * 100, 2) AS m1_pct,
    ROUND((m2 / cohort_size) * 100, 2) AS m2_pct,
    ROUND((m3 / cohort_size) * 100, 2) AS m3_pct
FROM RawCounts
ORDER BY cohort_month ASC;
    
-- Deliverable #5 - Retention by acquisition channel
WITH CombinedBase AS(
    SELECT
		canal_adquisicion,
        cc.cliente_id, 
        TIMESTAMPDIFF(MONTH, cc.fecha_registro, pc.fecha_pedido) AS month_diff
    FROM clientes_clean cc
    LEFT JOIN pedidos_clean pc 
        ON cc.cliente_id = pc.cliente_id
        AND TIMESTAMPDIFF(MONTH, cc.fecha_registro, pc.fecha_pedido) BETWEEN 0 AND 3),

RawCounts AS(
    SELECT
        canal_adquisicion,
        COUNT(DISTINCT cliente_id) AS cohort_size, 
        COUNT(DISTINCT CASE WHEN month_diff = 0 THEN cliente_id END) AS m0,
        COUNT(DISTINCT CASE WHEN month_diff = 1 THEN cliente_id END) AS m1, 
        COUNT(DISTINCT CASE WHEN month_diff = 2 THEN cliente_id END) AS m2, 
        COUNT(DISTINCT CASE WHEN month_diff = 3 THEN cliente_id END) AS m3
    FROM CombinedBase
    GROUP BY canal_adquisicion)

SELECT 
    canal_adquisicion,
    cohort_size,
    m0, 
		ROUND((m0 / cohort_size) * 100, 2) AS m0_pct, 
	m1, 
		ROUND((m1 / cohort_size) * 100, 2) AS m1_pct, 
	m2, 
		ROUND((m2 / cohort_size) * 100, 2) AS m2_pct, 
	m3, 
		ROUND((m3 / cohort_size) * 100, 2) AS m3_pct
FROM RawCounts;

-- Deliverable #6 - Steepest drop-off identification from cohorts
# The biggest drop off is in 2022-11 with a 12 person drop-off (16 to 4)

