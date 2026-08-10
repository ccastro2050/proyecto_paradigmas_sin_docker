"""
Ensamblador — el ÚNICO lugar del sistema que conoce clases concretas.

Tres líneas, sin diccionarios ni DB_PROVIDER: la v1 tiene UN motor y el
código lo dice (YAGNI con dirección). Cuando la v3 agregue MariaDB, SOLO este
archivo se convertirá en la fábrica real — controllers y servicios no se
tocarán: ese será el examen del principio abierto/cerrado.
"""

import os

from repositorios.repositorio_producto_postgresql import (
    RepositorioProductoPostgreSQL,
)
from servicios.abstracciones.i_servicio_producto import IServicioProducto
from servicios.servicio_producto import ServicioProducto


# La cadena de conexión por defecto apunta al PostgreSQL instalado en la
# máquina (puerto estándar 5432) con el usuario y la BD que crea
# db\crear_bd.ps1. Para apuntar a OTRA BD (ej. la de su reconstrucción)
# defina la variable de entorno ANTES de arrancar uvicorn:
#   $env:DB_POSTGRES = "postgresql+asyncpg://paradigmas:paradigmas123@localhost:5432/bdfacturas_mi_v1"
CADENA_POR_DEFECTO = (
    "postgresql+asyncpg://paradigmas:paradigmas123"
    "@localhost:5432/bdfacturas_postgres_local"
)


def crear_servicio_producto() -> IServicioProducto:
    """Arma el servicio con su repositorio (cadena del entorno o default)."""
    # os.environ.get(clave, default) → usa la variable si existe; si no,
    # cae al default (a diferencia de os.environ[clave], que revienta):
    repositorio = RepositorioProductoPostgreSQL(
        os.environ.get("DB_POSTGRES", CADENA_POR_DEFECTO)
    )
    return ServicioProducto(repositorio)
