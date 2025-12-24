-- ==================================================================
-- 09. TABLAS DE METAS Y NOTIFICACIONES
-- ==================================================================
-- Descripción: Metas financieras, aportaciones, notificaciones e historial
-- Orden de ejecución: 9
-- Dependencias: 03_tablas_grupos_usuarios.sql, 04_tablas_catalogos.sql
-- ==================================================================

-- ==================================================================
-- ELIMINAR TABLAS EXISTENTES (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS notificaciones CASCADE;
DROP TABLE IF EXISTS historial_ingresos CASCADE;
DROP TABLE IF EXISTS aportaciones_meta_grupo CASCADE;
DROP TABLE IF EXISTS metas CASCADE;

-- ==================================================================
-- CREAR TABLAS
-- ==================================================================

-- Metas financieras (ahorro, compras planificadas, control de presupuesto)
CREATE TABLE metas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID,
    grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE,
    ambito ambito_meta NOT NULL DEFAULT 'personal',
    tipo tipo_meta NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    monto_objetivo NUMERIC(14,2) NOT NULL CHECK (monto_objetivo > 0),
    monto_actual NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (monto_actual >= 0),
    monto_periodo NUMERIC(14,2),
    periodicidad_id UUID REFERENCES periodicidades(id) ON DELETE SET NULL,
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    fecha_inicio DATE NOT NULL DEFAULT CURRENT_DATE,
    fecha_limite DATE,
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente' 
        CHECK (estado IN ('pendiente', 'en_progreso', 'completada', 'cancelada', 'pausada')),
    fecha_creacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_ambito_usuario_grupo CHECK (
        (ambito = 'personal' AND usuario_id IS NOT NULL AND grupo_id IS NULL) OR
        (ambito = 'grupo' AND usuario_id IS NULL AND grupo_id IS NOT NULL)
    ),
    CONSTRAINT chk_monto_actual_valido CHECK (monto_actual <= monto_objetivo)
);

CREATE INDEX idx_metas_usuario ON metas(usuario_id) WHERE usuario_id IS NOT NULL;
CREATE INDEX idx_metas_grupo ON metas(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX idx_metas_estado ON metas(estado);
CREATE INDEX idx_metas_tipo ON metas(tipo);
CREATE INDEX idx_metas_ambito ON metas(ambito);

COMMENT ON TABLE metas IS 'Almacena metas financieras personales y grupales';
COMMENT ON COLUMN metas.tipo IS 'Tipo de meta financiera: ahorro, compra, presupuesto';
COMMENT ON COLUMN metas.ambito IS 'Ámbito de la meta: personal (solo usuario) o grupo (compartida)';
COMMENT ON COLUMN metas.monto_objetivo IS 'Cantidad total que se quiere alcanzar';
COMMENT ON COLUMN metas.monto_actual IS 'Progreso actual hacia la meta';
COMMENT ON COLUMN metas.monto_periodo IS 'Cantidad sugerida a ahorrar por período (opcional)';
COMMENT ON COLUMN metas.estado IS 'Estado actual: pendiente, en_progreso, completada, cancelada, pausada';


-- Tabla de aportaciones a metas grupales
CREATE TABLE aportaciones_meta_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meta_id UUID NOT NULL REFERENCES metas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL,
    monto_asignado NUMERIC(14,2) NOT NULL CHECK (monto_asignado >= 0),
    monto_aportado NUMERIC(14,2) DEFAULT 0 CHECK (monto_aportado >= 0),
    porcentaje_peso NUMERIC(5,2) NOT NULL CHECK (porcentaje_peso >= 0 AND porcentaje_peso <= 100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT chk_montos_aportacion CHECK (monto_aportado >= 0 AND monto_aportado <= monto_asignado)
);

CREATE INDEX idx_aportaciones_meta ON aportaciones_meta_grupo(meta_id);
CREATE INDEX idx_aportaciones_usuario ON aportaciones_meta_grupo(usuario_id);

COMMENT ON TABLE aportaciones_meta_grupo IS 'Registra aportaciones individuales a metas grupales según porcentaje de peso';


-- Tabla de historial de ingresos
CREATE TABLE historial_ingresos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL,
    tipo_frecuencia VARCHAR(20) NOT NULL 
        CHECK (tipo_frecuencia IN ('quincenal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual')),
    monto_ingreso NUMERIC(14,2) NOT NULL CHECK (monto_ingreso >= 0),
    fecha_ingreso DATE NOT NULL,
    notas TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_historial_usuario ON historial_ingresos(usuario_id);
CREATE INDEX idx_historial_fecha ON historial_ingresos(fecha_ingreso);
CREATE INDEX idx_historial_frecuencia ON historial_ingresos(tipo_frecuencia);

COMMENT ON TABLE historial_ingresos IS 'Almacena histórico de ingresos para cálculos de promedios y estadísticas';


-- Notificaciones del sistema y bitácora de eventos importantes
CREATE TABLE notificaciones (
  id               UUID           DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id       UUID           NOT NULL,
  grupo_usuario_id UUID           REFERENCES grupos_usuario(id) ON DELETE CASCADE,
  tipo             VARCHAR(50)    NOT NULL,
  severidad        severidad      NOT NULL DEFAULT 'informacion',
  titulo           VARCHAR(200)   NOT NULL,
  mensaje          TEXT           NOT NULL,
  id_relacionado   UUID,
  metadatos        JSONB,
  leida            BOOLEAN        NOT NULL DEFAULT FALSE,
  fecha_creacion   TIMESTAMPTZ    NOT NULL DEFAULT now()
);

CREATE INDEX ON notificaciones(usuario_id, leida);
CREATE INDEX ON notificaciones(grupo_usuario_id);

COMMENT ON TABLE notificaciones IS 'Sistema de notificaciones y bitácora de eventos importantes';
COMMENT ON COLUMN notificaciones.tipo IS 'Tipo de evento: alerta_presupuesto, meta_completada, pago_vencido, etc.';
COMMENT ON COLUMN notificaciones.id_relacionado IS 'UUID del objeto relacionado (transacción, meta, cuenta, etc.)';
COMMENT ON COLUMN notificaciones.metadatos IS 'Datos adicionales necesarios para procesar la notificación';
COMMENT ON COLUMN notificaciones.leida IS 'Estado de lectura para el usuario destinatario';
