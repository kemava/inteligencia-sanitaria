# Inteligencia Sanitaria · DEAEA, FASPA-UPCH (2026)

Sitio web y material del curso **Inteligencia Sanitaria** del Diplomado de Especialización en Analítica Epidemiológica Avanzada (Universidad Peruana Cayetano Heredia).

**Sitio:** https://kemava.github.io/inteligencia-sanitaria/

## Estructura

```
inteligencia-sanitaria/
├── _quarto.yml            configuración del sitio y menú
├── index.qmd              inicio: objetivos, calendario, evaluación
├── empezar.qmd            instalación y descarga del material
├── sesiones/              una carpeta por sesión (index.qmd, slides.qmd, practica.qmd)
├── proyecto/              encargo, avances, rúbricas y plantilla para los equipos
├── referencia/            bibliografía, fuentes de datos, datos simulados
├── R/                     scripts compartidos (instalación, simulación de datos)
├── datos/                 crudos (no se suben), procesados, referencia, simulados
├── references.bib         bibliografía en BibTeX
└── docs/                  sitio renderizado (lo publica GitHub Pages)
```

## Primera vez: crear el repositorio y publicar el sitio

1. En GitHub, crear un repositorio **público** llamado `inteligencia-sanitaria`, sin README.
2. Abrir `inteligencia-sanitaria.Rproj` en RStudio y renderizar el sitio en la pestaña **Build → Render Website** (o en la terminal: `quarto render`). Se crea la carpeta `docs/`.
3. Subir la carpeta a GitHub. Hay dos opciones:
   - **GitHub Desktop** (la más sencilla): *File → Add local repository* → *Publish repository*.
   - **Terminal**:
     ```bash
     git init
     git add .
     git commit -m "Versión inicial del sitio"
     git branch -M main
     git remote add origin https://github.com/kemava/inteligencia-sanitaria.git
     git push -u origin main
     ```
4. En GitHub: *Settings → Pages → Build and deployment → Deploy from a branch*, y elegir la rama `main` y la carpeta `/docs`. El sitio queda publicado en unos minutos.

## Cada semana: actualizar el sitio

1. Agregar o editar los archivos de la sesión en `sesiones/sXX-.../` (por ejemplo, `slides.qmd` y `practica.qmd`) y actualizar su `index.qmd`.
2. Renderizar el sitio: **Build → Render Website** o `quarto render`.
3. Revisar el resultado en el visor de RStudio.
4. Subir los cambios:
   - En GitHub Desktop: escribir un resumen (por ejemplo, "S2: diapositivas y práctica") → **Commit to main** → **Push origin**.
   - En la terminal:
     ```bash
     git add .
     git commit -m "S2: diapositivas y práctica"
     git push
     ```

Gracias a `freeze: auto`, las prácticas que ya se renderizaron no se vuelven a ejecutar, salvo que se modifiquen. Por eso hay que subir también la carpeta `_freeze/`.

## Datos

- Las bases NotiSP individuales van en `datos/crudos/`, **que no se sube** a GitHub (está excluida en `.gitignore`).
- Las prácticas usan bases agregadas en `datos/procesados/` y bases simuladas en `datos/simulados/`. Todo archivo simulado lo indica en su nombre y en su diccionario.
- Para regenerar los datos simulados: `source("R/preparar_ubigeos.R")` y luego `source("R/simular_datos.R")`.

## Licencia

Contenido bajo [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) y código bajo licencia MIT (ver `LICENSE.md`).
