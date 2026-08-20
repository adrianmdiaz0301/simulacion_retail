-- Deliverable #1 - Main Funnel Dropoff
SELECT *
FROM sesiones_web_clean; 

WITH paso1 AS(
	SELECT
		COUNT(*) AS total_sesiones, 
		COUNT(CASE WHEN agrego_al_carrito = 1 THEN 1 END) AS carrito_count, 
		COUNT(CASE WHEN realizo_compra = 1 THEN 1 END) AS realizo_count
	FROM sesiones_web_clean) 

SELECT 
	total_sesiones,
    carrito_count,
		ROUND(100 - (carrito_count/total_sesiones * 100), 2) AS stage2_dropoff, 
	realizo_count,
		ROUND(100 - (realizo_count/carrito_count * 100), 2) AS stage3_dropoff
FROM paso1; 

-- Deliverable #2 - Funnel by Traffic Source 
WITH paso1 AS(
	SELECT
		fuente_trafico, 
		COUNT(*) AS total_sesiones, 
		COUNT(CASE WHEN agrego_al_carrito = 1 THEN 1 END) AS carrito_count, 
		COUNT(CASE WHEN realizo_compra = 1 THEN 1 END) AS realizo_count
	FROM sesiones_web_clean
    GROUP BY fuente_trafico) 

SELECT 
	fuente_trafico, 
	total_sesiones,
    carrito_count,
		ROUND(100 - (carrito_count/total_sesiones * 100), 2) AS stage2_dropoff, 
	realizo_count,
		ROUND(100 - (realizo_count/carrito_count * 100), 2) AS stage3_dropoff,
	ROUND(realizo_count/total_sesiones * 100, 2) AS conv_rate
FROM paso1; 

-- Deliverable #3 - Funnel by device 
WITH paso1 AS(
	SELECT
		dispositivo, 
		COUNT(*) AS total_sesiones, 
		COUNT(CASE WHEN agrego_al_carrito = 1 THEN 1 END) AS carrito_count, 
		COUNT(CASE WHEN realizo_compra = 1 THEN 1 END) AS realizo_count
	FROM sesiones_web_clean
    GROUP BY dispositivo) 

SELECT 
	dispositivo, 
	total_sesiones,
    carrito_count,
		ROUND(100 - (carrito_count/total_sesiones * 100), 2) AS stage2_dropoff, 
	realizo_count,
		ROUND(100 - (realizo_count/carrito_count * 100), 2) AS stage3_dropoff, 
	ROUND(realizo_count/total_sesiones * 100, 2) AS conv_rate
FROM paso1; 

-- Deliverable #4 - Cart Abandonement Page Analysis 
WITH paso1 AS(
	SELECT
		pagina_salida, 
		COUNT(*) AS total_sesiones, 
		COUNT(CASE WHEN agrego_al_carrito = 1 AND realizo_compra = 0 THEN 1 END) AS abandonement_count
	FROM sesiones_web_clean
	GROUP BY pagina_salida)
    
SELECT
	pagina_salida,
    total_sesiones, 
    abandonement_count, 
    ROUND((abandonement_count / SUM(abandonement_count) OVER()) * 100, 2) AS pct_of_total_abandonments
FROM paso1
ORDER BY pct_of_total_abandonments DESC; 
