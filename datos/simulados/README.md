# Datos simulados del curso Inteligencia Sanitaria

**Todos los archivos de esta carpeta son SIMULADOS.** No son cifras oficiales del INEI, SENAMHI, MINSA ni de otra institución, y no deben citarse como tales. Sirven para practicar mientras no se tengan las fuentes oficiales; cuando se consigan, se reemplazan sin cambiar el resto del flujo, porque usan el mismo `ubigeo` de 6 dígitos que NotiSP.

Se generan con `R/simular_datos.R` (semilla `20261109`) a partir de `datos/referencia/ubigeos.csv`, que a su vez se extrae de la base NotiSP con `R/preparar_ubigeos.R`.

| Archivo | Unidad | Periodo | Uso en el curso |
|---|---|---|---|
| `poblacion_simulada.csv` | distrito × año × grupo de edad | 2010–2026 | Denominadores de tasas (S2–S4) |
| `clima_semanal_simulado.csv.gz` | distrito × semana epidemiológica | 2010–2026 | Clima como predictor rezagado del dengue (S2, S5) |
| `coberturas_vacunacion_simuladas.csv` | distrito × año × vacuna | 2015–2026 | Riesgo territorial de tos ferina y sarampión (S4, S5) |
| `vulnerabilidad_simulada.csv` | distrito | corte único | Priorización multicriterio (S4) |
| `diccionario_simulados.csv` | — | — | Descripción de cada variable |

## Qué patrones se simularon

- **Población.** El tamaño de cada distrito sigue una distribución log-normal, con distritos urbanos de costa más grandes, y crece entre −0,5 % y 2,5 % al año. La estructura por edad es más joven en la selva que en la costa.
- **Clima.** Hay un ciclo estacional con el máximo de temperatura y de lluvias hacia la semana 8. La temperatura disminuye 0,55 °C por cada 100 m de altitud. La costa centro-sur casi no tiene lluvia y la selva tiene lluvia abundante. En la costa norte se incluyen anomalías cálidas y lluviosas estilizadas en 2017 (SE 4–14) y 2023 (SE 8–20), que recuerdan los eventos de Niño costero pero no reproducen mediciones reales. Las semanas 53 están en 2014, 2020 y 2025, igual que en NotiSP.
- **Coberturas.** La costa tiene coberturas más altas que la sierra y la sierra más que la selva. SPR2 está por debajo de SPR1. Hay una caída en 2020 con recuperación incompleta. Se simularon focos de baja cobertura en Datem del Marañón (Loreto) y de SPR baja en Puno.
- **Vulnerabilidad.** Pobreza, falta de agua por red pública, tiempo al hospital y densidad de establecimientos, todos correlacionados entre sí y con la región.

## Problemas incluidos a propósito (para discutir en clase)

- **Coberturas mayores al 100 %.** En alrededor del 6 % de los registros el denominador está subestimado, y cerca del 3,5 % termina con una cobertura mayor a 100 %, como sucede en datos reales.
- **Denominador aproximado de SPR.** La población objetivo de SPR se calcula como (población de 1 a 4 años) / 4, lo cual es una aproximación.
- **Región asignada por departamento.** Cada distrito toma la región de su departamento, aunque departamentos como Piura o Cajamarca tienen distritos de costa, sierra y selva.

## Limitación del marco de distritos

`ubigeos.csv` incluye solo los 1280 distritos con al menos una notificación de metaxénicas, de los 1891 del país. Puno, Arequipa, Moquegua y Tacna quedan incompletos. Para los equipos de sarampión o tos ferina hay que reemplazar `ubigeos.csv` por la lista completa del INEI, o por los ubigeos de su propia base, y volver a ejecutar `R/simular_datos.R`.
