# Quickstart — API Facturas **v1**: producto + PostgreSQL

> **Versión 1** · Validación rápida de la v1 ya construida. Si aún no hay nada,
> empiece por [8_tasks.md](8_tasks.md).

---

## 1. Arrancar TODO

Prerrequisitos (una sola vez por máquina): PostgreSQL instalado
(servicio en 5432, superusuario `postgres`/`postgres`), Python 3.12+, y
la preparación del proyecto:

```powershell
# desde la raíz del proyecto (terminal integrada de VS Code):
.\db\crear_bd.ps1                                  # crea la BD (idempotente)
python -m venv .venv                               # el entorno virtual
.\.venv\Scripts\Activate.ps1
pip install -r api_facturas\requirements.txt       # las dependencias
```

Y el arranque (cada día — queda corriendo, se detiene con Ctrl+C):

```powershell
.\.venv\Scripts\Activate.ps1
cd api_facturas
uvicorn main:app --port 8002 --reload
```

## 3. Smoke test (los 6 criterios de aceptación, en orden)

```powershell
# 1. Diagnóstico y documentación
curl http://localhost:8002/                      # {"mensaje":"API Facturas funcionando","version":"v1",...}
# abrir http://localhost:8002/docs en el navegador

# 2. Listar — los 8 productos, y el query string en acción
curl http://localhost:8002/api/producto                      # total: 8
curl "http://localhost:8002/api/producto?limite=3"           # total: 3

# 3. Obtener uno / inexistente (parámetro de ruta)
curl http://localhost:8002/api/producto/PR001    # 200 Laptop Lenovo
curl -i http://localhost:8002/api/producto/PR999 # 404

# 4. Ciclo con los 5 verbos
curl -X POST http://localhost:8002/api/producto -H "Content-Type: application/json" `
     -d '{\"codigo\":\"PR009\",\"nombre\":\"Webcam Logitech\",\"stock\":5,\"valorunitario\":120000}'
curl -X PUT  http://localhost:8002/api/producto/PR009 -H "Content-Type: application/json" `
     -d '{\"nombre\":\"Webcam Logitech C920\",\"stock\":10,\"valorunitario\":150000}'   # reemplazo COMPLETO
curl -X PATCH http://localhost:8002/api/producto/PR009 -H "Content-Type: application/json" `
     -d '{\"stock\":7}'                                       # parcial: solo el stock
curl http://localhost:8002/api/producto/PR009    # nombre C920, stock = 7
curl -X DELETE http://localhost:8002/api/producto/PR009
curl -i -X DELETE http://localhost:8002/api/producto/PR009   # 404 (ya no existe)

# 4b. La diferencia PUT vs PATCH — el MISMO body, distinto veredicto
curl -i -X PUT   http://localhost:8002/api/producto/PR001 -H "Content-Type: application/json" `
     -d '{\"stock\":99}'    # 422: a PUT le faltan nombre y valorunitario
curl -i -X PATCH http://localhost:8002/api/producto/PR001 -H "Content-Type: application/json" `
     -d '{\"stock\":17}'    # 200: PATCH acepta el subconjunto

# 5. Pydantic como frontera — nunca llega a la BD
curl -i -X POST http://localhost:8002/api/producto -H "Content-Type: application/json" `
     -d '{\"codigo\":\"PRX\",\"nombre\":\"Test\",\"stock\":-5,\"valorunitario\":100}'   # 422
curl -i -X POST http://localhost:8002/api/producto -H "Content-Type: application/json" `
     -d '{\"codigo\":\"PR001\",\"nombre\":\"Duplicado\",\"stock\":1,\"valorunitario\":1}' # 500 (PK duplicada)
```

**6. Prueba de capas** (sin PostgreSQL): un script que instancie
`ServicioProducto` con un repositorio falso en memoria que cumpla
`IRepositorioProducto` y verifique crear/listar/eliminar — si funciona, las
capas quedaron bien cortadas ([8_tasks.md](8_tasks.md) Fase 4).

## 4. Si algo falla

| Síntoma | Causa probable |
|---|---|
| `KeyError: 'DB_POSTGRES'` al arrancar | Falta la variable de entorno (§2) |
| 500 en todos los endpoints | PostgreSQL apagado o cadena mal apuntada |
| 204 donde esperaba los 8 productos | La tabla está vacía: borre la BD (`DROP DATABASE` en pgAdmin) y re-corra `.\db\crear_bd.ps1` |
| 422 inesperado en POST/PUT | El body no cumple el modelo Pydantic — leer el `detail` de la respuesta, dice exactamente qué campo |
| El código nuevo no se refleja | `--reload` no está activo o el archivo no se guardó |
