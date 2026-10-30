# GUÍA DE CAPTURAS — Evaluación Unidad 2
## Administración de Base de Datos II — JD Refrigeración
### Temas: Tablespaces · Usuarios/Roles · Auditoría · AWR

> **Cómo usar esta guía:**
> 1. Conéctate a Oracle SQL Developer como **SYS AS SYSDBA**
> 2. Ejecuta el bloque SQL de cada paso
> 3. Toma la captura indicada
> 4. Págame las imágenes y genero el informe final en HTML/PDF

---

## 🗂️ SECCIÓN 1 — TABLESPACES (`S2_01_tablespaces.sql`)

### Captura 1 — Creación de Tablespaces

Ejecuta hasta la línea `CREATE TEMPORARY TABLESPACE TS_JD_TEMP...` inclusive.

```sql
CREATE TABLESPACE TS_JD_DATA
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_data01.dbf'
    SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE TS_JD_INDICES
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_indices01.dbf'
    SIZE 30M AUTOEXTEND ON NEXT 5M MAXSIZE 200M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

CREATE TABLESPACE TS_JD_MAESTROS
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_maestros01.dbf'
    SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE 100M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

CREATE TEMPORARY TABLESPACE TS_JD_TEMP
    TEMPFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_temp01.dbf'
    SIZE 20M AUTOEXTEND ON NEXT 5M MAXSIZE 100M;
```

> ✅ **Ruta confirmada:** `C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\` — ya está aplicada en los scripts.

📸 **Tomar captura de:** La pestaña "Salida de Script" mostrando los 4 mensajes `Tablespace created.`

---

### Captura 2 — Verificación de Tablespaces en el Diccionario

```sql
SELECT tablespace_name, status, contents, extent_management, allocation_type
FROM   dba_tablespaces
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;
```

📸 **Tomar captura de:** La cuadrícula de resultados mostrando los 4 tablespaces con status `ONLINE`.

---

### Captura 3 — Archivos Físicos (Datafiles)

```sql
SELECT file_name, tablespace_name,
       ROUND(bytes/1024/1024, 0) AS size_mb,
       autoextensible,
       ROUND(maxbytes/1024/1024, 0) AS max_mb
FROM   dba_data_files
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;
```

📸 **Tomar captura de:** La cuadrícula con los archivos `.dbf`, sus tamaños y `AUTOEXTENSIBLE = YES`.

---

### Captura 4 — Cuotas y Tablespace del Usuario

```sql
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_DATA;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_INDICES;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_MAESTROS;
ALTER USER jdrefrigeracion DEFAULT TABLESPACE TS_JD_DATA
                           TEMPORARY TABLESPACE TS_JD_TEMP;

SELECT username, default_tablespace, temporary_tablespace, profile
FROM   dba_users
WHERE  username = 'JDREFRIGERACION';
```

📸 **Tomar captura de:** La fila del usuario `JDREFRIGERACION` con `DEFAULT_TABLESPACE = TS_JD_DATA`.

---

## 👤 SECCIÓN 2 — USUARIOS Y ROLES (`S2_02_usuarios_roles.sql`)

### Captura 5 — Creación del Perfil de Seguridad

```sql
CREATE PROFILE PERFIL_JD_SEGURO LIMIT
    FAILED_LOGIN_ATTEMPTS  3
    PASSWORD_LOCK_TIME     1/24
    PASSWORD_LIFE_TIME     90
    PASSWORD_REUSE_TIME    365
    PASSWORD_REUSE_MAX     5
    PASSWORD_GRACE_TIME    7
    SESSIONS_PER_USER      3
    IDLE_TIME              30
    CONNECT_TIME           480;

SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  profile = 'PERFIL_JD_SEGURO'
ORDER  BY resource_name;
```

📸 **Tomar captura de:** La cuadrícula con el perfil y todos sus parámetros de seguridad.

---

### Captura 6 — Creación de Roles del Negocio

```sql
CREATE ROLE ROL_JD_ADMIN;
CREATE ROLE ROL_JD_ASISTENTE;

SELECT role FROM dba_roles WHERE role LIKE 'ROL_JD%' ORDER BY role;
```

📸 **Tomar captura de:** Los 3 roles listados (`ROL_JD_ADMIN`, `ROL_JD_ALMACEN`, `ROL_JD_ASISTENTE`).

---

### Captura 7 — Creación de Usuarios Nominales

```sql
CREATE USER lisandro_admin
    IDENTIFIED BY "JDRefri@Admin2026"
    DEFAULT TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE PERFIL_JD_SEGURO ACCOUNT UNLOCK;

CREATE USER lucy_ventas
    IDENTIFIED BY "JDRefri@Lucy2026"
    DEFAULT TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE PERFIL_JD_SEGURO ACCOUNT UNLOCK;

CREATE USER jd_reportes
    IDENTIFIED BY "JDRefri@Report2026"
    DEFAULT TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE PERFIL_JD_SEGURO ACCOUNT UNLOCK;

SELECT username, account_status, default_tablespace, profile
FROM   dba_users
WHERE  username IN ('LISANDRO_ADMIN','LUCY_VENTAS','JD_REPORTES')
ORDER  BY username;
```

📸 **Tomar captura de:** Los 3 usuarios con `ACCOUNT_STATUS = OPEN` y `PROFILE = PERFIL_JD_SEGURO`.

---

### Captura 8 — Asignación de Roles a Usuarios

```sql
GRANT ROL_JD_ADMIN     TO lisandro_admin;
GRANT ROL_JD_ASISTENTE TO lucy_ventas;
GRANT CONNECT          TO jd_reportes;

SELECT grantee, granted_role, admin_option, default_role
FROM   dba_role_privs
WHERE  grantee IN ('LISANDRO_ADMIN','LUCY_VENTAS','JD_REPORTES')
ORDER  BY grantee;
```

📸 **Tomar captura de:** La cuadrícula mostrando qué rol tiene cada usuario.

---

### Captura 9 — Privilegios de Objeto del Rol ASISTENTE

```sql
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.ventas         TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.proformas      TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.clientes       TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT         ON jdrefrigeracion.pagos          TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.productos      TO ROL_JD_ASISTENTE;

SELECT grantee, owner, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee = 'ROL_JD_ASISTENTE'
ORDER  BY table_name, privilege;
```

📸 **Tomar captura de:** Tabla de privilegios diferenciados por tabla (INSERT/UPDATE vs solo SELECT).

---

## 🔍 SECCIÓN 3 — AUDITORÍA (`S2_03_auditoria.sql`)

### Captura 10 — Creación de Políticas de Auditoría

```sql
CREATE AUDIT POLICY POL_JD_SESIONES
    ACTIONS LOGON, LOGOFF;
AUDIT POLICY POL_JD_SESIONES;

CREATE AUDIT POLICY POL_JD_VENTAS
    ACTIONS INSERT ON jdrefrigeracion.ventas,
            UPDATE ON jdrefrigeracion.ventas,
            DELETE ON jdrefrigeracion.ventas;
AUDIT POLICY POL_JD_VENTAS;

CREATE AUDIT POLICY POL_JD_PAGOS
    ACTIONS INSERT ON jdrefrigeracion.pagos,
            UPDATE ON jdrefrigeracion.pagos,
            DELETE ON jdrefrigeracion.pagos;
AUDIT POLICY POL_JD_PAGOS;

CREATE AUDIT POLICY POL_JD_MAESTROS
    ACTIONS INSERT ON jdrefrigeracion.clientes,
            UPDATE ON jdrefrigeracion.clientes,
            DELETE ON jdrefrigeracion.clientes,
            INSERT ON jdrefrigeracion.productos,
            UPDATE ON jdrefrigeracion.productos,
            DELETE ON jdrefrigeracion.productos;
AUDIT POLICY POL_JD_MAESTROS;

CREATE AUDIT POLICY POL_JD_DDL
    ACTIONS CREATE TABLE, DROP TABLE, ALTER TABLE, TRUNCATE TABLE;
AUDIT POLICY POL_JD_DDL;
```

📸 **Tomar captura de:** La pestaña "Salida de Script" con los mensajes `Audit Policy created.` y `Audit Policy altered.` para las 5 políticas.

---

### Captura 11 — Políticas Activas en el Diccionario

```sql
SELECT policy_name, enabled_option, entity_name, entity_type, success, failure
FROM   audit_unified_enabled_policies
WHERE  policy_name LIKE 'POL_JD%'
ORDER  BY policy_name;
```

📸 **Tomar captura de:** La cuadrícula con las 5 políticas en estado activo.

---

### Captura 12 — Registro de Actividad en el Audit Trail

Primero genera actividad auditada ejecutando desde una sesión normal (`jdrefrigeracion`):
```sql
-- Haz un INSERT y UPDATE en ventas (cualquier fila de prueba)
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id,
    subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (SYSTIMESTAMP, 'REGISTRADA', 'PEN', 3.75, 1, 100, 0, 18, 118, 118, 31.47, 'CONTADO', 'PAGADO', 0);
COMMIT;
```

Luego, vuelve a la sesión SYS y consulta:
```sql
SELECT dbusername,
       action_name,
       object_schema,
       object_name,
       unified_audit_policies,
       event_timestamp,
       return_code
FROM   unified_audit_trail
WHERE  object_schema = 'JDREFRIGERACION'
ORDER  BY event_timestamp DESC
FETCH FIRST 20 ROWS ONLY;
```

📸 **Tomar captura de:** El Audit Trail con los eventos registrados (usuario, acción, tabla, timestamp).

---

## 📊 SECCIÓN 4 — AWR (`S2_04_awr.sql`)

### Captura 13 — Verificación y Configuración de AWR

```sql
SELECT value FROM v$parameter WHERE name = 'control_management_pack_access';

EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(
    retention => 43200,
    interval  => 30
);

SELECT snap_interval, retention FROM dba_hist_wr_control;
```

📸 **Tomar captura de:** El resultado mostrando el intervalo y retención configurados para AWR.

---

### Captura 14 — Snapshot Inicial (Antes de la carga)

```sql
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

SELECT snap_id,
       TO_CHAR(begin_interval_time, 'DD/MM/YYYY HH24:MI:SS') AS inicio,
       TO_CHAR(end_interval_time,   'DD/MM/YYYY HH24:MI:SS') AS fin
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 5 ROWS ONLY;
```

📸 **Tomar captura de:** La lista con el nuevo snapshot creado (el más reciente arriba).

---

### Captura 15 — Carga de Trabajo (Consultas analíticas)

Ejecuta este bloque de consultas (simula el trabajo diario del negocio):

```sql
SELECT EXTRACT(YEAR FROM fecha) AS anio, EXTRACT(MONTH FROM fecha) AS mes,
       COUNT(*) AS total_ventas, SUM(total_soles) AS monto_total
FROM   jdrefrigeracion.ventas
GROUP  BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER  BY anio, mes;

SELECT c.nombre_comercial, COUNT(v.id) AS ventas,
       SUM(v.total_soles) AS facturacion
FROM   jdrefrigeracion.ventas v
JOIN   jdrefrigeracion.clientes c ON v.cliente_id = c.id
GROUP  BY c.nombre_comercial ORDER BY facturacion DESC;

SELECT jdrefrigeracion.FN_VALORIZACION_INVENTARIO() AS valor_inventario FROM DUAL;

SELECT COUNT(*), SUM(total_soles)
FROM   jdrefrigeracion.ventas PARTITION (p_ventas_2026);
```

📸 **Tomar captura de:** Los resultados de cualquiera de las consultas analíticas ejecutadas (preferiblemente la de ventas por año/mes).

---

### Captura 16 — Snapshot Final y Lista de Snapshots

```sql
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

SELECT snap_id,
       TO_CHAR(begin_interval_time, 'DD/MM/YYYY HH24:MI:SS') AS inicio,
       TO_CHAR(end_interval_time,   'DD/MM/YYYY HH24:MI:SS') AS fin,
       snap_level
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 10 ROWS ONLY;
```

📸 **Tomar captura de:** Los 2 snapshots creados (inicio y fin) visibles en la lista.

---

### Captura 17 — Reporte AWR desde SQL Developer (Visual)

Genera el reporte AWR de forma gráfica desde SQL Developer:

1. En SQL Developer ve a **Ver → DBA**
2. Panel lateral DBA → Expande tu conexión SYS
3. Ve a **Performance → AWR → Snapshots**
4. Selecciona el snapshot de **inicio** y el de **fin** (los 2 que tomaste)
5. Clic derecho → **Generate Report...**
6. Formato: **HTML** → Guarda en tu carpeta del proyecto

📸 **Tomar captura de:** La pantalla de SQL Developer mostrando los snapshots seleccionados o el reporte AWR abierto en el navegador.

---

## ✅ RESUMEN — Checklist de Capturas

| # | Sección | ¿Lista? |
|---|---|:---:|
| 1 | Creación de 4 Tablespaces (salida de script) | ⬜ |
| 2 | `DBA_TABLESPACES` — 4 tablespaces ONLINE | ⬜ |
| 3 | `DBA_DATA_FILES` — archivos .dbf con autoextend | ⬜ |
| 4 | Usuario `JDREFRIGERACION` con nuevo tablespace | ⬜ |
| 5 | Perfil `PERFIL_JD_SEGURO` con sus límites | ⬜ |
| 6 | 3 roles `ROL_JD_*` creados | ⬜ |
| 7 | 3 usuarios nominales con estado OPEN | ⬜ |
| 8 | Asignación de roles a usuarios | ⬜ |
| 9 | Privilegios diferenciados del rol ASISTENTE | ⬜ |
| 10 | 5 políticas de auditoría creadas (salida script) | ⬜ |
| 11 | Políticas activas en `AUDIT_UNIFIED_ENABLED_POLICIES` | ⬜ |
| 12 | Registros en `UNIFIED_AUDIT_TRAIL` | ⬜ |
| 13 | Configuración AWR (intervalo y retención) | ⬜ |
| 14 | Snapshot inicial creado | ⬜ |
| 15 | Consultas analíticas ejecutadas (carga de trabajo) | ⬜ |
| 16 | Snapshot final y lista de 2 snapshots | ⬜ |
| 17 | Reporte AWR en SQL Developer o navegador | ⬜ |

---

> 📌 **Cuando tengas todas las capturas, tráelas aquí al chat y genero el informe HTML completo listo para PDF.**
