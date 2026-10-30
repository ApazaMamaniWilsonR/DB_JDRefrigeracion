SELECT name FROM v$datafile FETCH FIRST 1 ROWS ONLY;

----------------------

INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id,
    subtotal, descuento, igv, total, total_soles, total_dolares,
    tipo_pago, estado_pago, saldo_pendiente)
VALUES (SYSTIMESTAMP, 'REGISTRADA', 'PEN', 3.75, 1,
    847.46, 0, 152.54, 1000.00, 1000.00, 266.67,
    'CONTADO', 'PAGADO', 0);
COMMIT;

----------------------

SELECT EXTRACT(YEAR FROM fecha)  AS anio,
       EXTRACT(MONTH FROM fecha) AS mes,
       COUNT(*)                  AS total_ventas,
       SUM(total_soles)          AS monto_soles,
       AVG(total_soles)          AS ticket_promedio
FROM   ventas
GROUP  BY EXTRACT(YEAR FROM fecha), EXTRACT(MONTH FROM fecha)
ORDER  BY anio, mes;

SELECT c.nombre_comercial, COUNT(v.id) AS ventas,
       SUM(v.total_soles) AS facturacion
FROM   ventas v JOIN clientes c ON v.cliente_id = c.id
GROUP  BY c.nombre_comercial
ORDER  BY facturacion DESC;

SELECT FN_VALORIZACION_INVENTARIO() AS valor_inventario FROM DUAL;

SELECT COUNT(*), SUM(total_soles)
FROM   ventas PARTITION (p_ventas_2026)
WHERE  tipo_pago = 'CONTADO';