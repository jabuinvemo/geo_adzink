
CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.COORDENADAS_UBICACIONES_COMPLETAS_ADHOC`
(
id_ubicacion		STRING,	
direccion		STRING,	
longitud_direccion		FLOAT64,
latitud_direccion		FLOAT64,	
DIRECCION_OK		STRING,	
CP		STRING,	
MUNICIPIO		STRING,	
PROVINCIA		STRING	

)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1dIzXg3fDgsrgv9MmwHAmyRf2YA_Ntj4BnegPx8vvCa0/edit?usp=drive_link'],
  skip_leading_rows = 1
);