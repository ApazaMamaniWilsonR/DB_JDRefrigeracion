# Base de Datos Empresarial — ERP JD Refrigeración S.A.C.
## Administración de Base de Datos II (Oracle Database 21c XE)

Repositorio oficial con los modelos relacionales, scripts de despliegue, esquemas particionados, políticas de seguridad y auditoría, y reportes técnicos para el sistema ERP de **JD Refrigeración S.A.C.**

---

## 👥 Integrantes del Proyecto
* **Apaza Mamani Wilson Ronald**
* **Magaño Quispe Aron Rodrigo**
* **Chambi Sirena Yoel Wagner**

---

## 📂 Estructura del Repositorio

```text
DB_JDRefrigeracion/
├── README.md                                          # Guía maestra de implementación paso a paso
├── BD_AdminII_Unidad2_JDRefrigeracion.md              # Informe formal con capturas de la Evaluación Unidad 2
├── BD_Implementacion_JDRefrigeracion.md               # Documentación técnica de la Unidad 1 (Modelo Relacional)
├── INFORME_PARTICIONAMIENTO_JD_REFRIGERACION.md       # Informe técnico de Particionamiento (Semana 6)
├── image.png ... image-25.png                         # Evidencias gráficas integradas al informe
│
├── scripts/
│   ├── 01_setup_inicial/
│   │   ├── 01_Admin_Local.sql                         # Creación de usuario jdrefrigeracion y privilegios desde SYS
│   │   └── 02_JD_Refrigeracion.sql                   # Modelo base (15 tablas, triggers, procedures y datos)
│   ├── 02_particionamiento/
│   │   └── 01_Particionamiento_JD_Refrigeracion.sql   # Tablas particionadas (VENTAS, PROFORMAS, COMPRAS)
│   └── 03_unidad_2_administracion/
│       ├── 01_Admin_Local_unidad_2.sql                # Tablespaces, cuotas, roles, perfiles, auditoría y AWR
│       └── 02_JD_Refrigeracion_unidad_2.sql           # Actividad transaccional y consultas de carga AWR
│
├── Admin_Local.sql                                    # Copia raíz de setup inicial
├── JD_Refrigeracion.sql                               # Copia raíz del modelo base
├── Admin_Local unidad 2.sql                           # Copia raíz de administración Unidad 2
├── JD_Refrigeracion unidad 2.sql                      # Copia raíz de carga Unidad 2
├── PARTICIONAMIENTO_JD_Refrigeracion.sql              # Copia raíz de particionamiento
├── JDRefrigeracion_modelo.architect                   # Modelo conceptual/lógico en SQL Power Architect
└── JDRefrigeracion.json                               # Configuración exportada de conexiones SQL Developer
```

---

## ⚙️ Guía de Implementación Paso a Paso en un PC Nuevo

Siga rigurosamente este orden para desplegar el proyecto desde cero en cualquier computadora con **Oracle Database 21c Express Edition** y **Oracle SQL Developer**.

---

### Paso 1: Configurar las Conexiones en Oracle SQL Developer

Abra Oracle SQL Developer y cree las dos conexiones base del proyecto:

#### 1. Conexión Administrativa (`Admin_Local`):
* **Nombre de Conexión:** `Admin_Local`
* **Usuario:** `sys`
* **Rol:** `SYSDBA`
* **Contraseña:** *(La contraseña configurada durante la instalación de Oracle XE)*
* **Tipo de Conexión:** Básico
* **Nombre de Host:** `localhost`
* **Puerto:** `1521`
* **Nombre del Servicio:** `XEPDB1` *(Importante: debe apuntar al PDB, no a la raíz CDB)*

#### 2. Conexión de Esquema (`JD_Refrigeracion`):
* **Nombre de Conexión:** `JD_Refrigeracion`
* **Usuario:** `jdrefrigeracion`
* **Contraseña:** `123456`
* **Rol:** `Valor por Defecto`
* **Nombre de Host:** `localhost`
* **Puerto:** `1521`
* **Nombre del Servicio:** `XEPDB1`

> 💡 *Nota:* Si prefiere importar automáticamente las conexiones, puede utilizar el archivo `JDRefrigeracion.json` desde el menú de conexiones de SQL Developer.

---

### Paso 2: Ejecutar Setup Inicial del Usuario Propietario
* **Conexión:** `Admin_Local` (`SYS AS SYSDBA`)
* **Script:** `scripts/01_setup_inicial/01_Admin_Local.sql` (o `Admin_Local.sql`)

Este script fija la sesión en el contenedor `XEPDB1`, crea el usuario `jdrefrigeracion` con contraseña `123456`, le asigna cuota sobre `USERS` y le otorga los roles `CONNECT`, `RESOURCE`, `DBA` y permisos de creación de objetos.

```sql
-- Ejecutar en Admin_Local:
@scripts/01_setup_inicial/01_Admin_Local.sql
```

---

### Paso 3: Desplegar el Esquema Relacional Base
* **Conexión:** `JD_Refrigeracion`
* **Script:** `scripts/01_setup_inicial/02_JD_Refrigeracion.sql` (o `JD_Refrigeracion.sql`)

Crea las tablas maestras, transaccionales, constraints, procedures (`SP_GENERAR_COMPROBANTE`, `SP_PROGRAMAR_MANTENIMIENTO`), funciones (`FN_VALORIZACION_INVENTARIO`), triggers de stock e inserta la población de datos inicial.

---

### Paso 4: Implementar Particionamiento de Tablas
* **Conexión:** `JD_Refrigeracion`
* **Script:** `scripts/02_particionamiento/01_Particionamiento_JD_Refrigeracion.sql` (o `PARTICIONAMIENTO_JD_Refrigeracion.sql`)

Reestructura las 3 tablas de mayor volumen del negocio aplicando las 3 estrategias de particionamiento de Oracle:
1. **`VENTAS`:** `PARTITION BY RANGE (fecha)` — Separación anual contable (`2025`, `2026`, `2027` y `MAXVALUE`).
2. **`PROFORMAS`:** `PARTITION BY LIST (estado)` — Separación por ciclo comercial (`BORRADOR`, `ENVIADA`, `APROBADA`, etc.).
3. **`COMPRAS`:** `PARTITION BY HASH (id)` — 4 particiones balanceadas de E/S.

---

### Paso 5: Administrar Tablespaces, Seguridad, Auditoría y AWR
* **Conexión:** `Admin_Local` (`SYS AS SYSDBA`)
* **Script:** `scripts/03_unidad_2_administracion/01_Admin_Local_unidad_2.sql` (o `Admin_Local unidad 2.sql`)

> ⚠️ **Antes de ejecutar en un PC nuevo:**  
> Compruebe la ruta física donde Oracle almacena sus datafiles ejecutando:  
> `SELECT name FROM v$datafile FETCH FIRST 1 ROWS ONLY;`  
> Si su ruta difiere de `C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\`, ajuste las rutas en las sentencias `CREATE TABLESPACE` antes de correr el script.

Este script ejecuta:
1. **Tablespaces:** Crea `TS_JD_DATA` (50M), `TS_JD_INDICES` (30M), `TS_JD_MAESTROS` (20M) y `TS_JD_TEMP` (20M), y reasigna el tablespace por defecto de `jdrefrigeracion`.
2. **Seguridad (RBAC):** Crea el perfil `PERFIL_JD_SEGURO`, los roles `ROL_JD_ADMIN` y `ROL_JD_ASISTENTE`, y los usuarios nominales `lisandro_admin`, `lucy_ventas` y `jd_reportes`.
3. **Auditoría Unificada:** Crea y habilita 5 políticas (`POL_JD_SESIONES`, `POL_JD_VENTAS`, `POL_JD_PAGOS`, `POL_JD_MAESTROS`, `POL_JD_DDL`).
4. **AWR:** Configura retención e intervalo en el repositorio y genera el snapshot inicial.

---

### Paso 6: Generar Carga y Validar Auditoría y AWR
* **Conexión:** `JD_Refrigeracion`
* **Script:** `scripts/03_unidad_2_administracion/02_JD_Refrigeracion_unidad_2.sql` (o `JD_Refrigeracion unidad 2.sql`)

Inserta una transacción de venta que dispara la política de auditoría y ejecuta consultas analíticas pesadas simulando la carga del ERP.  
Posteriormente, regrese a `Admin_Local` para tomar el snapshot final y consultar el Audit Trail (`UNIFIED_AUDIT_TRAIL`) y el AWR (`DBA_HIST_SNAPSHOT`).

---

## 🔒 Matriz de Usuarios y Roles del Sistema

| Usuario | Contraseña | Rol Asignado | Tablespace | Propósito |
|---|---|---|---|---|
| `jdrefrigeracion` | `123456` | `DBA` (Esquema) | `TS_JD_DATA` | Dueño de tablas, triggers y lógica del negocio |
| `lisandro_admin` | `JDRefri@Admin2026` | `ROL_JD_ADMIN` | `TS_JD_DATA` | Gerente: Acceso total DDL/DML y administración financiera |
| `lucy_ventas` | `JDRefri@Lucy2026` | `ROL_JD_ASISTENTE` | `TS_JD_DATA` | Ventas: Operación de cotizaciones y pagos (sin permiso `DELETE`) |
| `jd_reportes` | `JDRefri@Report2026` | Solo lectura | `TS_JD_DATA` | Auditoría externa y Business Intelligence |

---

## 🛠️ Preguntas Frecuentes y Solución de Problemas

### 1. Error `ORA-01017: invalid username/password; logon denied`
* Verifique que la conexión se realice hacia el servicio **`XEPDB1`** y no al contenedor raíz `XE`.
* En `Admin_Local`, ejecute `ALTER USER jdrefrigeracion ACCOUNT UNLOCK;`.

### 2. Mensaje "Diagnostic Pack Necesario" al abrir AWR en SQL Developer
* En SQL Developer vaya a: **Herramientas ➔ Preferencias ➔ Base de Datos ➔ Licencias**.
* Busque la conexión `Admin_Local` y seleccione **"Diagnostic Pack"**.
* Haga clic en **Aceptar** y vuelva a abrir el visor de instantáneas.

### 3. Error `ORA-00904: "AUDITING_OPTION": invalid identifier`
* La columna `auditing_option` no pertenece a `audit_unified_enabled_policies`. En su lugar use las columnas estándar `success, failure` (ya corregidas en los scripts de la carpeta `scripts/`).

---

## 📄 Documentación y Reportes PDF

Para visualizar o exportar el informe técnico completo de la Unidad 2 con todas las capturas integradas:
1. Abra [`BD_AdminII_Unidad2_JDRefrigeracion.md`](./BD_AdminII_Unidad2_JDRefrigeracion.md) en VS Code.
2. Presione `Ctrl + Shift + P`.
3. Seleccione `Markdown PDF: Export (pdf)`.
