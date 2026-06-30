

DROP TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_MAESTRO_MUPIS_DIGITAL_TOTAL_20260623`;

create OR REPLACE table 
`mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_MAESTRO_MUPIS_DIGITAL_TOTAL_20260623` AS

with

DATOS_MUPIS_TOTAL_INI  AS (

SELECT 'JCDCAUX' AS PROVEEDOR, FECHA_PROVEEDOR,FRAME_ID AS FRAME_ID,
'YES' AS ES_DIGITAL,
ENVIRONMENT AS TIPO_UBICACION,
LATITUDE AS LATITUD_DIRECCION,
LONGITUDE AS LONGITUD_DIRECCION,
ADDRESS AS DIRECCION,
upper(CITY) AS CIUDAD,
LPAD(POST_CODE, 5, '0') AS CODIGO_POSTAL,
'SI' AS Disponible_PDOOH,
CONCAT(SAFE_CAST(WIDTH AS STRING), 'x', (SAFE_CAST(height AS STRING))) as RESOLUCION

FROM (select PARSE_DATE('%Y%m%d','20260324') as fecha_proveedor, * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_JCDCAUX_20260324`)
-------------------------
UNION ALL
--------------------------
sELECT 'CLEAR_CHANNEL' AS PROVEEDOR ,fecha_proveedor,
Axion_ID AS	 FRAME_ID,	
UPPER(ES_DIGITAL)  AS ES_DIGITAL,
L3_Clasificacipn as TIPO_UBICACION,
Latitud		AS LATITUD_DIRECCION,
Longitud		AS LONGITUD_DIRECCION,	
Direccion		AS DIRECCION,	
Upper(Ciudad)		AS CIUDAD	,
LPAD(Codigo_Postal, 5, '0')  AS CODIGO_POSTAL,
Disponible_PDOOH AS Disponible_PDOOH,
L4_FORMATO AS RESOLUCION
FROM 
(select PARSE_DATE('%Y%m%d','20260407') as fecha_proveedor, * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CLEAR_CHANNEL_20260407`)
--------------------------
UNION ALL
---------------------------
sELECT 'GLOBAL' AS PROVEEDOR ,fecha_proveedor,
screen_id AS	 FRAME_ID,	
'YES' AS ES_DIGITAL,
VENUE_TYPE as TIPO_UBICACION,
Latitude		AS LATITUD_DIRECCION,
Longitude		AS LONGITUD_DIRECCION,	
screen_name		AS DIRECCION,	
upper(CITY)		AS CIUDAD	,
LPAD(POSTCODE, 5, '0')  AS CODIGO_POSTAL,
'SI' AS Disponible_PDOOH,
CONCAT(SAFE_CAST(SCREEN_DIMENSIONS_WIDTH AS STRING), 'x', (SAFE_CAST(SCREEN_DIMENSIONS_HEIGHT AS STRING))) as resolucion
FROM 
(select PARSE_DATE('%Y%m%d','20260313') as fecha_proveedor, * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_GLOBAL_20260313`)
----------------------
UNION ALL
-----------------------
SELECT 'EXTERIOR_PLUS' as PROVEEDOR,fecha_proveedor,
Screen_ID_BS		AS frame_id,
'YES' AS ES_DIGITAL,
VENUE_TYPE as TIPO_UBICACION,
Latitude		AS LATITUD_DIRECCION,
Longitude		AS LONGITUD_DIRECCION,
site_name		AS DIRECCION,	
upper(municipio)		AS CIUDAD	,
LPAD(cp, 5, '0')  AS CODIGO_POSTAL,
'SI' AS Disponible_PDOOH,
CONCAT(SAFE_CAST(WIDTH AS STRING), 'x', (SAFE_CAST(HEIGHT AS STRING))) as resolucion
from 
(select PARSE_DATE('%Y%m%d','20260519') as fecha_proveedor, * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_EXTERIOR_PLUS_20260519`)
--------------------------
UNION ALL
---------------------------
SELECT 'CLECEOOH' as PROVEEDOR,fecha_proveedor,
venue_id		AS frame_id,
'YES' AS ES_DIGITAL,
VENUE_TYPE as TIPO_UBICACION,
Latitude		AS LATITUD_DIRECCION,
Longitude		AS LONGITUD_DIRECCION,
address		AS DIRECCION,	
upper(provincia)		AS CIUDAD	,
LPAD(cp, 5, '0')  AS CODIGO_POSTAL,
'SI' AS Disponible_PDOOH,
CONCAT(SAFE_CAST(WIDTH_px AS STRING), 'x', (SAFE_CAST(HEIGHT_px AS STRING))) as resolucion
from 
(select PARSE_DATE('%Y%m%d','20260519') as fecha_proveedor, * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CLECEOOH_20260519`)
)

select 
PROVEEDOR, 
FECHA_PROVEEDOR,
FRAME_ID ,
ES_DIGITAL,
TIPO_UBICACION,
LATITUD_DIRECCION,
LONGITUD_DIRECCION,
DIRECCION,
CIUDAD,
CODIGO_POSTAL,
DISPONIBLE_PDOOH,
RESOLUCION,
CONCAT(CAST(latitud_direccion AS STRING), ", ", CAST(longitud_direccion AS STRING)) as COORDENADAS_LOOKER_MUPI 
from DATOS_MUPIS_TOTAL_INI 

-----------------------------------------------------------------------
------------------------------------------------------------------------

DROP EXTERNAL TABLE IF EXISTS `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_HORARIOS_CIRCUITOS_CAMPAINGS`;

CREATE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_HORARIOS_CIRCUITOS_CAMPAINGS`
(
CAMPAIGN		STRING,
PROVEEDOR		STRING,	
OLA_CIRCUITO		STRING,	
OLA_CAMPAIGN		STRING,	
FECHA_INICIO		DATE,	
FECHA_FIN		DATE,	
DIAS_SEMANA		STRING,	
HORAS		STRING	
)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1_AsW612t1ixD3rPIBA0xvNTof4NLHwhCGNJa_1akZ_w/edit?usp=drive_link'],
  sheet_range = 'HORARIOS_CIRCUITOS',  -- <-- AQUÍ ES DONDE FILTRAS LA PESTAÑA
  skip_leading_rows = 1             -- Para saltarse la fila de los encabezados
);


------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------

DROP EXTERNAL TABLE IF EXISTS  `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CIRCUITOS_CAMPAINGS`;

CREATE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CIRCUITOS_CAMPAINGS`

(CAMPAIGN	STRING,	
OLA_CIRCUITO	STRING,	
FECHA_INICIO	DATE,	
FECHA_FIN	DATE,	
proveedor	STRING,	
frame_id	STRING,	
tipo_ubicacion	STRING,	
direccion_mupi	STRING,	
municipio	STRING,	
provincia	STRING,	
coordenadas_looker STRING)

OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1_AsW612t1ixD3rPIBA0xvNTof4NLHwhCGNJa_1akZ_w/edit?usp=drive_link'],
  sheet_range = 'CIRCUITOS',  -- <-- AQUÍ ES DONDE FILTRAS LA PESTAÑA
  skip_leading_rows = 1             -- Para saltarse la fila de los encabezados
);