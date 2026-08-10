# Investigación y decisiones — Versión 1: producto + PostgreSQL

> **Versión 1** · **Lectura opcional** (el porqué de las decisiones del plan,
> con las alternativas que se evaluaron y descartaron). Complementa a
> [3_plan.md](3_plan.md); el orden de trabajo está en [8_tasks.md](8_tasks.md).

---

## D1 — Capas completas desde el día 1 (y no un MVP en un solo archivo)

**Alternativa descartada:** v1 = todo en `main.py` (lo más simple que
funcione) y refactorizar a capas en una versión posterior.
**Decisión:** controller → servicio → repositorio con interfaces desde v1,
aunque haya UNA entidad y UN motor.
**Por qué:** el valor de la v1 no es la funcionalidad sino el **esqueleto**
sobre el que crecen las demás versiones sin reescribir. Refactorizar "todo en
main.py" en la v2 enseñaría el dolor del código acoplado, pero cobraría ese
aprendizaje reescribiendo trabajo ya hecho. Además, el criterio de aceptación
6 (probar el servicio con un repositorio falso, sin PostgreSQL) **solo es
posible** si el servicio depende de una interfaz — es la prueba objetiva de
que las capas quedaron bien cortadas.

## D2 — Sin fábrica ni `DB_PROVIDER`: un ensamblador de 3 líneas

**Alternativa descartada:** escribir de una vez la fábrica multi-motor "para
que quede lista".
**Decisión:** `ensamblador.py` con 3 líneas que instancian la única
combinación existente (YAGNI con dirección).
**Por qué:** una fábrica con un solo producto es código muerto: no se puede
examinar (nada la pone a prueba) y anticipa decisiones que la v3 tomará con
mejor información. La interfaz `IRepositorioProducto` SÍ se escribe hoy —
es la puerta por la que entrará MariaDB — pero el mecanismo de selección
llega cuando exista algo que seleccionar. El examen del principio
abierto/cerrado será justamente ese: en v3, solo `ensamblador.py` cambia.

## D3 — La BD completa desde la v1 (la API solo toca `producto`)

**Alternativa descartada:** una BD mínima por versión (v1 = solo la tabla
producto) que crece junto con la API.
**Decisión:** `db/init.sql` crea `bdfacturas` COMPLETA (12 tablas, trigger,
SPs) desde el primer día; la regla es que el código de v1 solo puede nombrar
`producto`.
**Por qué:** los estudiantes ya vieron bases de datos — la BD es
**infraestructura dada**, no el objeto del curso; lo que se construye por
versiones es la API. Esto evita migraciones de esquema entre versiones (v2
no altera la BD: solo empieza a usar tablas que ya estaban) y deja el trigger
de facturación esperando su momento. El costo asumido: 11 tablas "a la vista"
que aún no se usan — por eso la regla se declara explícita en la spec.

## D4 — PUT y PATCH separados, con un modelo Pydantic por verbo

**Alternativa descartada:** un solo endpoint de actualización parcial (como
hacen muchas APIs reales con PUT relajado).
**Decisión:** PUT = reemplazo completo (`ProductoReemplazo`, todos
obligatorios) y PATCH = parcial (`ProductoActualizar`, todos opcionales).
**Por qué:** es un curso de paradigmas — la semántica HTTP ES contenido. El
contraste "el mismo body `{"stock": 7}` da 422 en PUT y 200 en PATCH" enseña
más que cualquier definición, y los modelos por verbo muestran que en Pydantic
la diferencia se escribe **en tipos**, no en comentarios. Costo: un modelo
más; despreciable.

## D5 — FastAPI + SQLAlchemy `text()` + asyncpg (SQL visible)

**Alternativa descartada:** ORM declarativo (modelos SQLAlchemy mapeados).
**Decisión:** SQL a mano con `text()` y parámetros nombrados, ejecutado por
el engine async.
**Por qué:** la constitución exige SQL visible — el estudiante debe VER el
`INSERT` y el `UPDATE ... WHERE`. El ORM esconde justo lo que el curso quiere
mostrar, y obligaría a modelos por tabla que la ruta multi-motor (v3/v4) no
necesita. `text()` además unifica el estilo con los motores futuros: la misma
consulta cambia de dialecto, no de API.

## D6 — El `limite` se valida en el servicio (400), no en FastAPI (422)

**Alternativa descartada:** `limite: int = Query(gt=0)` — FastAPI lo
rechazaría solo, con 422.
**Decisión:** el controller lo recibe sin restricción y el **servicio** lanza
`ValueError` (→ 400) si `limite <= 0`.
**Por qué:** dibuja la frontera entre capas con un ejemplo concreto: el 422
es "la FORMA del dato está mal" (frontera Pydantic), el 400 es "la forma está
bien pero la REGLA de negocio lo rechaza" (servicio). Además deja la regla en
la capa que sobrevive a un cambio de framework — si mañana FastAPI se cambia
por otra cosa, la validación de negocio no se va con él.

## D7 — PostgreSQL instalado + venv (la infraestructura sin Docker)

**Alternativas descartadas:** exigir Docker (no está disponible en todas
las salas del curso) y PostgreSQL portable (sin servicio de Windows ni
pgAdmin, más pasos manuales).
**Decisión:** el **instalador oficial de PostgreSQL** (servicio en 5432,
superusuario postgres/postgres, pgAdmin incluido) + `db/crear_bd.ps1`
como inicializador + venv de Python para la API.
**Por qué:** el espíritu del Artículo 4 (arranque simple y reproducible)
se mantiene sin contenedores: el servicio ya corre con la máquina, el
script es idempotente y pgAdmin llega gratis con el instalador. Quien
tenga Docker puede usar la variante principal del curso — misma API,
misma spec, otra infraestructura.
