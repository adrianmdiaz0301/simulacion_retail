# 📊 MercadoNova: Análisis CRM End-to-End para Retail E-commerce

Este proyecto forma parte de mi portafolio como Analista de Datos / BI y simula el trabajo analítico completo de un CRM Analyst en una empresa de retail e-commerce peruana (pensando en compañías como Falabella, Intercorp Retail o BBVA Perú). Todo el análisis se desarrolló en **MySQL**, partiendo de un dataset relacional sintético de 53,650 filas generado en Python (pandas + Faker).

El objetivo no fue solo escribir queries — fue simular el ciclo completo de un analista CRM: limpiar datos crudos con problemas reales, segmentar clientes, medir retención, diagnosticar el embudo de conversión y evaluar si una campaña realmente funcionó, entregando siempre una recomendación de negocio accionable.

---

## 📌 Problema de Negocio

Una empresa de retail e-commerce necesita entender a su base de clientes para tomar decisiones de CRM: ¿a quién retener, a quién reactivar, qué canal de adquisición realmente trae clientes de valor, y dónde se está perdiendo dinero en el embudo de conversión? Este proyecto responde esas preguntas usando exclusivamente SQL, desde la limpieza de datos crudos hasta el análisis estadístico de campañas.

## 🧠 Preguntas de Negocio Respondidas

1. ¿Qué segmentos de clientes generan más ingresos, y cuáles tienen el mayor ingreso por cliente? *(Segmentación RFM)*
2. ¿Cuánto ingreso se está perdiendo por clientes inactivos, y vale la pena una campaña de reactivación? *(RFM + Análisis Monetario)*
3. ¿Qué meses generan más ingresos y existe una tendencia de crecimiento consistente? *(Tendencia de Ingresos Mensual)*
4. ¿Qué categorías de producto generan el 80% del ingreso total, y los descuentos realmente aumentan el ingreso por categoría? *(Análisis de Pareto + Descuentos)*
5. De todos los clientes que se registran, ¿qué porcentaje compra dentro de sus primeros 3 meses — y qué canal de adquisición retiene mejor a los clientes en el tiempo? *(Retención por Cohortes)*
6. ¿En qué punto del embudo web se pierden más compradores potenciales, y qué fuente de tráfico y dispositivo convierte mejor? *(Análisis de Embudo)*
7. ¿Qué canal y variante de campaña genera la mayor tasa de conversión e ingreso por cliente — y es la diferencia estadísticamente significativa? *(A/B Testing)*

---

## 📚 Dataset

**Fuente:** dataset sintético generado con Python (pandas + Faker), diseñado para replicar patrones realistas de un negocio retail e-commerce peruano — 6 tablas relacionales, 53,650 filas en total.

| Tabla | Filas | Descripción |
|---|---|---|
| `clientes` | 2,000 | PK: `cliente_id`. Datos demográficos, canal de adquisición, segmento CRM |
| `productos` | 200 | PK: `producto_id`. Categoría, subcategoría, precio base, marca |
| `pedidos` | 8,000 | PK: `pedido_id`, FK: `cliente_id`. Fecha, total, estado, canal |
| `detalle_pedidos` | 18,000 | PK: `detalle_id`, FK: `pedido_id` + `producto_id`. Cantidad, precio unitario, descuento |
| `sesiones_web` | 15,450 | PK: `sesion_id`, FK: `cliente_id` (nullable). Fuente de tráfico, dispositivo, comportamiento |
| `campanas_crm` | 10,000 | PK: `campana_id`, FK: `cliente_id`. Tipo, variante A/B, apertura, clic, conversión |

**Problemas de calidad de datos incluidos intencionalmente** (para simular un dataset real de producción):
- ~8% de valores NULL en `edad`, `ciudad` y `segmento_crm`
- Formatos de ciudad inconsistentes (`Lima`, `LIMA`, `lima`, `Lima Metropolitana`, `Lima - Perú`)
- Categorías inconsistentes en `canal_adquisicion` y `tipo_campana` (`Email`, `email`, `E-mail`, `FB Ads`, `facebook`, `Meta Ads`)
- ~3% de filas duplicadas en `sesiones_web`
- ~1% de valores de `total_pedido` en cero o negativos
- ~0.5% de fechas fuera de rango (anteriores a 2022 o posteriores a 2025)

## 🛠️ Herramientas

- **MySQL Workbench** — limpieza, transformación y análisis completo en SQL
- **Python (pandas + Faker)** — generación del dataset sintético
- **Looker Studio** — dashboard final de visualización

---

## 🔍 Fases del Análisis

### Fase 1 — Limpieza de Datos
Estandarización de nombres de ciudad en `clientes` y `pedidos` separando y capitalizando el texto con `SUBSTRING_INDEX()` + `TRIM()`. Estandarización de canales de adquisición y tipo de campaña agrupando variantes inconsistentes (`'Email'`, `'email'`, `'E-mail'`, `'FB Ads'`, `'facebook'`, etc.) en categorías limpias con `CASE WHEN`. Normalización de método de pago (`'PagoEfectivo'` → `'Efectivo'`).

Al revisar `total_pedido <= 0`, encontré que corregir el signo con `ABS()` no era suficiente — el total del pedido no coincidía con la suma real de sus líneas en `detalle_pedidos`. Recalculé `total_pedido` para cada pedido usando `SUM(subtotal)` desde `detalle_pedidos_clean` vía un `UPDATE ... JOIN`, en lugar de solo filtrar o forzar el signo, para que el monto reflejara la venta real. También validé que no existieran `cliente_id` huérfanos en `sesiones_web` (IDs que no correspondían a ningún cliente ni a un visitante anónimo válido). Cada decisión de limpieza está documentada con comentarios SQL explicando el porqué.

<img width="1108" height="696" alt="Screenshot 2026-08-19 at 7 20 32 PM" src="https://github.com/user-attachments/assets/8d450f13-1827-4b90-8512-6cbf591922bf" />

<img width="773" height="508" alt="Screenshot 2026-08-19 at 7 21 41 PM" src="https://github.com/user-attachments/assets/cf0c2c69-8ef8-444a-a8a8-0881d99584b2" />
sc

### Fase 2 — Segmentación RFM
Arquitectura de múltiples CTEs encadenados (recencia, frecuencia, monetario, agregación y cuartiles) calculando recencia (`DATEDIFF` desde `CURDATE()` hasta `MAX(fecha_pedido)`), frecuencia (`COUNT(pedido_id)`) y monetario (`SUM(total_pedido)`) por cliente. Scoring con `NTILE(4)` — recencia en orden descendente (invertido, para que menos días = score 4), frecuencia y monetario en orden ascendente. El filtro de fechas fuera de rango (`fecha_pedido >= '2022-01-01'`) se aplica directamente en el CTE de recencia para excluir pedidos con fechas inválidas del cálculo. Etiquetas de segmento por rango: Campeón, Cliente Leal, Cliente Reciente, En Riesgo, Inactivo, Intermedio.

**Hallazgo clave:** Cliente Leal genera el mayor ingreso total (S/16.4M), pero Campeón tiene el mayor ingreso por cliente. El segmento Inactivo representa S/7.9M en gasto histórico — una oportunidad de reactivación a costo de adquisición cero.

**Queries**
<img width="829" height="564" alt="Screenshot 2026-08-19 at 7 24 44 PM" src="https://github.com/user-attachments/assets/b0b66938-7a3a-4fb9-9f94-3067f8d5d3ff" />
<img width="829" height="461" alt="Screenshot 2026-08-19 at 7 24 51 PM" src="https://github.com/user-attachments/assets/531bea88-16b4-4622-a129-bf62f6a21466" />
<img width="1036" height="505" alt="Screenshot 2026-08-19 at 7 25 08 PM" src="https://github.com/user-attachments/assets/c1836f32-5802-461d-8432-928f18eb381c" />
<img width="1036" height="219" alt="Screenshot 2026-08-19 at 7 25 16 PM" src="https://github.com/user-attachments/assets/5639931b-1790-4c9b-85d0-c425f2c59b49" />

**Tabla: Resumen por segmento**
<img width="532" height="167" alt="Screenshot 2026-08-19 at 7 26 27 PM" src="https://github.com/user-attachments/assets/7a163d0e-bd1e-462c-858d-54a49faf4f73" />

### Fase 3 — Análisis de Ingresos y Productos
Tendencia de ingresos mensual con `DATE_FORMAT` y arquitectura de dos CTEs — `LAG()` calculado una vez y referenciado en el `SELECT` final para el % de crecimiento mes a mes. Top 10 productos por ingreso. Desglose de ingreso por categoría usando `GROUP BY ... WITH ROLLUP` + `GROUPING()` para obtener el total general en la misma consulta, con `SUM() OVER()` como denominador de ventana para calcular el porcentaje de participación de cada categoría. Las categorías se ordenaron por ingreso descendente para identificar visualmente cuáles concentran el 80% del ingreso total (Pareto). Correlación entre descuento promedio y desempeño por categoría.

<img width="797" height="510" alt="Screenshot 2026-08-19 at 7 28 16 PM" src="https://github.com/user-attachments/assets/7cfd3c8f-cff9-457e-bec7-f8b4b921009a" />

### Fase 4 — Retención por Cohortes
`LEFT JOIN` de `pedidos_clean` a `clientes_clean` usando `TIMESTAMPDIFF(MONTH, fecha_registro, fecha_pedido) BETWEEN 0 AND 3` como condición de join (no en el `WHERE`, para conservar a los clientes que no compraron). Pivot con `COUNT(DISTINCT CASE WHEN month_diff = N THEN cliente_id END)` para los meses 0–3. `cohort_size` desde `clientes_clean` como denominador (no el conteo de compras del mes 0) para evitar retenciones mayores al 100%.

**Hallazgos clave:** solo el 10–30% de los registrados compra en el mes 0 — hay oportunidad de un incentivo de primera compra. Email activa más rápido (22.45% en m0) pero cae a 7% para el mes 2. Meta Ads retiene mejor en el mes 2 (14.29%) — clientes de mayor calidad pese a una conversión inicial más lenta.

<img width="879" height="692" alt="Screenshot 2026-08-19 at 7 54 24 PM" src="https://github.com/user-attachments/assets/200767e6-a0d6-4dac-a2e1-c3f63cca1de9" />

<img width="575" height="158" alt="Screenshot 2026-08-19 at 7 54 56 PM" src="https://github.com/user-attachments/assets/b20bdfb4-00a4-4cfe-b2dd-03ea005b41d8" />

### Fase 5 — Análisis del Embudo Web
Embudo de tres etapas desde `sesiones_web_clean`: sesiones totales → agregó al carrito → realizó compra. Tasas de abandono por etapa y conversión end-to-end, desglosadas por fuente de tráfico y dispositivo. Análisis de abandono de carrito filtrando `agrego_al_carrito=1 AND realizo_compra=0`, agrupado por página de salida, con `SUM() OVER()` para calcular el porcentaje de participación de cada página en el abandono total.

<img width="761" height="400" alt="Screenshot 2026-08-19 at 8 01 48 PM" src="https://github.com/user-attachments/assets/c372a060-96b5-4051-a689-6c648800ca12" />

### Fase 6 — A/B Testing de Campañas
Open rate, CTR y tasa de conversión por `tipo_campana` + `variante_ab`, con la tasa de conversión redondeada a 4 decimales dado lo pequeño de sus valores. Arquitectura de cuatro CTEs para el cálculo del z-score: métricas (n1, n2, c1, c2) → tasas (p1, p2, p_pooled) → z-score (`z = (p1-p2)/SQRT(p_pooled*(1-p_pooled)*(1/n1+1/n2))`) → etiqueta de significancia con `ABS(z_score) >= 1.96`. Ingreso por variante con `NULLIF` para protegerse de división entre cero.

**Hallazgos clave:** ningún tipo de campaña alcanzó significancia estadística (todos los z-scores < 1.96) — el test es inconcluso, se recomienda extender su duración. WhatsApp Variante A gana en ingreso por cliente convertido pese a tener la misma tasa de conversión que B. Correo Variante B genera 6x más ingreso total que A.

<img width="761" height="529" alt="Screenshot 2026-08-19 at 8 03 02 PM" src="https://github.com/user-attachments/assets/a9c68105-39de-4896-8811-9754fda5606a" />
<img width="761" height="465" alt="Screenshot 2026-08-19 at 8 03 13 PM" src="https://github.com/user-attachments/assets/053c6c22-a7e5-4d7a-9a8e-f04572d60b18" />

---

## 💡 Insights y Recomendaciones para el Negocio

- **Reactivación de clientes Inactivos:** S/7.9M en gasto histórico dormido representan la oportunidad de menor costo de adquisición disponible — priorizar una campaña de win-back sobre nueva adquisición.
- **Incentivo de primera compra:** con solo 10–30% de conversión en el mes 0, un descuento o incentivo de bienvenida podría capturar ingreso que hoy se pierde en el primer contacto.
- **Meta Ads como canal de calidad, no de volumen:** aunque activa más lento que Email, retiene mejor a mediano plazo — reasignar presupuesto de adquisición considerando retención, no solo conversión inicial.
- **Test A/B de campañas:** extender la duración de las pruebas antes de declarar un ganador — los resultados actuales no son estadísticamente concluyentes pese a diferencias aparentes en ingreso.
- **Categorías de alto impacto:** enfocar inventario y esfuerzo de marketing en el pequeño grupo de categorías que concentra la mayor parte del ingreso, validando si el descuento realmente está impulsando esas ventas o solo erosionando margen.

---

## 🖼️ Dashboard

<img width="1160" height="870" alt="Screenshot 2026-08-19 at 8 05 27 PM" src="https://github.com/user-attachments/assets/6d54da6b-e281-421a-a59c-2064c1735601" />

[Dashboard en Data Studio](https://datastudio.google.com/reporting/72f019d9-b095-4d74-8b41-79c7fbf14904)
---

## 📁 Estructura del Repositorio

```
📦 mercadonova-crm-analytics
├── sql/
│   ├── Phase_1_-_Data_Cleaning.sql
│   ├── Phase_2_-_RFM_Segmentation.sql
│   ├── Phase_3_-_Revenue_and_Product_Analysis.sql
│   ├── Phase_4_-_Cohort_Retention.sql
│   ├── Phase_5_-_Web_Funnel_Analysis.sql
│   └── Phase_6_-_A_B_Test.sql
├── data/
│   └── (dataset sintético: clientes, productos, pedidos, detalle_pedidos, sesiones_web, campanas_crm)
├── dashboard/
│   └── (enlace o capturas del dashboard en Looker Studio)
└── README.md
```

## 📌 Notas

El dataset es sintético, generado en Python con pandas y Faker, diseñado para replicar patrones realistas de un negocio retail e-commerce peruano (ciudades, canales de adquisición, comportamiento de compra y campañas CRM).

## 📬 Contacto

¿Tienes sugerencias o quieres colaborar? ¡Contáctame por [LinkedIn](https://www.linkedin.com/in/adrianmdiaz/) o revisa más proyectos en mi portafolio aqui en GitHub!
