
with
datos_mupis as (
SELECT * EXCEPT (LATITUD_DIRECCION,LONGITUD_DIRECCION),LATITUD_DIRECCION AS LATITUD_MUPI,LONGITUD_DIRECCION AS LONGITUD_MUPI  FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_MAESTRO_MUPIS_DIGITAL_TOTAL_20260626`

WHERE  latitud_direccion  between -90 and 90 AND latitud_direccion is NOT null 
),
datos_ubicaciones as (

SELECT * 
FROM `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.COORDENADAS_UBICACIONES_COMPLETAS_ADHOC` where id_ubicacion like '%LUJO%'
),
 distancias as (
            select *,
            ST_Distance(
                    ST_GeogPoint(longitud_DIRECCION, latitud_direccion),
                    ST_GeogPoint(LONGITUD_MUPI , latitud_MUPI)
            ) as distancia
                 from datos_ubicaciones cross join datos_mupis),

distancias_con_orden as (select *, ROW_NUMBER() OVER (PARTITION BY ID_UBICACION ORDER BY distancia) AS orden from distancias),

DATOS_EMPLAZAMIENTO_DISTANCIA_OK as (
select * from distancias_con_orden where distancia<400 or orden=1 
)

SELECT * FROM DATOS_EMPLAZAMIENTO_DISTANCIA_OK