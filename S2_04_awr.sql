-- ============================================================
-- SCRIPT 4: AWR (Automatic Workload Repository) - JD REFRIGERACIÓN
-- Ejecutar como: SYS AS SYSDBA
-- Propósito: Demostrar diagnóstico de rendimiento profesional
--            con snapshots antes y después de una carga de trabajo
-- ============================================================

-- -----------------------------------------------
-- PASO 1: VERIFICAR QUE AWR ESTÉ DISPONIBLE
-- -----------------------------------------------
-- AWR requiere la licencia de Oracle Diagnostics Pack
-- En Oracle XE 21c viene habilitado por defecto

SELECT version FROM v$instance;
SELECT value FROM v$parameter WHERE name = 'control_management_pack_access';
-- Si dice 'DIAGNOSTIC+TUNING' → AWR disponible ✓

-- Ver intervalo y retención actuales del AWR
SELECT snap_interval, retention
FROM   dba_hist_wr_control;

-- -----------------------------------------------
-- PASO 2: CONFIGURAR AWR PARA LA DEMO
-- Intervalos cortos para poder tomar snapshots rápidamente
-- -----------------------------------------------
EXEC DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(
    retention => 43200,   -- Retener 30 días en minutos (30 * 24 * 60)
    interval  => 30       -- Tomar snapshot automático cada 30 min
);

-- Verificar el cambio
SELECT snap_interval, retention FROM dba_hist_wr_control;

-- -----------------------------------------------
-- PASO 3: SNAPSHOT INICIAL (ANTES DE LA CARGA)
-- Registra el estado base del sistema
-- -----------------------------------------------
-- Tomar el primer snapshot manualmente
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

-- Guardar el ID del snapshot inicial
SELECT snap_id, begin_interval_time, end_interval_time, instance_number
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 5 ROWS ONLY;

-- Anotar el último snap_id (ese es tu SNAP_INICIO)

-- -----------------------------------------------
-- PASO 4: SIMULAR CARGA DE TRABAJO
-- Ejecutar las transacciones reales de JD Refrigeración
-- (Consultas analíticas, inserciones, procedures)
-- -----------------------------------------------

-- Consulta analítica de ventas por período (simula reporte gerencial)
SELECT EXTRACT(YEAR FROM fecha)  AS anio,
       EXTRACT(MONTH FROM fecha) AS mes,
       COUNT(*)                  AS total_ventas,
       SUM(total_soles)          AS monto_total_soles,
       SUM(total_dolares)        AS monto_total_dolares,
       AVG(total_soles)          AS ticket_promedio_soles
FROM   jdrefrigeracion.ventas
GROUP  BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER  BY anio, mes;

-- Consulta de cuentas por cobrar vigentes (ventas a crédito pendientes)
SELECT v.id             AS id_venta,
       c.nombre_comercial,
       v.fecha,
       v.total_soles,
       v.saldo_pendiente,
       v.fecha_vcto_credito,
       CASE WHEN v.fecha_vcto_credito < SYSDATE THEN 'VENCIDA' ELSE 'VIGENTE' END AS estado_credito
FROM   jdrefrigeracion.ventas  v
JOIN   jdrefrigeracion.clientes c ON v.cliente_id = c.id
WHERE  v.estado_pago IN ('PENDIENTE', 'PARCIAL')
ORDER  BY v.fecha_vcto_credito;

-- Valorización de inventario (llama a la función)
SELECT jdrefrigeracion.FN_VALORIZACION_INVENTARIO() AS valor_inventario_soles FROM DUAL;

-- Productos con stock crítico (debajo del mínimo)
SELECT p.nombre, p.stock, p.stock_minimo, c.nombre AS categoria,
       (p.stock_minimo - p.stock) AS unidades_faltantes
FROM   jdrefrigeracion.productos  p
JOIN   jdrefrigeracion.categorias c ON p.categoria_id = c.id
WHERE  p.stock <= p.stock_minimo AND p.activo = 1
ORDER  BY unidades_faltantes DESC;

-- Proformas activas (pendientes de respuesta del cliente)
SELECT pr.numero_proforma, c.nombre_comercial, pr.fecha,
       pr.fecha_vencimiento, pr.total_soles, pr.estado
FROM   jdrefrigeracion.proformas pr
JOIN   jdrefrigeracion.clientes  c  ON pr.cliente_id = c.id
WHERE  pr.estado = 'ENVIADA'
ORDER  BY pr.fecha_vencimiento;

-- Top 5 clientes por facturación total (Pareto)
SELECT c.nombre_comercial,
       COUNT(v.id)             AS total_ventas,
       SUM(v.total_soles)      AS facturacion_total,
       ROUND(SUM(v.total_soles) * 100 /
             (SELECT SUM(total_soles) FROM jdrefrigeracion.ventas), 2) AS porcentaje
FROM   jdrefrigeracion.ventas   v
JOIN   jdrefrigeracion.clientes c ON v.cliente_id = c.id
GROUP  BY c.nombre_comercial
ORDER  BY facturacion_total DESC
FETCH FIRST 5 ROWS ONLY;

-- Usar partition pruning en consulta de ventas del año 2026
SELECT COUNT(*), SUM(total_soles)
FROM   jdrefrigeracion.ventas PARTITION (p_ventas_2026)
WHERE  tipo_pago = 'CONTADO';

-- -----------------------------------------------
-- PASO 5: SNAPSHOT FINAL (DESPUÉS DE LA CARGA)
-- -----------------------------------------------
EXEC DBMS_WORKLOAD_REPOSITORY.CREATE_SNAPSHOT();

-- Ver los últimos snapshots tomados
SELECT snap_id,
       TO_CHAR(begin_interval_time, 'DD/MM/YYYY HH24:MI:SS') AS inicio,
       TO_CHAR(end_interval_time,   'DD/MM/YYYY HH24:MI:SS') AS fin
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 10 ROWS ONLY;

-- -----------------------------------------------
-- PASO 6: GENERAR EL REPORTE AWR EN HTML
-- (Reemplaza 0 con tu dbid, y los snap_ids reales)
-- -----------------------------------------------

-- Primero obtén el DBID de tu instancia:
SELECT dbid, db_name FROM v$database;

-- Luego obtén los snap_ids inicio y fin:
-- snap_id_inicio = el penúltimo (antes de la carga)
-- snap_id_fin    = el último    (después de la carga)

-- Genera el reporte HTML (resultado en cola de salida DBMS_OUTPUT):
-- OJO: Ajusta :dbid, :snap_inicio y :snap_fin con los valores reales

SELECT output
FROM   TABLE(
           DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(
               l_dbid    => (SELECT dbid FROM v$database),
               l_inst_num => 1,
               l_bid     => (SELECT MIN(snap_id) FROM (
                                 SELECT snap_id FROM dba_hist_snapshot
                                 ORDER BY snap_id DESC
                                 FETCH FIRST 2 ROWS ONLY)),
               l_eid     => (SELECT MAX(snap_id) FROM dba_hist_snapshot)
           )
       );

-- -----------------------------------------------
-- PASO 7: CONSULTAS DE ANÁLISIS AWR (para sustentar)
-- -----------------------------------------------

-- Top SQL por tiempo de CPU entre los snapshots
SELECT sql_id,
       ROUND(cpu_time_delta/1000000, 2)     AS cpu_segundos,
       ROUND(elapsed_time_delta/1000000, 2) AS tiempo_total_seg,
       executions_delta                      AS ejecuciones,
       ROUND(buffer_gets_delta / NULLIF(executions_delta,0), 0) AS gets_por_ejecucion,
       sql_text
FROM   dba_hist_sqlstat s
JOIN   dba_hist_sqltext  t USING (sql_id)
WHERE  snap_id IN (
           SELECT MAX(snap_id) FROM dba_hist_snapshot
       )
  AND  cpu_time_delta > 0
ORDER  BY cpu_time_delta DESC
FETCH FIRST 10 ROWS ONLY;

-- Estadísticas de sistema entre los 2 últimos snapshots
SELECT stat_name,
       value AS valor_acumulado
FROM   dba_hist_sysstat
WHERE  snap_id = (SELECT MAX(snap_id) FROM dba_hist_snapshot)
  AND  stat_name IN (
           'physical reads',
           'logical reads',
           'db block gets',
           'consistent gets',
           'user commits',
           'user rollbacks',
           'parse count (hard)',
           'execute count'
       )
ORDER  BY stat_name;

-- Historial de snapshots disponibles
SELECT snap_id,
       TO_CHAR(begin_interval_time, 'DD/MM/YYYY HH24:MI') AS inicio,
       TO_CHAR(end_interval_time,   'DD/MM/YYYY HH24:MI') AS fin,
       snap_level
FROM   dba_hist_snapshot
ORDER  BY snap_id DESC
FETCH FIRST 20 ROWS ONLY;

-- -----------------------------------------------
-- INSTRUCCIONES PARA OBTENER EL REPORTE AWR
-- desde SQL Developer de forma visual:
-- -----------------------------------------------
-- 1. Conectarse como SYS AS SYSDBA
-- 2. Ir a menú: Ver → DBA
-- 3. Panel DBA → Performance → AWR → Snapshots
-- 4. Seleccionar los 2 snapshots → clic derecho → "Generate Report"
-- 5. Elegir formato HTML → Guardar en la carpeta del proyecto
-- -----------------------------------------------
