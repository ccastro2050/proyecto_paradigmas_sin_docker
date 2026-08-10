"""
Modelos Pydantic de la entidad producto — la FRONTERA DE ENTRADA de la API.

Aquí no hay ni un solo `if` de validación: se DECLARA la forma correcta de los
datos (tipos, obligatoriedad, restricciones) y Pydantic valida al construir el
objeto. Un body inválido muere en 422 antes de tocar el servicio o la BD.

Hay UN modelo por semántica HTTP (ver 6_contracts.md):
- Producto           → POST : el recurso completo, con su código.
- ProductoReemplazo  → PUT  : reemplazo completo (el código va en la URL).
- ProductoActualizar → PATCH: parcial, todos los campos opcionales.
"""

from decimal import Decimal

from pydantic import BaseModel, Field


class Producto(BaseModel):
    """POST /api/producto — todos los campos son obligatorios."""

    codigo: str = Field(min_length=1, max_length=20)
    nombre: str = Field(min_length=1)
    stock: int = Field(ge=0)            # ge = greater or equal: stock >= 0
    valorunitario: Decimal = Field(ge=0)


class ProductoReemplazo(BaseModel):
    """PUT /api/producto/{codigo} — reemplazo COMPLETO: todos obligatorios.

    Omitir un campo es 422, no "dejarlo como estaba": esa es la semántica de PUT.
    """

    nombre: str = Field(min_length=1)
    stock: int = Field(ge=0)
    valorunitario: Decimal = Field(ge=0)


class ProductoActualizar(BaseModel):
    """PATCH /api/producto/{codigo} — parcial: solo se modifican los enviados."""

    nombre: str | None = Field(default=None, min_length=1)
    stock: int | None = Field(default=None, ge=0)
    valorunitario: Decimal | None = Field(default=None, ge=0)
