# Proyecto Paradigmas (sin Docker) — construcción por versiones

Proyecto del curso **Paradigmas de Programación** (USB Medellín). Aquí NO se
descarga un sistema terminado: **se construye un sistema real por versiones**,
guiado por especificaciones. El repositorio siempre contiene la **versión en
curso, funcionando** — usted la ejecuta, la estudia y luego la **reconstruye
desde cero** en su propio proyecto.

> 🐳 Esta es la variante **SIN Docker** del curso, para las salas donde no
> hay Docker Desktop: la BD vive en el **PostgreSQL instalado en Windows**
> (instalador oficial) y la API corre con `uvicorn` sobre un venv de
> Python. Si su máquina tiene Docker, existe la variante principal con
> contenedores: [proyecto_paradigmas](https://github.com/ccastro2050/proyecto_paradigmas)
> — misma API, misma spec, otra infraestructura.

---

## 1. Cómo le trabaja el estudiante (léame primero)

### Qué necesita instalado (una sola vez)

| Herramienta | Para qué |
|---|---|
| **Git** | Clonar el repositorio y traer versiones nuevas |
| **PostgreSQL** (instalador oficial) | La base de datos — corre como servicio en el puerto 5432 (superusuario `postgres`/`postgres`) y trae **pgAdmin 4** |
| **Python 3.12+** | El lenguaje de la API |
| **VS Code** | El editor — y su terminal integrada (*Terminal → New Terminal*) |

### Primera vez: cargar y EJECUTAR la versión

En la terminal integrada de VS Code (*Terminal → New Terminal*, PowerShell):

```powershell
git clone https://github.com/ccastro2050/proyecto_paradigmas_sin_docker.git
cd proyecto_paradigmas_sin_docker

# 1. Crear la BD en el PostgreSQL instalado (solo la primera vez):
.\db\crear_bd.ps1

# 2. Preparar el entorno de Python (solo la primera vez):
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r api_facturas\requirements.txt

# 3. Arrancar la API (queda corriendo; se detiene con Ctrl+C):
cd api_facturas
uvicorn main:app --port 8002 --reload
```

Quedan corriendo la base de datos (bdfacturas completa) y la API:

| Qué | Dónde |
|---|---|
| **API Facturas — Swagger** (probar los endpoints) | http://localhost:8002/docs |
| Diagnóstico | http://localhost:8002/ |
| PostgreSQL (para pgAdmin/SQLTools) | `localhost:5432` · `paradigmas`/`paradigmas123` |

Pruebe en Swagger: PUT con solo `{"stock": 99}` → 422; el mismo body en
PATCH → 200. Esa diferencia es parte de lo que enseña la v1.

### Los días siguientes (volver a encender)

PostgreSQL es un servicio de Windows: arranca solo con la máquina. Solo
falta la API:

```powershell
.\.venv\Scripts\Activate.ps1
cd api_facturas
uvicorn main:app --port 8002 --reload
```

### Cuando hay cambios

| Qué cambió | Qué hacer |
|---|---|
| **Usted edita un `.py`** | **Nada** — `--reload` reinicia la API sola al guardar |
| **El profesor publicó una versión nueva** | `git pull` (y si cambió `requirements.txt`: `pip install -r api_facturas\requirements.txt` con el venv activo) |
| **Quiere resetear la BD** a sus datos originales | Borre la BD (`DROP DATABASE bdfacturas_postgres_local;` en pgAdmin) y re-corra `.\db\crear_bd.ps1` |
| **Apagar todo** | Ctrl+C en la terminal de la API (PostgreSQL puede seguir: es un servicio) |

### Y ahora, SU trabajo: reconstruirla desde cero

Ejecutar la versión del repo es solo el punto de partida. Lo que se evalúa es
**reconstruirla usted mismo, en una carpeta propia (fuera del clon)**,
siguiendo las especificaciones — con o sin ayuda de IA:

> 🤖 **[Guía para construir la versión con IA](docs/GUIA_IA.md)** — los dos
> caminos con su prompt listo para copiar: **chat web** (Gemini, DeepSeek,
> ChatGPT) e **IDE agéntico** (Antigravity, Cursor, Claude Code).

### Conceptos resumidos (los que acaba de usar)

| Concepto | En una frase |
|---|---|
| **Clonar** | Descargar el repositorio con su historial; `git pull` trae lo nuevo |
| **Servicio de Windows** | PostgreSQL corre de fondo y arranca con la máquina — no hay que "levantarlo" cada día |
| **`crear_bd.ps1`** | El inicializador: crea el usuario del curso y la BD completa (idempotente) |
| **venv** | El entorno virtual de Python: las dependencias del proyecto viven ahí, no en el sistema |
| **--reload** | uvicorn vigila los archivos: guardar un `.py` recarga la API sola |
| **Swagger (/docs)** | La documentación interactiva: probar la API desde el navegador |
| **Spec kit** | Los documentos que dicen QUÉ/CÓMO/EN QUÉ ORDEN — la fuente de verdad |
| **Versión / tag** | Un incremento cerrado y verificado (`v1`, `v2`, …): se avanza solo en verde |

> Detalle del entorno: [docs/ENTORNO_LOCAL.md](docs/ENTORNO_LOCAL.md).

---

## 2. Estructura del repositorio

Qué es cada carpeta y cada archivo, y para qué sirve:

```
proyecto_paradigmas_sin_docker/
├── db/
│   ├── init.sql                 # Crea bdfacturas COMPLETA (12 tablas, triggers, datos)
│   └── crear_bd.ps1             # El inicializador: la ejecuta en el PostgreSQL instalado
│                                #   (idempotente; crea también el usuario del curso)
│
├── backupdb/                    # Respaldos (dumps) de la BD — su README explica
│                                #   cómo hacer el backup y cómo restaurarlo
│
├── api_facturas/                # LA API DE LA v1 — FastAPI (puerto 8002)
│   ├── requirements.txt         # Dependencias exactas (fastapi, uvicorn, sqlalchemy, asyncpg)
│   ├── main.py                  # Crea la app y registra el router
│   ├── controllers/             # Capa 1 — HTTP: los endpoints de /api/producto
│   ├── models/                  # Pydantic: un modelo por verbo (Producto,
│   │                            #   ProductoReemplazo, ProductoActualizar) → los 422
│   ├── servicios/               # Capa 2 — negocio: servicio + ensamblador (proto-fábrica)
│   │   └── abstracciones/       #   la interfaz (typing.Protocol) que la capa 1 conoce
│   └── repositorios/            # Capa 3 — datos: SQL asíncrono contra PostgreSQL
│       └── abstracciones/       #   la interfaz que la capa 2 conoce
│
├── docs/
│   ├── spec_kit/                # LAS ESPECIFICACIONES: constitución permanente +
│   │                            #   una carpeta de specs por versión (v1, v2, …)
│   ├── GUIA_IA.md               # Cómo reconstruir la versión desde 0 con ayuda de una IA
│   ├── ENTORNO_LOCAL.md         # PostgreSQL como servicio + venv + uvicorn, explicados
│   ├── PARADIGMA_POO.md         # Material conceptual: POO (con Pydantic), SOLID+capas,
│   ├── SOLID_CAPAS_PATRONES.md         #   ACID y SDD (un .md por tema)
│   ├── PRINCIPIOS_ACID.md       #
│   ├── SDD_SPECKIT.md           #
│   ├── TUTORIAL_PGADMIN.md      # Tutoriales de administración de la BD, paso a paso
│   ├── TUTORIAL_VSCODE_SQLTOOLS.md  #   con capturas reales
│   └── img_pgadmin/ img_sqltools/   # Las capturas de esos tutoriales
│
├── .gitignore / .gitattributes  # Higiene del repo (ignora .venv, .session.sql, EOL)
└── README.md                    # Este archivo
```

La regla de lectura: **la infraestructura son PostgreSQL + `db/crear_bd.ps1`**,
la API vive en `api_facturas/` (una carpeta por capa, cada una con su interfaz
en `abstracciones/`), y **todo lo que explica** vive en `docs/`. Cuando
lleguen las versiones siguientes, aquí aparecerán más carpetas de componentes.

## 3. La ruta de versiones

```
v1  api_facturas: CRUD de producto, solo PostgreSQL   ← USTED ESTÁ AQUÍ (cerrada: tag v1)
v2  más tablas (persona, factura maestro-detalle…)
v3  segundo motor (MariaDB) — nace la fábrica y DB_PROVIDER
v4  tercer motor (SQL Server)
v5  frontend Flask
```

La regla del juego: la **constitución** es permanente, cada versión tiene su
propia spec, y una versión está TERMINADA solo cuando pasa sus criterios de
aceptación (se cierra con tag). Detalle completo:
**[mapa de versiones](docs/spec_kit/versiones/0_mapa_versiones.md)**.

## 4. Las especificaciones de la versión actual (v1)

| Documento | Qué contiene |
|---|---|
| [Constitución](docs/spec_kit/1_constitution.md) | Las reglas permanentes del proyecto |
| [2_spec.md](docs/spec_kit/versiones/v1_producto_postgres/2_spec.md) | QUÉ construir y los 6 criterios de aceptación |
| [3_plan.md](docs/spec_kit/versiones/v1_producto_postgres/3_plan.md) | CÓMO: stack, carpetas, capas e interfaces |
| [4_research.md](docs/spec_kit/versiones/v1_producto_postgres/4_research.md) | Las decisiones y sus alternativas descartadas *(lectura opcional)* |
| [5_data_model.md](docs/spec_kit/versiones/v1_producto_postgres/5_data_model.md) | La BD completa (dada) y la tabla `producto` que usa la v1 |
| [6_contracts.md](docs/spec_kit/versiones/v1_producto_postgres/6_contracts.md) | Los 7 endpoints con formatos exactos (5 verbos HTTP) |
| [7_quickstart.md](docs/spec_kit/versiones/v1_producto_postgres/7_quickstart.md) | Smoke test para validar lo construido |
| [8_tasks.md](docs/spec_kit/versiones/v1_producto_postgres/8_tasks.md) | Las fases de construcción, en orden |

## 5. Material conceptual del curso

| Documento | Qué cubre |
|---|---|
| [SDD y Spec Kit](docs/SDD_SPECKIT.md) | La metodología con la que se trabaja este curso: la spec manda sobre el código |
| [Calidad de las pruebas](docs/CALIDAD_DE_PRUEBAS.md) | Cobertura, la métrica CRAP y mutation testing: cómo saber si sus pruebas de verdad protegen — y por qué hoy es reto opcional, no alcance del proyecto |
| [El paradigma P.O.O.](docs/PARADIGMA_POO.md) | Qué es un paradigma, los 4 pilares, la P.O.O. de Python (`Protocol`, duck typing) y **Pydantic** como clases que validan datos |
| [SOLID, capas y patrones de diseño](docs/SOLID_CAPAS_PATRONES.md) | Los 5 principios y las capas — y en qué versión se demuestra cada uno |
| [Principios ACID](docs/PRINCIPIOS_ACID.md) | Las 4 garantías transaccionales, por qué una facturación las exige, y el contraste con BASE |
| [El entorno local](docs/ENTORNO_LOCAL.md) | PostgreSQL como servicio de Windows, pgAdmin, el venv y `uvicorn --reload` — qué es cada pieza y cómo se relacionan |
| [Tutorial pgAdmin](docs/TUTORIAL_PGADMIN.md) | Administrar la BD paso a paso: conectarse, explorar, editar datos (y verlos cambiar en la API), Query Tool y ERD |
| [Tutorial SQLTools (VS Code)](docs/TUTORIAL_VSCODE_SQLTOOLS.md) | La BD sin salir del editor: extensión + driver, conexión, explorar, SELECT/INSERT/DELETE y ejecutar una sentencia entre varias |

---

*Proyecto Paradigmas (sin Docker) · USB Med · Base de datos bdfacturas
(facturación + RBAC).*
