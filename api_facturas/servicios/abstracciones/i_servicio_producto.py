"""
Contrato del servicio de producto — la abstracción de la capa de negocio.

El controller depende de esta interfaz: no sabe (ni debe saber) qué hay
detrás. Los métodos lanzan excepciones de NEGOCIO que el controller traduce
a códigos HTTP: ValueError → 400 · LookupError → 404 · cualquier otra → 500.
"""

from typing import Protocol


class IServicioProducto(Protocol):
    """Las operaciones de negocio sobre productos."""

    async def listar(self, limite: int) -> list[dict]:
        """Hasta `limite` productos. ValueError si limite <= 0."""
        ...

    async def obtener(self, codigo: str) -> dict:
        """El producto con ese código. LookupError si no existe."""
        ...

    async def crear(self, datos: dict) -> None:
        """Crea el producto (los datos ya vienen validados por Pydantic)."""
        ...

    async def actualizar(self, codigo: str, datos: dict) -> int:
        """Escribe los campos enviados (PUT manda todos, PATCH un subconjunto).

        ValueError si no llegó ningún campo · LookupError si el código no
        existe · devuelve las filas afectadas.
        """
        ...

    async def eliminar(self, codigo: str) -> int:
        """Elimina. LookupError si no existe · devuelve filas eliminadas."""
        ...
