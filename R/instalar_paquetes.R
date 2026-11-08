# =============================================================================
# Curso Inteligencia Sanitaria — instalar_paquetes.R
# Instala solo los paquetes que falten. Ejecutar una vez antes de la S1.
# =============================================================================

paquetes <- c(
  "tidyverse",   # manejo de datos y gráficos (dplyr, ggplot2, readr, ...)
  "lubridate",   # fechas y semanas epidemiológicas
  "janitor",     # limpieza de nombres y tablas de frecuencia
  "sf",          # datos espaciales (S4)
  "surveillance",# detección de brotes (S3)
  "MASS",        # regresión binomial negativa (S5)
  "knitr",       # renderizado de Quarto
  "rmarkdown"
)

faltan <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltan) > 0) {
  message("Instalando: ", paste(faltan, collapse = ", "))
  install.packages(faltan)
} else {
  message("Todos los paquetes ya estaban instalados.")
}

ok <- vapply(paquetes, requireNamespace, logical(1), quietly = TRUE)
if (all(ok)) {
  message("Entorno listo.")
} else {
  warning("No se pudieron cargar: ", paste(paquetes[!ok], collapse = ", "))
}
