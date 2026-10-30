-- ==============================================================
-- SCRIPT: 01_Particionamiento_JD_Refrigeracion.sql
-- Propósito: Implementación de Particionamiento Físico en JD Refrigeración
-- Tablas:
--   - VENTAS    -> PARTITION BY RANGE (fecha)
--   - PROFORMAS -> PARTITION BY LIST (estado)
--   - COMPRAS   -> PARTITION BY HASH (id)
-- Ejecutar como: jdrefrigeracion
-- Conexión en SQL Developer: JD_Refrigeracion
-- ==============================================================

-- --------------------------------------------------------------
-- 1. DROP EN ORDEN DE RESTRICCIONES (FK)
-- --------------------------------------------------------------
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

-- --------------------------------------------------------------
-- 2. TABLAS MAESTRAS
-- --------------------------------------------------------------
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
    activo                  NUMBER(1)     DEFAULT 1 NOT NULL
);

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

-- --------------------------------------------------------------
-- 3. TABLAS PARTICIONADAS
-- --------------------------------------------------------------

-- ▶ COMPRAS: PARTITION BY HASH (id) — 4 particiones
CREATE TABLE compras (
    id             NUMBER(19)   GENERATED AS IDENTITY,
    proveedor_id   NUMBER(19)   NOT NULL,
    fecha_compra   DATE         NOT NULL,
    numero_factura VARCHAR2(50),
    moneda         VARCHAR2(10) NOT NULL,
    total          NUMBER(12,2) NOT NULL,
    CONSTRAINT pk_compras     PRIMARY KEY (id),
    CONSTRAINT fk_compra_prov FOREIGN KEY (proveedor_id) REFERENCES proveedores(id)
) PARTITION BY HASH (id)
PARTITIONS 4;

-- ▶ PROFORMAS: PARTITION BY LIST (estado) — 5 particiones discretas
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
    CONSTRAINT pk_proformas    PRIMARY KEY (id),
    CONSTRAINT fk_proforma_cli FOREIGN KEY (cliente_id) REFERENCES clientes(id)
) PARTITION BY LIST (estado) (
    PARTITION p_borrador   VALUES ('BORRADOR'),
    PARTITION p_enviada    VALUES ('ENVIADA'),
    PARTITION p_aprobada   VALUES ('APROBADA'),
    PARTITION p_rechazada  VALUES ('RECHAZADA'),
    PARTITION p_convertida VALUES ('CONVERTIDA')
);

-- ▶ VENTAS: PARTITION BY RANGE (fecha) — segmentación anual + MAXVALUE
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
    CONSTRAINT pk_ventas         PRIMARY KEY (id),
    CONSTRAINT fk_venta_cli      FOREIGN KEY (cliente_id)  REFERENCES clientes(id),
    CONSTRAINT fk_venta_proforma FOREIGN KEY (proforma_id) REFERENCES proformas(id)
) PARTITION BY RANGE (fecha) (
    PARTITION p_ventas_2025   VALUES LESS THAN (TIMESTAMP '2026-01-01 00:00:00'),
    PARTITION p_ventas_2026   VALUES LESS THAN (TIMESTAMP '2027-01-01 00:00:00'),
    PARTITION p_ventas_2027   VALUES LESS THAN (TIMESTAMP '2028-01-01 00:00:00'),
    PARTITION p_ventas_futuro VALUES LESS THAN (MAXVALUE)
);

-- --------------------------------------------------------------
-- 4. TABLAS HIJO RESTANTES
-- --------------------------------------------------------------
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

-- --------------------------------------------------------------
-- 5. POBLACIÓN DE DATOS (ENRUTAMIENTO AUTOMÁTICO)
-- --------------------------------------------------------------
INSERT INTO categorias VALUES (DEFAULT, 'Equipos de Aire Acondicionado', 'Unidades split y condensadoras', 1);
INSERT INTO categorias VALUES (DEFAULT, 'Gases Refrigerantes', 'Cilindros y boyas de gas', 1);

INSERT INTO proveedores VALUES (DEFAULT, 'EMPRESA', 'Refrigeración Industrial SAC', '20888888888', NULL, 'Av. Argentina 1500', '999888777', 'ventas@refriindustrial.pe', 'Carlos Gomez');
INSERT INTO proveedores VALUES (DEFAULT, 'EMPRESA', 'Frío Sur Distribuciones E.I.R.L.', '20777777777', NULL, 'Jr. Tacna 230', '987654321', 'compras@friosur.pe', 'Ana López');

INSERT INTO clientes (tipo_cliente, numero_documento, nombres, apellidos, nombre_comercial, correo, telefono, activo)
VALUES ('PERSONA', '76543210', 'Juan Carlos', 'Perez Quispe', 'Juan Perez', 'juan@gmail.com', '951234567', 1);
INSERT INTO clientes (tipo_cliente, numero_documento, razon_social, nombre_comercial, direccion, correo, telefono, activo)
VALUES ('EMPRESA', '20512345678', 'Clínica San Pablo S.A.', 'Clínica San Pablo', 'Av. El Polo 789', 'logistica@sanpablo.pe', '014567890', 1);

INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Aire Acondicionado Split 12000 BTU', 'Inverter clase A', 1200.00, 320.00, 850.00, 41.18, 15, 3, 1, 1);
INSERT INTO productos (nombre, descripcion, precio_pen, precio_usd, costo, margen, stock, stock_minimo, activo, categoria_id)
VALUES ('Gas Refrigerante R-410A (11.3kg)', 'Gas ecológico', 180.00, 48.00, 120.00, 50.00, 30, 5, 1, 2);

-- Compras (Hash)
INSERT INTO compras (proveedor_id, fecha_compra, numero_factura, moneda, total)
VALUES (1, DATE '2026-02-10', 'F001-0001', 'PEN', 3600.00);
INSERT INTO compras (proveedor_id, fecha_compra, numero_factura, moneda, total)
VALUES (2, DATE '2026-05-20', 'F002-0014', 'USD', 950.00);

-- Proformas (List)
INSERT INTO proformas (numero_proforma, fecha, fecha_vencimiento, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, observaciones)
VALUES ('PRO-2026-001', TIMESTAMP '2026-03-01 09:00:00', DATE '2026-03-15', 'BORRADOR', 'PEN', 3.75, 1, 1016.95, 0, 183.05, 1200.00, 1200.00, 320.00, 'Borrador');
INSERT INTO proformas (numero_proforma, fecha, fecha_vencimiento, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares)
VALUES ('PRO-2026-002', TIMESTAMP '2026-04-10 10:00:00', DATE '2026-04-25', 'ENVIADA',  'PEN', 3.75, 2, 2033.90, 0, 366.10, 2400.00, 2400.00, 640.00);

-- Ventas (Range)
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2025-08-15 10:00:00', 'FACTURADA', 'PEN', 3.75, 1, 1016.95, 0, 183.05, 1200.00, 1200.00, 320.00, 'CONTADO', 'PAGADO', 0);
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2026-04-22 14:00:00', 'REGISTRADA', 'PEN', 3.75, 2, 2033.90, 0, 366.10, 2400.00, 2400.00, 640.00, 'CREDITO', 'PENDIENTE', 2400.00);
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2027-02-05 11:00:00', 'REGISTRADA', 'PEN', 3.75, 2, 2542.37, 0, 457.63, 3000.00, 3000.00, 800.00, 'CREDITO', 'PARCIAL', 1500.00);
INSERT INTO ventas (fecha, estado, moneda, tipo_cambio, cliente_id, subtotal, descuento, igv, total, total_soles, total_dolares, tipo_pago, estado_pago, saldo_pendiente)
VALUES (TIMESTAMP '2028-11-30 16:00:00', 'REGISTRADA', 'PEN', 3.76, 1, 1525.42, 0, 274.58, 1800.00, 1800.00, 478.72, 'CONTADO', 'PAGADO', 0);
COMMIT;

-- --------------------------------------------------------------
-- 6. PROCEDURES Y TRIGGERS ACTUALIZADOS
-- --------------------------------------------------------------
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
    INTO v_tipo_cliente, v_subtotal, v_descuento, v_igv, v_total,
         v_total_soles, v_total_dolares, v_moneda, v_tipo_cambio
    FROM ventas v JOIN clientes c ON v.cliente_id = c.id
    WHERE v.id = p_venta_id;

    IF v_tipo_cliente = 'EMPRESA' THEN
        v_tipo_doc := 'FACTURA'; v_serie := 'F001';
    ELSE
        v_tipo_doc := 'BOLETA';  v_serie := 'B001';
    END IF;

    SELECT LPAD(NVL(MAX(TO_NUMBER(correlativo)), 0) + 1, 7, '0')
    INTO v_correlativo
    FROM comprobantes_electronicos WHERE serie = v_serie;

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
END;
/

CREATE OR REPLACE FUNCTION FN_VALORIZACION_INVENTARIO RETURN NUMBER IS
    v_val NUMBER(12,2);
BEGIN
    SELECT NVL(SUM(stock * precio_pen), 0) INTO v_val FROM productos WHERE activo = 1;
    RETURN v_val;
END;
/

CREATE OR REPLACE TRIGGER TRG_AUMENTAR_STOCK_COMPRA
AFTER INSERT ON detalle_compra FOR EACH ROW
BEGIN
    UPDATE productos SET stock = stock + :NEW.cantidad WHERE id = :NEW.producto_id;
END;
/
