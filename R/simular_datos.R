# =============================================================================
# Curso Inteligencia Sanitaria — DEAEA, FASPA-UPCH (2026)
# Script: simular_datos.R
#
# Propósito: generar bases SIMULADAS que complementan las bases reales de
# vigilancia (NotiSP) del curso, para los insumos que no están disponibles o
# que aún no se han conseguido:
#   1. Población por distrito, año y grupo de edad      (denominadores)
#   2. Clima semanal por distrito                        (dengue, S2/S5)
#   3. Coberturas de vacunación por distrito y año       (tos ferina, sarampión)
#   4. Indicadores de vulnerabilidad y capacidad          (priorización, S4)
#
# TODOS LOS VALORES SON SIMULADOS. No representan cifras oficiales del INEI,
# SENAMHI, MINSA ni de ninguna otra institución. Los patrones (estacionalidad,
# diferencias costa/sierra/selva, caída de coberturas en 2020, anomalías
# cálidas y lluviosas en la costa norte en 2017 y 2023) imitan de forma
# cualitativa lo conocido, sin pretender reproducir mediciones reales.
# Reemplazar por las fuentes oficiales cuando estén disponibles.
#
# Entrada : datos/referencia/ubigeos.csv  (ubigeo, departamento, provincia,
#           distrito). Puede reemplazarse por la lista completa del INEI;
#           el script funciona con cualquier lista de distritos.
# Salida  : datos/simulados/*.csv  y  datos/simulados/diccionario_simulados.csv
#
# Uso     : abrir el proyecto RStudio del curso y ejecutar
#           source("R/simular_datos.R")
# =============================================================================

library(dplyr)
library(tidyr)
library(readr)
library(purrr)

set.seed(20261109)   # semilla fija: los resultados son reproducibles

dir_ref <- file.path("datos", "referencia")
dir_sim <- file.path("datos", "simulados")
dir.create(dir_sim, showWarnings = FALSE, recursive = TRUE)

anos <- 2010:2026

# -----------------------------------------------------------------------------
# 0. Marco de distritos y región natural
# -----------------------------------------------------------------------------
ubigeos <- read_csv(file.path(dir_ref, "ubigeos.csv"),
                    col_types = cols(.default = col_character()))

costa <- c("TUMBES", "PIURA", "LAMBAYEQUE", "LA LIBERTAD", "LIMA", "CALLAO",
           "ICA", "AREQUIPA", "MOQUEGUA", "TACNA")
selva <- c("AMAZONAS", "LORETO", "SAN MARTIN", "UCAYALI", "MADRE DE DIOS")
costa_norte <- c("TUMBES", "PIURA", "LAMBAYEQUE", "LA LIBERTAD")

# Simplificación: la región se asigna por departamento. En la realidad varios
# departamentos tienen distritos de costa, sierra y selva (p. ej., Piura).
distritos <- ubigeos |>
  mutate(
    region = case_when(
      departamento %in% costa ~ "costa",
      departamento %in% selva ~ "selva",
      TRUE                    ~ "sierra"
    ),
    zona_clima = case_when(
      departamento %in% costa_norte          ~ "costa_norte",
      region == "costa"                      ~ "costa_centro_sur",
      region == "selva"                      ~ "selva",
      TRUE                                   ~ "sierra"
    ),
    # Altitud simulada (m s. n. m.)
    altitud_m = round(case_when(
      region == "costa" ~ rgamma(n(), shape = 1.5, rate = 1 / 150),
      region == "selva" ~ runif(n(), 100, 900),
      TRUE              ~ rnorm(n(), 3200, 500)
    )),
    altitud_m = pmax(altitud_m, 5),
    urbano = departamento %in% c("LIMA", "CALLAO") |
      (region == "costa" & runif(n()) < 0.35)
  )

# -----------------------------------------------------------------------------
# 1. Población por distrito, año y grupo de edad
# -----------------------------------------------------------------------------
# Tamaño base (2010) log-normal; distritos urbanos de costa más grandes.
# Crecimiento anual distinto por distrito (−0.5 % a +2.5 %).
# Estructura por edad: la selva es más joven que la costa.
grupos_edad <- c("<1", "1-4", "5-14", "15-59", "60+")

estructura <- tribble(
  ~region,  ~`<1`, ~`1-4`, ~`5-14`, ~`15-59`, ~`60+`,
  "costa",  0.016, 0.064,  0.160,   0.630,    0.130,
  "sierra", 0.019, 0.075,  0.190,   0.586,    0.130,
  "selva",  0.023, 0.090,  0.220,   0.582,    0.085
) |>
  pivot_longer(-region, names_to = "grupo_edad", values_to = "prop")

pob_base <- distritos |>
  transmute(
    ubigeo, region,
    pob_2010 = round(exp(rnorm(n(),
                               mean = if_else(urbano, 10.6, 8.6),
                               sd   = if_else(urbano, 0.8, 0.9)))),
    crec = runif(n(), -0.005, 0.025)
  )

poblacion <- pob_base |>
  crossing(ano = anos) |>
  mutate(pob_total = round(pob_2010 * (1 + crec)^(ano - 2010))) |>
  inner_join(estructura, by = "region", relationship = "many-to-many") |>
  mutate(
    # pequeña variación aleatoria de la estructura por distrito-año
    poblacion = round(pob_total * prop * rnorm(n(), 1, 0.03)),
    poblacion = pmax(poblacion, 1L)
  ) |>
  select(ubigeo, ano, grupo_edad, poblacion) |>
  arrange(ubigeo, ano, factor(grupo_edad, levels = grupos_edad))

# -----------------------------------------------------------------------------
# 2. Clima semanal por distrito (temperatura media y precipitación)
# -----------------------------------------------------------------------------
# Semanas epidemiológicas: 2014, 2020 y 2025 tienen 53 semanas, igual que en
# la base NotiSP del curso.
semanas <- tibble(ano = anos) |>
  mutate(n_sem = if_else(ano %in% c(2014, 2020, 2025), 53L, 52L)) |>
  mutate(semana = map(n_sem, seq_len)) |>
  unnest(semana) |>
  select(-n_sem)

# Parámetros por zona: temperatura media anual al nivel del mar, amplitud
# estacional, precipitación semanal media en el pico de lluvias.
par_clima <- tribble(
  ~zona_clima,         ~t_media, ~t_amp, ~p_pico, ~p_base,
  "costa_norte",       26.0,     3.5,    12,      0.3,
  "costa_centro_sur",  21.5,     3.5,    0.8,     0.1,
  "sierra",            29.0,     2.0,    35,      2,
  "selva",             28.5,     1.0,    70,      35
)
# La temperatura se corrige por altitud (−0.55 °C cada 100 m).

# Anomalías (estilizadas) tipo "Niño costero" en la costa norte:
# 2017: semanas 4 a 14 ; 2023: semanas 8 a 20.

clima <- distritos |>
  select(ubigeo, zona_clima, altitud_m) |>
  inner_join(par_clima, by = "zona_clima") |>
  crossing(semanas) |>
  arrange(ubigeo, ano, semana) |>
  group_by(ubigeo) |>
  mutate(
    # ciclo estacional: máximo de temperatura y lluvia hacia la semana 8
    fase   = 2 * pi * (semana - 8) / 52,
    ruido_t = as.numeric(stats::filter(rnorm(n(), 0, 0.6), 0.6,
                                       method = "recursive")),
    nino17 = zona_clima == "costa_norte" & ano == 2017 & semana %in% 4:14,
    nino23 = zona_clima == "costa_norte" & ano == 2023 & semana %in% 8:20,
    dt     = case_when(nino17 ~ 2.5, nino23 ~ 3.0, TRUE ~ 0),
    fp     = case_when(nino17 ~ 12, nino23 ~ 10, TRUE ~ 1),
    temp_media_c = t_media - 0.0055 * altitud_m + t_amp * cos(fase) +
                   dt + ruido_t,
    lluvia_esperada = (p_base + (p_pico - p_base) * pmax(cos(fase), 0)^2) * fp,
    precip_mm = rgamma(n(), shape = 1.2, rate = 1.2 / lluvia_esperada)
  ) |>
  ungroup() |>
  transmute(ubigeo, ano, semana,
            temp_media_c = round(temp_media_c, 1),
            precip_mm    = round(precip_mm, 1))

# -----------------------------------------------------------------------------
# 3. Coberturas de vacunación por distrito y año
# -----------------------------------------------------------------------------
# Vacunas: PENTA3 (pentavalente 3.a dosis, menores de 1 año),
#          SPR1 (12 meses) y SPR2 (18 meses).
# Población objetivo: <1 año para PENTA3; para SPR1 y SPR2 se usa
# (población 1-4) / 4 como aproximación de una cohorte anual.
# Rasgos simulados:
#   - Cobertura base menor en selva y algo menor en sierra que en costa.
#   - Efecto aleatorio por distrito persistente en el tiempo.
#   - Caída en 2020 y recuperación parcial e incompleta después.
#   - Coberturas bajas en Datem del Marañón (Loreto) y en Puno (SPR).
#   - Aproximadamente 6 % de distrito-años con cobertura > 100 %, por
#     subestimación del denominador (problema frecuente en datos reales).
anos_vac <- 2015:2026
vacunas  <- c("PENTA3", "SPR1", "SPR2")

ef_distrito <- distritos |>
  transmute(
    ubigeo, departamento, provincia, region,
    ef_d = rnorm(n(), 0, 0.35),
    foco_bajo = grepl("DATEM", provincia) |
      (departamento == "LORETO" & runif(n()) < 0.25)
  )

pob_obj <- poblacion |>
  filter(ano %in% anos_vac, grupo_edad %in% c("<1", "1-4")) |>
  pivot_wider(names_from = grupo_edad, values_from = poblacion)

coberturas <- ef_distrito |>
  crossing(ano = anos_vac, vacuna = vacunas) |>
  left_join(pob_obj, by = c("ubigeo", "ano")) |>
  mutate(
    base_logit = case_when(region == "costa" ~ 1.9,     # ~87 %
                           region == "sierra" ~ 1.6,    # ~83 %
                           TRUE ~ 1.1),                 # ~75 %
    ef_vac = case_when(vacuna == "SPR2" ~ -0.45,
                       vacuna == "SPR1" ~ -0.10,
                       TRUE ~ 0),
    ef_ano = case_when(ano == 2020 ~ -0.85,
                       ano == 2021 ~ -0.55,
                       ano >= 2022 ~ -0.35,
                       TRUE ~ 0),
    ef_foco = if_else(foco_bajo, -0.9, 0) +
              if_else(departamento == "PUNO" & vacuna != "PENTA3", -0.6, 0),
    p = plogis(base_logit + ef_vac + ef_ano + ef_foco + ef_d +
                 rnorm(n(), 0, 0.15)),
    poblacion_objetivo = if_else(vacuna == "PENTA3", `<1`, round(`1-4` / 4)),
    poblacion_objetivo = pmax(poblacion_objetivo, 1),
    vacunados = rbinom(n(), poblacion_objetivo, p),
    # denominador subestimado en ~6 % de los registros
    sub_denom = runif(n()) < 0.06,
    poblacion_objetivo = if_else(
      sub_denom, round(poblacion_objetivo * runif(n(), 0.6, 0.85)),
      poblacion_objetivo),
    poblacion_objetivo = pmax(poblacion_objetivo, 1),
    cobertura_pct = round(100 * vacunados / poblacion_objetivo, 1)
  ) |>
  select(ubigeo, ano, vacuna, poblacion_objetivo, vacunados, cobertura_pct) |>
  arrange(ubigeo, ano, vacuna)

# -----------------------------------------------------------------------------
# 4. Vulnerabilidad y capacidad de respuesta (corte transversal)
# -----------------------------------------------------------------------------
vulnerabilidad <- distritos |>
  left_join(ef_distrito |> select(ubigeo, ef_d), by = "ubigeo") |>
  mutate(
    pobreza_pct = plogis(case_when(urbano ~ -1.6,
                                   region == "selva" ~ 0.1,
                                   region == "sierra" ~ 0.3,
                                   TRUE ~ -0.8) +
                         rnorm(n(), 0, 0.6) - 0.5 * ef_d),
    sin_agua_red_pct = plogis(qlogis(pobreza_pct) * 0.8 + rnorm(n(), 0, 0.5)),
    horas_hospital   = round(case_when(urbano ~ rgamma(n(), 2, 4),
                                       region == "selva" ~ rgamma(n(), 2, 0.25),
                                       TRUE ~ rgamma(n(), 2, 0.8)), 1),
    eess_por_10mil   = round(rgamma(n(), 3, if_else(urbano, 3, 1.5)), 2)
  ) |>
  transmute(ubigeo, region, altitud_m,
            pobreza_pct      = round(100 * pobreza_pct, 1),
            sin_agua_red_pct = round(100 * sin_agua_red_pct, 1),
            horas_hospital, eess_por_10mil)

# -----------------------------------------------------------------------------
# 5. Guardar
# -----------------------------------------------------------------------------
write_csv(poblacion,      file.path(dir_sim, "poblacion_simulada.csv"))
write_csv(clima,          file.path(dir_sim, "clima_semanal_simulado.csv.gz"))
write_csv(coberturas,     file.path(dir_sim, "coberturas_vacunacion_simuladas.csv"))
write_csv(vulnerabilidad, file.path(dir_sim, "vulnerabilidad_simulada.csv"))

diccionario <- tribble(
  ~archivo, ~variable, ~tipo, ~descripcion,
  "poblacion_simulada.csv", "ubigeo", "texto", "Código de distrito (6 dígitos), igual que en NotiSP",
  "poblacion_simulada.csv", "ano", "entero", "Año (2010-2026)",
  "poblacion_simulada.csv", "grupo_edad", "texto", "<1, 1-4, 5-14, 15-59, 60+ años",
  "poblacion_simulada.csv", "poblacion", "entero", "Población SIMULADA del grupo de edad",
  "clima_semanal_simulado.csv.gz", "ubigeo", "texto", "Código de distrito",
  "clima_semanal_simulado.csv.gz", "ano", "entero", "Año epidemiológico",
  "clima_semanal_simulado.csv.gz", "semana", "entero", "Semana epidemiológica (1-52; 53 en 2014, 2020 y 2025)",
  "clima_semanal_simulado.csv.gz", "temp_media_c", "numérico", "Temperatura media semanal SIMULADA (°C)",
  "clima_semanal_simulado.csv.gz", "precip_mm", "numérico", "Precipitación acumulada semanal SIMULADA (mm)",
  "coberturas_vacunacion_simuladas.csv", "ubigeo", "texto", "Código de distrito",
  "coberturas_vacunacion_simuladas.csv", "ano", "entero", "Año (2015-2026)",
  "coberturas_vacunacion_simuladas.csv", "vacuna", "texto", "PENTA3 (<1 año), SPR1 (12 meses), SPR2 (18 meses)",
  "coberturas_vacunacion_simuladas.csv", "poblacion_objetivo", "entero", "Denominador SIMULADO; ~6 % subestimado a propósito",
  "coberturas_vacunacion_simuladas.csv", "vacunados", "entero", "Niños vacunados SIMULADOS",
  "coberturas_vacunacion_simuladas.csv", "cobertura_pct", "numérico", "100 * vacunados / poblacion_objetivo; puede superar 100",
  "vulnerabilidad_simulada.csv", "ubigeo", "texto", "Código de distrito",
  "vulnerabilidad_simulada.csv", "region", "texto", "Costa, sierra o selva (asignada por departamento)",
  "vulnerabilidad_simulada.csv", "altitud_m", "entero", "Altitud SIMULADA (m s. n. m.)",
  "vulnerabilidad_simulada.csv", "pobreza_pct", "numérico", "Pobreza monetaria SIMULADA (%)",
  "vulnerabilidad_simulada.csv", "sin_agua_red_pct", "numérico", "Hogares sin agua por red pública SIMULADO (%)",
  "vulnerabilidad_simulada.csv", "horas_hospital", "numérico", "Tiempo SIMULADO al hospital de referencia (horas)",
  "vulnerabilidad_simulada.csv", "eess_por_10mil", "numérico", "Establecimientos de salud por 10 000 hab. SIMULADO"
)
write_csv(diccionario, file.path(dir_sim, "diccionario_simulados.csv"))

message("Bases simuladas guardadas en ", dir_sim)
