-- ==============================================================
-- SCRIPT: 01_Admin_Local_unidad_2.sql
-- Propósito: Administración Empresarial - Evaluación Unidad 2
-- Ejecutar como: SYS AS SYSDBA
-- Conexión en SQL Developer: Admin_Local (Service: XEPDB1)
-- ==============================================================

-- --------------------------------------------------------------
-- 1. CREACIÓN DE TABLESPACES EMPRESARIALES
-- --------------------------------------------------------------
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

-- Verificación de Tablespaces
SELECT tablespace_name, status, contents, extent_management, allocation_type
FROM   dba_tablespaces
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;

-- Verificación de Datafiles
SELECT file_name, tablespace_name,
       ROUND(bytes/1024/1024, 0)    AS size_mb,
       autoextensible,
       ROUND(maxbytes/1024/1024, 0) AS max_mb
FROM   dba_data_files
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;

-- Asignación de Cuotas y Reasignación de Default Tablespace
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_DATA;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_INDICES;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_MAESTROS;
ALTER USER jdrefrigeracion QUOTA 0         ON USERS;
ALTER USER jdrefrigeracion
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP;

SELECT username, default_tablespace, temporary_tablespace, profile
FROM   dba_users
WHERE  username = 'JDREFRIGERACION';

-- --------------------------------------------------------------
-- 2. PERFIL DE SEGURIDAD, ROLES Y USUARIOS NOMINALES
-- --------------------------------------------------------------
CREATE PROFILE PERFIL_JD_SEGURO LIMIT
    FAILED_LOGIN_ATTEMPTS   3
    PASSWORD_LOCK_TIME      1/24
    PASSWORD_LIFE_TIME      90
    PASSWORD_REUSE_TIME     365
    PASSWORD_REUSE_MAX      5
    PASSWORD_GRACE_TIME     7
    SESSIONS_PER_USER       3
    IDLE_TIME               30
    CONNECT_TIME            480;

SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  profile = 'PERFIL_JD_SEGURO'
ORDER  BY resource_name;

-- Creación de Roles de Negocio
CREATE ROLE ROL_JD_ADMIN;
CREATE ROLE ROL_JD_ASISTENTE;

SELECT role FROM dba_roles
WHERE  role LIKE 'ROL_JD%'
ORDER  BY role;

-- Creación de Usuarios Nominales
CREATE USER lisandro_admin
    IDENTIFIED BY "JDRefri@Admin2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

CREATE USER lucy_ventas
    IDENTIFIED BY "JDRefri@Lucy2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

CREATE USER jd_reportes
    IDENTIFIED BY "JDRefri@Report2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

SELECT username, account_status, default_tablespace, profile
FROM   dba_users
WHERE  username IN ('LISANDRO_ADMIN','LUCY_VENTAS','JD_REPORTES')
ORDER  BY username;

-- Asignación de Roles a Usuarios
GRANT CONNECT, RESOURCE TO ROL_JD_ADMIN;
GRANT CONNECT           TO ROL_JD_ASISTENTE;

GRANT ROL_JD_ADMIN     TO lisandro_admin;
GRANT ROL_JD_ASISTENTE TO lucy_ventas;

GRANT CONNECT          TO jd_reportes;
GRANT CREATE SESSION   TO jd_reportes;

SELECT grantee, granted_role, admin_option
FROM   dba_role_privs
WHERE  grantee IN ('LISANDRO_ADMIN','LUCY_VENTAS')
ORDER  BY grantee;

-- Privilegios de Objeto Granulares para el Rol ASISTENTE
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.ventas            TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.proformas         TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.clientes          TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT         ON jdrefrigeracion.pagos             TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT         ON jdrefrigeracion.pago_ventas       TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.productos         TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.categorias        TO ROL_JD_ASISTENTE;
GRANT EXECUTE ON jdrefrigeracion.SP_GENERAR_COMPROBANTE           TO ROL_JD_ASISTENTE;

SELECT grantee, owner, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee = 'ROL_JD_ASISTENTE'
ORDER  BY table_name, privilege;

-- --------------------------------------------------------------
-- 3. AUDITORÍA UNIFICADA (ORACLE UNIFIED AUDITING)
-- --------------------------------------------------------------
CREATE AUDIT POLICY POL_JD_SESIONES
    ACTIONS LOGON, LOGOFF;
AUDIT POLICY POL_JD_SESIONES;

CREATE AUDIT POLICY POL_JD_VENTAS
    ACTIONS
        INSERT ON jdrefrigeracion.ventas,
        UPDATE ON jdrefrigeracion.ventas,
        DELETE ON jdrefrigeracion.ventas;
AUDIT POLICY POL_JD_VENTAS;

CREATE AUDIT POLICY POL_JD_PAGOS
    ACTIONS
        INSERT ON jdrefrigeracion.pagos,
        UPDATE ON jdrefrigeracion.pagos,
        DELETE ON jdrefrigeracion.pagos;
AUDIT POLICY POL_JD_PAGOS;

CREATE AUDIT POLICY POL_JD_MAESTROS
    ACTIONS
        INSERT ON jdrefrigeracion.clientes,
        UPDATE ON jdrefrigeracion.clientes,
        DELETE ON jdrefrigeracion.clientes,
        INSERT ON jdrefrigeracion.productos,
        UPDATE ON jdrefrigeracion.productos,
        DELETE ON jdrefrigeracion.productos;
AUDIT POLICY POL_JD_MAESTROS;

CREATE AUDIT POLICY POL_JD_DDL
    ACTIONS CREATE TABLE, DROP TABLE, ALTER TABLE, TRUNCATE TABLE;
AUDIT POLICY POL_JD_DDL;

-- Verificación de Políticas Habilitadas
SELECT policy_name, enabled_option, entity_name, entity_type, success, failure
FROM   audit_unified_enabled_policies
WHERE  policy_name LIKE 'POL_JD%'
ORDER  BY policy_name;

-- Consulta al Audit Trail
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

-- --------------------------------------------------------------
-- 4. REPOSITORIO AUTOMÁTICO DE CARGA DE TRABAJO (AWR)
-- --------------------------------------------------------------
SELECT value FROM v$parameter
WHERE  name = 'control_management_pack_access';

-- Configuración de Retención e Intervalo
EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(
    retention => 43200,   -- 30 días
    interval  => 30       -- 30 minutos
);

SELECT snap_interval, retention FROM dba_hist_wr_control;

-- Snapshot Inicial (Antes de Carga)
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

SELECT snap_id,
       TO_CHAR(begin_interval_time,'DD/MM/YYYY HH24:MI:SS') AS inicio,
       TO_CHAR(end_interval_time,  'DD/MM/YYYY HH24:MI:SS') AS fin
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 5 ROWS ONLY;

-- Snapshot Final (Después de Carga)
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

SELECT snap_id,
       TO_CHAR(begin_interval_time,'DD/MM/YYYY HH24:MI:SS') AS inicio,
       TO_CHAR(end_interval_time,  'DD/MM/YYYY HH24:MI:SS') AS fin,
       snap_level
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 10 ROWS ONLY;
