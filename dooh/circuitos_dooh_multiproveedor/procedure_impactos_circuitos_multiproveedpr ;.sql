CREATE OR REPLACE PROCEDURE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.estimacion_impactos_circuitos_dooh_campaign`(
  IN CAMPAIGN_STR STRING,
  iN FLAG_METRO BOOL

)
BEGIN

declare FECHA_TILES_STR STRING;
declare FECHA_MASTER_TOPOLOGY_STR STRING;
DECLARE LISTA_UBICACIONES  ARRAY<STRING> DEFAULT ['%'];
--DECLARE CAMPAIGN_STR STRING;
DECLARE OLA_STR STRING;
DECLARE FECHA_INICIO_OLA DATETIME;
DECLARE FECHA_FIN_OLA DATETIME;
DECLARE HORA_INICIO_OLA INT64;
DECLARE HORA_FIN_OLA INT64;
--DECLARE FLAG_METRO BOOL DEFAULT FALSE ;


DECLARE PROVEEDORES ARRAY<STRING>;
DECLARE OLAS_CAMPAIGN ARRAY<STRING>;


--SET CAMPAIGN_STR='FANTA_WANTA';
SET PROVEEDORES=['JCDCAUX','CLEAR_CHANNEL'];
--SET OLAS_CAMPAIGN=['OLA_1_1','OLA_1_2','OLA_1_3','OLA_2_1','OLA_2_2','OLA_2_3'];

SET OLAS_CAMPAIGN=[
'LUNES_VIERNES_19_20',
'SABADO_DOMINGO_13_20',
'VIERNES_19_20'
];


SET FECHA_TILES_STR = (SELECT MAX(_TABLE_SUFFIX) FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.master_tiles_*`);

SET FECHA_MASTER_TOPOLOGY_STR = (select max(_table_suffix) from `mm-cdr-prod.00_SANDBOX_CEM_OSP.martes_topology_history_*` );

--SET FLAG_METRO=FALSE;


create temp table horarios_campaigns as 

WITH 
DATOS_OLAS_CAMPAIGNS AS (
SELECT A.*,CAST(DIAS_SEMANA_CAMPAIGN AS INT64) AS DIAS_SEMANA_CAMPAIGN,
CAST(HORAS_CAMPAIGN AS INT64) AS HORA_CAMPAIGN

 FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_HORARIOS_CIRCUITOS_CAMPAINGS` A ,
unnest(split(DIAS_SEMANA,',')) AS DIAS_SEMANA_CAMPAIGN,unnest(split(HORAS,',')) AS HORAS_CAMPAIGN

WHERE /*PROVEEDOR IN UNNEST(PROVEEDORES) AND OLA_CAMPAIGN IN UNNEST(OLAS_CAMPAIGN) and */CAMPAIGN=CAMPAIGN_STR)


SELECT * FROM DATOS_OLAS_CAMPAIGNS A INNER JOIN (
SELECT 
  fecha,
  EXTRACT(DAYOFWEEK FROM fecha) AS dia_semana_num,

FROM UNNEST(GENERATE_DATE_ARRAY(
                                (select min(fecha_inicio) from DATOS_OLAS_CAMPAIGNS), 
                                (select max(fecha_fin) from DATOS_OLAS_CAMPAIGNS), INTERVAL 1 DAY)) AS fecha
) b

ON B.FECHA BETWEEN A.FECHA_INICIO AND A.FECHA_FIN 
  AND A.DIAS_SEMANA_CAMPAIGN=B.dia_semana_num;



set FECHA_INICIO_OLA = ( SELECT CAST(MIN(FECHA_INICIO) AS DATETIME) FROM horarios_campaigns );
set FECHA_FIN_OLA = ( SELECT  DATETIME(MAX(FECHA_FIN), '23:59:59') FROM horarios_campaigns);

SET HORA_INICIO_OLA = (SELECT MIN(HORA_CAMPAIGN ) FROM horarios_campaigns);
SET HORA_FIN_OLA = (SELECT MAX(HORA_CAMPAIGN) FROM horarios_campaigns);

---------------- BORRADO DATOS PREVIOS

DELETE FROM  `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_DOOH_MSISDN_CIRCUITOS_OLAS`
WHERE CAMPAIGN=CAMPAIGN_STR AND FECHA BETWEEN DATE(FECHA_INICIO_OLA) AND DATE(FECHA_FIN_OLA);


------------------ INSERTAMOS VALORES

INSERT INTO `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DETALLE_DOOH_MSISDN_CIRCUITOS_OLAS`

WITH

mupis_circuitos as (


SELECT A.*,B.FRAME_ID FROM horarios_campaigns A INNER JOIN 

`mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CIRCUITOS_CAMPAINGS` B

ON A.CAMPAIGN=B.CAMPAIGN
AND A.OLA_CIRCUITO=B.OLA_CIRCUITO
AND A.PROVEEDOR=B.proveedor
),




DATOS_MUPIS_TOTAL  AS ( 
  
  select * from `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_MAESTRO_MUPIS_DIGITAL_TOTAL_20260623` 

  where  
  
  (
    (NOT FLAG_METRO AND upper(tipo_ubicacion) NOT like '%SUBWAY%' )

    OR
  
    (FLAG_METRO AND upper(tipo_ubicacion) like '%SUBWAY%')
  )

  AND latitud_direccion  between -90 and 90 AND latitud_direccion is NOT null
),



DATOS_MUPI_DIGITAL AS (

SELECT * EXCEPT(CIUDAD),  CONCAT(CAST(latitud_direccion AS STRING), ", ", CAST(longitud_direccion AS STRING)) as coordenadas_looker_mupi,

TRANSLATE(
    CIUDAD, 
    'áéíóúÁÉÍÓÚäëïöüÄËÏÖÜ', -- Caracteres que quieres buscar
    'aeiouAEIOUaeiouAEIOU'  -- Caracteres por los que los quieres sustituir
  ) AS CIUDAD,
ST_GEOGPOINT(longitud_direccion, latitud_direccion) as coordenadas_mupi  FROM DATOS_MUPIS_TOTAL

where Disponible_PDOOH='SI' AND  latitud_direccion <1000

),


datos_ubicaciones_completo as (

SELECT PROVEEDOR AS GRUPO_UBICACION, * , FRAME_ID AS ID_UBICACION,

 ST_GEOGPOINT(longitud_direccion,latitud_direccion) AS coordenadas_ubicacion
 FROM DATOS_MUPI_DIGITAL
),



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
  where  
  
  (NOT FLAG_METRO AND emplazamiento  not in (
                          'MAD6109','MAD6206','MAD6355','MAD6378','MAD6353','MAD6354','MAD6356','MAD6377','MAD6338',
                          'MAD6308','MAD6341','MAD6335','MAD6368','MAD6336','MAD6337','MAD6348','MAD6315','MAD6364',
                          'MAD6366','MAD6379','MAD6307','MAD6362','MAD6340','MAD6374','MAD6357','MAD6367','MAD6334',
                          'MAD6375','MAD6365','MAD6328','MAD6339','MAD6329','MAD6326',
                          'CAT5830','CAT5841','CAT6124','CAT6131','CAT6141','CAT5893','CAT5811','CAT6136','CAT6139',
                          'CAT5834','CAT5838','CAT6134','CAT6135','CAT6137','CAT6155','CAT6132','CAT6113','CAT6133',
                          'CAT6144','CAT5812','CAT5814','CAT5815','CAT5816','CAT5912','CAT5914','CAT5915','CAT5916',
                          'CAT5892',
                          'PVA0722','PVA1800','PVA1801','PVA1804','PVA1806','PVA1809','PVA1812','PVA1813','PVA1814',
                          'PVA1818','PVA1821','PVA1825','PVA1826','PVA1827'
                          )
  )
  OR 

  
  (FLAG_METRO AND emplazamiento  in (
                          'MAD6109','MAD6206','MAD6355','MAD6378','MAD6353','MAD6354','MAD6356','MAD6377','MAD6338',
                          'MAD6308','MAD6341','MAD6335','MAD6368','MAD6336','MAD6337','MAD6348','MAD6315','MAD6364',
                          'MAD6366','MAD6379','MAD6307','MAD6362','MAD6340','MAD6374','MAD6357','MAD6367','MAD6334',
                          'MAD6375','MAD6365','MAD6328','MAD6339','MAD6329','MAD6326',
                          'CAT5830','CAT5841','CAT6124','CAT6131','CAT6141','CAT5893','CAT5811','CAT6136','CAT6139',
                          'CAT5834','CAT5838','CAT6134','CAT6135','CAT6137','CAT6155','CAT6132','CAT6113','CAT6133',
                          'CAT6144','CAT5812','CAT5814','CAT5815','CAT5816','CAT5912','CAT5914','CAT5915','CAT5916',
                          'CAT5892',
                          'PVA0722','PVA1800','PVA1801','PVA1804','PVA1806','PVA1809','PVA1812','PVA1813','PVA1814',
                          'PVA1818','PVA1821','PVA1825','PVA1826','PVA1827'
                          )  
)



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
--fecha_master,
sum(count_tile) as eventos

from datos_tiles_emplazamientos
group by all
)
,

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


datos_completos_tiles_sectores_filtrados as (

select * from datos_completos_tiles_sectores 
--where distancia_tile_emplazamiento <=400
--OR orden_distancia_tile_sector =1
--OR porcentaje_tile>=25
),


-------------------------------------------------------
--- 10. PAra cada mupi, nos quedamos todos los tiels a menos de 50 metros
--- que es la distancia de visualiacion
-------------------------------------------------------
datos_tiles_sectores_ubicaciones_ok as (

select *,st_distance(coordenadas_tile,coordenadas_ubicacion) as distancia_tile_ubicacion from 
datos_completos_tiles_sectores_filtrados inner join 
datos_ubicaciones_completo
on st_distance(coordenadas_tile,coordenadas_ubicacion) <50 ),



-------------------------------------------------------
--- 11.  calculamos cada sector a que mupio de cad aproveedor afecta mas 
--- pero no nos quedamos sólo ocn uno, como en las ubicaciones "normales"
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

-------------------------------------------------------
--- 12. Nos quedamos para cada mupio la los tiles que le afectan y la probailidad de ese tiel
--- para cada sector
-------------------------------------------------------


maestro_mupis_sectores_probabilidad as (
select proveedor,frame_id, Tipo_ubicacion, Direccion, latitud_direccion,longitud_direccion,ciudad,codigo_postal,
tile_id,emplazamiento,sector_completo,longitude,latitude, sum(porcentaje_sector) as probabilidad_mupi_tile_sector

 from datos_tiles_sectores_ordenadas_grupo_ubicacion
 group by all),


-------------------------------------------------------
--- 12. Nos quedamos con los datos de probabilida de los 
--- mupis de los circuios de la campaña que apliquen
-------------------------------------------------------

mupis_circuito_INI AS ( select CAMPAIGN,OLA_CIRCUITO,PROVEEDOR,FRAME_ID FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CIRCUITOS_CAMPAIGNS` 
                     WHERE CAMPAIGN=CAMPAIGN_STR AND OLA_CIRCUITO LIKE OLA_STR),


datos_mupis_tiles_sectores_circuito as (SELECT B.CAMPAIGN,B.OLA_CIRCUITO,B.OLA_CAMPAIGN,
                                               --B.FECHA_INICIO,B.FECHA_FIN,B.HORA_INICIO,B.HORA_FIN,
                                               b.fecha,b.hora_campaign,
                                               A.*  
                                               FROM maestro_mupis_sectores_probabilidad A INNER JOIN mupis_circuitos B
                                               ON A.FRAME_ID=B.FRAME_ID),



-------------------------------------------------------
--- 13. Nos quedamos para cada sector nos quedamos con la probabilidad total
--- de impactar al algun mupi, quitando solpes entre mupis 
--- y  considerando solo los tiles unicos dentor de cada sector
-------------------------------------------------------


probabilidad_impacto_sector as (select fecha,hora_campaign,emplazamiento, sector_completo, sum(probabilidad_mupi_tile_sector) as probabilidad_impacto_sector from 
                                       (select distinct fecha,hora_campaign,emplazamiento,sector_completo,tile_id,probabilidad_mupi_tile_sector 
                                       from datos_mupis_tiles_sectores_circuito) group by all ),


-------------------------------------------------------
--- 13. Nos quedamos para cada mupi del ciurcuito con su probabilidad total para cada sector
--- sumado todos sus tuiles en ese sector
-------------------------------------------------------

datos_mupis_sectores as (
select CAMPAIGN,OLA_CIRCUITO,OLA_CAMPAIGN,PROVEEDOR,
       fecha,hora_campaign,
       FRAME_ID,EMPLAZAMIENTO,SECTOR_COMPLETO, SUM(probabilidad_mupi_tile_sector) AS PROBABILIDAD_MUPI_SECTOR
FROM datos_mupis_tiles_sectores_circuito GROUP BY ALL),



-------------------------------------------------------
--- 19. Repartimos la probabilida de ver algun mupi en el sector por el peso de cada mupi 
--- en el secteo (probabilidad del mupi en el sector /total se probabilidades de tods los mupi de lsector)

-------------------------------------------------------

datos_final_probabilidad_ponderada_mupi_sector as (


  SELECT * , probabilidad_impacto_sector*PORCENTAJE_REPARTO_IMPACTO_MUPI_SECTOR AS PROBABILIDAD_IMPACTO_MUPI_SECTOR
  FROM (
  SELECT *, SUM(PROBABILIDAD_MUPI_SECTOR) OVER (PARTITION BY SECTOR_COMPLETO,fecha,hora_campaign) AS SUMA_PROBABILIDAD_MUPIS_SECTOR  ,

  PROBABILIDAD_MUPI_SECTOR/SUM(PROBABILIDAD_MUPI_SECTOR) OVER (PARTITION BY SECTOR_COMPLETO,fecha,hora_campaign) AS PORCENTAJE_REPARTO_IMPACTO_MUPI_SECTOR
        FROM (
          SELECT A.*,B.probabilidad_impacto_sector
          FROM datos_mupis_sectores A INNER JOIN probabilidad_impacto_sector b 
          ON A.SECTOR_COMPLETO=B.SECTOR_COMPLETO AND A.fecha=B.fecha and A.hora_campaign=B.hora_campaign
        )
  )
),

--select * from datos_final_probabilidad_ponderada_mupi_sector



DATOS_TPT AS (select        
        --aggregation_date, 
        msisdn,
        sector_completo ,
        DATE(aggregation_date) AS fecha,
        EXTRACT(HOUR FROM aggregation_date) as hora,
        EXTRACT(DAYOFWEEK FROM  DATE(aggregation_date)) AS dia_semana_num
        from 
        
              (select * from `mm-cdr-prod.00_SANDBOX_CEM_OSP.timepertechnology_hour` WHERE 
              aggregation_date >= FECHA_INICIO_OLA  AND aggregation_date <=  FECHA_FIN_OLA
              and emplazamiento in (select distinct coalesce(emplazamiento,'nulo')  from datos_final_probabilidad_ponderada_mupi_sector)
              --AND EXTRACT(HOUR FROM aggregation_date) BETWEEN (SELECT MIN(HORA_INICIO) FROM horarios_campaigns) AND (SELECT MAX(HORA_INICIO) FROM horarios_campaigns) 
              ) TPT
        inner join datos_completos_cgi_sector CGI_SECTOR

        on TPT.cgi=CGI_SECTOR.CGI
        where EXTRACT(HOUR FROM aggregation_date) >=HORA_INICIO_OLA and EXTRACT(HOUR FROM aggregation_date) <=HORA_FIN_OLA
        group by 1,2,3,4,5
        having sum(tiempototal) >300 --BETWEEN 60*5 AND 60*60
        )


 select CAMPAIGN, OLA_CIRCUITO, OLA_CAMPAIGN,
 --A.SECTOR_COMPLETO,
 PROVEEDOR,FRAME_ID, MSISDN, 
 --COUNT(DISTINCT FECHA) as DIAS_DISTINTOS,
 A.FECHA,
 --HORA
 --sum(PROBABILIDAD_IMPACTO_MUPI_SECTOR) as PROBABILIDAD_IMPACTO_MUPI_SECTOR,
 count(distinct HORA) as HORAS_DISTINTAS,
 Sum(PROBABILIDAD_IMPACTO_MUPI_SECTOR) AS PROBABILIDAD_MSISDN_MUPI_TOTAL 

 
 from DATOS_TPT A inner  join datos_final_probabilidad_ponderada_mupi_sector B

 on A.SECTOR_COMPLETO=B.SECTOR_COMPLETO
 AND A.FECHA=B.FECHA 
 AND A.HORA=B.HORA_CAMPAIGN
 
-- WHERE HORA >=HORA_INICIO AND HORA<=HORA_FIN
--       AND FECHA>=FECHA_INICIO  AND FECHA<=FECHA_FIN
----  where msisdn='34653568810'
 GROUP BY ALL;


END