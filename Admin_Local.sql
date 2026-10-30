-- ==============================================================
-- SCRIPT: Admin_Local.sql
-- Propósito: Setup Inicial del Esquema jdrefrigeracion en un PC nuevo
-- Ejecutar como: SYS AS SYSDBA
-- Conexión en SQL Developer: Admin_Local (Service: XEPDB1)
-- ==============================================================

SET SERVEROUTPUT ON;

-- 1. Fijar sesión en el Pluggable Database XEPDB1
ALTER SESSION SET CONTAINER = XEPDB1;

-- 2. Crear usuario si no existe, o resetear credenciales
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'JDREFRIGERACION';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER jdrefrigeracion IDENTIFIED BY 123456 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP QUOTA UNLIMITED ON USERS';
        DBMS_OUTPUT.PUT_LINE('Usuario JDREFRIGERACION creado exitosamente.');
    ELSE
        EXECUTE IMMEDIATE 'ALTER USER jdrefrigeracion IDENTIFIED BY 123456 ACCOUNT UNLOCK';
        DBMS_OUTPUT.PUT_LINE('Usuario JDREFRIGERACION actualizado.');
    END IF;
END;
/

-- 3. Privilegios de desarrollo y administración básica del esquema
GRANT CONNECT, RESOURCE, DBA TO jdrefrigeracion;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE TO jdrefrigeracion;
ALTER USER jdrefrigeracion QUOTA UNLIMITED ON USERS;

-- 4. Verificación
SELECT username, account_status, default_tablespace, temporary_tablespace, created
FROM   dba_users
WHERE  username = 'JDREFRIGERACION';
