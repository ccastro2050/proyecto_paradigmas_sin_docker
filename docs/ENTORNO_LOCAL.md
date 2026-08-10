# El entorno local — PostgreSQL + Python (venv) + uvicorn

> El "motor" de esta variante del curso: qué es cada pieza, por qué está
> ahí y cómo se relacionan. Es el documento análogo al de conceptos de
> infraestructura de cualquier proyecto — aquí la infraestructura no son
> contenedores sino **programas instalados en su Windows**.

---

## 1. Las tres piezas

```
PostgreSQL (servicio de Windows, :5432)  ← la base de datos bdfacturas
pgAdmin 4 (vino con el instalador)       ← administrarla con clics
Python + venv ──► uvicorn (:8002)        ← LA API
```

| Pieza | Qué aporta |
|---|---|
| **PostgreSQL** | El motor de BD, corriendo como **servicio** (arranca con la máquina) |
| **pgAdmin 4** | El administrador gráfico — viene incluido con el instalador |
| **venv + uvicorn** | El entorno de Python del proyecto y su servidor web |

## 2. PostgreSQL como servicio de Windows

El instalador oficial deja PostgreSQL corriendo como **servicio**: un
programa de fondo que Windows arranca solo al encender la máquina. Por
eso en este curso no hay que "levantar la BD" cada día — ya está arriba.

- Escucha en el puerto **5432** (el estándar de PostgreSQL).
- El superusuario es **`postgres`** (clave de las salas: `postgres`).
  La API no lo usa: se conecta con el usuario del curso
  (`paradigmas`/`paradigmas123`) que crea `db\crear_bd.ps1` — la misma
  higiene de producción: cada aplicación con su usuario limitado.
- Los datos viven en `C:\Program Files\PostgreSQL\<versión>\data` y
  sobreviven a reinicios sin hacer nada.
- Si alguna vez no responde: `services.msc` → busque `postgresql` →
  clic derecho → *Iniciar*.

## 3. El inicializador: `db\crear_bd.ps1`

Hace una vez lo que en otros entornos hace la infraestructura: crea el
usuario `paradigmas`, crea la BD `bdfacturas_postgres_local` (con él
como dueño) y ejecuta `db/init.sql` — las 12 tablas con sus triggers,
procedimientos y datos, leyendo el archivo en **UTF-8** para que las
tildes se guarden bien. Es **idempotente**: si la BD ya existe, no hace
nada.

```powershell
.\db\crear_bd.ps1                          # la BD del curso
.\db\crear_bd.ps1 -NombreBd bdfacturas_mi_v1   # otra BD (su reconstrucción)
.\db\crear_bd.ps1 -Puerto 5433             # si su PostgreSQL usa otro puerto
```

## 4. El venv y uvicorn

- **venv** (entorno virtual): una carpeta `.venv/` con un Python privado
  del proyecto — lo que instale `pip` queda AHÍ, no en el sistema. Se
  crea una vez (`python -m venv .venv`) y se "enciende" en cada terminal
  con `.\.venv\Scripts\Activate.ps1`.
- **uvicorn**: el servidor que corre la API. Con `--reload` vigila los
  archivos: **guardar un `.py` recarga la API sola** — ese es el ciclo
  de desarrollo del curso.

```powershell
.\.venv\Scripts\Activate.ps1
cd api_facturas
uvicorn main:app --port 8002 --reload
```

La terminal queda "ocupada" mostrando cada petición — eso es el log. Se
detiene con **Ctrl+C**.

## 5. El botón de pánico

¿La BD quedó en mal estado por un experimento? Volver al estado de
fábrica son dos pasos (el Artículo 6 de la constitución):

```sql
-- en pgAdmin (Query Tool sobre la BD postgres) o con psql:
DROP DATABASE bdfacturas_postgres_local;
```

```powershell
.\db\crear_bd.ps1     # desde la raíz del repo — la recrea completa
```

## 6. Este entorno y la variante con Docker

Este curso tiene un repositorio gemelo que corre las MISMAS piezas en
contenedores:
[proyecto_paradigmas](https://github.com/ccastro2050/proyecto_paradigmas).
La API y las especificaciones son idénticas; cambia solo quién pone la
infraestructura:

| | Esta variante (sin Docker) | La variante con Docker |
|---|---|---|
| PostgreSQL | Servicio de Windows (`localhost:5432`) | Contenedor (`localhost:15432`) |
| Crear la BD | `.\db\crear_bd.ps1` | Automático al primer arranque |
| La API | `uvicorn` sobre su venv | Contenedor con `--reload` |
| Encender | Solo la API (la BD ya es un servicio) | `docker compose up -d` |
| Resetear la BD | `DROP DATABASE` + `crear_bd.ps1` | `docker compose down -v` + `up -d` |

La lección de fondo es la misma en ambos: la aplicación no sabe ni le
importa DÓNDE corre su base de datos — solo conoce una cadena de
conexión que llega por configuración.
