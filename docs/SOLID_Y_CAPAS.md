# SOLID y programación por capas

> Documento conceptual del curso. Los cinco principios SOLID y la arquitectura
> por capas: qué son, por qué importan, y dónde se ven (o se verán) en cada
> versión del proyecto.

---

## 1. Programación por capas

Organizar el sistema en **niveles con responsabilidades distintas**, donde
cada capa solo conoce a la inmediatamente inferior y siempre a través de un
contrato. Así se ve el **viaje de UNA petición** por dentro de la API — el
"diagrama de palitos" del curso:

```
            EL CLIENTE (navegador, Swagger, curl)
                 │
                 │  ① GET /api/producto/PR001
                 ▼
┌─────────────────────────────────────────────────────┐
│ CAPA 1 — CONTROLLER (HTTP)                          │
│ controllers/producto_controller.py                  │
│ Recibe la petición y traduce el resultado a códigos │
│ HTTP y JSON. NO tiene negocio. NO tiene SQL.        │
└────────────────┬────────────────────────────────────┘
                 │  ② servicio.obtener_por_codigo("PR001")
                 ▼
┌─────────────────────────────────────────────────────┐
│ CAPA 2 — SERVICIO (negocio)                         │
│ servicios/servicio_producto.py                      │
│ Las reglas del dominio: qué se puede y qué no (el   │
│ 404 "no existe" NACE aquí). NO conoce FastAPI.      │
│ NO sabe qué motor hay debajo.                       │
└────────────────┬────────────────────────────────────┘
                 │  ③ repositorio.obtener_por_codigo("PR001")
                 │     — a través de la INTERFAZ IRepositorioProducto
                 ▼
┌─────────────────────────────────────────────────────┐
│ CAPA 3 — REPOSITORIO (datos)                        │
│ repositorios/repositorio_producto_postgresql.py     │
│ El SQL: traduce filas ↔ objetos. NO conoce HTTP.    │
│ NO decide negocio.                                  │
└────────────────┬────────────────────────────────────┘
                 │  ④ SELECT … FROM producto WHERE codigo = 'PR001'
                 ▼
          ┌───────────────┐
          │ BASE DE DATOS │  PostgreSQL — bdfacturas
          └───────┬───────┘
                  │
   y la respuesta hace el viaje DE VUELTA:
   fila → dict (repositorio) → dict (servicio) → JSON + 200 (controller)
```

Qué hace — y qué tiene PROHIBIDO — cada capa:

| Capa | Su trabajo | Prohibido para ella | En la v1 |
|---|---|---|---|
| **Controller** | HTTP: rutas, códigos de estado, JSON | SQL y reglas de negocio | `controllers/producto_controller.py` |
| **Servicio** | Las reglas del negocio (¿existe? ¿se puede?) | Saber de HTTP o del motor de BD | `servicios/servicio_producto.py` |
| **Repositorio** | El SQL y el mapeo fila ↔ objeto | Saber de HTTP o decidir negocio | `repositorios/repositorio_producto_postgresql.py` |

**La regla de oro:** las dependencias apuntan en una sola dirección y cruzan
por **interfaces**. El controller conoce al servicio; el servicio conoce la
interfaz del repositorio; **nadie** conoce dos capas hacia abajo (el
controller no sabe que existe PostgreSQL).

**El mismo viaje cuando algo sale mal** — `GET /api/producto/PR999`:

1. El **repositorio** no encuentra la fila y devuelve `None` — un HECHO,
   sin opinión.
2. El **servicio** decide qué significa ese hecho: "ese producto no
   existe" — una DECISIÓN de negocio.
3. El **controller** la traduce al idioma HTTP: **404** con su JSON.

Cada capa aportó exactamente lo suyo: datos → hecho, negocio → decisión,
HTTP → código de estado.

**Justificación:** cada capa se puede cambiar, probar o reemplazar sin tocar
las otras. La prueba viva es el criterio 6 de la v1: el servicio se prueba con
un repositorio falso, sin base de datos.

Y el SISTEMA COMPLETO (la meta, v6) repite el patrón a lo grande:

```
CAPA 1: FRONT (v6)      → solo pinta y llama APIs
CAPA 2: APIs (v1…v5)    → solo JSON
CAPA 3: DATOS (v1…)     → PostgreSQL → +MariaDB → +SQL Server
```

## 2. Los cinco principios SOLID

SOLID (Robert C. Martin) son cinco reglas de diseño orientado a objetos para
que el software **aguante el cambio**. Este proyecto está diseñado para que
cada principio tenga su momento de demostración en la ruta de versiones:

### S — Responsabilidad Única (*Single Responsibility*)
> Una clase debe tener UNA sola razón para cambiar.

**En la v1:** el controller cambia si cambia el HTTP; el servicio si cambian
las reglas de negocio; el repositorio si cambia el SQL. Tres archivos, tres
razones de cambio, cero mezcla.

```python
# ❌ Sin S: un "controller" con tres razones de cambio (HTTP + negocio + SQL)
@router.get("/api/producto/{codigo}")
async def obtener(codigo: str):
    fila = await sesion.execute(text("SELECT ..."))    # SQL aquí = mezcla
    if fila is None:                                   # negocio aquí = mezcla
        return JSONResponse(status_code=404, ...)

# ✅ Con S (la v1): tres archivos, una razón de cambio cada uno
#   controllers/   → cambia solo si cambia el HTTP
#   servicios/     → cambia solo si cambian las reglas
#   repositorios/  → cambia solo si cambia el SQL
```

### O — Abierto/Cerrado (*Open/Closed*)
> Abierto a extensión, cerrado a modificación: agregar sin romper lo que hay.

**Su momento es la v3:** agregar MariaDB será escribir UNA clase nueva
(`RepositorioProductoMysqlMariaDB`) y una línea en la fábrica — controllers y
servicios no se tocan. Si en la v3 hay que modificar el servicio, el diseño de
la v1 estuvo mal (por eso la v1 deja las interfaces listas).

```python
# La v3 AGREGARÁ sin modificar: una clase nueva con la misma interfaz...
class RepositorioProductoMariaDB:
    """Los mismos 5 métodos que promete IRepositorioProducto."""

# ...y el ensamblador (ÚNICO archivo tocado) elegirá el motor:
repositorio = (RepositorioProductoMariaDB(cadena)
               if motor == "mariadb"
               else RepositorioProductoPostgreSQL(cadena))
```

### L — Sustitución de Liskov (*Liskov Substitution*)
> Donde sirve el tipo base, debe servir CUALQUIER implementación, sin sorpresas.

**Su momento son la v3 y la v4:** los tres repositorios de producto
(PostgreSQL, MariaDB, SQL Server) deben ser **indistinguibles** desde el
servicio: mismos métodos, misma semántica, mismos errores. Cambiar
`DB_PROVIDER` y que nada se rompa ES la prueba de Liskov.

```python
# Ya se ve en la v1: el repositorio FALSO de la prueba (criterio 6)
class RepositorioFalso:
    """Sin base de datos: un diccionario en memoria, misma interfaz."""
    async def obtener_por_codigo(self, codigo: str) -> dict | None:
        return self._datos.get(codigo)
    # ...los otros 4 métodos...

servicio = ServicioProducto(RepositorioFalso())   # ← el servicio NI SE ENTERA
```

### I — Segregación de Interfaces (*Interface Segregation*)
> Muchas interfaces pequeñas y específicas, no una gigante que obligue a
> implementar lo que no se usa.

**En la v1:** `IRepositorioProducto` tiene exactamente los 5 métodos del CRUD
de producto — no un `IRepositorioUniversal` con 40 métodos. Cuando la v2
agregue persona, tendrá SU interfaz.

```python
# ✅ La interfaz de la v1: SOLO los 5 métodos del CRUD de producto
class IRepositorioProducto(Protocol):
    async def obtener_todos(self, limite: int) -> list[dict]: ...
    async def obtener_por_codigo(self, codigo: str) -> dict | None: ...
    async def crear(self, datos: dict) -> bool: ...
    async def actualizar(self, codigo: str, datos: dict) -> int: ...
    async def eliminar(self, codigo: str) -> int: ...

# ❌ El anti-ejemplo: un IRepositorioUniversal de 40 métodos donde cada
#    clase implementa 35 con "raise NotImplementedError".
```

### D — Inversión de Dependencias (*Dependency Inversion*)
> Depender de abstracciones, no de implementaciones concretas.

**En la v1:** `ServicioProducto` recibe **la interfaz** por constructor; solo
`ensamblador.py` (3 líneas) conoce la clase concreta. En la v3 ese ensamblador
se convierte en la fábrica real — el único archivo que sabe qué motores existen.

## 3. Cómo se refuerzan entre sí (el resumen para el examen)

| Sin este principio… | …pasa esto |
|---|---|
| Sin S | El "controller" de 800 líneas que hace HTTP + negocio + SQL: cambiar cualquier cosa arriesga todo |
| Sin O | Cada motor nuevo = editar el servicio con otro `if provider == …`: el archivo crece y se rompe |
| Sin L | El motor nuevo "casi" funciona igual → ifs especiales por motor → se perdió O |
| Sin I | Interfaces obesas → clases llenas de `raise NotImplementedError` |
| Sin D | El servicio importa PostgreSQL directo → no hay repositorio falso, no hay pruebas, no hay v3 |

Y las **capas** son SOLID a escala de arquitectura: S reparte responsabilidades
entre capas, D las comunica por contratos, O/L permiten reemplazar una capa
entera (otro motor, otro front) sin tocar las demás.

## 4. Ejemplo resumido de la v1 (todo junto)

```python
# D: el servicio depende de la ABSTRACCIÓN, recibida por constructor
class ServicioProducto:
    def __init__(self, repositorio: IRepositorioProducto):   # ← interfaz, no clase
        self._repositorio = repositorio

# El ÚNICO lugar que conoce la clase concreta (v3 lo convertirá en fábrica):
def crear_servicio_producto() -> IServicioProducto:
    repositorio = RepositorioProductoPostgreSQL(os.environ["DB_POSTGRES"])
    return ServicioProducto(repositorio)
```

Tres líneas que compran, sin costo extra hoy, toda la ruta v3–v4.

## 5. Referencias

1. Robert C. Martin — *Design Principles and Design Patterns* (el artículo
   original de los principios, 2000):
   <https://web.archive.org/web/20150906155800/http://www.objectmentor.com/resources/articles/Principles_and_Patterns.pdf>
2. Robert C. Martin — *Clean Architecture* (2017): capas, la regla de
   dependencia y SOLID aplicado a arquitectura.
3. Martin Fowler — *PresentationDomainDataLayering*:
   <https://martinfowler.com/bliki/PresentationDomainDataLayering.html>
4. Refactoring Guru (es) — principios de diseño:
   <https://refactoring.guru/es/design-patterns/what-is-pattern>
5. En este repositorio: el [plan de la v1](spec_kit/versiones/v1_producto_postgres/3_plan.md)
   (§3 capas, §4.1 interfaces, §4.3 la proto-fábrica) y el
   [mapa de versiones](spec_kit/versiones/0_mapa_versiones.md) (dónde entra
   cada principio).
