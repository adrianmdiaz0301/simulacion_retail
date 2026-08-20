SELECT *
FROM campanas_crm_clean;

-- Deliverable #1 - Open rate, CTR, and conversion rate per variant per campaign type
WITH metrics AS (	
    SELECT
		tipo_campana, 
		variante_ab, 
		COUNT(campana_id) AS total_sent, 
        COUNT(CASE WHEN abierto = '1' THEN campana_id END) AS abierto_count, 
        COUNT(CASE WHEN clic = '1' THEN campana_id END) AS click_count, 
        COUNT(CASE WHEN convirtio = '1' THEN campana_id END) AS convirtio_count
	FROM campanas_crm_clean
	GROUP BY tipo_campana, variante_ab) 

SELECT
	tipo_campana, 
	variante_ab, 
    ROUND(abierto_count/total_sent, 2) AS open_rate, 
    ROUND(click_count/total_sent, 2) AS ctr, 
    ROUND(convirtio_count/total_sent, 4) AS conv_rate
FROM metrics
ORDER BY tipo_campana; 

-- Deliverable #2 - Statistical significance test on conversion rate
WITH metrics AS (
    SELECT
        tipo_campana,
        SUM(CASE WHEN variante_ab = 'A' THEN 1 ELSE 0 END) AS n1,
        SUM(CASE WHEN variante_ab = 'B' THEN 1 ELSE 0 END) AS n2,
        SUM(CASE WHEN variante_ab = 'A' AND convirtio = '1' THEN 1 ELSE 0 END) AS c1,
        SUM(CASE WHEN variante_ab = 'B' AND convirtio = '1' THEN 1 ELSE 0 END) AS c2
    FROM campanas_crm_clean
    GROUP BY tipo_campana
),

calc_rates AS (
    SELECT
        tipo_campana,
        n1,
        n2,
        c1,
        c2,
        (c1 / n1) AS p1,
        (c2 / n2) AS p2,
        (c1 + c2) / (n1 + n2) AS p_pooled
    FROM metrics
    WHERE n1 > 0 AND n2 > 0 
),

z_scores AS (
    SELECT
        tipo_campana,
        p1 AS conv_rate_A,
        p2 AS conv_rate_B,
        p_pooled,
        (p1 - p2) / SQRT(
            p_pooled * (1 - p_pooled) * ((1.0 / n1) + (1.0 / n2))
        ) AS z_score
    FROM calc_rates
)

SELECT
    tipo_campana,
    conv_rate_A,
    conv_rate_B,
    z_score,
    CASE 
        WHEN ABS(z_score) >= 1.96 THEN 'significant'
        ELSE 'not significant'
    END AS significance
FROM z_scores;

-- Deliverable #3 - Revenue per variant
SELECT
    tipo_campana,
    variante_ab,
    SUM(ingreso_generado) AS total_revenue,
    ROUND(SUM(ingreso_generado) / NULLIF(COUNT(CASE WHEN convirtio = '1' THEN campana_id END), 0), 2) AS avg_rev_per_converted_customer
FROM campanas_crm_clean
GROUP BY tipo_campana, variante_ab
ORDER BY tipo_campana, variante_ab;