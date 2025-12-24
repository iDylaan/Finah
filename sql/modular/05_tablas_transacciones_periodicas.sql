-- ==================================================================
-- SCRIPT: 05_tablas_transacciones_periodicas.sql
-- DESCRIPCIÓN: Crea las tablas para transacciones periódicas (recurrentes),
--              ejecuciones de transacciones periódicas, y funciones relacionadas
-- DEPENDENCIAS: 
--   - 01_extensiones_y_tipos.sql (tipos ENUM y extensiones)
--   - 02_tablas_catalogos.sql (catálogos: categorías, niveles, periodicidades)
--   - 03_tablas_grupos_y_cuentas.sql (grupos, cuentas)
--   - 04_tablas_transacciones.sql (transacciones)
-- ORDEN DE EJECUCIÓN: 5
-- ==================================================================

-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS ejecuciones_transacciones_periodicas CASCADE; -- Ejecuciones de transacciones periódicas
DROP TABLE IF EXISTS transacciones_periodicas CASCADE;             -- Transacciones programadas/recurrentes


-- ==================================================================
-- 2) Crear función auxiliar para updated_at
-- ==================================================================

-- Función genérica para actualizar timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Función trigger para actualizar automáticamente el campo updated_at';


-- ==================================================================
-- 3) Crear tabla de transacciones periódicas
-- ==================================================================

-- 3.1) Tabla principal de transacciones periódicas
CREATE TABLE transacciones_periodicas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Información básica
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo tipo_transaccion NOT NULL, -- 'ingreso', 'gasto', 'transferencia'
    
    -- Monto
    monto DECIMAL(15, 2) NOT NULL CHECK (monto > 0),
    
    -- ========================================
    -- CONFIGURACIÓN DE RECURRENCIA AVANZADA
    -- ========================================
    
    frecuencia frecuencia_transaccion NOT NULL,
    
    -- Para frecuencia 'dias_naturales': cada X días
    intervalo_dias INTEGER, -- Ej: 30 para cada 30 días
    
    -- Para frecuencia 'mensual': día específico del mes
    dia_del_mes INTEGER CHECK (dia_del_mes >= 1 AND dia_del_mes <= 31),
    
    -- Para frecuencia 'semanal': días de la semana
    dias_semana dia_semana[], -- Array de días ['lunes', 'miercoles', 'viernes']
    
    -- Para frecuencia 'anual': mes y día específico
    mes_del_anio INTEGER CHECK (mes_del_anio >= 1 AND mes_del_anio <= 12),
    dia_del_anio INTEGER CHECK (dia_del_anio >= 1 AND dia_del_anio <= 31),
    
    -- ========================================
    -- CRITERIOS DE FINALIZACIÓN
    -- ========================================
    
    criterio_fin criterio_finalizacion NOT NULL DEFAULT 'sin_fin',
    
    -- Si criterio_fin = 'fecha_fin'
    fecha_fin DATE,
    
    -- Si criterio_fin = 'numero_repeticiones'
    numero_total_repeticiones INTEGER,
    repeticiones_completadas INTEGER DEFAULT 0,
    
    -- ========================================
    -- ESPECÍFICO PARA MSI
    -- ========================================
    
    es_msi BOOLEAN DEFAULT FALSE,
    monto_total_msi DECIMAL(15, 2), -- Monto total del MSI
    numero_meses_total INTEGER, -- Total de meses del MSI
    meses_pagados INTEGER DEFAULT 0, -- Meses ya pagados (para registros avanzados)
    monto_por_mes DECIMAL(15, 2), -- Monto mensual calculado (auto-calculado)
    
    -- ========================================
    -- CUENTA(S) INVOLUCRADA(S)
    -- ========================================
    
    cuenta_id UUID REFERENCES cuentas(id) ON DELETE CASCADE,
    cuenta_destino_id UUID REFERENCES cuentas(id) ON DELETE SET NULL, -- Para transferencias
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    
    -- ========================================
    -- PROGRAMACIÓN Y ESTADO
    -- ========================================
    
    fecha_inicio DATE NOT NULL,
    proxima_ejecucion TIMESTAMP WITH TIME ZONE,
    
    -- ========================================
    -- CONTROL DE EJECUCIÓN
    -- ========================================
    
    activa BOOLEAN DEFAULT TRUE,
    requiere_confirmacion BOOLEAN DEFAULT TRUE, -- FALSE para MSI en tarjetas de crédito
    auto_ejecutar BOOLEAN DEFAULT FALSE, -- TRUE para MSI, FALSE para otras
    
    -- ========================================
    -- METADATA
    -- ========================================
    
    etiquetas TEXT[],
    notas TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- ========================================
    -- CONSTRAINTS
    -- ========================================
    
    -- MSI debe tener todos los campos requeridos
    CONSTRAINT chk_msi_completo CHECK (
        NOT es_msi OR (
            monto_total_msi IS NOT NULL AND
            numero_meses_total IS NOT NULL AND
            monto_por_mes IS NOT NULL AND
            cuenta_id IS NOT NULL AND
            frecuencia = 'msi'
        )
    ),
    
    -- Validar que si usa días_naturales tenga intervalo_dias
    CONSTRAINT chk_dias_naturales CHECK (
        frecuencia != 'dias_naturales' OR intervalo_dias IS NOT NULL
    ),
    
    -- Validar que si es mensual tenga dia_del_mes
    CONSTRAINT chk_mensual CHECK (
        frecuencia != 'mensual' OR dia_del_mes IS NOT NULL
    ),
    
    -- Validar que si es semanal tenga dias_semana
    CONSTRAINT chk_semanal CHECK (
        frecuencia != 'semanal' OR (dias_semana IS NOT NULL AND array_length(dias_semana, 1) > 0)
    ),
    
    -- Validar que si es anual tenga mes y día
    CONSTRAINT chk_anual CHECK (
        frecuencia != 'anual' OR (mes_del_anio IS NOT NULL AND dia_del_anio IS NOT NULL)
    ),
    
    -- Validar criterios de finalización
    CONSTRAINT chk_fecha_fin CHECK (
        criterio_fin != 'fecha_fin' OR fecha_fin IS NOT NULL
    ),
    
    CONSTRAINT chk_numero_repeticiones CHECK (
        criterio_fin != 'numero_repeticiones' OR numero_total_repeticiones IS NOT NULL
    )
);

-- Índices para transacciones_periodicas
CREATE INDEX ON transacciones_periodicas(usuario_id);
CREATE INDEX ON transacciones_periodicas(cuenta_id);
CREATE INDEX ON transacciones_periodicas(proxima_ejecucion) WHERE activa = TRUE;
CREATE INDEX ON transacciones_periodicas(activa);

-- Trigger para updated_at
CREATE TRIGGER update_transacciones_periodicas_updated_at
    BEFORE UPDATE ON transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para transacciones_periodicas
COMMENT ON TABLE transacciones_periodicas IS 'Transacciones programadas y recurrentes - soporta ingresos periódicos, gastos recurrentes, MSI, etc.';
COMMENT ON COLUMN transacciones_periodicas.frecuencia IS 'Tipo de frecuencia: diaria, semanal, mensual, etc.';
COMMENT ON COLUMN transacciones_periodicas.intervalo_dias IS 'Para frecuencia dias_naturales: ejecutar cada X días (ej: cada 30 días)';
COMMENT ON COLUMN transacciones_periodicas.dia_del_mes IS 'Para frecuencia mensual: día específico del mes (1-31)';
COMMENT ON COLUMN transacciones_periodicas.dias_semana IS 'Para frecuencia semanal: array de días [''lunes'', ''miercoles'', ''viernes'']';
COMMENT ON COLUMN transacciones_periodicas.mes_del_anio IS 'Para frecuencia anual: mes específico (1-12)';
COMMENT ON COLUMN transacciones_periodicas.dia_del_anio IS 'Para frecuencia anual: día específico (1-31)';
COMMENT ON COLUMN transacciones_periodicas.criterio_fin IS 'Cómo determinar cuándo termina: sin_fin, fecha_fin, numero_repeticiones';
COMMENT ON COLUMN transacciones_periodicas.fecha_fin IS 'Fecha límite si criterio_fin = fecha_fin';
COMMENT ON COLUMN transacciones_periodicas.numero_total_repeticiones IS 'Total de veces a repetir si criterio_fin = numero_repeticiones';
COMMENT ON COLUMN transacciones_periodicas.repeticiones_completadas IS 'Contador de repeticiones completadas';
COMMENT ON COLUMN transacciones_periodicas.es_msi IS 'TRUE si es un pago a Meses Sin Intereses';
COMMENT ON COLUMN transacciones_periodicas.monto_total_msi IS 'Monto total de la compra MSI';
COMMENT ON COLUMN transacciones_periodicas.numero_meses_total IS 'Total de meses del MSI (3, 6, 9, 12, 18, 24)';
COMMENT ON COLUMN transacciones_periodicas.meses_pagados IS 'Meses ya pagados (útil para registrar MSI en progreso)';
COMMENT ON COLUMN transacciones_periodicas.monto_por_mes IS 'Monto mensual calculado (monto_total / numero_meses)';


-- ==================================================================
-- 4) Agregar foreign key a tabla transacciones
-- ==================================================================

-- Agregar foreign key constraint para transacciones.msi_id (ahora que transacciones_periodicas existe)
ALTER TABLE transacciones 
ADD CONSTRAINT fk_transacciones_msi_id 
FOREIGN KEY (msi_id) REFERENCES transacciones_periodicas(id) ON DELETE CASCADE;

COMMENT ON CONSTRAINT fk_transacciones_msi_id ON transacciones IS 'Foreign key a transacciones_periodicas para cuotas MSI';


-- ==================================================================
-- 5) Crear tabla de ejecuciones de transacciones periódicas
-- ==================================================================

-- 5.1) Tabla para ejecuciones de transacciones periódicas
CREATE TABLE ejecuciones_transacciones_periodicas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaccion_periodica_id UUID NOT NULL REFERENCES transacciones_periodicas(id) ON DELETE CASCADE,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL, -- NULL si está pendiente
    
    -- Estado
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente', -- 'pendiente', 'confirmada', 'ejecutada', 'cancelada', 'fallida'
    
    -- Fechas
    fecha_programada DATE NOT NULL,
    fecha_ejecutada TIMESTAMP WITH TIME ZONE,
    fecha_confirmada TIMESTAMP WITH TIME ZONE,
    
    -- Monto (puede variar si el usuario lo ajusta)
    monto_programado DECIMAL(15, 2) NOT NULL,
    monto_ejecutado DECIMAL(15, 2),
    
    -- Para MSI
    numero_cuota INTEGER, -- Número de cuota (1, 2, 3, etc.)
    
    -- Notas
    notas TEXT,
    error_mensaje TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE  -- Baja lógica: NULL = activa, con fecha = eliminada
);

-- Índices para ejecuciones_transacciones_periodicas
CREATE INDEX ON ejecuciones_transacciones_periodicas(transaccion_periodica_id);
CREATE INDEX ON ejecuciones_transacciones_periodicas(estado);
CREATE INDEX ON ejecuciones_transacciones_periodicas(fecha_programada);

-- Trigger para updated_at
CREATE TRIGGER update_ejecuciones_periodicas_updated_at
    BEFORE UPDATE ON ejecuciones_transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comentarios para ejecuciones_transacciones_periodicas
COMMENT ON TABLE ejecuciones_transacciones_periodicas IS 'Registro de cada ejecución individual de una transacción periódica';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.transaccion_periodica_id IS 'Referencia a la transacción periódica que se ejecuta';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.transaccion_id IS 'Referencia a la transacción real creada (NULL si aún está pendiente)';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.estado IS 'Estado de la ejecución: pendiente, confirmada, ejecutada, cancelada, fallida';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.fecha_programada IS 'Fecha en que estaba programada la ejecución';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.fecha_ejecutada IS 'Fecha en que se ejecutó realmente';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.fecha_confirmada IS 'Fecha en que el usuario confirmó la ejecución';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.monto_programado IS 'Monto originalmente programado';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.monto_ejecutado IS 'Monto realmente ejecutado (puede variar si el usuario lo ajustó)';
COMMENT ON COLUMN ejecuciones_transacciones_periodicas.numero_cuota IS 'Número de cuota para pagos MSI (1, 2, 3, etc.)';


-- ==================================================================
-- Mensaje de confirmación
-- ==================================================================
DO $$
BEGIN
  RAISE NOTICE '✓ Archivo 05_tablas_transacciones_periodicas.sql ejecutado correctamente';
  RAISE NOTICE '  - Tablas creadas: transacciones_periodicas, ejecuciones_transacciones_periodicas';
  RAISE NOTICE '  - Función creada: update_updated_at_column()';
  RAISE NOTICE '  - Foreign key agregado: transacciones.msi_id -> transacciones_periodicas.id';
END $$;
