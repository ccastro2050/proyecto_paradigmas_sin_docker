"""
Servicio de producto — la capa de NEGOCIO de la v1.

Recibe POR CONSTRUCTOR la interfaz del repositorio (inversión de
dependencias): no sabe si detrás hay PostgreSQL, un falso en memoria para
pruebas, o el MariaDB que llegará en la v3.

No conoce FastAPI ni HTTP: comunica los problemas con excepciones de negocio
que el controller traduce a códigos (ValueError → 400 · LookupError → 404).
"""

from repositorios.abstracciones.i_repositorio_producto import IRepositorioProducto


class ServicioProducto:
    """Reglas de negocio del CRUD de producto."""

    def __init__(self, repositorio: IRepositorioProducto):
        # Se guarda LA INTERFAZ: cualquier clase que cumpla el Protocol sirve.
        self._repositorio = repositorio

    # ------------------------------------------------------------------
    # Validaciones pequeñas y compartidas
    # ------------------------------------------------------------------

    @staticmethod
    def _validar_codigo(codigo: str) -> str:
        codigo = (codigo or "").strip()
        if not codigo:
            raise ValueError("El código del producto no puede estar vacío.")
        return codigo

    # ------------------------------------------------------------------
    # Operaciones de negocio
    # ------------------------------------------------------------------

    async def listar(self, limite: int) -> list[dict]:
        # El contrato dice 400 (no 422) para límites inválidos:
        # por eso se valida aquí, en negocio, y no en el modelo Pydantic.
        if limite <= 0:
            raise ValueError("El límite debe ser un entero mayor que cero.")
        return await self._repositorio.obtener_todos(limite)

    async def obtener(self, codigo: str) -> dict:
        codigo = self._validar_codigo(codigo)
        fila = await self._repositorio.obtener_por_codigo(codigo)
        if fila is None:
            raise LookupError(f"No existe un producto con codigo = {codigo}")
        return fila

    async def crear(self, datos: dict) -> None:
        # Los datos ya pasaron por Pydantic (tipos y rangos): aquí solo se
        # delega. Si la BD rechaza (PK duplicada), la excepción del motor
        # sube tal cual y el controller la convierte en 500 con el detalle.
        await self._repositorio.crear(datos)

    async def actualizar(self, codigo: str, datos: dict) -> int:
        codigo = self._validar_codigo(codigo)
        if not datos:
            raise ValueError("No se envió ningún campo para actualizar.")
        filas_afectadas = await self._repositorio.actualizar(codigo, datos)
        if filas_afectadas == 0:
            raise LookupError(f"No existe un producto con codigo = {codigo}")
        return filas_afectadas

    async def eliminar(self, codigo: str) -> int:
        codigo = self._validar_codigo(codigo)
        filas_eliminadas = await self._repositorio.eliminar(codigo)
        if filas_eliminadas == 0:
            raise LookupError(f"No existe un producto con codigo = {codigo}")
        return filas_eliminadas
