-- ============================================================
-- SCRIPT 2: USUARIOS, ROLES Y PERFILES - JD REFRIGERACIÓN
-- Ejecutar como: SYS AS SYSDBA
-- Propósito: Seguridad de acceso por rol de negocio
-- Roles del sistema:
--   ADMIN     → Lisandro (gerente/administrador)
--   ASISTENTE → Lucy (ventas y atención al cliente)
-- ============================================================

-- -----------------------------------------------
-- PASO 1: PERFIL DE CONTRASEÑA SEGURA
-- -----------------------------------------------
CREATE PROFILE PERFIL_JD_SEGURO LIMIT
    FAILED_LOGIN_ATTEMPTS   3          -- Bloquea tras 3 intentos fallidos
    PASSWORD_LOCK_TIME      1/24       -- Bloqueo por 1 hora (1/24 de día)
    PASSWORD_LIFE_TIME      90         -- La contraseña vence a los 90 días
    PASSWORD_REUSE_TIME     365        -- No puede reusar contraseña por 1 año
    PASSWORD_REUSE_MAX      5          -- Ni las últimas 5 contraseñas
    PASSWORD_GRACE_TIME     7          -- 7 días de gracia para cambiarla
    SESSIONS_PER_USER       3          -- Máximo 3 sesiones simultáneas
    IDLE_TIME               30         -- Cierra sesión inactiva tras 30 min
    CONNECT_TIME            480;       -- Sesión máxima: 8 horas

-- -----------------------------------------------
-- PASO 2: ROLES DE NEGOCIO
-- -----------------------------------------------

CREATE ROLE ROL_JD_ADMIN;
GRANT CONNECT, RESOURCE    TO ROL_JD_ADMIN;
GRANT CREATE SESSION        TO ROL_JD_ADMIN;
GRANT CREATE TABLE          TO ROL_JD_ADMIN;
GRANT CREATE VIEW           TO ROL_JD_ADMIN;
GRANT CREATE PROCEDURE      TO ROL_JD_ADMIN;
GRANT CREATE TRIGGER        TO ROL_JD_ADMIN;
GRANT CREATE SEQUENCE       TO ROL_JD_ADMIN;

-- Privilegios de objeto: acceso total al esquema jdrefrigeracion
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.ventas                   TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.detalle_ventas           TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.proformas                TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.detalle_proformas        TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.compras                  TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.detalle_compra           TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.clientes                 TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.productos                TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.categorias               TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.proveedores              TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.pagos                    TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.pago_ventas              TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.instalaciones            TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.mantenimientos           TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.notificaciones           TO ROL_JD_ADMIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON jdrefrigeracion.comprobantes_electronicos TO ROL_JD_ADMIN;
GRANT EXECUTE ON jdrefrigeracion.SP_GENERAR_COMPROBANTE                          TO ROL_JD_ADMIN;
GRANT EXECUTE ON jdrefrigeracion.SP_PROGRAMAR_MANTENIMIENTO                      TO ROL_JD_ADMIN;
GRANT EXECUTE ON jdrefrigeracion.FN_VALORIZACION_INVENTARIO                      TO ROL_JD_ADMIN;
GRANT EXECUTE ON jdrefrigeracion.FN_TOTAL_PROFORMA_CLIENTE                       TO ROL_JD_ADMIN;

-- ROL ASISTENTE: acceso operativo de ventas y consulta (para Lucy)
CREATE ROLE ROL_JD_ASISTENTE;
GRANT CONNECT TO ROL_JD_ASISTENTE;
GRANT CREATE SESSION TO ROL_JD_ASISTENTE;

-- Solo puede ver y operar ventas, clientes y cotizaciones — NO anular ni borrar
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.ventas            TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.detalle_ventas    TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.proformas         TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.detalle_proformas TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT         ON jdrefrigeracion.pagos             TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT         ON jdrefrigeracion.pago_ventas       TO ROL_JD_ASISTENTE;
GRANT SELECT, INSERT, UPDATE ON jdrefrigeracion.clientes          TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.productos         TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.categorias        TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.proveedores       TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.notificaciones    TO ROL_JD_ASISTENTE;
GRANT SELECT                 ON jdrefrigeracion.comprobantes_electronicos TO ROL_JD_ASISTENTE;
GRANT EXECUTE ON jdrefrigeracion.SP_GENERAR_COMPROBANTE           TO ROL_JD_ASISTENTE;
GRANT EXECUTE ON jdrefrigeracion.FN_TOTAL_PROFORMA_CLIENTE        TO ROL_JD_ASISTENTE;

-- -----------------------------------------------
-- PASO 3: USUARIOS NOMINALES DEL NEGOCIO
-- -----------------------------------------------

-- LISANDRO: Gerente / Administrador General
CREATE USER lisandro_admin
    IDENTIFIED BY "JDRefri@Admin2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

GRANT ROL_JD_ADMIN TO lisandro_admin;
ALTER USER lisandro_admin QUOTA 10M ON TS_JD_DATA;

-- LUCY: Asistente de Ventas y Atención al Cliente
CREATE USER lucy_ventas
    IDENTIFIED BY "JDRefri@Lucy2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

GRANT ROL_JD_ASISTENTE TO lucy_ventas;
ALTER USER lucy_ventas QUOTA 5M ON TS_JD_DATA;

-- Usuario solo lectura para reportes/análisis
CREATE USER jd_reportes
    IDENTIFIED BY "JDRefri@Report2026"
    DEFAULT   TABLESPACE TS_JD_DATA
    TEMPORARY TABLESPACE TS_JD_TEMP
    PROFILE   PERFIL_JD_SEGURO
    ACCOUNT   UNLOCK;

GRANT CONNECT TO jd_reportes;
GRANT CREATE SESSION TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.ventas       TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.compras      TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.proformas    TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.clientes     TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.productos    TO jd_reportes;
GRANT SELECT ON jdrefrigeracion.pagos        TO jd_reportes;

-- -----------------------------------------------
-- PASO 4: VERIFICACIONES
-- -----------------------------------------------

-- Ver todos los usuarios del proyecto
SELECT username, account_status, default_tablespace, profile, created
FROM   dba_users
WHERE  username IN ('JDREFRIGERACION', 'LISANDRO_ADMIN', 'LUCY_VENTAS', 'JD_REPORTES')
ORDER  BY username;

-- Ver roles creados
SELECT role FROM dba_roles WHERE role LIKE 'ROL_JD%';

-- Ver qué privilegios tiene cada rol
SELECT grantee, granted_role, admin_option
FROM   dba_role_privs
WHERE  grantee IN ('LISANDRO_ADMIN', 'LUCY_VENTAS', 'JD_REPORTES')
ORDER  BY grantee;

-- Ver privilegios de objeto del rol ASISTENTE
SELECT grantee, owner, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee = 'ROL_JD_ASISTENTE'
ORDER  BY table_name, privilege;

-- Ver perfil de seguridad
SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  profile = 'PERFIL_JD_SEGURO'
ORDER  BY resource_name;
