CREATE TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.VISITAS_UBICACION_GEO_TILES` 

(

POC		STRING,	
grupo_ubicacion		STRING,	
id_ubicacion		STRING	,
msisdn		STRING,	
fecha		DATE	,
num_horas		INT64	,
tiempo_total_ok_dia		INT64	,
tiempo_total_no_ok_dia		INT64	,
hora_minima		INT64	,
hora_maxima		INT64	,
dif_horas		INT64	,
tiempo_total_no_ok_ubicacion_dia		INT64	,
PROBABILIDAD_PONDERADA		FLOAT64,
PROBABILIDAD_PONDERADA_TOTAL_SECTOR		FLOAT64,	
PROBABILIDAD_TOTAL		FLOAT64,	
PROBABILIDAD_VISITA_OK		FLOAT64,	
DIA_SEMANA		INT64	,
PERIODO		STRING	,
brand_ds		STRING,	
segment_ds		STRING,	
customer_id		STRING,	
PHONE_NM		STRING	,
dias_msisdn_ubicacion		INT64,	
dias_msisdn_ubicacion_PERIODO		INT64,
FECHA_LOG TIMESTAMP	

)

PARTITION BY FECHA

CLUSTER BY POC,GRUPO_UBICACION,PERIODO