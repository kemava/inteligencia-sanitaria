# =============================================================================
# Curso Inteligencia Sanitaria — wavelet_piura.R
# Análisis de ondículas (wavelets) cruzado entre los casos de dengue de Piura
# y la precipitación semanal (ERA5), 2010–2025.
#
# Entradas: datos/procesados/dengue_piura_semanal.csv
#           datos/procesados/precipitacion_piura_semanal.csv
# Salidas:  img/wavelet_dengue_lluvia_piura.png
#           img/wavelet_fase_dengue_lluvia_piura.png
# Requiere: install.packages("WaveletComp")
# =============================================================================

library(readr)
library(dplyr)
library(tidyr)
library(WaveletComp)

set.seed(2023)

dengue <- read_csv(file.path("datos", "procesados", "dengue_piura_semanal.csv"),
                   col_types = cols(ubigeo = col_character()), show_col_types = FALSE) |>
  filter(ano <= 2025, semana <= 52) |>
  group_by(ano, semana) |>
  summarise(casos = sum(casos), .groups = "drop") |>
  complete(ano = 2010:2025, semana = 1:52, fill = list(casos = 0))

lluvia <- read_csv(file.path("datos", "procesados", "precipitacion_piura_semanal.csv"),
                   show_col_types = FALSE) |>
  filter(semana <= 52)

datos <- dengue |>
  inner_join(lluvia, by = c("ano", "semana")) |>
  arrange(ano, semana) |>
  transmute(
    date = as.Date(paste0(ano, "-01-01")) + (semana - 1) * 7,
    dengue = log(casos + 1),       # escala log para estabilizar la varianza
    lluvia = log(precip_mm + 1)
  ) |>
  as.data.frame()

# Periodos de 3 meses a 4 años; dt en años (52 semanas = 1 año)
wc <- analyze.coherency(
  datos, my.pair = c("dengue", "lluvia"),
  loess.span = 0, dt = 1 / 52, dj = 1 / 25,
  lowerPeriod = 0.25, upperPeriod = 4,
  make.pval = TRUE, n.sim = 100, verbose = FALSE
)

dir.create("img", showWarnings = FALSE)

png(file.path("img", "wavelet_dengue_lluvia_piura.png"), width = 2400, height = 1150, res = 200)
par(mar = c(4, 4.5, 3, 1))
wc.image(
  wc, which.image = "wp", n.levels = 250,
  color.key = "interval", legend.params = list(lab = "Potencia cruzada", label.digits = 1),
  periodlab = "Periodo (años)", timelab = "",
  show.date = TRUE, date.format = "%Y-%m-%d",
  spec.time.axis = list(at = paste0(seq(2010, 2025, 3), "-01-01"),
                        labels = seq(2010, 2025, 3)),
  siglvl.contour = 0.05, plot.arrow = TRUE, siglvl.arrow = 0.05,
  main = "Espectro cruzado de ondículas: dengue y precipitación, Piura 2010–2025"
)
dev.off()

# Desfase en la banda anual, en semanas.
# WaveletComp calcula la diferencia de fase como fase(dengue) - fase(lluvia):
# valores negativos indican que la lluvia antecede al dengue.
fila_anual <- which.min(abs(wc$Period - 1))
desfase <- data.frame(
  fecha = datos$date,
  semanas = -wc$Angle[fila_anual, ] / (2 * pi) * 52,
  p_valor = wc$Power.xy.pval[fila_anual, ]
)

library(ggplot2)
grafico <- ggplot(desfase, aes(fecha, semanas)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_line(linewidth = 1.1, colour = "#2166ac") +
  scale_y_continuous(limits = c(0, 16), breaks = seq(0, 16, 4)) +
  labs(x = NULL, y = "Semanas que la lluvia\nantecede al dengue",
       title = "Desfase entre lluvia y dengue en la banda anual (periodo de 1 año)") +
  theme_minimal(base_size = 16) +
  theme(panel.grid.minor = element_blank(), plot.title = element_text(size = 15))
ggsave(file.path("img", "wavelet_desfase_dengue_lluvia_piura.png"), grafico,
       width = 12, height = 4.2, dpi = 200, bg = "white")

cat("Semanas con potencia cruzada anual no significativa:", sum(desfase$p_valor >= 0.05), "\n")
cat("Desfase medio en la banda anual (semanas):", round(mean(desfase$semanas), 1),
    " rango:", round(range(desfase$semanas), 1), "\n")
