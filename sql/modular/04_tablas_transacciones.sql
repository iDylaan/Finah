-- ==================================================================
-- SCRIPT: 04_tablas_transacciones.sql
-- DESCRIPCIÓN: Crea las tablas relacionadas con transacciones, divisiones,
--              deudas, MSI, reglas recurrentes, metas y notificaciones
-- DEPENDENCIAS: 
--   - 01_extensiones_y_tipos.sql (tipos ENUM y extensiones)
--   - 02_tablas_catalogos.sql (catálogos: categorías, niveles, periodicidades)
--   - 03_tablas_grupos_y_cuentas.sql (grupos, cuentas, miembros)
-- ORDEN DE EJECUCIÓN: 4
-- ==================================================================

-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS notificaciones CASCADE;       -- Notificaciones del sistema
DROP TABLE IF EXISTS metas CASCADE;                -- Metas de ahorro y gastos
DROP TABLE IF EXISTS reglas_recurrentes CASCADE;   -- Reglas para transacciones automáticas
DROP TABLE IF EXISTS cuotas_deuda CASCADE;         -- Cuotas individuales de deudas
DROP TABLE IF EXISTS compras_msi CASCADE;          -- Compras en meses sin intereses
DROP TABLE IF EXISTS compras_deuda CASCADE;        -- Compras a meses sin intereses o crédito
DROP TABLE IF EXISTS divisiones_transaccion CASCADE; -- División de gastos grupales
DROP TABLE IF EXISTS transacciones CASCADE;        -- Todas las transacciones financieras


-- ==================================================================
-- 2) Crear tabla de transacciones
-- ==================================================================

-- 2.1) Registro de todas las transacciones financieras
CREATE TABLE transacciones (
  id               UUID              DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID              NOT NULL REFERENCES profiles(id),    -- Usuario que registró la transacción
  cuenta_id        UUID              NOT NULL REFERENCES cuentas(id) ON DELETE RESTRICT,     -- Cuenta donde se realizó
  categoria_id     UUID              NOT NULL REFERENCES categorias(id),  -- Categoría del gasto/ingreso
  nivel_id         UUID              REFERENCES niveles(id),              -- Nivel de prioridad (opcional)
  tipo             tipo_transaccion  NOT NULL,                            -- Tipo de transacción
  severidad        severidad         NOT NULL DEFAULT 'secundario',       -- Nivel de importancia para alertas
  monto            NUMERIC(14,2)     NOT NULL,                            -- Cantidad de dinero
  fecha_ocurrencia DATE              NOT NULL,                            -- Cuándo ocurrió realmente
  descripcion      TEXT,                                                  -- Descripción opcional
  url_recibo       TEXT,                                                  -- URL del comprobante/recibo
  metadatos        JSONB,                                                 -- Datos adicionales (ID de deuda, cuota, etc.)
  -- Campos para MSI (Meses Sin Intereses) - Foreign key se agrega después
  es_cuota_msi      BOOLEAN           DEFAULT FALSE,                     -- TRUE si es una cuota de MSI
  msi_id            UUID,                                                -- Referencia al MSI padre (constraint se agrega después)
  numero_cuota_msi  INTEGER,                                             -- Número de cuota (1, 2, 3, etc.)
  estado_msi        VARCHAR(20)       DEFAULT 'programada'               -- Estado: 'programada', 'pendiente_pago', 'pagada', 'vencida'
                    CHECK (estado_msi IN ('programada', 'pendiente_pago', 'pagada', 'vencida', NULL)),
  fecha_creacion   TIMESTAMPTZ       NOT NULL DEFAULT now(),             -- Cuándo se registró
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now(),              -- Última modificación
  deleted_at       TIMESTAMPTZ                                            -- Baja lógica: NULL = activa, con fecha = eliminada
);
-- Índices para mejorar consultas
CREATE INDEX ON transacciones(usuario_id, fecha_ocurrencia); -- Buscar por usuario y fecha
CREATE INDEX ON transacciones(cuenta_id);                    -- Buscar por cuenta
CREATE INDEX ON transacciones(categoria_id);                 -- Buscar por categoría
CREATE INDEX ON transacciones(severidad);                    -- Buscar por severidad
CREATE INDEX ON transacciones(msi_id) WHERE es_cuota_msi = TRUE; -- Buscar cuotas de un MSI
CREATE INDEX ON transacciones(cuenta_id, fecha_ocurrencia, es_cuota_msi); -- Queries por periodo
CREATE INDEX ON transacciones(estado_msi) WHERE es_cuota_msi = TRUE; -- Buscar por estado MSI

-- Comentarios para campos MSI
COMMENT ON COLUMN transacciones.es_cuota_msi IS 'TRUE si esta transacción es una cuota de pago diferido (MSI)';
COMMENT ON COLUMN transacciones.msi_id IS 'ID del MSI padre en transacciones_periodicas';
COMMENT ON COLUMN transacciones.numero_cuota_msi IS 'Número de cuota dentro del plan MSI (1, 2, 3, etc.)';
COMMENT ON COLUMN transacciones.estado_msi IS 'Estado de la cuota MSI: programada (futura), pendiente_pago (en periodo actual), pagada (ya se pagó el periodo), vencida (no se pagó a tiempo)';


-- ==================================================================
-- 3) Crear tabla de divisiones de transacciones
-- ==================================================================

-- 3.1) División de gastos grupales entre miembros
CREATE TABLE divisiones_transaccion (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  transaccion_id  UUID             NOT NULL REFERENCES transacciones(id) ON DELETE CASCADE, -- Transacción que se divide
  usuario_id      UUID             NOT NULL REFERENCES profiles(id),                        -- Usuario responsable de esta parte
  porcentaje_participacion NUMERIC(5,2) NOT NULL,                                          -- Porcentaje que le corresponde
  monto           NUMERIC(14,2)    NOT NULL,                                                -- Monto específico de esta división
  fecha_creacion  TIMESTAMPTZ      NOT NULL DEFAULT now()                                  -- Cuándo se creó la división
);
-- Índice para buscar divisiones por transacción
CREATE INDEX ON divisiones_transaccion(transaccion_id);


-- ==================================================================
-- 4) Crear tablas de deudas y cuotas
-- ==================================================================

-- 4.1) Compras financiadas (meses sin intereses o a plazos)
CREATE TABLE compras_deuda (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID             NOT NULL REFERENCES profiles(id),   -- Usuario que realizó la compra
  cuenta_id        UUID             NOT NULL REFERENCES cuentas(id) ON DELETE RESTRICT,    -- Cuenta donde se cargó (tarjeta de crédito)
  descripcion      TEXT,                                                -- Descripción de lo que se compró
  monto_total      NUMERIC(14,2)    NOT NULL,                          -- Monto total de la compra
  meses            INT              NOT NULL,                           -- Número de meses para pagar
  fecha_inicio     DATE             NOT NULL,                           -- Cuándo empezó a pagarse
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),             -- Cuándo se registró
  deleted_at       TIMESTAMPTZ                                          -- Baja lógica: NULL = activa, con fecha = eliminada
);


-- 4.2) Cuotas individuales de cada compra financiada
CREATE TABLE cuotas_deuda (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  compra_id         UUID             NOT NULL REFERENCES compras_deuda(id) ON DELETE CASCADE, -- Compra a la que pertenece
  numero_cuota      INT              NOT NULL,                                                 -- Número de cuota (1, 2, 3...)
  fecha_vencimiento DATE             NOT NULL,                                                 -- Cuándo vence esta cuota
  monto             NUMERIC(14,2)    NOT NULL,                                                -- Monto de esta cuota específica
  pagada            BOOLEAN          NOT NULL DEFAULT FALSE,                                  -- Si ya se pagó o no
  fecha_pago        TIMESTAMPTZ,                                                             -- Cuándo se pagó (si aplica)
  transaccion_id    UUID             REFERENCES transacciones(id),                           -- Transacción del pago (si aplica)
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),                                 -- Cuándo se creó el registro
  
  -- Restricción: solo una cuota por número en cada compra
  CONSTRAINT unico_numero_cuota_por_compra UNIQUE(compra_id, numero_cuota)
);


-- ==================================================================
-- 5) Crear tabla de compras MSI
-- ==================================================================

-- 5.1) Compras en Meses Sin Intereses (MSI)
CREATE TABLE compras_msi (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  compra_deuda_id   UUID             REFERENCES compras_deuda(id) ON DELETE CASCADE,  -- Compra padre a la que pertenece
  cuenta_id         UUID             NOT NULL REFERENCES cuentas(id),                 -- Cuenta (tarjeta de crédito) donde se realizó la compra MSI
  cuotas_totales    INT              NOT NULL,                                         -- Número total de MSI (3, 6, 12, 18, 24 meses)
  cuotas_pagadas    INT              NOT NULL DEFAULT 0,                              -- Cuotas ya pagadas
  monto_cuota       NUMERIC(14,2)    NOT NULL,                                        -- Monto fijo a pagar cada mes
  monto_restante    NUMERIC(14,2)    NOT NULL,                                        -- Cantidad que aún falta por pagar
  fecha_fin_promocion DATE,                                                          -- Cuándo termina la promoción sin intereses
  tasa_interes_posterior NUMERIC(5,2),                                               -- Tasa de interés que aplicaría después de la promoción
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),                         -- Cuándo se registró la compra MSI
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now()                          -- Última modificación del registro
);
-- Índice para buscar compras MSI por cuenta
CREATE INDEX ON compras_msi(cuenta_id);

-- Comentarios explicativos para la tabla de MSI
COMMENT ON TABLE compras_msi IS 'Registro de compras realizadas con promociones de Meses Sin Intereses (MSI)';
COMMENT ON COLUMN compras_msi.compra_deuda_id IS 'Referencia a la compra padre en la tabla compras_deuda';
COMMENT ON COLUMN compras_msi.cuenta_id IS 'Cuenta (tarjeta de crédito) donde se realizó la compra MSI';
COMMENT ON COLUMN compras_msi.cuotas_totales IS 'Número total de meses sin intereses (3, 6, 9, 12, 18, 24, etc.)';
COMMENT ON COLUMN compras_msi.cuotas_pagadas IS 'Cantidad de cuotas que ya han sido pagadas';
COMMENT ON COLUMN compras_msi.monto_cuota IS 'Monto fijo que se paga cada mes durante la promoción MSI';
COMMENT ON COLUMN compras_msi.monto_restante IS 'Saldo pendiente de pagar de la compra MSI';
COMMENT ON COLUMN compras_msi.fecha_fin_promocion IS 'Fecha límite de la promoción sin intereses';
COMMENT ON COLUMN compras_msi.tasa_interes_posterior IS 'Tasa de interés que se aplicaría si no se completa el pago en tiempo';


-- ==================================================================
-- 6) Crear tabla de reglas recurrentes
-- ==================================================================

-- 6.1) Reglas para transacciones que se repiten automáticamente
CREATE TABLE reglas_recurrentes (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID             NOT NULL REFERENCES profiles(id),    -- Usuario propietario de la regla
  nombre           TEXT             NOT NULL,                            -- Nombre descriptivo (ej: "Renta mensual")
  tipo             tipo_transaccion NOT NULL,                           -- Tipo de transacción que generará
  cuenta_id        UUID             NOT NULL REFERENCES cuentas(id),    -- Cuenta donde se aplicará
  categoria_id     UUID             NOT NULL REFERENCES categorias(id), -- Categoría que se asignará
  nivel_id         UUID             REFERENCES niveles(id),             -- Nivel de prioridad (opcional)
  monto            NUMERIC(14,2)    NOT NULL,                           -- Monto de cada transacción
  periodicidad_id  UUID             NOT NULL REFERENCES periodicidades(id), -- Qué tan seguido se ejecuta
  fecha_inicio     DATE             NOT NULL,                           -- Cuándo empezó la regla
  fecha_fin        DATE,                                                -- Cuándo termina (opcional)
  proxima_ejecucion DATE,                                               -- Cuándo se ejecutará la próxima vez
  metadatos        JSONB,                                               -- Datos adicionales
  activa           BOOLEAN          NOT NULL DEFAULT TRUE,              -- Si la regla está activa
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now()             -- Cuándo se creó
);
-- Índice para encontrar reglas que deben ejecutarse
CREATE INDEX ON reglas_recurrentes(proxima_ejecucion);


-- ==================================================================
-- 7) Crear tabla de metas
-- ==================================================================

-- 7.1) Metas financieras (ahorro, compras, control de presupuesto)
CREATE TABLE metas (
  id                UUID           DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id        UUID           NOT NULL REFERENCES profiles(id),     -- Usuario propietario de la meta
  grupo_usuario_id  UUID           REFERENCES grupos_usuario(id),        -- Grupo al que pertenece (opcional)
  tipo              tipo_meta      NOT NULL,                             -- Tipo de meta (ahorro, compra, presupuesto)
  titulo            TEXT           NOT NULL,                             -- Título descriptivo (ej: "Viaje a Europa")
  monto_objetivo    NUMERIC(14,2)  NOT NULL,                            -- Cantidad que se quiere alcanzar
  monto_actual      NUMERIC(14,2)  NOT NULL DEFAULT 0,                  -- Cantidad acumulada hasta ahora
  fecha_inicio      DATE           NOT NULL,                             -- Cuándo empezó la meta
  fecha_fin         DATE,                                                -- Cuándo se quiere completar (opcional)
  periodicidad_id   UUID           REFERENCES periodicidades(id),       -- Frecuencia de aportaciones (opcional)
  monto_periodo     NUMERIC(14,2),                                      -- Cantidad a ahorrar por período
  categoria_id      UUID           REFERENCES categorias(id),           -- Categoría relacionada (opcional)
  estado            TEXT           NOT NULL DEFAULT 'pendiente',        -- Estado actual (pendiente, en_progreso, completada, cancelada)
  fecha_creacion    TIMESTAMPTZ    NOT NULL DEFAULT now(),             -- Cuándo se creó
  fecha_actualizacion TIMESTAMPTZ  NOT NULL DEFAULT now()              -- Última modificación
);
-- Índices para mejorar consultas
CREATE INDEX ON metas(usuario_id);        -- Buscar metas por usuario
CREATE INDEX ON metas(grupo_usuario_id);  -- Buscar metas por grupo


-- ==================================================================
-- 8) Crear tabla de notificaciones
-- ==================================================================

-- 8.1) Notificaciones del sistema y bitácora de eventos importantes
CREATE TABLE notificaciones (
  id               UUID           DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID           NOT NULL REFERENCES profiles(id),     -- Usuario destinatario
  grupo_usuario_id UUID           REFERENCES grupos_usuario(id),        -- Grupo relacionado (opcional)
  tipo             TEXT           NOT NULL,                             -- Tipo de notificación (alerta_presupuesto, meta_completada, etc.)
  id_relacionado   UUID,                                                -- ID del objeto relacionado (transacción, meta, etc.)
  titulo           TEXT           NOT NULL,                             -- Título de la notificación
  mensaje          TEXT           NOT NULL,                             -- Contenido del mensaje
  metadatos        JSONB,                                               -- Datos adicionales en JSON
  leida            BOOLEAN        NOT NULL DEFAULT FALSE,              -- Si el usuario ya la leyó
  fecha_creacion   TIMESTAMPTZ    NOT NULL DEFAULT now()               -- Cuándo se generó
);
-- Índices para mejorar consultas
CREATE INDEX ON notificaciones(usuario_id, leida);   -- Buscar notificaciones no leídas por usuario
CREATE INDEX ON notificaciones(grupo_usuario_id);    -- Buscar notificaciones por grupo


-- ==================================================================
-- Mensaje de confirmación
-- ==================================================================
DO $$
BEGIN
  RAISE NOTICE '✓ Archivo 04_tablas_transacciones.sql ejecutado correctamente';
  RAISE NOTICE '  - Tablas creadas: transacciones, divisiones_transaccion, compras_deuda, cuotas_deuda';
  RAISE NOTICE '  - Tablas creadas: compras_msi, reglas_recurrentes, metas, notificaciones';
END $$;
