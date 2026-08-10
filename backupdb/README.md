# backupdb — respaldos de la base de datos

En esta carpeta se guardan los **respaldos (backups)** de `bdfacturas`.
En PostgreSQL el respaldo clásico es un **dump**: un archivo `.sql` con
los `CREATE TABLE` y los `INSERT` de todo lo que hay — texto plano que
se puede abrir y leer.

> ¿En qué se diferencia de `db/init.sql`? En que ese script crea la BD
> en su **estado inicial** (los datos de fábrica del curso), mientras que
> un backup captura **SU estado actual**: lo que usted insertó, editó o
> borró. Si solo quiere volver al estado inicial, no necesita backup:
> borre la BD y re-corra `.\db\crear_bd.ps1`.

Convención de nombres: `bdfacturas_postgres_AAAA-MM-DD.sql` (si hace
varios el mismo día, agregue un sufijo: `_2.sql`).

> Los comandos usan la ruta del PostgreSQL instalado —
> `C:\Program Files\PostgreSQL\18\bin` — **ajuste el número de versión**
> al que tenga su máquina (el instalador no agrega estas herramientas al
> PATH). Y las dos variables de entorno de la primera línea evitan que
> psql pregunte la clave y que la consola dañe las tildes.

---

## Cómo hacer un backup

Desde la **raíz del repositorio**:

```powershell
$env:PGPASSWORD = "paradigmas123"; $env:PGCLIENTENCODING = "UTF8"
& "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -h localhost -U paradigmas -d bdfacturas_postgres_local --clean --if-exists -f "$PWD\backupdb\bdfacturas_postgres_2026-08-09.sql"
```

Qué hace cada pieza:

- `pg_dump -U paradigmas` — el respaldador de PostgreSQL, entrando con
  el usuario del curso (dueño de la BD).
- `--clean --if-exists` — el dump incluye los `DROP` previos: así el
  restore puede ejecutarse SOBRE la BD existente sin chocar con lo que
  ya hay.
- `-f ...` — escribe directo al archivo. `$PWD` es la carpeta actual —
  por eso se corre desde la raíz del repo.

## Cómo restaurar un backup (restore)

El camino inverso: ejecutar el dump sobre la BD (los `DROP` del
`--clean` limpian primero y luego se recrea todo):

```powershell
$env:PGPASSWORD = "paradigmas123"; $env:PGCLIENTENCODING = "UTF8"
& "C:\Program Files\PostgreSQL\18\bin\psql.exe" -h localhost -U paradigmas -d bdfacturas_postgres_local -q -f "$PWD\backupdb\bdfacturas_postgres_2026-08-09.sql"
```

Verifique: `http://localhost:8002/api/producto` (con la API corriendo)
debe mostrar los datos tal como estaban cuando hizo el backup.

## Para probar el ciclo completo (ejercicio)

1. Haga un backup (arriba).
2. Cambie algo a propósito: cree un producto `PR999` con la API (POST
   desde Swagger, `/docs`) o edite el stock de uno existente.
3. Restaure el backup.
4. `PR999` desapareció (o el stock volvió) — la BD regresó EXACTAMENTE
   al momento del backup. Eso es un respaldo funcionando.

> ⚠️ El restore pisa el contenido actual de la BD con el del archivo.
> Lo que haya cambiado DESPUÉS del backup se pierde. Por eso los
> respaldos se hacen ANTES de operaciones riesgosas (y en producción,
> con agenda).
