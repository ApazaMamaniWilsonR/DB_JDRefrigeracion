-- ============================================================
-- SCRIPT 3: AUDITORÍA UNIFICADA - JD REFRIGERACIÓN
-- Ejecutar como: SYS AS SYSDBA (en XEPDB1)
-- Propósito: Registrar accesos y cambios críticos sobre
--            las tablas transaccionales del sistema
-- ============================================================

-- -----------------------------------------------
-- PASO 1: VERIFICAR QUE AUDITORÍA ESTÉ ACTIVA
-- -----------------------------------------------
-- Oracle 21c XE usa Unified Auditing por defecto
-- Verificamos que esté habilitada:
SELECT value FROM v$option WHERE parameter = 'Unified Auditing';

-- Si devuelve TRUE, procedemos. Si es FALSE, requiere recompilar Oracle.

-- -----------------------------------------------
-- PASO 2: POLÍTICA DE AUDITORÍA DE SESIONES
-- Registra todos los intentos de login fallidos y exitosos
-- -----------------------------------------------
CREATE AUDIT POLICY POL_JD_SESIONES
    ACTIONS
        LOGON, LOGOFF
    WHEN 'SYS_CONTEXT(''USERENV'',''DB_NAME'') IS NOT NULL'
    EVALUATE PER SESSION;

AUDIT POLICY POL_JD_SESIONES;

-- -----------------------------------------------
-- PASO 3: POLÍTICA DE AUDITORÍA SOBRE VENTAS
-- Registra toda inserción, modificación y anulación de ventas
-- -----------------------------------------------
CREATE AUDIT POLICY POL_JD_VENTAS
    ACTIONS
        INSERT ON jdrefrigeracion.ventas,
        UPDATE ON jdrefrigeracion.ventas,
        DELETE ON jdrefrigeracion.ventas,
        INSERT ON jdrefrigeracion.detalle_ventas,
        DELETE ON jdrefrigeracion.detalle_ventas;

AUDIT POLICY POL_JD_VENTAS;

-- -----------------------------------------------
-- PASO 4: POLÍTICA DE AUDITORÍA SOBRE PAGOS
-- Crítica para detectar fraude o manipulación financiera
-- -----------------------------------------------
CREATE AUDIT POLICY POL_JD_PAGOS
    ACTIONS
        INSERT ON jdrefrigeracion.pagos,
        UPDATE ON jdrefrigeracion.pagos,
        DELETE ON jdrefrigeracion.pagos,
        INSERT ON jdrefrigeracion.pago_ventas,
        DELETE ON jdrefrigeracion.pago_ventas;

AUDIT POLICY POL_JD_PAGOS;

-- -----------------------------------------------
-- PASO 5: POLÍTICA DE AUDITORÍA SOBRE DATOS MAESTROS
-- Registra cambios en catálogo de productos y clientes
-- -----------------------------------------------
CREATE AUDIT POLICY POL_JD_MAESTROS
    ACTIONS
        INSERT ON jdrefrigeracion.clientes,
        UPDATE ON jdrefrigeracion.clientes,
        DELETE ON jdrefrigeracion.clientes,
        INSERT ON jdrefrigeracion.productos,
        UPDATE ON jdrefrigeracion.productos,
        DELETE ON jdrefrigeracion.productos,
        INSERT ON jdrefrigeracion.proveedores,
        UPDATE ON jdrefrigeracion.proveedores,
        DELETE ON jdrefrigeracion.proveedores;

AUDIT POLICY POL_JD_MAESTROS;

-- -----------------------------------------------
-- PASO 6: POLÍTICA DE AUDITORÍA DE ACCIONES DDL
-- Detecta si alguien intenta modificar la estructura del esquema
-- -----------------------------------------------
CREATE AUDIT POLICY POL_JD_DDL
    ACTIONS
        CREATE TABLE,
        DROP TABLE,
        ALTER TABLE,
        CREATE INDEX,
        DROP INDEX,
        TRUNCATE TABLE;

AUDIT POLICY POL_JD_DDL;

-- -----------------------------------------------
-- PASO 7: GENERAR ACTIVIDAD PARA EVIDENCIAR AUDITORÍA
-- (Ejecutar estas operaciones para que aparezcan en el trail)
-- -----------------------------------------------

-- Simular acceso con usuario lisandro_admin
-- (Esto lo ejecutas tú desde una sesión de lisandro_admin)
-- INSERT INTO jdrefrigeracion.ventas ... (ya realizado antes)

-- Intentar un acceso fallido (para que quede registrado):
-- Desde SQL Developer, intentar conectarse con contraseña incorrecta
-- a lisandro_admin para generar el registro de FAILED LOGON

-- -----------------------------------------------
-- PASO 8: CONSULTAS AL UNIFIED AUDIT TRAIL
-- -----------------------------------------------

-- Ver todas las políticas de auditoría activas
SELECT policy_name, enabled_option, entity_name, entity_type, success, failure
FROM   audit_unified_enabled_policies
WHERE  policy_name LIKE 'POL_JD%'
ORDER  BY policy_name;

-- Ver definición de las políticas creadas
SELECT policy_name, audit_option, object_schema, object_name, audit_option_type
FROM   audit_unified_policies
WHERE  policy_name LIKE 'POL_JD%'
ORDER  BY policy_name, object_name;

-- Ver registro de auditoría (últimas 50 acciones del esquema)
SELECT dbusername,
       action_name,
       object_schema,
       object_name,
       unified_audit_policies,
       event_timestamp,
       return_code
FROM   unified_audit_trail
WHERE  object_schema = 'JDREFRIGERACION'
   OR  unified_audit_policies LIKE '%POL_JD%'
ORDER  BY event_timestamp DESC
FETCH FIRST 50 ROWS ONLY;

-- Ver intentos de LOGIN fallidos (return_code <> 0)
SELECT dbusername,
       action_name,
       unified_audit_policies,
       event_timestamp,
       return_code,
       os_username,
       userhost
FROM   unified_audit_trail
WHERE  unified_audit_policies LIKE '%POL_JD_SESIONES%'
  AND  return_code != 0
ORDER  BY event_timestamp DESC;

-- Resumen de actividad por usuario
SELECT dbusername,
       action_name,
       object_name,
       COUNT(*) AS total_operaciones
FROM   unified_audit_trail
WHERE  object_schema = 'JDREFRIGERACION'
   OR  unified_audit_policies LIKE '%POL_JD%'
GROUP  BY dbusername, action_name, object_name
ORDER  BY total_operaciones DESC;

-- -----------------------------------------------
-- PASO 9 (OPCIONAL): LIMPIAR EL TRAIL PARA DEMO
-- -----------------------------------------------
-- Solo si necesitas empezar con un trail limpio antes de grabar capturas:
-- EXEC DBMS_AUDIT_MGMT.CLEAN_AUDIT_TRAIL(2, FALSE, SYSDATE - 0);
