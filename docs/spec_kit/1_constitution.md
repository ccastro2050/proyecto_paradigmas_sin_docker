# Constitución del Proyecto Paradigmas

> Principios **innegociables** que gobiernan todo el proyecto. Esta
> constitución es **permanente**: describe el sistema COMPLETO al que se llega
> al final, y no cambia entre versiones.
>
> El proyecto se construye **por versiones** (desarrollo incremental guiado por
> especificaciones): ver el [mapa de versiones](versiones/0_mapa_versiones.md).
> Cada artículo aplica desde la versión que introduce su alcance — por ejemplo,
> en la v1 solo existe `api_facturas` con PostgreSQL, así que los artículos
> sobre el front y los otros motores son la META, no el estado
> actual.

---

## Artículo 1 — Propósito didáctico ante todo

Este proyecto existe para **enseñar paradigmas de programación y arquitectura de
software** a estudiantes universitarios. Ante cualquier disyuntiva entre "lo más
profesional" y "lo más claro para aprender", gana la claridad:

- Todo el código, comentarios, docstrings, mensajes y documentación se escriben en **español**.
- Cada archivo abre con un docstring/comentario que explica su papel en la arquitectura.
- Se prefiere código explícito y repetitivo-pero-legible sobre metaprogramación compacta.

## Artículo 2 — Arquitectura de 3 capas estricta

```
CAPA 1: FRONT (Flask, :8000)  — solo pinta HTML y llama APIs; NUNCA toca la BD
CAPA 2: APIs (FastAPI)        — api_generica :8001 y api_facturas :8002
CAPA 3: DATOS                 — PostgreSQL | MariaDB | SQL Server (bdfacturas)
```

- El front **no importa drivers de base de datos**; solo habla HTTP con las APIs.
- Las APIs no generan HTML; solo JSON.
- Cada capa se puede reemplazar sin tocar las otras (el front funciona igual con
  las dos APIs; las APIs funcionan igual con los 3 motores).

## Artículo 3 — Independencia del motor de base de datos

- El motor activo se elige con **una sola variable**: `DB_PROVIDER`
  (`postgres` | `mariadb` | `sqlserver`). Nunca con cambios de código.
- Los tres motores contienen la **misma base de datos** (`bdfacturas_*_local`):
  mismas 12 tablas, mismos datos de ejemplo, mismos triggers y procedimientos
  almacenados, traducidos al dialecto de cada motor.
- Todo acceso a datos pasa por interfaces (Protocol) + fábrica de repositorios,
  aplicando inversión de dependencias (SOLID). Ver `docs/PRINCIPIOS_SOLID_ACID.md`.

## Artículo 4 — Un solo comando para arrancar

Esta variante del curso corre **directo en Windows**, con dos piezas que
las salas ya tienen: **PostgreSQL** (instalador oficial: corre como
servicio en el puerto 5432, superusuario `postgres`/`postgres`, con
pgAdmin 4 incluido) y **Python 3.12+**. La preparación es UNA vez:

1. `.\db\crear_bd.ps1` — crea la BD completa (idempotente).
2. `python -m venv .venv` + `pip install -r api_facturas\requirements.txt`.

Y el arranque diario es UN comando (con el venv activo, desde
`api_facturas\`): `uvicorn main:app --port 8002 --reload`.
Sin instaladores exóticos ni pasos ocultos: si algo más hace falta, va
escrito en la documentación.

## Artículo 5 — Persistencia y reproducibilidad

- Los datos viven en el PostgreSQL instalado (servicio de Windows):
  sobreviven a reinicios del PC sin hacer nada.
- El "botón de pánico" oficial para volver al estado de fábrica: borrar
  la BD (`DROP DATABASE bdfacturas_postgres_local;` desde pgAdmin) y
  re-correr `.\db\crear_bd.ps1`.
- Los scripts de inicialización son **idempotentes**: `crear_bd.ps1`
  verifica si la BD existe antes de crear nada — correrlo mil veces no
  daña nada.

## Artículo 6 — Convenciones fijas

| Cosa | Convención |
|---|---|
| Puertos públicos | front 8000 · api_generica 8001 · api_facturas 8002 (con `uvicorn`) |
| Puertos de BD | PostgreSQL **5432** (el servicio instalado) · MariaDB 3306 y SQL Server 1433 (instalaciones locales de versiones futuras) |
| Administrador gráfico | **pgAdmin 4** (viene con el instalador de PostgreSQL) |
| Credenciales BD | la API usa `paradigmas` / `paradigmas123`; el superusuario es `postgres` / `postgres` (solo para administrar y para `crear_bd.ps1`) |
| Bases de datos | `bdfacturas_postgres_local` · `bdfacturas_mariadb_local` · `bdfacturas_sqlserver_local` |
| Nombres de código | snake_case en español; clases PascalCase; interfaces con prefijo `i_`/`I` |
| Documentación de APIs | api_generica: `/swagger` · api_facturas: `/docs` |

## Artículo 7 — Desarrollo con recarga en caliente

Los servidores corren con `--debug`/`--reload`: guardar un archivo
recarga la aplicación sola — ese es el ciclo de desarrollo del curso.
Instalar dependencias nuevas es un `pip install` en el venv.

## Artículo 8 — Seguridad en su justa medida académica

- Las contraseñas de usuarios de la aplicación se almacenan con **BCrypt** (nunca texto plano en código nuevo).
- Los valores SQL siempre van **parametrizados** (nunca concatenados).
- Las credenciales de infraestructura (paradigmas/paradigmas123) son públicas y
  didácticas **a propósito**: este entorno jamás se despliega a producción.
