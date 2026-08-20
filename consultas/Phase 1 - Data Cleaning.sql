-- Standarizing city names from clientes 
SELECT 
	ciudad, 
    CONCAT(UPPER(SUBSTRING(clean_city, 1, 1)), LOWER(SUBSTRING(clean_city, 2))) AS proper_city
FROM( 
	SELECT
		ciudad,
		TRIM(SUBSTRING_INDEX(REPLACE(ciudad, '-', ' '), ' ', 1)) AS clean_city
	FROM clientes_clean) AS inner_table;
    
UPDATE clientes_clean
SET ciudad = TRIM(SUBSTRING_INDEX(REPLACE(ciudad, '-', ' '), ' ', 1))
WHERE ciudad IS NOT NULL AND ciudad <> '';

UPDATE clientes_clean
SET ciudad = CONCAT(UPPER(SUBSTRING(ciudad, 1, 1)), LOWER(SUBSTRING(ciudad, 2)))
WHERE ciudad IS NOT NULL AND ciudad <> '';

SELECT DISTINCT ciudad
FROM clientes_clean; 

-- Standarizing channel name from clientes
SELECT DISTINCT canal_adquisicion 
FROM clientes_clean; 

# Channels: TikTok Ads, referral, organic, Meta Ads, Email, Google Ads, SEO 

UPDATE clientes_clean
SET canal_adquisicion = TRIM(REPLACE(canal_adquisicion, '-', ' '))
WHERE canal_adquisicion IS NOT NULL AND canal_adquisicion <> '';

UPDATE clientes_clean
SET canal_adquisicion = CASE 
    -- Google Ads Group
    WHEN LOWER(canal_adquisicion) IN ('google ads', 'googleads', 'google', 'sem') THEN 'Google Ads'
    
    -- Meta Ads Group
    WHEN LOWER(canal_adquisicion) IN ('meta ads', 'facebook ads', 'meta', 'fb ads', 'facebook') THEN 'Meta Ads'
    
    -- Organic Group
    WHEN LOWER(canal_adquisicion) IN ('orgánico', 'organico', 'seo') THEN 'Orgánico'
    
    -- Email Group
    WHEN LOWER(canal_adquisicion) IN ('email', 'e mail', 'correo') THEN 'Email'
    
    -- Referral Group
    WHEN LOWER(canal_adquisicion) IN ('referido', 'referral') THEN 'Referido'
    
    -- TikTok Ads Group
    WHEN LOWER(canal_adquisicion) IN ('tiktok ads', 'tiktok') THEN 'TikTok Ads'
    
    ELSE canal_adquisicion -- Safe fallback
END
WHERE canal_adquisicion IS NOT NULL AND canal_adquisicion <> '';

SELECT *
FROM clientes_clean; 

-- Standarizing city names from pedidos
SELECT DISTINCT proper_city
FROM (
	SELECT 
		ciudad_entrega, 
        CONCAT(UPPER(SUBSTRING(clean_cityv1,1, 1)), LOWER(SUBSTRING(clean_cityv1, 2))) AS proper_city
	FROM(
		SELECT
			ciudad_entrega, 
			TRIM(SUBSTRING_INDEX(REPLACE(ciudad_entrega, '-', ' '), ' ', 1)) AS clean_cityv1
		FROM pedidos_clean) AS trim_table) AS upper_table; 	
        
UPDATE pedidos_clean
SET ciudad_entrega = TRIM(SUBSTRING_INDEX(REPLACE(ciudad_entrega, '-', ' '), ' ', 1)) 
WHERE ciudad_entrega IS NOT NULL AND ciudad_entrega <> '';

UPDATE pedidos_clean
SET ciudad_entrega = CONCAT(UPPER(SUBSTRING(ciudad_entrega,1, 1)), LOWER(SUBSTRING(ciudad_entrega, 2)))
WHERE ciudad_entrega IS NOT NULL AND ciudad_entrega <> '';

SELECT DISTINCT metodo_pago, 
	CASE 
		WHEN metodo_pago = 'PagoEfectivo' THEN 'Efectivo' 
        ELSE metodo_pago
	END 
FROM pedidos_clean; 

UPDATE pedidos_clean
SET metodo_pago = 	CASE 
		WHEN metodo_pago = 'PagoEfectivo' THEN 'Efectivo' 
        ELSE metodo_pago
	END; 

SELECT DISTINCT metodo_pago
FROM pedidos_clean; 

-- Handlign neg. numbers from pedidos_clean 
SELECT
	*
FROM pedidos_clean
WHERE total_pedido <= 0 AND estado != 'Cancelado'; 

UPDATE pedidos_clean
SET total_pedido = ABS(total_pedido); 

SELECT *
FROM detalle_pedidos_clean; 

SELECT
	total_pedido, 
    estado, 
    precio_unitario, 
    descuento_aplicado, 
    subtotal
FROM pedidos_clean AS pc
JOIN detalle_pedidos_clean dpc
	ON pc.pedido_id = dpc.pedido_id
WHERE total_pedido <= 0 AND estado != 'Cancelado'; 

# Found out that total_pedido != all subtotal values (data quality issue as it should -> Use SUM(subtotal) to find the real values
SELECT
	pc.pedido_id, 
	total_pedido, 
    estado, 
    precio_unitario, 
    descuento_aplicado, 
    subtotal 
FROM pedidos_clean AS pc
JOIN detalle_pedidos_clean dpc
	ON pc.pedido_id = dpc.pedido_id
ORDER BY pc.pedido_id ASC; 

SELECT 
    pedido_id, 
    SUM(subtotal) AS actual_total_pedido
FROM detalle_pedidos_clean
GROUP BY pedido_id
ORDER BY pedido_id ASC;

# Updated the total_pedido values to reflect the actual total from subtotal 
UPDATE pedidos_clean p
JOIN (
    SELECT 
        pedido_id, 
        SUM(subtotal) AS calculated_total
    FROM detalle_pedidos_clean
    GROUP BY pedido_id
) d ON p.pedido_id = d.pedido_id
SET p.total_pedido = d.calculated_total;

SELECT *
FROM pedidos_clean; 

-- Standarizing campanas_crm channel 
SELECT DISTINCT tipo_campana
FROM campanas_crm_clean; 

UPDATE campanas_crm_clean
SET tipo_campana = CASE 
    -- Email group
    WHEN LOWER(tipo_campana) IN ('email', 'e mail', 'correo', 'e-mail') THEN 'Correo'
    
    -- WhatsApp group
    WHEN LOWER(tipo_campana) IN ('whatsapp') THEN 'WhatsApp'
    
    -- SMS group
    WHEN LOWER(tipo_campana) IN ('sms') THEN 'SMS'
    
    -- Push notifications group
    WHEN LOWER(tipo_campana) IN ('push') THEN 'Push'
    
    ELSE tipo_campana 
END
WHERE tipo_campana IS NOT NULL AND tipo_campana <> '';
    
SELECT *
FROM campanas_crm_clean; 

-- Cleaning sesiones_web_clean boolean 
SELECT COUNT(*) 
FROM sesiones_web_clean 
WHERE realizo_compra IS False;

SELECT COUNT(*) 
FROM sesiones_web_clean; 

UPDATE sesiones_web_clean
SET fuente_trafico = CASE 
    WHEN LOWER(fuente_trafico) IN ('google ads', 'googleads', 'google', 'sem') THEN 'Google Ads'
    WHEN LOWER(fuente_trafico) IN ('meta ads', 'facebook ads', 'meta', 'fb ads', 'facebook') THEN 'Meta Ads'
    WHEN LOWER(fuente_trafico) IN ('orgánico', 'organico', 'seo', 'organic') THEN 'Orgánico'
    WHEN LOWER(fuente_trafico) IN ('email', 'e mail', 'correo', 'e-mail') THEN 'Correo'
    WHEN LOWER(fuente_trafico) IN ('referido', 'referral') THEN 'Referido'
    WHEN LOWER(fuente_trafico) IN ('tiktok ads', 'tiktok') THEN 'TikTok Ads'
    ELSE fuente_trafico 
END
WHERE fuente_trafico IS NOT NULL AND fuente_trafico <> '';

SELECT *
FROM sesiones_web_clean; 

SELECT COUNT(*) AS ghost_sessions # Checking for invalid IDs -> All IDs are either from a user or guest on website 
FROM sesiones_web_clean s
LEFT JOIN clientes_clean c 
	ON s.cliente_id = c.cliente_id
WHERE s.cliente_id IS NOT NULL 
  AND s.cliente_id <> 0 
  AND c.cliente_id IS NULL;
  
SELECT *
FROM detalle_pedidos_clean; 