-- ==================================================================
-- 08. TABLAS DE DEUDAS Y MSI
-- ==================================================================
-- Descripción: Compras a plazos, MSI y cuotas de deuda
-- Orden de ejecución: 8
-- Dependencias: 05_tablas_cuentas.sql, 06_tablas_transacciones.sql
-- ==================================================================

-- ==================================================================
-- ELIMINAR TABLAS EXISTENTES (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS compras_msi         CASCADE;
DROP TABLE IF EXISTS cuotas_deuda        CASCADE;
DROP TABLE IF EXISTS compras_deuda       CASCADE;

-- ==================================================================
-- CREAR TABLAS
-- ==================================================================

-- Compras financiadas (meses sin intereses o a plazos)
CREATE TABLE compras_deuda (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID             NOT NULL,
  cuenta_id        UUID             NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
  concepto         TEXT             NOT NULL,
  monto_total      NUMERIC(14,2)    NOT NULL CHECK (monto_total > 0),
  meses            INTEGER          NOT NULL CHECK (meses > 0),
  fecha_inicio     DATE             NOT NULL,
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),
  deleted_at       TIMESTAMPTZ
);

COMMENT ON TABLE compras_deuda IS 'Compras financiadas a meses con o sin intereses';
COMMENT ON COLUMN compras_deuda.meses IS 'Número de meses para liquidar la compra';
COMMENT ON COLUMN compras_deuda.fecha_inicio IS 'Fecha de la primera cuota o cargo';


-- Cuotas individuales de cada compra financiada
CREATE TABLE cuotas_deuda (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  compra_id         UUID             NOT NULL REFERENCES compras_deuda(id) ON DELETE CASCADE,
  numero_cuota      INTEGER          NOT NULL CHECK (numero_cuota > 0),
  monto             NUMERIC(14,2)    NOT NULL CHECK (monto > 0),
  fecha_vencimiento DATE             NOT NULL,
  pagada            BOOLEAN          NOT NULL DEFAULT FALSE,
  fecha_pago        TIMESTAMPTZ,
  transaccion_id    UUID             REFERENCES transacciones(id) ON DELETE SET NULL,
  notas             TEXT,
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT unico_numero_cuota_por_compra UNIQUE(compra_id, numero_cuota)
);

COMMENT ON TABLE cuotas_deuda IS 'Cuotas individuales de cada compra financiada';
COMMENT ON COLUMN cuotas_deuda.numero_cuota IS 'Número secuencial de la cuota (1, 2, 3, etc.)';
COMMENT ON COLUMN cuotas_deuda.pagada IS 'Estado del pago: TRUE si ya se pagó, FALSE si está pendiente';
COMMENT ON COLUMN cuotas_deuda.transaccion_id IS 'Referencia a la transacción de pago (si ya se pagó)';


-- Compras en Meses Sin Intereses (MSI)
CREATE TABLE compras_msi (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  compra_deuda_id   UUID             NOT NULL REFERENCES compras_deuda(id) ON DELETE CASCADE,
  cuenta_id         UUID             NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
  cuotas_totales    INTEGER          NOT NULL CHECK (cuotas_totales > 0),
  cuotas_pagadas    INTEGER          NOT NULL DEFAULT 0 CHECK (cuotas_pagadas >= 0),
  monto_cuota       NUMERIC(14,2)    NOT NULL CHECK (monto_cuota > 0),
  monto_restante    NUMERIC(14,2)    NOT NULL CHECK (monto_restante >= 0),
  fecha_fin_promocion DATE,
  tasa_interes_posterior NUMERIC(5,2),
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX ON compras_msi(cuenta_id);

COMMENT ON TABLE compras_msi IS 'Registro de compras realizadas con promociones de Meses Sin Intereses (MSI)';
COMMENT ON COLUMN compras_msi.compra_deuda_id IS 'Referencia a la compra padre en la tabla compras_deuda';
COMMENT ON COLUMN compras_msi.cuenta_id IS 'Cuenta (tarjeta de crédito) donde se realizó la compra MSI';
COMMENT ON COLUMN compras_msi.cuotas_totales IS 'Número total de meses sin intereses (3, 6, 9, 12, 18, 24, etc.)';
COMMENT ON COLUMN compras_msi.cuotas_pagadas IS 'Cantidad de cuotas que ya han sido pagadas';
COMMENT ON COLUMN compras_msi.monto_cuota IS 'Monto fijo que se paga cada mes durante la promoción MSI';
COMMENT ON COLUMN compras_msi.monto_restante IS 'Saldo pendiente de pagar de la compra MSI';
COMMENT ON COLUMN compras_msi.fecha_fin_promocion IS 'Fecha límite de la promoción sin intereses';
COMMENT ON COLUMN compras_msi.tasa_interes_posterior IS 'Tasa de interés que se aplicaría si no se completa el pago en tiempo';
