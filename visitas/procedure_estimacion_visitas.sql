CREATE OR REPLACE PROCEDURE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.estimacion_visitas_con_tiles`
(IN NOMBRE_POC STRING, 
IN LISTA_UBICACIONES ARRAY<STRING>, 
IN FECHA_INICIO_OK DATE, 
IN FECHA_FIN_OK DATE, 
IN LISTA_HORAS_OK ARRAY<INT64>, 
IN MINUTOS_MIN INT64, 
IN MINUTOS_MAX INT64, 
IN RADIO_UBICACION INT64)
BEGIN

--DECLARE NOMBRE_POC STRING;
DECLARE NOMBRE_POC_UBICACIONES_REPORTING STRING;
DECLARE NOMBRE_UBICACION STRING;
DECLARE NOMBRE_UBICACION_AGRUPADO STRING;
DECLARE UBICACION_BORRADO STRING;
DECLARE FECHA_INICIO_RANGO DATE;
DECLARE FECHA_FIN_RANGO DATE;
--DECLARE FECHA_INICIO_OK DATE;
--DECLARE FECHA_FIN_OK DATE;

DECLARE VENTANA_DIAS_CAMPAIGN INT64;
 
DECLARE HORA_INICIO_OK INT64;
DECLARE HORA_FIN_OK INT64;
DECLARE HORA_INICIO_OK2 INT64;
DECLARE HORA_FIN_OK2 INT64;
DECLARE DIAS_DESPLAZAMIENTO INT64;
--DECLARE RADIO_UBICION INT64;


declare FECHA_TILES_STR STRING;
declare FECHA_MASTER_TOPOLOGY_STR STRING;
--DECLARE LISTA_UBICACIONES  ARRAY<STRING> DEFAULT ['%'];
--DECLARE LISTA_HORAS_OK  ARRAY<INT64> ;

--DECLARE MINUTOS_MIN INT64;
--DECLARE MINUTOS_MAX INT64;
 

--SET FECHA_INICIO_OK = '2026-05-04'; --'2026-05-21';--2026-04-20';
--SET FECHA_FIN_OK ='2026-05-31'; --'2026-05-23'; --'2026-05-30';


SET VENTANA_DIAS_CAMPAIGN=DATE_DIFF(FECHA_FIN_OK,FECHA_INICIO_OK,DAY);

SET FECHA_INICIO_RANGO =date_sub(FECHA_INICIO_OK,INTERVAL VENTANA_DIAS_CAMPAIGN+1 DAY);
SET FECHA_FIN_RANGO =date_ADD(FECHA_FIN_OK,INTERVAL VENTANA_DIAS_CAMPAIGN+1 DAY);

--SET LISTA_HORAS_OK=[8,9,10,11,12,13,14];


--SET MINUTOS_MIN =10;
--SET MINUTOS_MAX =60;
 
--SET NOMBRE_POC='ECI_SIN_DESCARTES_PERIMETRO';

--SET LISTA_UBICACIONES=['TIENDA_MERCADONA'];


SET FECHA_TILES_STR = (SELECT MAX(_TABLE_SUFFIX) FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.master_tiles_*`);

SET FECHA_MASTER_TOPOLOGY_STR = (select max(_table_suffix) from `mm-cdr-prod.00_SANDBOX_CEM_OSP.martes_topology_history_*` );

INSERT INTO `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.VISITAS_UBICACION_GEO_TILES` 

with



-------------------------------------------------------
--- 4. Generamos el maestro de datos de topologia seleccionando el ultimo dato para cada cgi
--- (otra opcion seria quedarse con la ultima tabla de la sharded de master_topology)
--- Generamos un maestro final asignando a cada sector una unica longitud/latitud 
--- (la correspondiente a la última fecha que se tenga para el emplazamiento del sector)
-------------------------------------------------------

maestro_topologia_last as 
(select * from `mm-cdr-prod.00_SANDBOX_CEM_OSP.martes_topology_history_*` where _table_suffix=(select max(_table_suffix) from `mm-cdr-prod.00_SANDBOX_CEM_OSP.martes_topology_history_*` )
),


maestro_topologia_con_historico as
(select * from (
                select *,_table_suffix as fecha_master, row_number() over  (partition by cgi order by _table_suffix desc ) as row_number_cgi,_table_suffix as fecha from `mm-cdr-prod.00_SANDBOX_CEM_OSP.martes_topology_history_*`)
where row_number_cgi=1),
 
maestro_topologia_inicial as (
  select * from maestro_topologia_con_historico --maestro_topologia_con_historico -- maestro_topologia_last
),

datos_sectores_finales as (

  select emplazamiento,sector,concat(emplazamiento,"-",sector) as sector_completo,longitude,latitude,row_number() over (partition by emplazamiento  order by fecha_master desc) as orden_sectores
  from maestro_topologia_inicial

),

maestro_topologia as (
  select A.* except (longitude,latitude), b.longitude,b.latitude 
  from maestro_topologia_inicial A left join (select * from datos_sectores_finales where orden_sectores=1) B
  
  on a.emplazamiento=B.emplazamiento --maestro_topologia_con_historico -- maestro_topologia_last
),


-------------------------------------------------------
--- 5. Generamos una tabla final con los emplazamientos, sectores y cgis para
--- posteriormente procesar timepertechnology
-------------------------------------------------------

datos_completos_cgi_sector as (
select cgi, emplazamiento,concat(emplazamiento,"-",sector) as sector_completo
from maestro_topologia
where concat(emplazamiento,"-",sector)  is not null 
group by all

),


-------------------------------------------------------
--- 6. Cruzamos los datos de eventos por tile y cgi con el maestro de topologia generado
--- Solo nos quedamos con lso tiles de menor tamaño (30/35 metros vs los de 140 m de lado)
--- Obtenemos las coordendas del centroide de cada tile y de los sectores de los cgis que les afectab
-------------------------------------------------------
 
 
datos_tiles_emplazamientos as (
select a.*,
ST_GEOGPOINT(centroid_longitude,centroid_latitude) AS coordenadas_tile,
ST_GEOGPOINT(longitude,latitude ) AS coordenadas_emplazamiento,
b.cgi as cgi_master,
b.sector as sector_master,
b.celda as celda_master,
nodo as nodo_master,
nodo_radio as nodo_radio_master,
concat(emplazamiento,"-",b.sector) as sector_completo,
emplazamiento,
latitude,
longitude,fecha_master,
centroid_longitude,centroid_latitude,
geometry
from
(SELECT * FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.master_tile_to_cgi_*` WHERE _TABLE_SUFFIX=FECHA_TILES_STR) A left join
maestro_topologia B
ON A.CGI=B.CGI
inner join (select   * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.master_tiles_*`  WHERE _TABLE_SUFFIX=FECHA_TILES_STR)  c
on a.tile_id=c.tile_id
WHERE B.CGI IS NOT NULL AND longitude IS NOT NULL AND latitude is not null
and spatial_resolution_meters<=50
),

-------------------------------------------------------
--- 7. Agrupamos el total de eventos de cada tipe por sector
--- (agregamos los eventos de los diferenes cgis del mismo sector
--- que pudieran afectar al tile)
-------------------------------------------------------

datos_tiles_sectores as (

select tile_id, centroid_longitude,centroid_latitude,
emplazamiento,sector_completo,latitude,longitude,
----------------PERIMETRO- COMO TEXTO APRA PODER AGRUPAR
ST_ASTEXT(geometry) as geometry_text,
-------------------
--fecha_master,
sum(count_tile) as eventos

from datos_tiles_emplazamientos
group by all
),

-------------------------------------------------------
--- 8. Completamos los datos de tile-sector, calculando
--- el porcentaje de eventos del tile que vienen de cada sector
--- el porcentaje del total de eventosw del sector que vienen del tile
-------------------------------------------------------

datos_completos_tiles_sectores as (

select *,
ST_GEOGPOINT(centroid_longitude,centroid_latitude) AS coordenadas_tile,
ST_GEOGPOINT(longitude,latitude ) AS coordenadas_emplazamiento,
st_distance(ST_GEOGPOINT(centroid_longitude,centroid_latitude),
            ST_GEOGPOINT(longitude,latitude)) as distancia_tile_emplazamiento,

sum(eventos) over (partition by sector_completo) as eventos_sector_total,
sum(eventos) over (partition by tile_id) as eventos_tile_total,
eventos/sum(eventos) over (partition by sector_completo) as porcentaje_sector,
eventos/sum(eventos) over (partition by tile_id) as porcentaje_tile,
row_number() over (partition by tile_id order by st_distance(ST_GEOGPOINT(centroid_longitude,centroid_latitude),
            ST_GEOGPOINT(longitude,latitude))) as orden_distancia_tile_sector
from datos_tiles_sectores-- order by datos_tiles_emplazamientos order by cgi_master,sector_master

),

-------------------------------------------------------
--- 9. cruzamos los datos de evnetos de los tiles con las ubicaciones
--- para cada ubicacion nos quedamos con los tiles a menos de una cierta distnacia
--- En este punto no filtramos los tiles  po sectores por importancia o distancia
-------------------------------------------------------

datos_completos_tiles_sectores_filtrados as (

select * from datos_completos_tiles_sectores 
--where distancia_tile_emplazamiento <=400
--OR orden_distancia_tile_sector =1
--OR porcentaje_tile>=25
),

datos_ubicaciones_completo as ( 

Select
REGEXP_EXTRACT(id_ubicacion, r'^(.*?)_\d+') AS GRUPO_UBICACION ,
 *,
 ST_GEOGPOINT(longitud_direccion,latitud_direccion) AS coordenadas_ubicacion
 from 


 `mm-new-business-reporting.ADVERTISING.COORDENADAS_EMPLAZAMIENTOS_INTERES_REPORTING`


),


datos_tiles_sectores_ubicaciones_ok as (

select *,st_distance(coordenadas_tile,coordenadas_ubicacion) as distancia_tile_ubicacion from 
datos_completos_tiles_sectores_filtrados inner join 
(SELECT * FROM datos_ubicaciones_completo WHERE EXISTS (
              SELECT 1 
              FROM UNNEST(LISTA_UBICACIONES) AS p
              WHERE GRUPO_UBICACION LIKE CONCAT('%', p, '%')) 
)AS datos_ubicaciones_completo
on st_distance(coordenadas_tile,coordenadas_ubicacion) <=RADIO_UBICACION ),

--SELECT * FROM datos_tiles_sectores_ubicaciones_ok WHERE ID_UBICACION='TIENDAS_LIDL_100'

--SELECT GEOMETRY FROM ((select   * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.master_tiles_*`  WHERE _TABLE_SUFFIX=FECHA_TILES_STR) )
--WHERE TILE_ID IN (SELECT TILE_ID  FROM datos_tiles_sectores_ubicaciones_ok)

-------------------------------------------------------
--- 10. Para cada grupo ubicaciones filtramos que un sector 
--- sólo puede afectar a una ubicacion concreta dentro del grupo
--- nos quedamos con ela ubicación que tienen más eventos del sector
-------------------------------------------------------

datos_tiles_sectores_ordenadas_grupo_ubicacion as (


select * , dense_rank() over (partition by sector_completo,GRUPO_UBICACION order by eventos_sector_ubicacion desc,id_ubicacion) as orden_sector_ubicacion

from (
  select *, SUM(eventos) over (partition by sector_completo,id_ubicacion ) as eventos_sector_ubicacion

  from datos_tiles_sectores_ubicaciones_ok 
  )
--where sector_completo='EXT0320-1'
--where id_ubicacion='ABANCA_100_Bande'

order by sector_completo,GRUPO_UBICACION,orden_sector_ubicacion ),

porcentajes_sector_ubicacion as (

select id_ubicacion,SECTOR_COMPLETO,sum(porcentaje_sector) as porcentaje_sectores_ubicacion from datos_tiles_sectores_ordenadas_grupo_ubicacion
where orden_sector_ubicacion=1
and (porcentaje_tile>=0.15 or distancia_tile_emplazamiento<=400 or orden_distancia_tile_sector =1)
group by all
),

--SELECT * FROM porcentajes_sector_ubicacion


-------------------------------------------------------
--- 11.Generamos una tbala final en el que para ubicacion dentro de un grupo
--- obtenemos todos los sectoes que le afectan y toos los cgis de esos sectores
-------------------------------------------------------

datos_cgis_sectores_ubicaciones_final as (
select A.*, cgi from 

(select

 PARSE_DATE('%Y%m%d', fecha_tiles_STR) as fecha_tiles, PARSE_DATE('%Y%m%d', fecha_master_topology_STR) as fecha_master_topology,grupo_ubicacion,id_ubicacion ,direccion, longitud_direccion,latitud_direccion,
emplazamiento,sector_completo,longitude,latitude

from datos_tiles_sectores_ordenadas_grupo_ubicacion
where orden_sector_ubicacion=1
and (porcentaje_tile>=0.15 or distancia_tile_emplazamiento<=400 or orden_distancia_tile_sector =1)
--AND EMPLAZAMIENTO='GAL8303'
group by all) A

inner join datos_completos_cgi_sector B

on A.sector_completo=B.sector_completo

),


DATOS_TPT_INI AS (
  SELECT
      grupo_ubicacion,id_ubicacion,msisdn,
    --  TPT.emplazamiento,
      SECTOR_COMPLETO,
      aggregation_date AS fecha_hora,
   --   EXTRACT(HOUR FROM aggregation_date) as hora,
      COUNT(DISTINCT aggregation_date) AS HORAS_DISTINTAS,
      SUM(CASE
         WHEN EXTRACT(HOUR FROM aggregation_date) IN UNNEST(LISTA_HORAS_OK) 
         --WHEN EXTRACT(HOUR FROM aggregation_date) BETWEEN HORA_INICIO_OK AND HORA_FIN_OK
          THEN tiempototal ELSE 0 END) AS tiempo_ok,
      SUM(CASE
         WHEN EXTRACT(HOUR FROM aggregation_date) NOT IN UNNEST(LISTA_HORAS_OK)
         -- WHEN NOT(EXTRACT(HOUR FROM aggregation_date) BETWEEN HORA_INICIO_OK AND HORA_FIN_OK)         
          THEN tiempototal ELSE 0 END) AS tiempo_no_ok,
      'NORMAL' AS HORARIO
  FROM (select *  FROM `mm-cdr-prod.00_SANDBOX_CEM_OSP.timepertechnology_hour`
        WHERE DATE(aggregation_date) BETWEEN FECHA_INICIO_RANGO AND FECHA_FIN_RANGO
          AND emplazamiento in  (SELECT DISTINCT emplazamiento FROM datos_cgis_sectores_ubicaciones_final) ) TPT

  inner join    datos_cgis_sectores_ubicaciones_final  DATA_UBIC  

  ON TPT.CGI=DATA_UBIC.CGI
  GROUP BY ALL
),

DATOS_TPT_SECTOR as (
      select
      A.grupo_ubicacion,A.id_ubicacion,A.msisdn,
      A.SECTOR_COMPLETO,
      A.fecha_hora,
      A.tiempo_ok,
      A.tiempo_no_ok,
      sum(tiempo_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn,A.fecha_hora) as tiempo_total_ok,
      sum(tiempo_no_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn,A.fecha_hora) as tiempo_total_no_ok,
      max(tiempo_no_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn) as tiempo_total_no_ok_ubicacion,
      porcentaje_sectores_ubicacion,
      (1-porcentaje_sectores_ubicacion) as porcentaje_sector_no_visita,

      sum(tiempo_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn,DATE(A.fecha_hora)) as tiempo_total_ok_ubicacion_dia,
      sum(tiempo_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn,DATE(A.fecha_hora),A.SECTOR_COMPLETO) as tiempo_total_ok_ubicacion_dia_sector,
      ---nuevo 20260528
      sum(tiempo_no_ok) over(partition by  A.grupo_ubicacion,A.id_ubicacion,A.msisdn,DATE(A.fecha_hora)) as tiempo_total_no_ok_ubicacion_dia
      --- fin nuevo 20260528

      from DATOS_TPT_INI A inner join porcentajes_sector_ubicacion B

      on a.id_ubicacion=B.id_ubicacion
         AND A.SECTOR_COMPLETO=B.SECTOR_COMPLETO

   --   COUNT(DISTINCT aggregation_date) AS HORAS_DISTINTAS,


),


--select * from DATOS_TPT_SECTOR

DATOS_TPT AS (
 
 SELECT       
 grupo_ubicacion,id_ubicacion,msisdn, DATE(fecha_hora) AS fecha,
 
 count(distinct fecha_hora) as num_horas,
 SUM(tiempo_total_ok) AS tiempo_total_ok_dia, 
 SUM(tiempo_total_no_ok) AS tiempo_total_no_ok_dia, 
 MIN(EXTRACT(HOUR FROM fecha_hora)) AS hora_minima,
 MAX(EXTRACT(HOUR FROM fecha_hora)) AS hora_maxima,
      -- Diferencia simple en horas
 MAX(EXTRACT(HOUR FROM fecha_hora)) - MIN(EXTRACT(HOUR FROM fecha_hora)) AS dif_horas,
 
 
 --tiempo_total_no_ok_ubicacion,
 tiempo_total_no_ok_ubicacion_dia,
 SUM(porcentaje_sectores_ubicacion * tiempo_ok/tiempo_total_ok) AS PROBABILIDAD_PONDERADA,
 SUM(porcentaje_sectores_ubicacion * tiempo_total_ok_ubicacion_dia_sector/tiempo_total_ok_ubicacion_dia) AS PROBABILIDAD_PONDERADA_TOTAL_SECTOR,
SUM(porcentaje_sectores_ubicacion) AS PROBABILIDAD_TOTAL,
1-exp(sum(LN(porcentaje_sector_no_visita+0.00001))) AS PROBABILIDAD_VISITA_OK
 
 FROM DATOS_TPT_SECTOR
 
 ---nuevo 20260528
 -- PREVIO where tiempo_total_no_ok_ubicacion=0 and tiempo_TOTAL_ok>0 AND tiempo_total_ok_ubicacion_dia>0
 where tiempo_total_no_ok_ubicacion_dia>=0 and tiempo_TOTAL_ok>0 AND tiempo_total_ok_ubicacion_dia>0
 -- FIN nuevo 20260528
 

 GROUP BY ALL
 HAVING  tiempo_TOTAL_ok_dia BETWEEN (60*MINUTOS_MIN) AND (60*MINUTOS_MAX)
)

--select * from DATOS_TPT



SELECT *,
count (distinct fecha) over (partition by id_ubicacion,msisdn) as dias_msisdn_ubicacion, 
count (distinct fecha) over (partition by id_ubicacion,msisdn,PERIODO) as dias_msisdn_ubicacion_PERIODO,
CURRENT_TIMESTAMP()
FROM


(SELECT NOMBRE_POC AS POC,A.*, 
EXTRACT(DAYOFWEEK FROM fecha) AS DIA_SEMANA,
CASE WHEN FECHA<FECHA_INICIO_OK THEN 'PREVIO'
                                      WHEN FECHA>FECHA_FIN_OK THEN 'POSTERIOR'
                                      ELSE 'CAMPAIGN' END AS PERIODO,
b.*

FROM DATOS_TPT A

inner JOIN (

select brand_ds,segment_ds,customer_id,PHONE_NM,
--RANGO_EDAD_NORMALIZADO,GENERO_NORMALIZADO, NIVEL_RENTA, Per_tipoFamilia,Per_nivelSocioeconomico,
FROM 
 `mm-new-business-reporting.ADVERTISING.TABLA_PERFILADOS`

 --WHERE RANGO_EDAD_NORMALIZADO!='NO DEFINIDO'
 --ANd GENERO_NORMALIZADO !='DESCONOCIDO'
 --AND NIVEL_RENTA IS NOT NULL
 --AND Per_tipoFamilia!='DESCONOCIDO'
 

) B

ON REGEXP_REPLACE(A.MSISDN,'^34', '')= B.PHONE_NM
);

END;