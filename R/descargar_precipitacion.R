# =============================================================================
# Curso Inteligencia Sanitaria — descargar_precipitacion.R
# Descarga la precipitación diaria del reanálisis ERA5 (vía Open-Meteo) para
# cuatro ciudades de Piura y la agrega por semana epidemiológica.
#
# Fuente: Open-Meteo Historical Weather API (https://open-meteo.com/),
# datos ERA5 (Hersbach et al., 2020). Licencia CC BY 4.0.
# Salida: datos/procesados/precipitacion_piura_semanal.csv
#
# Limitación: es el promedio de cuatro puntos de una rejilla de ~25 km
# (Piura, Sullana, Chulucanas, Paita), no una medición de estación ni un
# promedio de todo el departamento.
# =============================================================================

library(jsonlite)
library(dplyr)
library(lubridate)
library(readr)

puntos <- data.frame(
  ciudad   = c("Piura", "Sullana", "Chulucanas", "Paita"),
  latitud  = c(-5.19, -4.90, -5.09, -5.09),
  longitud = c(-80.63, -80.69, -80.16, -81.11)
)

url <- paste0(
  "https://archive-api.open-meteo.com/v1/archive?",
  "latitude=", paste(puntos$latitud, collapse = ","),
  "&longitude=", paste(puntos$longitud, collapse = ","),
  "&start_date=2010-01-01&end_date=2025-12-31",
  "&daily=precipitation_sum&timezone=America%2FLima"
)

respuesta <- fromJSON(url, simplifyVector = FALSE)

diario <- bind_rows(lapply(seq_along(respuesta), function(i) {
  data.frame(
    ciudad = puntos$ciudad[i],
    fecha = as.Date(unlist(respuesta[[i]]$daily$time)),
    precip_mm = as.numeric(sapply(respuesta[[i]]$daily$precipitation_sum,
                                  function(x) if (is.null(x)) NA else x))
  )
}))

# Promedio de los cuatro puntos y suma por semana epidemiológica
semanal <- diario |>
  group_by(fecha) |>
  summarise(precip_mm = mean(precip_mm, na.rm = TRUE), .groups = "drop") |>
  mutate(ano = epiyear(fecha), semana = epiweek(fecha)) |>
  filter(ano %in% 2010:2025) |>
  group_by(ano, semana) |>
  summarise(precip_mm = round(sum(precip_mm), 1), dias = n(), .groups = "drop")

write_csv(semanal, file.path("datos", "procesados", "precipitacion_piura_semanal.csv"))
