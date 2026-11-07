[README.md](https://github.com/user-attachments/files/34505425/README.md)
# Proyecto Integrador: GitHub Actions + Docker + Microsoft SQL Server

Automatización del despliegue de una base de datos **Microsoft SQL Server** usando **GitHub Actions** y **Docker**. El proyecto levanta una instancia de SQL Server en un contenedor, crea la base de datos `EmpresaDB` y ejecuta lógica de negocio mediante tablas, un procedimiento almacenado y un trigger. Además, un segundo workflow programado genera un reporte CSV y lo publica como Artifact.

**Autor:** Ari Maximiliano Muñiz Moncada
**Materia:** Ingeniería de Software II — Universidad Politécnica de San Luis Potosí (UPSLP)

---

## Estructura del proyecto

```
proyecto-sqlserver-actions
│
├── .github
│   └── workflows
│       ├── deploy.yml        # Despliegue de SQL Server + ejecución de scripts
│       └── report.yml        # Reporte CSV programado (Artifact)
│
├── sql
│   ├── create_database.sql   # Crea EmpresaDB
│   ├── create_tables.sql     # Ventas, AuditoriaVentas e Inventario
│   ├── create_procedure.sql  # sp_RegistrarAuditoria
│   ├── create_trigger.sql    # trg_AuditarVenta (por conjuntos)
│   └── test_data.sql         # Datos de prueba y consultas de verificación
│
└── README.md
```

## Tecnologías utilizadas

| Tecnología | Uso en el proyecto |
|---|---|
| GitHub Actions | Automatiza el despliegue y el reporte programado |
| Docker | Ejecuta SQL Server en un contenedor dentro del runner |
| Microsoft SQL Server 2022 | Motor de base de datos (imagen oficial de Microsoft) |
| T-SQL | Tablas, procedimiento almacenado y trigger |
| sqlcmd | Cliente de línea de comandos para ejecutar los scripts |
| GitHub Secrets | Manejo seguro de la contraseña del usuario `sa` |

## Configuración del Secret

La contraseña de SQL Server **no está escrita en el código**. Se guarda como Secret del repositorio:

1. Ir a **Settings → Secrets and variables → Actions**.
2. Clic en **New repository secret**.
3. Nombre: `MSSQL_SA_PASSWORD`.
4. Valor: la contraseña del usuario `sa` (debe cumplir la política de complejidad de SQL Server).

Los workflows la leen con `${{ secrets.MSSQL_SA_PASSWORD }}`.

## Variables de entorno

```yaml
env:
  ACCEPT_EULA: Y
  MSSQL_PID: Developer
  SA_PASSWORD: ${{ secrets.MSSQL_SA_PASSWORD }}
```

## Modelo de datos

- **Ventas**: `VentaID` (PK, identity), `Producto`, `Cantidad`, `Fecha`.
- **AuditoriaVentas**: `AuditoriaID` (PK, identity), `VentaID`, `FechaRegistro`, `Mensaje`.
- **Inventario** (reto avanzado): `Producto` (PK), `Existencias`.

## Lógica de negocio

### Trigger `trg_AuditarVenta`

Se ejecuta `AFTER INSERT` sobre `Ventas`. Está implementado **por conjuntos (set-based)**: lee la tabla lógica `inserted`, que contiene todas las filas insertadas en la operación, y registra la auditoría de todas ellas con una sola sentencia `INSERT ... SELECT`. De esta forma funciona correctamente con inserciones múltiples.

> La versión original asignaba `VentaID` a una variable escalar (`SELECT @VentaID = VentaID FROM inserted`), por lo que, ante un `INSERT` de varias filas, solo se auditaba una de ellas.

### Procedimiento `sp_RegistrarAuditoria`

Recibe un `@VentaID`, registra el mensaje de auditoría y descuenta del `Inventario` las existencias del producto vendido.

### Inventario (reto avanzado)

Cada venta descuenta automáticamente sus unidades del inventario. Con los datos de prueba (inventario inicial de 50 Laptops y 80 Monitores):

| Producto | Inicial | Vendido | Existencias finales |
|---|---|---|---|
| Laptop | 50 | 3 + 1 + 4 = 8 | 42 |
| Monitor | 80 | 5 + 2 = 7 | 73 |

## Workflows

### 1. `deploy.yml` — Deploy SQL Server

**Se ejecuta con:** `push` a `main` o manualmente (`workflow_dispatch`).

Pasos:
1. Descarga el repositorio (`actions/checkout`).
2. Inicia un contenedor Docker con SQL Server 2022 y monta la carpeta `sql/`.
3. Espera a que SQL Server acepte conexiones.
4. Ejecuta en orden los scripts: `create_database`, `create_tables`, `create_procedure`, `create_trigger` y `test_data`.

Si algún script falla, el workflow termina con error.

### 2. `report.yml` — Reporte CSV programado

**Se ejecuta con:** cron diario (12:00 UTC) o manualmente (`workflow_dispatch`).

Pasos:
1. Levanta SQL Server y carga la base de datos (el contenedor es efímero).
2. Consulta las ventas junto con su auditoría y exporta el resultado a `reporte_ventas.csv`.
3. Publica el archivo como **Artifact** (`reporte-ventas`) con `actions/upload-artifact`.

**Para descargarlo:** Actions → Reporte CSV programado → seleccionar una ejecución → sección **Artifacts**.

## Cómo ejecutar el proyecto

1. Crear el Secret `MSSQL_SA_PASSWORD` (ver sección de configuración).
2. Hacer `push` a la rama `main`: el workflow **Deploy SQL Server** se ejecuta automáticamente.
3. Para el reporte, ir a **Actions → Reporte CSV programado → Run workflow**.
4. Revisar los resultados en el log del paso **Ejecutar scripts SQL** y descargar el Artifact generado.

## Resultados esperados

Tras ejecutar `test_data.sql`:

- `Ventas`: 5 registros.
- `AuditoriaVentas`: 5 registros (uno por venta, incluidas las 3 insertadas en un solo `INSERT`).
- `Inventario`: Laptop = 42, Monitor = 73.

## Reto principal: conceptos clave

- **Tabla lógica `inserted`**: tabla temporal que SQL Server crea dentro de un trigger con las filas nuevas de la operación. Puede contener cero, una o muchas filas.
- **Procesamiento por conjuntos (set-based)**: una sola sentencia opera sobre todas las filas a la vez, y el motor optimiza el plan completo.
- **Fila a fila vs. por conjunto**: los cursores y ciclos ejecutan una operación por fila (más lentos y con más bloqueos); las operaciones por conjunto son más cortas, más rápidas y escalan mejor.

## Referencia

Repositorio de referencia del curso: <https://github.com/jesusrevilla/T41A-P16>
