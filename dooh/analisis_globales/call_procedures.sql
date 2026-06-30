 
 CALL `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.estimacion_impactos_dooh_fecha_hora_multiproveedor`(
 -- CALL `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.estimacion_impactos_dooh_agregado_multiproveedor`(
  'COMPLETO_MULTIPROVEEDOR',
  TRUE,
  DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) ,
  CURRENT_DATE()
 )