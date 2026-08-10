"""
Contrato del repositorio de producto — la abstracción de la capa de datos.

Un Protocol define QUÉ métodos debe tener un repositorio de producto, sin
decir CÓMO ni CONTRA QUÉ motor. Cualquier clase con estos 5 métodos cumple el
contrato SIN heredar (tipado estructural, PEP 544): el PostgreSQL real de la
v1, el falso en memoria de las pruebas, o el MariaDB que llegará en la v3.

El servicio depende de ESTA interfaz, nunca de una clase concreta
(inversión de dependencias — la D de SOLID).
"""

from typing import Protocol


class IRepositorioProducto(Protocol):
    """Las 5 operaciones de datos de la entidad producto."""

    async def obtener_todos(self, limite: int) -> list[dict]:
        """Devuelve hasta `limite` productos ordenados por código."""
        ...

    async def obtener_por_codigo(self, codigo: str) -> dict | None:
        """Devuelve el producto con ese código, o None si no existe."""
        ...

    async def crear(self, datos: dict) -> bool:
        """Inserta un producto. Devuelve True si quedó insertado."""
        ...

    async def actualizar(self, codigo: str, datos: dict) -> int:
        """Escribe los campos de `datos` (los usan PUT y PATCH).

        Devuelve el número de filas afectadas (0 = el código no existe).
        """
        ...

    async def eliminar(self, codigo: str) -> int:
        """Elimina el producto. Devuelve filas eliminadas (0 = no existía)."""
        ...
