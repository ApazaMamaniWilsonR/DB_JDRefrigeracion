-- ============================================================
-- SCRIPT 1: TABLESPACES - JD REFRIGERACIÓN
-- Ejecutar como: SYS AS SYSDBA
-- Propósito: Crear almacenamiento físico separado por tipo de dato
-- ============================================================

-- Tablespace para datos transaccionales (VENTAS, COMPRAS, PROFORMAS, PAGOS)
CREATE TABLESPACE TS_JD_DATA
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_data01.dbf'
    SIZE 50M
    AUTOEXTEND ON NEXT 10M MAXSIZE 500M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

-- Tablespace para índices y constraints
CREATE TABLESPACE TS_JD_INDICES
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_indices01.dbf'
    SIZE 30M
    AUTOEXTEND ON NEXT 5M MAXSIZE 200M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

-- Tablespace para datos maestros (CLIENTES, PRODUCTOS, PROVEEDORES, CATEGORIAS)
CREATE TABLESPACE TS_JD_MAESTROS
    DATAFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_maestros01.dbf'
    SIZE 20M
    AUTOEXTEND ON NEXT 5M MAXSIZE 100M
    EXTENT MANAGEMENT LOCAL AUTOALLOCATE
    SEGMENT SPACE MANAGEMENT AUTO;

-- Tablespace temporal para operaciones de ordenamiento y hash joins
CREATE TEMPORARY TABLESPACE TS_JD_TEMP
    TEMPFILE 'C:\APP\WIGETTA\PRODUCT\21C\ORADATA\XE\XEPDB1\jd_temp01.dbf'
    SIZE 20M
    AUTOEXTEND ON NEXT 5M MAXSIZE 100M;

-- Verificar tablespaces creados
SELECT tablespace_name, status, contents, extent_management, allocation_type
FROM   dba_tablespaces
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;

-- Ver archivos físicos asociados
SELECT file_name, tablespace_name, bytes/1024/1024 AS size_mb, autoextensible
FROM   dba_data_files
WHERE  tablespace_name LIKE 'TS_JD%'
ORDER  BY tablespace_name;

-- Asignar cuotas al usuario propietario del esquema
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_DATA;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_INDICES;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON TS_JD_MAESTROS;
ALTER USER jdrefrigeracion QUOTA 0         ON USERS;

-- Cambiar tablespace por defecto y temporal del usuario
ALTER USER jdrefrigeracion
    DEFAULT TABLESPACE   TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP;

-- Verificar configuración del usuario
SELECT username, default_tablespace, temporary_tablespace, profile
FROM   dba_users
WHERE  username = 'JDREFRIGERACION';
