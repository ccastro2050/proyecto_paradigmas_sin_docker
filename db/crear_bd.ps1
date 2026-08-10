# ==============================================================
# crear_bd.ps1 — crea la base de datos bdfacturas en el
# PostgreSQL instalado en Windows.
#
# En las salas, PostgreSQL está instalado con el instalador
# oficial: corre como SERVICIO de Windows (arranca solo con la
# máquina) en el puerto 5432, con el superusuario `postgres`
# (clave: postgres). Este script hace lo que en otros entornos
# hace un inicializador: crea el usuario del curso, crea la BD
# y ejecuta el script provisto db/init.sql (las 12 tablas con
# sus triggers, procedimientos y datos).
#
# Es IDEMPOTENTE: correrlo mil veces no daña nada — si la BD ya
# existe, no hace nada.
#
# Uso (desde la raíz del proyecto):
#   .\db\crear_bd.ps1
#
# Para crear una BD con OTRO nombre (por ejemplo la de SU
# reconstrucción de la guía de IA):
#   .\db\crear_bd.ps1 -NombreBd bdfacturas_mi_v1
#
# Si su PostgreSQL escucha en otro puerto:
#   .\db\crear_bd.ps1 -Puerto 5433
# ==============================================================

# param() declara los parámetros del script, con sus defaults:
param(
    [string]$NombreBd = "bdfacturas_postgres_local",
    [int]$Puerto = 5432
)

# --- Encontrar psql (el cliente de línea de comandos de PostgreSQL) ---
# El instalador lo deja en C:\Program Files\PostgreSQL\<versión>\bin
# pero NO lo agrega al PATH. Se busca la versión más nueva instalada:
$carpetaPg = "C:\Program Files\PostgreSQL"
if (-not (Test-Path $carpetaPg)) {
    Write-Host "[crear_bd] ERROR: no se encontró $carpetaPg"
    Write-Host "[crear_bd] ¿PostgreSQL está instalado (instalador oficial)?"
    exit 1
}
$version = Get-ChildItem $carpetaPg -Directory | Sort-Object { [int]$_.Name } -Descending | Select-Object -First 1
$psql = Join-Path $version.FullName "bin\psql.exe"
Write-Host "[crear_bd] Usando PostgreSQL $($version.Name) ($psql)"

# --- Credenciales del superusuario ---
# psql pide la clave por teclado; la variable PGPASSWORD se la entrega
# sin preguntar (la clave estándar de las salas es "postgres"):
$env:PGPASSWORD = "postgres"
# Y esta otra variable le dice a psql que los archivos .sql están en
# UTF-8 — SIN ella, la consola de Windows los lee con otra codificación
# y las tildes de los datos se guardan dañadas:
$env:PGCLIENTENCODING = "UTF8"

Write-Host "[crear_bd] Verificando que PostgreSQL responda en el puerto $Puerto..."
& $psql -h localhost -p $Puerto -U postgres -d postgres -c "SELECT 1" *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[crear_bd] ERROR: PostgreSQL no responde en localhost:$Puerto."
    Write-Host "[crear_bd] Verifique el servicio (services.msc → postgresql) y la clave."
    exit 1
}

Write-Host "[crear_bd] Asegurando el usuario del curso (paradigmas)..."
# La API NO se conecta como postgres: usa el usuario del curso, igual
# que en producción se usa un usuario con permisos limitados a SU base.
# El bloque DO lo crea solo si no existe (idempotente):
& $psql -h localhost -p $Puerto -U postgres -d postgres -c "DO `$`$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'paradigmas') THEN CREATE ROLE paradigmas LOGIN PASSWORD 'paradigmas123'; END IF; END `$`$;"

Write-Host "[crear_bd] Verificando si la base de datos $NombreBd existe..."
# -t -A = salida limpia (solo el valor, sin encabezados ni bordes):
$existe = & $psql -h localhost -p $Puerto -U postgres -d postgres -t -A -c "SELECT COUNT(*) FROM pg_database WHERE datname = '$NombreBd'"

if ("$existe".Trim() -eq "1") {
    Write-Host "[crear_bd] La base de datos $NombreBd ya existe. No se hace nada."
    exit 0
}

Write-Host "[crear_bd] Creando la base de datos $NombreBd (dueño: paradigmas)..."
& $psql -h localhost -p $Puerto -U postgres -d postgres -c "CREATE DATABASE $NombreBd OWNER paradigmas"

Write-Host "[crear_bd] Ejecutando init.sql (12 tablas, triggers, SPs y datos)..."
# $PSScriptRoot = la carpeta donde vive ESTE script (db\).
# Se ejecuta COMO paradigmas (-U paradigmas): así todas las tablas
# quedan de su propiedad y la API no tendrá problemas de permisos.
$script = Join-Path $PSScriptRoot "init.sql"
$env:PGPASSWORD = "paradigmas123"
& $psql -h localhost -p $Puerto -U paradigmas -d $NombreBd -v ON_ERROR_STOP=1 -f $script
if ($LASTEXITCODE -ne 0) {
    Write-Host "[crear_bd] ERROR ejecutando init.sql."
    exit 1
}

Write-Host "[crear_bd] Listo: $NombreBd creada con sus 12 tablas y datos de ejemplo."
