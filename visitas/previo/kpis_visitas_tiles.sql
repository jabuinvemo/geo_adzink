-------------VOLVO

WITH

AUDIENCIA AS (

  SELECT * FROM `mm-new-business-reporting.ADVERTISING.AUDIENCIAS_POC_COMPLETAS_CON_LINEA_AUDIENCIA` 
  WHERE POC = 'VOLVO_XC40-AON_ABR2026_1'
  AND SERVICE_TYPE='MOBILE' and TELEFONO_SELECCIONADO='SELECCIONADO'
),


visitas as 
(
select periodo, brand_ds,segment_ds,customer_id,phone_nm, PROB_VISITAS ,MIN(FECHA) AS FECHA_MIN,MAX(FECHA) AS FECHA_MAX
FROM   
(
select *, 
    count(distinct  id_ubicacion) over (partition by msisdn) as num_ubicaciones, 
    count(distinct fecha) over (partition by msisdn,id_ubicacion) as num_fechas,
    sum(PROBABILIDAD_PONDERADA_total_sector) over (partition by msisdn) AS PROB_VISITAS
    from
`mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_VISITAS_GEO_CAMPAIGN_UBICACION` A 
where brand_ds is not null and CAMPAIGN  like '%VOLVO_XC40-AON_ABR2026_1_SIN_DESCARTES%')

where num_ubicaciones<=2 and num_fechas<=3

group by all

)


select periodo, MIN(FECHA_MIN),MAX(FECHA_MAX), poc,tipo_audiencia_accionable,
count(distinct concat(b.brand_Ds,b.segment_ds,b.customer_id)) AS CLIENTES,
count(distinct concat(b.brand_Ds,b.segment_ds,b.customer_id,B.PHONE_NM)) AS LINEAS,
SUM(PROB_VISITAS) AS PROB_VISITAS

from visitas a inner join audiencia b

on a.brand_ds=b.brand_ds and a.segment_ds=b.segment_ds 
and a.customer_id=b.customer_id and a.phone_nm=b.phone_nm


.---------------------------------ALDI



WITH

AUDIENCIA AS (

  SELECT * FROM `mm-new-business-reporting.ADVERTISING.AUDIENCIAS_POC_COMPLETAS_CON_LINEA_AUDIENCIA` 
  WHERE POC = 'LIDL_COMPETENCIA_MAY2026_COMPETENCIA-ALDI-PROMO1-MAIDS'
  AND SERVICE_TYPE='MOBILE' and TELEFONO_SELECCIONADO='SELECCIONADO'
),


visitas as 
(
select periodo, brand_ds,segment_ds,customer_id,phone_nm,MIN(FECHA) AS FECHA_MIN,MAX(FECHA) AS FECHA_MAX
FROM   
(
select *, 
    count(distinct  id_ubicacion) over (partition by msisdn) as num_ubicaciones, 
    count(distinct fecha) over (partition by msisdn,id_ubicacion) as num_fechas
    from
`mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_VISITAS_GEO_CAMPAIGN_UBICACION` A 
where brand_ds is not null and CAMPAIGN  like '%LIDL_COMPETENCIA_MAY2026_COMPETENCIA-ALDI-OLA-1_SIN-DESCARTES%')

where num_ubicaciones<=2 and num_fechas<=3

group by all

)


select periodo, MIN(FECHA_MIN),MAX(FECHA_MAX), poc,tipo_audiencia_accionable,count(distinct concat(b.brand_Ds,b.segment_ds,b.customer_id,B.PHONE_NM))

from visitas a inner join audiencia b

on a.brand_ds=b.brand_ds and a.segment_ds=b.segment_ds 
and a.customer_id=b.customer_id and a.phone_nm=b.phone_nm

group by all

-----------------------------------------------
SELECT PERIODO,NUM_CENTROS, COUNT(*)

FROM (
SELECT PERIODO,MSISDN , COUNT(DISTINCT ID_UBICACION) AS NUM_CENTROS

FROM   `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_VISITAS_GEO_CAMPAIGN_UBICACION` A 
where brand_ds is not null and CAMPAIGN  like '%LIDL_COMPETENCIA_MAY2026_COMPETENCIA-ALDI-OLA-1_SIN-DESCARTES%'
GROUP BY ALL
)

GROUP BY ALL

------------------------------------------------------------------

SELECT NUM_PERIODOS, COUNT(*)

FROM (
SELECT MSISDN , COUNT(DISTINCT PERIODO) AS NUM_PERIODOS

FROM   `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_VISITAS_GEO_CAMPAIGN_UBICACION` A 
where brand_ds is not null and CAMPAIGN  like '%LIDL_COMPETENCIA_MAY2026_COMPETENCIA-ALDI-OLA-1_SIN-DESCARTES%' AND SEGMENT_DS='RESIDENCIAL'
GROUP BY ALL
)

GROUP BY ALL

---------------------------------------------------------------------

SELECT PERIODO,num_fechas, COUNT(*)

FROM (
SELECT PERIODO,MSISDN , id_ubicacion,COUNT(DISTINCT fecha) AS num_fechas

FROM   `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_VISITAS_GEO_CAMPAIGN_UBICACION` A 
where brand_ds is not null and CAMPAIGN  like '%LIDL_COMPETENCIA_MAY2026_COMPETENCIA-ALDI-OLA-1_SIN-DESCARTES%'
GROUP BY ALL
)

group by all