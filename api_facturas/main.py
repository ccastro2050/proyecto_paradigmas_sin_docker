"""
Punto de entrada de la API Facturas v1.

Crea la aplicación FastAPI, registra el router de producto y expone el
endpoint de diagnóstico. Swagger queda en /docs y ReDoc en /redoc
(los defaults de FastAPI).

Arranque:  uvicorn main:app --port 8002 --reload   (con el venv activo)
Conexión:  por defecto va al PostgreSQL local (ver servicios/ensamblador.py);
           la variable de entorno DB_POSTGRES la puede sobreescribir.
"""

from fastapi import FastAPI

from controllers.producto_controller import router as router_producto

app = FastAPI(
    title="API Facturas",
    version="v1",
    description="CRUD de producto contra PostgreSQL — versión 1 del proyecto.",
)

# Un router por entidad: la v2 agregará aquí persona, factura, etc.
app.include_router(router_producto)


@app.get("/", tags=["Diagnóstico"])
async def diagnostico():
    """Confirma que la API está en línea (usable como healthcheck)."""
    return {"mensaje": "API Facturas funcionando", "version": "v1",
            "documentacion": "/docs"}
