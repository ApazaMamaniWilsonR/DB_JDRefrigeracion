ALTER TABLE productos RENAME COLUMN precio TO precio_pen;
ALTER TABLE productos ADD precio_usd   NUMBER(12,2);
ALTER TABLE productos ADD costo        NUMBER(12,2);
ALTER TABLE productos ADD margen       NUMBER(5,2);

--------------------

-- Primero los hijos (FK)
DROP TABLE detalle_cotizaciones;
DROP TABLE cotizaciones;

-- Nueva tabla PROFORMAS
CREATE TABLE proformas (
    id                  NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    numero_proforma     VARCHAR2(20),
    fecha               TIMESTAMP     NOT NULL,
    fecha_vencimiento   DATE,
    estado              VARCHAR2(30)  NOT NULL,  -- BORRADOR, ENVIADA, APROBADA, RECHAZADA, CONVERTIDA
    moneda              VARCHAR2(10)  NOT NULL,  -- PEN, USD
    tipo_cambio         NUMBER(12,4)  NOT NULL,
    cliente_id          NUMBER(19)    NOT NULL,
    subtotal            NUMBER(12,2)  NOT NULL,
    descuento           NUMBER(12,2)  NOT NULL,
    igv                 NUMBER(12,2)  NOT NULL,
    total               NUMBER(12,2)  NOT NULL,
    total_soles         NUMBER(12,2)  NOT NULL,
    total_dolares       NUMBER(12,2)  NOT NULL,
    observaciones       VARCHAR2(500),
    correo_enviado      NUMBER(1)     DEFAULT 0 NOT NULL,
    fecha_envio_correo  TIMESTAMP,
    correo_destino      VARCHAR2(150),
    CONSTRAINT fk_proforma_cliente FOREIGN KEY (cliente_id) REFERENCES clientes(id)
);

-- Detalle de proforma
CREATE TABLE detalle_proformas (
    id                  NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    proforma_id         NUMBER(19)    NOT NULL,
    producto_id         NUMBER(19)    NOT NULL,
    cantidad            NUMBER(10)    NOT NULL,
    precio_unitario     NUMBER(12,2)  NOT NULL,
    subtotal            NUMBER(12,2)  NOT NULL,
    CONSTRAINT fk_detpro_proforma  FOREIGN KEY (proforma_id)  REFERENCES proformas(id),
    CONSTRAINT fk_detpro_producto  FOREIGN KEY (producto_id)  REFERENCES productos(id)
);

--------------------

ALTER TABLE ventas ADD proforma_id          NUMBER(19);
ALTER TABLE ventas ADD tipo_pago            VARCHAR2(10)  DEFAULT 'CONTADO' NOT NULL;
ALTER TABLE ventas ADD fecha_vcto_credito   DATE;
ALTER TABLE ventas ADD estado_pago          VARCHAR2(20)  DEFAULT 'PENDIENTE' NOT NULL;
ALTER TABLE ventas ADD saldo_pendiente      NUMBER(12,2)  DEFAULT 0;

ALTER TABLE ventas ADD CONSTRAINT fk_venta_proforma
    FOREIGN KEY (proforma_id) REFERENCES proformas(id);

--------------------

-- Eliminar FK existente
ALTER TABLE pagos DROP CONSTRAINT FK_PAGO_VENTA;

-- Eliminar la columna de FK directa
ALTER TABLE pagos DROP COLUMN venta_id;

-- Tabla puente N:N (un pago puede cubrir varias ventas)
CREATE TABLE pago_ventas (
    id              NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    pago_id         NUMBER(19)   NOT NULL,
    venta_id        NUMBER(19)   NOT NULL,
    monto_aplicado  NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_pagoven_pago   FOREIGN KEY (pago_id)   REFERENCES pagos(id),
    CONSTRAINT fk_pagoven_venta  FOREIGN KEY (venta_id)  REFERENCES ventas(id),
    CONSTRAINT uq_pago_venta     UNIQUE (pago_id, venta_id)
);

--------------------

ALTER TABLE mantenimientos ADD numero_mantenimiento  NUMBER(1);
ALTER TABLE mantenimientos ADD meses_intervalo        NUMBER(3);
-- Valores esperados: numero=1→3m, 2→6m, 3→9m, 4→12m

--------------------

ALTER TABLE notificaciones ADD canal         VARCHAR2(20);   -- CORREO, WHATSAPP, SISTEMA
ALTER TABLE notificaciones ADD destinatario  VARCHAR2(150);  -- email o teléfono
ALTER TABLE notificaciones ADD fecha_envio   TIMESTAMP;

--------------------

DROP TABLE notificaciones          PURGE;
DROP TABLE mantenimientos          PURGE;
DROP TABLE instalaciones           PURGE;
DROP TABLE comprobantes_electronicos PURGE;
DROP TABLE pago_ventas             PURGE;
DROP TABLE pagos                   PURGE;
DROP TABLE detalle_ventas          PURGE;
DROP TABLE ventas                  PURGE;
DROP TABLE detalle_proformas       PURGE;
DROP TABLE proformas               PURGE;
DROP TABLE detalle_compra          PURGE;
DROP TABLE compras                 PURGE;
DROP TABLE productos               PURGE;
DROP TABLE clientes                PURGE;
DROP TABLE proveedores             PURGE;
DROP TABLE categorias              PURGE;

--------------------

CREATE TABLE categorias (
    id          NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR2(120) NOT NULL,
    descripcion VARCHAR2(250),
    activo      NUMBER(1)     DEFAULT 1 NOT NULL
);

CREATE TABLE proveedores (
    id                    NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    tipo                  VARCHAR2(20)  NOT NULL,
    nombre_o_razon_social VARCHAR2(150) NOT NULL,
    ruc                   VARCHAR2(11),
    dni                   VARCHAR2(8),
    direccion             VARCHAR2(200),
    telefono              VARCHAR2(20),
    correo                VARCHAR2(100),
    contacto_vendedor     VARCHAR2(150)
);

--------------------

CREATE TABLE clientes (
    id                      NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    tipo_cliente            VARCHAR2(20)  NOT NULL,
    numero_documento        VARCHAR2(11)  NOT NULL UNIQUE,
    nombres                 VARCHAR2(120),
    apellidos               VARCHAR2(120),
    razon_social            VARCHAR2(200),
    nombre_comercial        VARCHAR2(220) NOT NULL,
    direccion               VARCHAR2(250),
    estado_contribuyente    VARCHAR2(80),
    condicion_contribuyente VARCHAR2(80),
    correo                  VARCHAR2(150),
    telefono                VARCHAR2(20),
    persona_contacto        VARCHAR2(120),
    activo                  NUMBER(1) DEFAULT 1 NOT NULL
);

--------------------

CREATE TABLE productos (
    id           NUMBER(19)    GENERATED AS IDENTITY PRIMARY KEY,
    nombre       VARCHAR2(150) NOT NULL,
    descripcion  VARCHAR2(300),
    precio_pen   NUMBER(12,2)  NOT NULL,
    precio_usd   NUMBER(12,2),
    costo        NUMBER(12,2),
    margen       NUMBER(5,2),
    stock        NUMBER(10)    NOT NULL,
    stock_minimo NUMBER(10)    NOT NULL,
    activo       NUMBER(1)     DEFAULT 1 NOT NULL,
    categoria_id NUMBER(19)    NOT NULL,
    CONSTRAINT fk_prod_cat FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

--------------------

-- ▶ COMPRAS: PARTITION BY HASH (id) — 4 particiones de carga uniforme
CREATE TABLE compras (
    id             NUMBER(19)   GENERATED AS IDENTITY,
    proveedor_id   NUMBER(19)   NOT NULL,
    fecha_compra   DATE         NOT NULL,
    numero_factura VARCHAR2(50),
    moneda         VARCHAR2(10) NOT NULL,
    total          NUMBER(12,2) NOT NULL,
    CONSTRAINT pk_compras         PRIMARY KEY (id),
    CONSTRAINT fk_compra_prov     FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
) PARTITION BY HASH (id)
PARTITIONS 4;

--------------------

-- ▶ PROFORMAS: PARTITION BY LIST (estado) — una partición por estado de negocio
CREATE TABLE proformas (
    id                 NUMBER(19)    GENERATED AS IDENTITY,
    numero_proforma    VARCHAR2(20),
    fecha              TIMESTAMP(6)  NOT NULL,
    fecha_vencimiento  DATE,
    estado             VARCHAR2(30)  NOT NULL,
    moneda             VARCHAR2(10)  NOT NULL,
    tipo_cambio        NUMBER(12,4)  NOT NULL,
    cliente_id         NUMBER(19)    NOT NULL,
    subtotal           NUMBER(12,2)  NOT NULL,
    descuento          NUMBER(12,2)  NOT NULL,
    igv                NUMBER(12,2)  NOT NULL,
    total              NUMBER(12,2)  NOT NULL,
    total_soles        NUMBER(12,2)  NOT NULL,
    total_dolares      NUMBER(12,2)  NOT NULL,
    observaciones      VARCHAR2(500),
    correo_enviado     NUMBER(1)     DEFAULT 0 NOT NULL,
    fecha_envio_correo TIMESTAMP(6),
    correo_destino     VARCHAR2(150),
    CONSTRAINT pk_proformas        PRIMARY KEY (id),
    CONSTRAINT fk_proforma_cli     FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) PARTITION BY LIST (estado) (
    PARTITION p_borrador   VALUES ('BORRADOR'),
    PARTITION p_enviada    VALUES ('ENVIADA'),
    PARTITION p_aprobada   VALUES ('APROBADA'),
    PARTITION p_rechazada  VALUES ('RECHAZADA'),
    PARTITION p_convertida VALUES ('CONVERTIDA')
);

--------------------

CREATE TABLE ventas (
    id                 NUMBER(19)   GENERATED AS IDENTITY,
    vendedor_id        VARCHAR2(36),
    fecha              TIMESTAMP(6) NOT NULL,
    estado             VARCHAR2(30) NOT NULL,
    moneda             VARCHAR2(10) NOT NULL,
    tipo_cambio        NUMBER(12,4) NOT NULL,
    cliente_id         NUMBER(19)   NOT NULL,
    proforma_id        NUMBER(19),
    tipo_pago          VARCHAR2(10) DEFAULT 'CONTADO' NOT NULL,
    fecha_vcto_credito DATE,
    subtotal           NUMBER(12,2) NOT NULL,
    descuento          NUMBER(12,2) NOT NULL,
    igv                NUMBER(12,2) NOT NULL,
    total              NUMBER(12,2) NOT NULL,
    total_soles        NUMBER(12,2) NOT NULL,
    total_dolares      NUMBER(12,2) NOT NULL,
    estado_pago        VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    saldo_pendiente    NUMBER(12,2) DEFAULT 0,
    CONSTRAINT pk_ventas          PRIMARY KEY (id),
    CONSTRAINT fk_venta_cli       FOREIGN KEY (cliente_id)  REFERENCES clientes(id),
    CONSTRAINT fk_venta_proforma  FOREIGN KEY (proforma_id) REFERENCES proformas(id)
) PARTITION BY RANGE (fecha) (
    PARTITION p_ventas_2025   VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00'),
    PARTITION p_ventas_2026   VALUES LESS THAN (TIMESTAMP '2027-01-01 00:00:00'),
    PARTITION p_ventas_2027   VALUES LESS THAN (TIMESTAMP '2028-01-01 00:00:00'),
    PARTITION p_ventas_futuro VALUES LESS THAN (MAXVALUE)
);

--------------------

CREATE TABLE detalle_ventas (
    id              NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    venta_id        NUMBER(19)   NOT NULL,
    producto_id     NUMBER(19)   NOT NULL,
    cantidad        NUMBER(10)   NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    subtotal        NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_dv_venta FOREIGN KEY (venta_id)    REFERENCES ventas(id),
    CONSTRAINT fk_dv_prod  FOREIGN KEY (producto_id) REFERENCES productos(id)
);

CREATE TABLE detalle_compra (
    id                     NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    compra_id              NUMBER(19)   NOT NULL,
    producto_id            NUMBER(19)   NOT NULL,
    cantidad               NUMBER(10)   NOT NULL,
    precio_unitario_compra NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_dc_compra FOREIGN KEY (compra_id)   REFERENCES compras(id),
    CONSTRAINT fk_dc_prod   FOREIGN KEY (producto_id) REFERENCES productos(id)
);

CREATE TABLE detalle_proformas (
    id              NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    proforma_id     NUMBER(19)   NOT NULL,
    producto_id     NUMBER(19)   NOT NULL,
    cantidad        NUMBER(10)   NOT NULL,
    precio_unitario NUMBER(12,2) NOT NULL,
    subtotal        NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_dp_proforma FOREIGN KEY (proforma_id) REFERENCES proformas(id),
    CONSTRAINT fk_dp_prod     FOREIGN KEY (producto_id) REFERENCES productos(id)
);

CREATE TABLE pagos (
    id            NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    fecha_pago    TIMESTAMP(6) NOT NULL,
    moneda        VARCHAR2(20) NOT NULL,
    tipo_cambio   NUMBER(12,4) NOT NULL,
    monto         NUMBER(12,2) NOT NULL,
    monto_soles   NUMBER(12,2) NOT NULL,
    monto_dolares NUMBER(12,2) NOT NULL,
    metodo_pago   VARCHAR2(30) NOT NULL,
    observacion   VARCHAR2(250)
);

CREATE TABLE pago_ventas (
    id             NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    pago_id        NUMBER(19)   NOT NULL,
    venta_id       NUMBER(19)   NOT NULL,
    monto_aplicado NUMBER(12,2) NOT NULL,
    CONSTRAINT fk_pagoven_pago  FOREIGN KEY (pago_id)  REFERENCES pagos(id),
    CONSTRAINT fk_pagoven_venta FOREIGN KEY (venta_id) REFERENCES ventas(id),
    CONSTRAINT uq_pago_venta    UNIQUE (pago_id, venta_id)
);

CREATE TABLE instalaciones (
    id                          NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    venta_id                    NUMBER(19)   NOT NULL UNIQUE,
    fecha_instalacion           DATE         NOT NULL,
    fecha_fin_garantia          DATE         NOT NULL,
    fecha_proximo_mantenimiento DATE         NOT NULL,
    direccion_instalacion       VARCHAR2(250),
    observaciones               VARCHAR2(500),
    CONSTRAINT fk_inst_venta FOREIGN KEY (venta_id) REFERENCES ventas(id)
);

CREATE TABLE comprobantes_electronicos (
    id                    NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    tipo_comprobante      VARCHAR2(20) NOT NULL,
    serie                 VARCHAR2(10) NOT NULL,
    correlativo           VARCHAR2(20) NOT NULL,
    fecha_emision         TIMESTAMP(6) NOT NULL,
    moneda                VARCHAR2(10) NOT NULL,
    tipo_cambio           NUMBER(12,4) NOT NULL,
    subtotal              NUMBER(12,2) NOT NULL,
    descuento             NUMBER(12,2) NOT NULL,
    igv                   NUMBER(12,2) NOT NULL,
    total                 NUMBER(12,2) NOT NULL,
    total_soles           NUMBER(12,2) NOT NULL,
    total_dolares         NUMBER(12,2) NOT NULL,
    estado_sunat          VARCHAR2(40) NOT NULL,
    mensaje_sunat         VARCHAR2(500),
    estado_envio_cliente  VARCHAR2(40) NOT NULL,
    correo_destino        VARCHAR2(150),
    telefono_destino      VARCHAR2(20),
    nombre_archivo_xml    VARCHAR2(300),
    nombre_archivo_cdr    VARCHAR2(300),
    nombre_archivo_pdf    VARCHAR2(300),
    fecha_envio_sunat     TIMESTAMP(6),
    fecha_respuesta_sunat TIMESTAMP(6),
    fecha_envio_cliente   TIMESTAMP(6),
    venta_id              NUMBER(19)   NOT NULL,
    CONSTRAINT fk_comp_venta FOREIGN KEY (venta_id) REFERENCES ventas(id)
);

CREATE TABLE mantenimientos (
    id                   NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    instalacion_id       NUMBER(19)   NOT NULL,
    fecha_programada     DATE         NOT NULL,
    fecha_realizada      DATE,
    estado               VARCHAR2(30) NOT NULL,
    observaciones        VARCHAR2(500),
    numero_mantenimiento NUMBER(1),
    meses_intervalo      NUMBER(3),
    CONSTRAINT fk_mant_inst FOREIGN KEY (instalacion_id) REFERENCES instalaciones(id)
);

CREATE TABLE notificaciones (
    id              NUMBER(19)   GENERATED AS IDENTITY PRIMARY KEY,
    tipo            VARCHAR2(40) NOT NULL,
    titulo          VARCHAR2(150) NOT NULL,
    mensaje         VARCHAR2(500) NOT NULL,
    estado          VARCHAR2(20) NOT NULL,
    fecha_creacion  TIMESTAMP(6) NOT NULL,
    referencia_tipo VARCHAR2(50),
    referencia_id   NUMBER(19),
    canal           VARCHAR2(20),
    destinatario    VARCHAR2(150),
    fecha_envio     TIMESTAMP(6)
);

--------------------

-- Categorias y Proveedores
INSERT INTO categorias VALUES (DEFAULT, 'Equipos de Aire Acondicionado', 'Unidades split y condensadoras', 1);
INSERT INTO categorias VALUES (DEFAULT, 'Gases Refrigerantes', 'Cilindros y boyas de gas', 1);
INSERT INTO categorias VALUES (DEFAULT, 'Tuberías y Aislamientos', 'Tuberías de cobre y accesorios', 1);
INSERT INTO categorias VALUES (DEFAULT, 'Herramientas Técnicas', 'Equipos de trabajo para técnicos', 1);

INSERT INTO proveedores VALUES (DEFAULT, 'EMPRESA', 'Refrigeración Industrial SAC', '20888888888', NULL, 'Av. Argentina 1500', '999888777', 'ventas@refriindustrial.pe', 'Carlos Gomez');

-- CLIENTES: enrutamiento automático por tipo_cliente
-- → p_persona: PERSONA
INSERT INTO clientes (tipo_cliente, numero_documento, nombres, apellidos, nombre_comercial, correo, telefono, activo)
VALUES ('PERSONA', '76543210', 'Juan Carlos', 'Perez Quispe', 'Juan Perez', 'juan@gmail.com', '951234567', 1);

-- → p_empresa: EMPRESA
INSERT INTO clientes (tipo_cliente, numero_documento, razon_social, nombre_comercial, direccion, correo, telefono, activo)
VALUES ('EMPRESA', '20512345678', 'Clínica San Pablo S.A.', 'Clínica San Pablo', 'Av. El Polo 789', 'logistica@sanpablo.pe', '014567890', 1);

-- → p_persona: PERSONA
INSERT INTO clientes (tipo_cliente, numero_documento, nombres, apellidos, nombre_comercial, correo, activo)
VALUES ('PERSONA', '45678901', 'María Elena', 'Quispe Torres', 'María Quispe', 'maria@hotmail.com', 1);

-- → p_empresa: EMPRESA
INSERT INTO clientes (tipo_cliente, numero_documento, razon_social, nombre_comercial, correo, activo)
VALUES ('EMPRESA', '20601234567', 'Distribuidora El Sol S.R.L.', 'El Sol', 'ventas@elsol.pe', 1);

-- PRODUCTOS: enrutamiento automático por función HASH sobre id
INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Aire Acondicionado Split 12000 BTU', 'Inverter clase A', 1200.00, 320.00, 850.00, 41.18, 15, 3, 1, 1);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Aire Acondicionado Split 18000 BTU', 'Inverter con WiFi', 1850.00, 493.33, 1300.00, 42.31, 8, 2, 1, 1);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Gas Refrigerante R-410A (11.3kg)', 'Gas ecológico certificado', 180.00, 48.00, 120.00, 50.00, 30, 5, 1, 2);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Gas Refrigerante R-22 (13.6kg)', 'Gas convencional', 250.00, 66.67, 180.00, 38.89, 20, 4, 1, 2);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Tubería de Cobre 1/4" (rollo 15m)', 'Tipo ACR refrigeración', 95.00, 25.33, 65.00, 46.15, 50, 10, 1, 3);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Manifold Digitalizado R-410A', 'Manómetro digital', 380.00, 101.33, 260.00, 46.15, 5, 1, 1, 4);

-- VENTAS: enrutamiento automático por rango de fecha
-- → p_ventas_2025
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2025-05-10 10:30:00', 'FACTURADA', 'PEN', 3.75, 1, 1016.95, 0, 183.05, 1200.00, 1200.00, 320.00, 'CONTADO', 'PAGADO', 0);

-- → p_ventas_2026
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2026-03-15 14:00:00', 'REGISTRADA', 'PEN', 3.75, 2, 2033.90, 0, 366.10, 2400.00, 2400.00, 640.00, 'CREDITO', 'PENDIENTE', 2400.00);

-- → p_ventas_2026
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2026-08-22 09:15:00', 'FACTURADA', 'USD', 3.80, 1, 847.46, 0, 152.54, 1000.00, 3800.00, 1000.00, 'CONTADO', 'PAGADO', 0);

-- → p_ventas_2027
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2027-01-08 11:00:00', 'REGISTRADA', 'PEN', 3.75, 2, 1525.42, 0, 274.58, 1800.00, 1800.00, 480.00, 'CONTADO', 'PAGADO', 0);

-- → p_ventas_futuro
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2028-06-30 16:45:00', 'REGISTRADA', 'PEN', 3.76, 1, 2542.37, 0, 457.63, 3000.00, 3000.00, 797.87, 'CREDITO', 'PARCIAL', 1500.00);

COMMIT;

--------------------

-- 1. Tipo de particionamiento y cantidad de particiones
SELECT table_name, partitioning_type, partition_count, status
FROM   user_part_tables
WHERE  table_name IN ('VENTAS', 'COMPRAS', 'PROFORMAS')
ORDER  BY table_name;

-- 2. Detalle de cada partición
SELECT table_name, partition_name, partition_position,
       high_value, tablespace_name
FROM   user_tab_partitions
WHERE  table_name IN ('VENTAS', 'COMPRAS', 'PROFORMAS')
ORDER  BY table_name, partition_position;

-- 3. RANGE: solo ventas del año 2026
SELECT id, fecha, estado, total_soles, tipo_pago
FROM   ventas PARTITION (p_ventas_2026);

-- 4. LIST: solo proformas pendientes de respuesta (ENVIADAS)
SELECT id, numero_proforma, fecha, cliente_id, total_soles
FROM   proformas PARTITION (p_enviada);

-- 5. LIST: proformas ya cerradas positivamente
SELECT id, numero_proforma, estado, total_soles
FROM   proformas PARTITION (p_aprobada)
UNION ALL
SELECT id, numero_proforma, estado, total_soles
FROM   proformas PARTITION (p_convertida);

-- 6. HASH: distribución de compras entre las 4 particiones
SELECT partition_name, num_rows
FROM   user_tab_partitions
WHERE  table_name = 'COMPRAS'
ORDER  BY partition_name;

-- 7. Índices globales generados
SELECT index_name, table_name, partitioned, uniqueness
FROM   user_indexes
WHERE  table_name IN ('VENTAS', 'COMPRAS', 'PROFORMAS')
ORDER  BY table_name;

--------------------

-- SP_GENERAR_COMPROBANTE (sin cambios, funciona con VENTAS particionada)
CREATE OR REPLACE PROCEDURE SP_GENERAR_COMPROBANTE(p_venta_id IN NUMBER) AS
    v_tipo_doc      VARCHAR2(20);
    v_serie         VARCHAR2(10);
    v_correlativo   VARCHAR2(20);
    v_tipo_cliente  VARCHAR2(20);
    v_subtotal      NUMBER(12,2);
    v_descuento     NUMBER(12,2);
    v_igv           NUMBER(12,2);
    v_total         NUMBER(12,2);
    v_total_soles   NUMBER(12,2);
    v_total_dolares NUMBER(12,2);
    v_moneda        VARCHAR2(10);
    v_tipo_cambio   NUMBER(12,4);
BEGIN
    SELECT c.tipo_cliente, v.subtotal, v.descuento, v.igv, v.total,
           v.total_soles, v.total_dolares, v.moneda, v.tipo_cambio
    INTO   v_tipo_cliente, v_subtotal, v_descuento, v_igv, v_total,
           v_total_soles, v_total_dolares, v_moneda, v_tipo_cambio
    FROM   ventas v JOIN clientes c ON v.cliente_id = c.id
    WHERE  v.id = p_venta_id;

    IF v_tipo_cliente = 'EMPRESA' THEN
        v_tipo_doc := 'FACTURA'; v_serie := 'F001';
    ELSE
        v_tipo_doc := 'BOLETA';  v_serie := 'B001';
    END IF;

    SELECT LPAD(NVL(MAX(TO_NUMBER(correlativo)), 0) + 1, 7, '0')
    INTO   v_correlativo
    FROM   comprobantes_electronicos WHERE serie = v_serie;

    INSERT INTO comprobantes_electronicos (
        tipo_comprobante, serie, correlativo, fecha_emision, moneda,
        tipo_cambio, subtotal, descuento, igv, total,
        total_soles, total_dolares, estado_sunat, estado_envio_cliente, venta_id
    ) VALUES (
        v_tipo_doc, v_serie, v_correlativo, SYSTIMESTAMP, v_moneda,
        v_tipo_cambio, v_subtotal, v_descuento, v_igv, v_total,
        v_total_soles, v_total_dolares, 'GENERADO', 'NO_ENVIADO', p_venta_id
    );
    UPDATE ventas SET estado = 'FACTURADA' WHERE id = p_venta_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Comprobante ' || v_tipo_doc || ' ' || v_serie || '-' || v_correlativo || ' generado.');
END;
/

-- FN_VALORIZACION_INVENTARIO (actualizado: precio → precio_pen)
CREATE OR REPLACE FUNCTION FN_VALORIZACION_INVENTARIO RETURN NUMBER IS
    v_val NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(stock * precio_pen), 0) INTO v_val
    FROM   productos WHERE activo = 1;
    RETURN v_val;
END;
/

-- FN_TOTAL_PROFORMA_CLIENTE (actualizado: cotizaciones → proformas)
CREATE OR REPLACE FUNCTION FN_TOTAL_PROFORMA_CLIENTE(p_cliente_id IN NUMBER) RETURN NUMBER IS
    v_total NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(total_soles), 0) INTO v_total
    FROM   proformas
    WHERE  cliente_id = p_cliente_id AND estado = 'ENVIADA';
    RETURN v_total;
END;
/

-- SP_PROGRAMAR_MANTENIMIENTO (sin cambios)
CREATE OR REPLACE PROCEDURE SP_PROGRAMAR_MANTENIMIENTO(
    p_instalacion_id IN NUMBER,
    p_numero_mant    IN NUMBER DEFAULT 1,
    p_meses_adelante IN NUMBER DEFAULT 3
) AS
    v_fecha DATE;
BEGIN
    v_fecha := ADD_MONTHS(SYSDATE, p_meses_adelante);
    INSERT INTO mantenimientos (instalacion_id, fecha_programada, estado,
                                numero_mantenimiento, meses_intervalo, observaciones)
    VALUES (p_instalacion_id, v_fecha, 'PENDIENTE',
            p_numero_mant, p_meses_adelante,
            'Mantenimiento preventivo N°' || p_numero_mant || ' (' || p_meses_adelante || ' meses)');
    UPDATE instalaciones SET fecha_proximo_mantenimiento = v_fecha WHERE id = p_instalacion_id;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Mant. N°' || p_numero_mant || ' programado para ' || TO_CHAR(v_fecha, 'DD/MM/YYYY'));
END;
/

-- TRG_AUMENTAR_STOCK_COMPRA
CREATE OR REPLACE TRIGGER TRG_AUMENTAR_STOCK_COMPRA
AFTER INSERT ON detalle_compra FOR EACH ROW
BEGIN
    UPDATE productos SET stock = stock + :NEW.cantidad WHERE id = :NEW.producto_id;
END;
/

-- TRG_NOTIFICAR_INSTALACION
CREATE OR REPLACE TRIGGER TRG_NOTIFICAR_INSTALACION
AFTER INSERT ON instalaciones FOR EACH ROW
BEGIN
    INSERT INTO notificaciones (tipo, titulo, mensaje, estado, fecha_creacion, referencia_tipo, referencia_id, canal)
    VALUES ('MANTENIMIENTO_PROXIMO', 'Nueva instalación registrada',
            'Próximo mantenimiento: ' || TO_CHAR(:NEW.fecha_proximo_mantenimiento, 'DD/MM/YYYY'),
            'NO_LEIDA', SYSTIMESTAMP, 'INSTALACION', :NEW.id, 'SISTEMA');
END;
/

--------------------



--------------------



--------------------



--------------------



--------------------
