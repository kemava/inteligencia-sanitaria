# =============================================================================
# Curso Inteligencia Sanitaria — preparar_ubigeos.R
# Extrae la lista de distritos (ubigeo, departamento, provincia, distrito)
# desde la base NotiSP del curso. Es el marco que usa simular_datos.R.
#
# Limitación: solo incluye distritos con al menos una notificación de
# metaxénicas (1280 de 1891). Puno, Arequipa, Moquegua y Tacna quedan
# incompletos. Para los proyectos de sarampión o tos ferina, reemplazar por
# la lista completa de ubigeos del INEI o construirla desde sus propias bases.
# =============================================================================

library(dplyr)
library(readr)

base <- readRDS(file.path("datos", "crudos", "metaxenicas_total.rds"))

ubigeos <- base |>
  distinct(ubigeo, departamento, provincia, distrito) |>
  arrange(ubigeo)

dir.create(file.path("datos", "referencia"), showWarnings = FALSE,
           recursive = TRUE)
write_csv(ubigeos, file.path("datos", "referencia", "ubigeos.csv"))
