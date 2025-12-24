-- ==================================================================
-- FINAH - Sistema de Gestión Financiera
-- Archivo: 09_sistema_grupos_fase1.sql
-- Descripción: Sistema de grupos fase 1 - Tablas principales, triggers y funciones
-- ==================================================================
-- 
-- Este archivo contiene la implementación completa del sistema de grupos
-- incluyendo las modificaciones a tablas existentes, nuevas tablas,
-- triggers y funciones para la gestión de grupos colaborativos.
--
-- Contenido:
-- - Modificaciones a tabla grupos_usuario
-- - Tabla invitaciones_grupo completa
-- - Modificaciones a tablas existentes (niveles, categorías, bancos, cuentas, transacciones)
-- - Tablas de metas grupales
-- - Tabla aportaciones_meta_grupo
-- - Tabla historial_ingresos
-- - Triggers del sistema de grupos
-- - Funciones principales para gestión de grupos
--
-- Dependencias:
-- - 01_extensiones_y_tipos.sql
-- - 02_tablas_catalogos.sql
-- - 03_tablas_grupos_y_cuentas.sql
-- - 04_tablas_transacciones.sql
-- - 05_tablas_transacciones_periodicas.sql
-- - 06_triggers_y_funciones_auxiliares.sql
-- - 07_funciones_tarjetas_credito.sql
-- - 08_funciones_msi_y_periodicas.sql
-- - 08_tablas_deudas_msi.sql
--
-- Orden de ejecución: 9
-- ==================================================================

-- TABLAS PRINCIPALES DE GRUPOS
-- ==================================================================

-- NOTA: La tabla grupos_usuario ya está definida al inicio del script (línea ~156)
-- No se debe eliminar y recrear aquí porque causaría problemas con las dependencias
-- La tabla grupos_usuario ya tiene: id, propietario_id, nombre, descripcion, color, imagen_url, fecha_creacion

-- Agregar columnas adicionales a grupos_usuario si no existen
ALTER TABLE grupos_usuario ADD COLUMN IF NOT EXISTS limite_miembros INTEGER DEFAULT 10 CHECK (limite_miembros > 0 AND limite_miembros <= 50);
ALTER TABLE grupos_usuario ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT TRUE;
ALTER TABLE grupos_usuario ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Crear índices si no existen
CREATE INDEX IF NOT EXISTS idx_grupos_usuario_activo ON grupos_usuario(activo);

COMMENT ON COLUMN grupos_usuario.limite_miembros IS 'Número máximo de miembros permitidos en el grupo';
COMMENT ON COLUMN grupos_usuario.activo IS 'Indica si el grupo está activo o deshabilitado';

-- ==================================================================

-- NOTA: La tabla miembros_grupo ya está definida en la línea 394
-- Esta segunda definición ha sido eliminada para evitar conflictos de FK
-- La tabla miembros_grupo usa grupos_usuario(id) como debe ser

-- ==================================================================

-- Tabla de invitaciones a grupos (reemplaza invitaciones_grupo existente)
DROP TABLE IF EXISTS invitaciones_grupo CASCADE;

-- 4.18) Tabla de invitaciones a grupos
-- NOTA: Esta tabla NO tiene Row Level Security (RLS) habilitado
-- Se deshabilitó RLS para evitar problemas de permisos con auth.users
-- La seguridad se maneja mediante validación en frontend y funciones SECURITY DEFINER
-- ===================================================
-- 4.18) Invitaciones a grupos
-- ===================================================
-- NOTA: Esta tabla NO tiene Row Level Security (RLS) habilitado
-- Se deshabilitó RLS para evitar problemas de permisos con auth.users
-- La seguridad se maneja mediante validación en frontend y funciones SECURITY DEFINER
CREATE TABLE invitaciones_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos_usuario(id) ON DELETE CASCADE,
    email_invitado VARCHAR(255) NOT NULL,
    invitado_por UUID NOT NULL,
    rol_asignado rol_grupo NOT NULL DEFAULT 'miembro',
    estado estado_invitacion DEFAULT 'pendiente',
    mensaje TEXT,
    fecha_invitacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_expiracion TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    fecha_respuesta TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_email_valido CHECK (email_invitado ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_invitaciones_grupo ON invitaciones_grupo(grupo_id);
CREATE INDEX idx_invitaciones_email ON invitaciones_grupo(email_invitado);
CREATE INDEX idx_invitaciones_estado ON invitaciones_grupo(estado);
CREATE INDEX idx_invitaciones_expiracion ON invitaciones_grupo(fecha_expiracion) WHERE estado = 'pendiente';

-- Trigger para updated_at
CREATE TRIGGER update_invitaciones_grupo_updated_at
    BEFORE UPDATE ON invitaciones_grupo
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE invitaciones_grupo IS 'Gestiona invitaciones pendientes, aceptadas y rechazadas a grupos';
COMMENT ON COLUMN invitaciones_grupo.fecha_expiracion IS 'Invitación expira automáticamente después de 7 días';
COMMENT ON COLUMN invitaciones_grupo.invitado_por IS 'UUID del usuario que envió la invitación (sin foreign key a auth.users para evitar problemas de permisos RLS)';

-- ==================================================================
-- MODIFICACIONES A TABLAS EXISTENTES
-- ==================================================================

-- Niveles: Agregar soporte para grupos
ALTER TABLE niveles ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE;
ALTER TABLE niveles ADD COLUMN IF NOT EXISTS tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX IF NOT EXISTS idx_niveles_grupo ON niveles(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_niveles_visibilidad ON niveles(tipo_visibilidad);

COMMENT ON COLUMN niveles.grupo_id IS 'Si tiene valor, este nivel pertenece al grupo';
COMMENT ON COLUMN niveles.tipo_visibilidad IS 'Tipo de visibilidad: publico (todos), personal (solo usuario), grupo (miembros del grupo)';

-- Categorías: Agregar soporte para grupos
ALTER TABLE categorias ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE;
ALTER TABLE categorias ADD COLUMN IF NOT EXISTS tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX IF NOT EXISTS idx_categorias_grupo ON categorias(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_categorias_visibilidad ON categorias(tipo_visibilidad);

COMMENT ON COLUMN categorias.grupo_id IS 'Si tiene valor, esta categoría pertenece al grupo';
COMMENT ON COLUMN categorias.tipo_visibilidad IS 'Tipo de visibilidad del catálogo';

-- Grupos de Categoría: Agregar soporte para grupos
ALTER TABLE grupos_categoria ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE;
ALTER TABLE grupos_categoria ADD COLUMN IF NOT EXISTS tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX IF NOT EXISTS idx_grupos_categoria_grupo ON grupos_categoria(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_grupos_categoria_visibilidad ON grupos_categoria(tipo_visibilidad);

COMMENT ON COLUMN grupos_categoria.grupo_id IS 'Si tiene valor, este grupo de categoría pertenece al grupo';

-- Bancos: Agregar soporte para grupos
ALTER TABLE bancos ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE;
ALTER TABLE bancos ADD COLUMN IF NOT EXISTS tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX IF NOT EXISTS idx_bancos_grupo ON bancos(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_bancos_visibilidad ON bancos(tipo_visibilidad);

COMMENT ON COLUMN bancos.grupo_id IS 'Si tiene valor, este banco pertenece al grupo';

-- Cuentas: Agregar soporte para grupos y compartidas
ALTER TABLE cuentas ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE;
ALTER TABLE cuentas ADD COLUMN IF NOT EXISTS tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('personal', 'grupo'));
-- Columna creada_por ya existe, solo agregar comentario
COMMENT ON COLUMN cuentas.creada_por IS 'Usuario que creó la cuenta (admin/owner del grupo o usuario personal)';

CREATE INDEX IF NOT EXISTS idx_cuentas_grupo ON cuentas(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cuentas_visibilidad ON cuentas(tipo_visibilidad);

COMMENT ON COLUMN cuentas.grupo_id IS 'Si es NULL, es cuenta personal. Si tiene valor, es cuenta compartida del grupo';
COMMENT ON COLUMN cuentas.tipo_visibilidad IS 'personal: solo el usuario la ve, grupo: todos los miembros la ven';

-- Transacciones: Agregar información de divisiones y usuario
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE SET NULL;
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS registrada_por UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS es_gasto_compartido BOOLEAN DEFAULT FALSE;
ALTER TABLE transacciones ADD COLUMN IF NOT EXISTS division_gastos JSONB;

CREATE INDEX IF NOT EXISTS idx_transacciones_grupo ON transacciones(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transacciones_registrada_por ON transacciones(registrada_por);
CREATE INDEX IF NOT EXISTS idx_transacciones_compartido ON transacciones(es_gasto_compartido) WHERE es_gasto_compartido = TRUE;

COMMENT ON COLUMN transacciones.registrada_por IS 'Usuario que registró la transacción';
COMMENT ON COLUMN transacciones.division_gastos IS 'JSON con división del gasto entre miembros: [{usuario_id, monto_asignado, porcentaje, pagado}]';

-- Transacciones Periódicas: Agregar grupo y clasificación de ingresos
ALTER TABLE transacciones_periodicas ADD COLUMN IF NOT EXISTS grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE SET NULL;
ALTER TABLE transacciones_periodicas ADD COLUMN IF NOT EXISTS es_ingreso_base BOOLEAN DEFAULT FALSE;
ALTER TABLE transacciones_periodicas ADD COLUMN IF NOT EXISTS tipo_ingreso VARCHAR(20) 
    CHECK (tipo_ingreso IN ('quincenal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual'));

CREATE INDEX IF NOT EXISTS idx_transacciones_periodicas_grupo ON transacciones_periodicas(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_transacciones_periodicas_ingreso_base ON transacciones_periodicas(es_ingreso_base) WHERE es_ingreso_base = TRUE;

COMMENT ON COLUMN transacciones_periodicas.es_ingreso_base IS 'Marca si este ingreso se usa para calcular peso en grupo';
COMMENT ON COLUMN transacciones_periodicas.tipo_ingreso IS 'Frecuencia del ingreso para cálculos anuales';

-- ==================================================================
-- TABLAS DE METAS GRUPALES
-- ==================================================================

-- Reemplazar tabla metas existente
DROP TABLE IF EXISTS metas CASCADE;

CREATE TABLE metas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    grupo_id UUID REFERENCES grupos_usuario(id) ON DELETE CASCADE,
    tipo tipo_meta NOT NULL,                                    -- Tipo de meta: ahorro, compra, presupuesto
    ambito ambito_meta NOT NULL DEFAULT 'personal',            -- Ámbito: personal o grupo
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    monto_objetivo DECIMAL(15, 2) NOT NULL CHECK (monto_objetivo > 0),
    monto_actual DECIMAL(15, 2) DEFAULT 0.00 CHECK (monto_actual >= 0),
    fecha_objetivo DATE,
    estado estado_meta DEFAULT 'activa',
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    biblioteca_iconos VARCHAR(50) DEFAULT 'material',
    nombre_icono VARCHAR(100) DEFAULT 'flag',
    color VARCHAR(7) DEFAULT '#4CAF50',
    prioridad INTEGER DEFAULT 1 CHECK (prioridad >= 1 AND prioridad <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_meta_ambito CHECK (
        (ambito = 'personal' AND usuario_id IS NOT NULL AND grupo_id IS NULL) OR
        (ambito = 'grupo' AND grupo_id IS NOT NULL AND usuario_id IS NULL)
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

-- Tabla de aportaciones a metas grupales
DROP TABLE IF EXISTS aportaciones_meta_grupo CASCADE;

CREATE TABLE aportaciones_meta_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meta_id UUID NOT NULL REFERENCES metas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    monto_asignado DECIMAL(15, 2) NOT NULL,
    monto_aportado DECIMAL(15, 2) DEFAULT 0.00,
    porcentaje_participacion DECIMAL(5, 2) NOT NULL,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
    fecha_aportacion TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(meta_id, usuario_id),
    CONSTRAINT chk_montos_aportacion CHECK (monto_aportado >= 0 AND monto_aportado <= monto_asignado)
);

CREATE INDEX idx_aportaciones_meta ON aportaciones_meta_grupo(meta_id);
CREATE INDEX idx_aportaciones_usuario ON aportaciones_meta_grupo(usuario_id);

COMMENT ON TABLE aportaciones_meta_grupo IS 'Registra aportaciones individuales a metas grupales según porcentaje de peso';

-- Tabla de historial de ingresos
DROP TABLE IF EXISTS historial_ingresos CASCADE;

CREATE TABLE historial_ingresos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
    transaccion_periodica_id UUID REFERENCES transacciones_periodicas(id) ON DELETE SET NULL,
    monto DECIMAL(15, 2) NOT NULL CHECK (monto > 0),
    tipo_frecuencia VARCHAR(20) CHECK (tipo_frecuencia IN ('quincenal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual', 'variable')),
    fecha_ingreso DATE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_historial_usuario ON historial_ingresos(usuario_id);
CREATE INDEX idx_historial_fecha ON historial_ingresos(fecha_ingreso);
CREATE INDEX idx_historial_frecuencia ON historial_ingresos(tipo_frecuencia);

COMMENT ON TABLE historial_ingresos IS 'Almacena histórico de ingresos para cálculos de promedios y estadísticas';

-- ==================================================================
-- TRIGGERS PARA SISTEMA DE GRUPOS
-- ==================================================================

-- Trigger para actualizar updated_at en grupos_usuario
DROP TRIGGER IF EXISTS trg_grupos_usuario_updated_at ON grupos_usuario;
CREATE TRIGGER trg_grupos_usuario_updated_at
    BEFORE UPDATE ON grupos_usuario
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para actualizar updated_at en miembros_grupo
-- Nota: miembros_grupo no tiene columna updated_at, se omite este trigger

-- Trigger para crear miembro owner al crear grupo
-- NOTA: Ya existe el trigger "al_crear_grupo_asignar_admin" que hace esto mismo
-- No se crea duplicado para evitar conflictos

-- Trigger para validar un solo owner por grupo
CREATE OR REPLACE FUNCTION validar_un_owner_por_grupo()
RETURNS TRIGGER AS $$
DECLARE
    v_count_owners INTEGER;
BEGIN
    IF NEW.rol = 'owner' THEN
        SELECT COUNT(*) INTO v_count_owners
        FROM miembros_grupo
        WHERE grupo_id = NEW.grupo_id
            AND rol = 'owner'
            AND (TG_OP = 'INSERT' OR id != NEW.id);
        
        IF v_count_owners > 0 THEN
            RAISE EXCEPTION 'Ya existe un owner en este grupo. Solo puede haber un owner por grupo.';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validar_un_owner ON miembros_grupo;
CREATE TRIGGER trg_validar_un_owner
    BEFORE INSERT OR UPDATE ON miembros_grupo
    FOR EACH ROW
    EXECUTE FUNCTION validar_un_owner_por_grupo();

-- Trigger para marcar invitación como expirada automáticamente
CREATE OR REPLACE FUNCTION marcar_invitacion_expirada()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_expiracion < NOW() AND NEW.estado = 'pendiente' THEN
        NEW.estado = 'expirada';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_marcar_invitacion_expirada
    BEFORE INSERT OR UPDATE ON invitaciones_grupo
    FOR EACH ROW
    EXECUTE FUNCTION marcar_invitacion_expirada();

-- Trigger para recalcular pesos al cambiar miembros
CREATE OR REPLACE FUNCTION trigger_recalcular_pesos()
RETURNS TRIGGER AS $$
DECLARE
    v_num_miembros INTEGER;
    v_grupo_id UUID;
BEGIN
    -- Determinar el grupo_id según la operación
    IF TG_OP = 'DELETE' THEN
        v_grupo_id := OLD.grupo_id;
    ELSE
        v_grupo_id := NEW.grupo_id;
    END IF;
    
    -- Contar miembros activos en el grupo
    SELECT COUNT(*) INTO v_num_miembros
    FROM miembros_grupo
    WHERE grupo_id = v_grupo_id AND activo = TRUE;
    
    -- Solo recalcular si hay más de un miembro
    -- Esto evita recursión cuando se crea el primer miembro (owner)
    IF v_num_miembros > 1 THEN
        PERFORM recalcular_pesos_grupo(v_grupo_id);
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Trigger para actualizar updated_at en metas
CREATE OR REPLACE FUNCTION update_metas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_metas_updated_at
    BEFORE UPDATE ON metas
    FOR EACH ROW
    EXECUTE FUNCTION update_metas_updated_at();

-- Trigger para crear aportaciones al crear meta grupal
CREATE OR REPLACE FUNCTION crear_aportaciones_meta_grupo()
RETURNS TRIGGER AS $$
DECLARE
    v_miembro RECORD;
BEGIN
    IF NEW.tipo = 'grupo' THEN
        FOR v_miembro IN
            SELECT usuario_id, porcentaje_participacion
            FROM miembros_grupo
            WHERE grupo_id = NEW.grupo_id
        LOOP
            INSERT INTO aportaciones_meta_grupo (
                meta_id, 
                usuario_id, 
                monto_asignado, 
                porcentaje_participacion
            ) VALUES (
                NEW.id,
                v_miembro.usuario_id,
                NEW.monto_objetivo * (v_miembro.porcentaje_participacion / 100),
                v_miembro.porcentaje_participacion
            );
        END LOOP;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_crear_aportaciones_meta
    AFTER INSERT ON metas
    FOR EACH ROW
    EXECUTE FUNCTION crear_aportaciones_meta_grupo();

-- ==================================================================
-- FUNCIONES PRINCIPALES PARA GESTIÓN DE GRUPOS
-- ==================================================================

-- Función para recalcular pesos del grupo
DROP FUNCTION IF EXISTS recalcular_pesos_grupo(UUID);

CREATE OR REPLACE FUNCTION recalcular_pesos_grupo(p_grupo_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_ingresos DECIMAL(15, 2);
    v_tiene_ingresos_todos BOOLEAN;
    v_num_miembros INTEGER;
    v_peso_equitativo DECIMAL(5, 2);
    v_miembro RECORD;
    v_ingreso_anual DECIMAL(15, 2);
BEGIN
    SELECT COUNT(*) INTO v_num_miembros
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id;
    
    IF v_num_miembros = 0 THEN
        RETURN;
    END IF;
    
    SELECT 
        COUNT(*) = v_num_miembros
    INTO v_tiene_ingresos_todos
    FROM miembros_grupo mg
    WHERE mg.grupo_id = p_grupo_id 
        AND EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.usuario_id = mg.usuario_id
                AND tp.tipo = 'ingreso'
                AND tp.es_ingreso_base = TRUE
                AND tp.activa = TRUE
        );
    
    IF v_tiene_ingresos_todos THEN
        v_total_ingresos := 0;
        
        FOR v_miembro IN
            SELECT mg.id, mg.usuario_id
            FROM miembros_grupo mg
            WHERE mg.grupo_id = p_grupo_id
        LOOP
            SELECT COALESCE(
                (SELECT SUM(
                    CASE 
                        WHEN tp.tipo_ingreso = 'quincenal' THEN tp.monto * 24
                        WHEN tp.tipo_ingreso = 'mensual' THEN tp.monto * 12
                        WHEN tp.tipo_ingreso = 'bimestral' THEN tp.monto * 6
                        WHEN tp.tipo_ingreso = 'trimestral' THEN tp.monto * 4
                        WHEN tp.tipo_ingreso = 'semestral' THEN tp.monto * 2
                        WHEN tp.tipo_ingreso = 'anual' THEN tp.monto
                        ELSE 0
                    END
                )
                FROM transacciones_periodicas tp
                WHERE tp.usuario_id = v_miembro.usuario_id
                    AND tp.tipo = 'ingreso'
                    AND tp.es_ingreso_base = TRUE
                    AND tp.activa = TRUE
                ),
                0
            ) INTO v_ingreso_anual;
            
            v_total_ingresos := v_total_ingresos + v_ingreso_anual;
        END LOOP;
        
        IF v_total_ingresos > 0 THEN
            FOR v_miembro IN
                SELECT mg.id, mg.usuario_id
                FROM miembros_grupo mg
                WHERE mg.grupo_id = p_grupo_id
            LOOP
                SELECT COALESCE(
                    (SELECT SUM(
                        CASE 
                            WHEN tp.tipo_ingreso = 'quincenal' THEN tp.monto * 24
                            WHEN tp.tipo_ingreso = 'mensual' THEN tp.monto * 12
                            WHEN tp.tipo_ingreso = 'bimestral' THEN tp.monto * 6
                            WHEN tp.tipo_ingreso = 'trimestral' THEN tp.monto * 4
                            WHEN tp.tipo_ingreso = 'semestral' THEN tp.monto * 2
                            WHEN tp.tipo_ingreso = 'anual' THEN tp.monto
                            ELSE 0
                        END
                    )
                    FROM transacciones_periodicas tp
                    WHERE tp.usuario_id = v_miembro.usuario_id
                        AND tp.tipo = 'ingreso'
                        AND tp.es_ingreso_base = TRUE
                        AND tp.activa = TRUE
                    ),
                    0
                ) INTO v_ingreso_anual;
                
                UPDATE miembros_grupo
                SET porcentaje_participacion = ROUND((v_ingreso_anual / v_total_ingresos) * 100, 2)
                WHERE id = v_miembro.id;
            END LOOP;
        ELSE
            v_peso_equitativo := ROUND(100.0 / v_num_miembros, 2);
            
            UPDATE miembros_grupo
            SET porcentaje_participacion = v_peso_equitativo
            WHERE grupo_id = p_grupo_id;
        END IF;
    ELSE
        v_peso_equitativo := ROUND(100.0 / v_num_miembros, 2);
        
        UPDATE miembros_grupo
        SET porcentaje_participacion = v_peso_equitativo
        WHERE grupo_id = p_grupo_id;
    END IF;
    
    UPDATE miembros_grupo mg
    SET porcentaje_participacion = porcentaje_participacion + (
        100 - (SELECT SUM(porcentaje_participacion) FROM miembros_grupo WHERE grupo_id = p_grupo_id)
    )
    WHERE mg.grupo_id = p_grupo_id 
        AND mg.id = (
            SELECT id FROM miembros_grupo 
            WHERE grupo_id = p_grupo_id 
            ORDER BY porcentaje_participacion DESC 
            LIMIT 1
        );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION recalcular_pesos_grupo IS 'Recalcula los porcentajes de peso de todos los miembros activos de un grupo según sus ingresos';

-- Crear el trigger que usa esta función
DROP TRIGGER IF EXISTS trg_recalcular_pesos_miembro ON miembros_grupo;
CREATE TRIGGER trg_recalcular_pesos_miembro
    AFTER INSERT OR UPDATE OR DELETE ON miembros_grupo
    FOR EACH ROW
    EXECUTE FUNCTION trigger_recalcular_pesos();

-- ===================================================

-- Función para calcular división de gastos
DROP FUNCTION IF EXISTS calcular_division_gasto(DECIMAL, UUID, UUID[], BOOLEAN);

CREATE OR REPLACE FUNCTION calcular_division_gasto(
    p_monto_total DECIMAL(15, 2),
    p_grupo_id UUID,
    p_miembros_participantes UUID[] DEFAULT NULL,
    p_redondear BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
    v_miembro RECORD;
    v_monto_asignado DECIMAL(15, 2);
    v_suma_verificacion DECIMAL(15, 2) := 0;
    v_diferencia DECIMAL(15, 2);
    v_resultado JSONB := '[]'::JSONB;
    v_peso_total DECIMAL(5, 2) := 0;
BEGIN
    SELECT SUM(mg.porcentaje_participacion) INTO v_peso_total
    FROM miembros_grupo mg
    WHERE mg.grupo_id = p_grupo_id
        AND (
            p_miembros_participantes IS NULL 
            OR mg.usuario_id = ANY(p_miembros_participantes)
        );
    
    IF v_peso_total = 0 OR v_peso_total IS NULL THEN
        RETURN JSONB_BUILD_OBJECT(
            'error', TRUE,
            'mensaje', 'No hay miembros participantes o pesos no configurados'
        );
    END IF;
    
    FOR v_miembro IN
        SELECT 
            mg.usuario_id,
            u.email,
            (mg.porcentaje_participacion / v_peso_total * 100) as porcentaje_ajustado
        FROM miembros_grupo mg
        JOIN auth.users u ON u.id = mg.usuario_id
        WHERE mg.grupo_id = p_grupo_id
            AND (
                p_miembros_participantes IS NULL 
                OR mg.usuario_id = ANY(p_miembros_participantes)
            )
        ORDER BY (mg.porcentaje_participacion / v_peso_total * 100) DESC
    LOOP
        v_monto_asignado := p_monto_total * (v_miembro.porcentaje_ajustado / 100);
        
        IF p_redondear THEN
            v_monto_asignado := CEIL(v_monto_asignado);
        ELSE
            v_monto_asignado := ROUND(v_monto_asignado, 2);
        END IF;
        
        v_suma_verificacion := v_suma_verificacion + v_monto_asignado;
        
        v_resultado := v_resultado || JSONB_BUILD_OBJECT(
            'usuario_id', v_miembro.usuario_id,
            'usuario_email', v_miembro.email,
            'porcentaje', ROUND(v_miembro.porcentaje_ajustado, 2),
            'monto_asignado', v_monto_asignado,
            'pagado', FALSE,
            'fecha_pago', NULL
        );
    END LOOP;
    
    IF v_suma_verificacion != p_monto_total THEN
        v_diferencia := p_monto_total - v_suma_verificacion;
        
        v_resultado := JSONB_SET(
            v_resultado,
            '{0,monto_asignado}',
            TO_JSONB((v_resultado->0->>'monto_asignado')::DECIMAL + v_diferencia)
        );
    END IF;
    
    RETURN JSONB_BUILD_OBJECT(
        'monto_total', p_monto_total,
        'redondeado', p_redondear,
        'miembros', v_resultado
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION calcular_division_gasto IS 'Calcula la división de un gasto entre miembros del grupo según sus pesos';

-- ===================================================

-- Función para rechazar invitación
DROP FUNCTION IF EXISTS rechazar_invitacion_grupo(UUID, UUID);

CREATE OR REPLACE FUNCTION rechazar_invitacion_grupo(
    p_invitacion_id UUID,
    p_usuario_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_invitacion RECORD;
    v_usuario_email TEXT;
BEGIN
    -- Obtener email del usuario
    SELECT email INTO v_usuario_email
    FROM auth.users
    WHERE id = p_usuario_id;
    
    SELECT * INTO v_invitacion
    FROM invitaciones_grupo
    WHERE id = p_invitacion_id
        AND estado = 'pendiente'
        AND email_invitado = v_usuario_email;
    
    IF NOT FOUND THEN
        RETURN JSONB_BUILD_OBJECT(
            'success', FALSE,
            'error', 'Invitación no encontrada o ya procesada'
        );
    END IF;
    
    UPDATE invitaciones_grupo
    SET estado = 'rechazada',
        fecha_respuesta = NOW()
    WHERE id = p_invitacion_id;
    
    RETURN JSONB_BUILD_OBJECT(
        'success', TRUE,
        'mensaje', 'Invitación rechazada'
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION rechazar_invitacion_grupo IS 'Procesa el rechazo de una invitación a un grupo';

-- ===================================================

-- Función para salir de un grupo
DROP FUNCTION IF EXISTS salir_de_grupo(UUID, UUID);

CREATE OR REPLACE FUNCTION salir_de_grupo(
    p_grupo_id UUID,
    p_usuario_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_miembro RECORD;
BEGIN
    SELECT * INTO v_miembro
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
        AND usuario_id = p_usuario_id
;
    
    IF NOT FOUND THEN
        RETURN JSONB_BUILD_OBJECT(
            'success', FALSE,
            'error', 'No eres miembro de este grupo'
        );
    END IF;
    
    IF v_miembro.rol = 'owner' THEN
        RETURN JSONB_BUILD_OBJECT(
            'success', FALSE,
            'error', 'El owner no puede salir del grupo. Debes transferir la propiedad o disolver el grupo.'
        );
    END IF;
    
    UPDATE miembros_grupo
    SET activo = FALSE,
        fecha_salida = NOW()
    WHERE id = v_miembro.id;
    
    PERFORM recalcular_pesos_grupo(p_grupo_id);
    
    RETURN JSONB_BUILD_OBJECT(
        'success', TRUE,
        'mensaje', 'Has salido del grupo exitosamente'
    );
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION salir_de_grupo IS 'Permite a un miembro (no owner) salir de un grupo';

-- ==================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ==================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Sistema de Grupos - Fase 1 instalado exitosamente';
    RAISE NOTICE '📊 Tablas modificadas: grupos_usuario + invitaciones_grupo';
    RAISE NOTICE '🔧 Modificaciones a tablas existentes: niveles, categorías, bancos, cuentas, transacciones';
    RAISE NOTICE '📋 Nuevas tablas: metas, aportaciones_meta_grupo, historial_ingresos';
    RAISE NOTICE '⚡ Triggers creados: 6';
    RAISE NOTICE '🔨 Funciones creadas: 4 (recalcular_pesos_grupo, calcular_division_gasto, rechazar_invitacion_grupo, salir_de_grupo)';
END $$;
