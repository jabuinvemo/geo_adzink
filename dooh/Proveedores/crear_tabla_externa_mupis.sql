-----------------FORMULAs AYUDA EXCEL ------------------------
-- =SUSTITUIR(ESPACIOS(A6); " "; "_")
-- =CONCAT(B6;" STRING,")
--------------------------------------------------------------

CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CLEAR_CHANNEL_20260407`
(
Axion_ID STRING,
Internal_Panel_ID STRING,
Id_Cara_Geomex STRING,
Latitud FLOAT64,
Longitud FLOAT64,
L3_Clasificacipn STRING,
L4_Formato STRING,
L6_Tipo_de_mueble STRING,
Es_digital STRING,
Direccion STRING,
Codigo_Postal STRING,
Ciudad STRING,
Provincia STRING,
Impresiones INT64,
Google_Street_View STRING,
Disponible_PDOOH STRING,
BSR_ID STRING


)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1tmHfNV8VLT7dl2W2mTNwsK6FAiTQH-0rR-UrhPnKjfA/edit?usp=drive_link'],
  skip_leading_rows = 1
);

---------------------------------------------------------------------------------------------


CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CLEAR_CHANNEL_20260220`
(
Axion_ID STRING,
Internal_Panel_ID STRING,
Id_Cara_Geomex STRING,
Latitud FLOAT64,
Longitud FLOAT64,
L3_Clasificacipn STRING,
L4_Formato STRING,
L6_Tipo_de_mueble STRING,
Es_digital STRING,
Direccion STRING,
Codigo_Postal STRING,
Ciudad STRING,
Provincia STRING,
Google_Street_View STRING,

)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1WPMiac4bcStHXISxHeLQZAr4faYm3yCOGDtnc7ZYEAw/edit?usp=drive_link'],
  skip_leading_rows = 1
);


----------------------


CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_GLOBAL_20260313`
(
adserver STRING,
publisher_name STRING,
venue_id STRING,
venue_name STRING,
player_id STRING,
player_name STRING,
visual_unit_id STRING,
visual_unit_name STRING,
screen_id STRING,
screen_name STRING,
screen_units STRING,
sell_aggregation_level STRING,
report_aggregation_level STRING,
venue_type STRING,
address STRING,
country STRING,
city STRING,
region STRING,
postcode STRING,
postcode_income STRING,
latitude FLOAT64,
longitude FLOAT64,
accepted_media_types STRING,
accepted_banner_formats STRING,
accepted_video_formats STRING,
max_ad_duration STRING,
min_ad_duration STRING,
frequency STRING,
screen_dimensions_width FLOAT64,
screen_dimensions_height FLOAT64,
max_image_size FLOAT64,
min_image_size FLOAT64,
max_video_size FLOAT64,
min_video_size FLOAT64,
screen_orientation STRING,
audience_data_source STRING,
audience_data_source_name STRING,
average_weekly_impressions FLOAT64,
average_weekly_impressions_pDOOH FLOAT64,
average_audience_multiplier FLOAT64,
alcohol_restriction_by_volume STRING,
tobacco_restriction STRING,
gambling_restriction STRING,
fireworks_restriction STRING,
fastfood_restriction STRING,
is_adult STRING,
is_male STRING,
is_female STRING,
is_rch STRING,
is_young STRING,
is_family STRING,
is_premium STRING,
CPM FLOAT64,
cpm_currency STRING,
purchase_type STRING,
Id_Hivestack STRING

)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/18vdG5pDnXAmKAKtnrb5H7anSwwc3h9mvS8H7TSupWtQ/edit?usp=drive_link'],
  skip_leading_rows = 1
);

---------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_JCDCAUX_20260324`
(
Frame_ID	STRING,
Visual_Unit	STRING,
Visual_Unit_ID	STRING,
media_owner	STRING,
screen_name	STRING,
environment	STRING,
venue_type	STRING,
network	STRING,
outdoor_indoor	STRING,
country	STRING,
city	STRING,
address	STRING,
post_code	STRING,
Latitude	FLOAT64,
Longitude	FLOAT64,
format	STRING,
width	INTEGER,
height	INTEGER,
aspect_ratio	FLOAT64,
ad_length	STRING,
video_accepted	STRING,
html_zip_accepted	STRING,
fps	STRING,
monthly_impressions	FLOAT64,
frame_CPM	FLOAT64,
status	STRING
)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1JiJsJSKVsKIIHxv0QrT9d5L3X3DelfUXw02IT4vPNZY/edit?usp=drive_link'],
  skip_leading_rows = 1
);

----------------------------------------------------------------------

CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_EXTERIOR_PLUS_20260519`
(
Screen_ID_BS	STRING,
venue_type	STRING,
site_name	STRING,
site_ID	STRING,
screen_name	STRING,
Num_Pantallas	int64,
width	int64,
height	int64,
Resolution	STRING,
Municipio	STRING,
Provincia	STRING,
Comunidad_autonoma STRING,	
latitude	Float64,
longitude	float64,
CP string
)

OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/14YyC51S1LTe4fDamGSXDOUYOIPXwFxHdHnuwW312vRY/edit?usp=drive_link'],
  skip_leading_rows = 1
);

-------------------------------------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_CLECEOOH_20260519`

(venue_id STRING,
name STRING,
venue_type	STRING,
address	STRING,
latitude	FLOAT64,
longitude	FLOAT64,
cpm_floor_cents	FLOAT64,
impressions_per_spot	INT64,
width_px	INT64,
height_px	INT64,
static_duration_seconds INT64,
static_supported	STRING,
video_supported		STRING,
html_supported	 	STRING,
weekly_impressions INT64,
CP String,
PROVINCIA STRING

)


OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1DpxYNxKadUc6Fnx4H_E-vzqwe2cSiApe0bhjqfY0a6w/edit?usp=drive_link'],
  skip_leading_rows = 1
);
----------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_TUMEDIO_20260622`
(
ES_DIGITAL  STRING,
tIPO_UBICACION STRING,
LATITUD	 FLOAT64,
LONGITUD	 FLOAT64,
DIRECCION	 STRING,
CIUDAD	 STRING,
CODIGO_POSTAL	 STRING,
DISPONIBLE_PROGRAMATICA  STRING,
RESOLUCION	 STRING,
SCREEN_NAME STRING

)
OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1PEu2WWK_Ipc0JgXhNpUkMh-fBenljMnaEn-o8iv20DQ/edit?usp=drive_link'],
  skip_leading_rows = 1
);
----------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE EXTERNAL TABLE `mo-advertising-sta.ADVERTISING_ANALISIS_ADHOC.DOOH_IWALL_20260625`

(

id_interno_IWALL  STRING,
display_unit_id	  STRING,
hivestack_id  STRING,
ES_DIGITAL  STRING,
TIPO_UBICACION  STRING,
latitud  FLOAT64,
longitud FLOAT64,
direccion  STRING,
DISPONIBLE_PROGRAMATICA  STRING,
buyer_facing_name  STRING,
venue_type_id	  STRING,
allowed_ad_types  STRING,
motion_allowed  STRING,
min_ad_duration_ms  STRING,
max_ad_duration_ms  STRING,
open_exchange_enabled  STRING,
audience_sources  STRING,
screen_image_urls  STRING,
Centro_comercial  STRING,
Numero_de_pantallas_asociadas  INT64,
codigo_postal  STRING,
ciudad  STRING
)

OPTIONS (
  format = 'GOOGLE_SHEETS',
  uris = ['https://docs.google.com/spreadsheets/d/1CvCWDwiCSSxtFXjF-mzoVTQ7oetP5zbtU9HbOzkCNmg/edit?usp=drive_link'],
  skip_leading_rows = 1
);