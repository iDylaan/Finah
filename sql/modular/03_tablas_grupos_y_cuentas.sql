-- ==================================================================
-- SCRIPT: 03_tablas_grupos_y_cuentas.sql
-- DESCRIPCIÓN: Crea las tablas relacionadas con grupos de usuarios,
--              cuentas financieras, miembros de grupos y reglas de reparto
-- DEPENDENCIAS: 
--   - 01_extensiones_y_tipos.sql (tipos ENUM y extensiones)
--   - 02_tablas_catalogos.sql (catálogos: bancos, niveles, categorías)
-- ORDEN DE EJECUCIÓN: 3
-- ==================================================================

-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS historial_saldos CASCADE;       -- Historial de saldos de cuentas
DROP TABLE IF EXISTS reglas_reparto_grupo CASCADE;   -- Reglas de reparto por tipo de gasto
DROP TABLE IF EXISTS miembros_grupo CASCADE;         -- Miembros de grupos familiares/compartidos
DROP TABLE IF EXISTS cuentas CASCADE;                -- Cuentas bancarias, efectivo, tarjetas
DROP TABLE IF EXISTS grupos_usuario CASCADE;         -- Grupos familiares o compartidos


-- ==================================================================
-- 2) Crear tabla de grupos de usuarios
-- ==================================================================

-- 2.1) Grupos de usuarios (familia, pareja, compañeros de casa, etc.)
CREATE TABLE grupos_usuario (
  id                  UUID               DEFAULT gen_random_uuid() PRIMARY KEY,
  propietario_id      UUID               NOT NULL,                          -- Usuario que creó el grupo (sin FK a auth.users para evitar problemas de permisos RLS)
  nombre              TEXT               NOT NULL,                          -- Nombre del grupo (ej: "Familia García")
  descripcion         TEXT,                                                 -- Descripción opcional del grupo
  color               TEXT               DEFAULT '#3B82F6',                 -- Color del grupo en formato hexadecimal
  biblioteca_iconos   biblioteca_iconos  NOT NULL DEFAULT 'material',       -- Librería de iconos: material o primevue
  nombre_icono        VARCHAR(100)       NOT NULL DEFAULT 'group',          -- Nombre del icono (ej: group, people, family)
  fecha_creacion      TIMESTAMPTZ        NOT NULL DEFAULT now()             -- Cuándo se creó el grupo
);

COMMENT ON COLUMN grupos_usuario.propietario_id IS 'UUID del usuario propietario (sin FK a auth.users para evitar problemas de permisos RLS)';
COMMENT ON COLUMN grupos_usuario.biblioteca_iconos IS 'Librería de iconos: material o primevue';
COMMENT ON COLUMN grupos_usuario.nombre_icono IS 'Nombre del icono (ej: group, people, family)';

-- Crear índice para búsquedas por icono
CREATE INDEX IF NOT EXISTS idx_grupos_usuario_icono ON grupos_usuario(biblioteca_iconos, nombre_icono);


-- ==================================================================
-- 3) Función para crear grupo con propietario
-- ==================================================================

-- Función para crear grupo con miembro inicial (evita problemas de RLS recursivo)
CREATE OR REPLACE FUNCTION crear_grupo_con_propietario(
  p_nombre TEXT,
  p_descripcion TEXT DEFAULT NULL,
  p_color TEXT DEFAULT NULL,
  p_imagen_url TEXT DEFAULT NULL,
  p_limite_miembros INTEGER DEFAULT 10
)
RETURNS grupos_usuario
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_grupo grupos_usuario;
  v_user_id UUID;
BEGIN
  -- Obtener el ID del usuario actual
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;
  
  -- Insertar el grupo
  INSERT INTO grupos_usuario (
    propietario_id,
    nombre,
    descripcion,
    color,
    imagen_url,
    limite_miembros
  ) VALUES (
    v_user_id,
    p_nombre,
    p_descripcion,
    p_color,
    p_imagen_url,
    p_limite_miembros
  )
  RETURNING * INTO v_grupo;
  
  -- Insertar al propietario como administrador con 100% participación
  INSERT INTO miembros_grupo (
    grupo_id,
    usuario_id,
    rol,
    porcentaje_participacion
  ) VALUES (
    v_grupo.id,
    v_user_id,
    'administrador',
    100.00
  );
  
  RETURN v_grupo;
END;
$$;

COMMENT ON FUNCTION crear_grupo_con_propietario IS 'Crea un grupo e inserta automáticamente al propietario como administrador con 100% participación. Evita problemas de recursión RLS.';

-- DESACTIVAR el trigger que causa recursión
DROP TRIGGER IF EXISTS al_crear_grupo_asignar_admin ON grupos_usuario;


-- ==================================================================
-- 4) Crear tabla de cuentas financieras
-- ==================================================================

-- 4.1) Cuentas financieras (efectivo, bancarias, tarjetas, etc.)
CREATE TABLE cuentas (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  creada_por       UUID             NOT NULL REFERENCES profiles(id),  -- Usuario que creó la cuenta
  grupo_usuario_id UUID             REFERENCES grupos_usuario(id),     -- Grupo al que pertenece (opcional)
  banco_id         UUID             REFERENCES bancos(id),             -- Banco asociado (para cuentas bancarias y tarjetas)
  
  -- INFORMACIÓN BÁSICA
  nombre           TEXT             NOT NULL,                          -- Nombre descriptivo (ej: "Efectivo cartera", "BBVA Débito")
  tipo             TEXT             NOT NULL,                          -- Tipo: 'cash', 'bank', 'debit_card', 'credit_card'
  saldo            NUMERIC(14,2)    NOT NULL DEFAULT 0,               -- Saldo actual de la cuenta
  metadatos        JSONB,                                             -- Datos adicionales en JSON (últimos 4 dígitos, ubicación efectivo, etc.)
  
  -- CAMPOS ESPECÍFICOS PARA TARJETAS DE CRÉDITO (null para otros tipos)
  limite_credito         NUMERIC(14,2),                              -- Límite máximo de crédito
  credito_disponible     NUMERIC(14,2),                              -- Crédito actualmente disponible
  saldo_periodo_actual   NUMERIC(14,2)    DEFAULT 0,                 -- Saldo variable del periodo (se recalcula en corte)
  saldo_arrastre         NUMERIC(14,2)    DEFAULT 0,                 -- Deuda no pagada de periodos anteriores
  dia_pago               INT,                                        -- Día del mes para realizar el pago (1-31)
  dia_corte              INT,                                        -- Día de corte del estado de cuenta (1-31)
  tasa_interes           NUMERIC(5,2),                               -- Tasa de interés anual
  porcentaje_pago_minimo NUMERIC(5,2),                               -- Porcentaje mínimo a pagar
  proxima_fecha_pago     DATE,                                       -- Cuándo vence el próximo pago
  proxima_fecha_corte    DATE,                                       -- Cuándo es el próximo corte
  porcentaje_cat         NUMERIC(5,2),                               -- Costo Anual Total en porcentaje
  anualidad              NUMERIC(10,2)    DEFAULT 0,                 -- Costo anual por tener la tarjeta
  gasto_exencion_anualidad NUMERIC(12,2),                            -- Compras anuales para no pagar anualidad
  porcentaje_cashback    NUMERIC(4,2),                               -- Porcentaje de cashback que otorga
  puntos_por_peso        NUMERIC(6,2),                               -- Puntos de recompensa por cada peso gastado
  dias_gracia            INTEGER,                                    -- Días sin intereses después del corte
  notas                  TEXT,                                       -- Promociones, beneficios especiales, MSI, etc.
  
  -- FECHAS DE CONTROL
  fecha_creacion         TIMESTAMPTZ      NOT NULL DEFAULT now(),   -- Cuándo se creó
  fecha_actualizacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),   -- Última modificación
  deleted_at             TIMESTAMPTZ,                                -- Baja lógica: NULL = activa, con fecha = eliminada
  
  -- RESTRICCIONES PARA VALIDAR DATOS
  CONSTRAINT chk_tipo_cuenta CHECK (tipo IN ('cash', 'bank', 'debit_card', 'credit_card')),
  CONSTRAINT chk_porcentaje_cat CHECK (porcentaje_cat IS NULL OR (porcentaje_cat >= 0 AND porcentaje_cat <= 500)),
  CONSTRAINT chk_anualidad CHECK (anualidad IS NULL OR anualidad >= 0),
  CONSTRAINT chk_porcentaje_cashback CHECK (porcentaje_cashback IS NULL OR (porcentaje_cashback >= 0 AND porcentaje_cashback <= 20)),
  CONSTRAINT chk_puntos_por_peso CHECK (puntos_por_peso IS NULL OR (puntos_por_peso >= 0 AND puntos_por_peso <= 100)),
  CONSTRAINT chk_dias_gracia CHECK (dias_gracia IS NULL OR (dias_gracia >= 0 AND dias_gracia <= 60)),
  CONSTRAINT chk_dia_pago CHECK (dia_pago IS NULL OR (dia_pago >= 1 AND dia_pago <= 31)),
  CONSTRAINT chk_dia_corte CHECK (dia_corte IS NULL OR (dia_corte >= 1 AND dia_corte <= 31))
);

-- Índices para mejorar consultas
CREATE INDEX ON cuentas(creada_por);        -- Buscar cuentas por usuario
CREATE INDEX ON cuentas(grupo_usuario_id);  -- Buscar cuentas por grupo
CREATE INDEX ON cuentas(banco_id);          -- Buscar cuentas por banco
CREATE INDEX ON cuentas(tipo);              -- Buscar cuentas por tipo
CREATE INDEX ON cuentas(porcentaje_cat) WHERE porcentaje_cat IS NOT NULL;  -- Buscar por CAT
CREATE INDEX ON cuentas(anualidad) WHERE anualidad > 0;                    -- Buscar tarjetas con anualidad

-- Comentarios explicativos para campos de tarjetas de crédito
COMMENT ON COLUMN cuentas.limite_credito IS 'Límite máximo de crédito - Solo para credit_card';
COMMENT ON COLUMN cuentas.credito_disponible IS 'Crédito actualmente disponible - Solo para credit_card';
COMMENT ON COLUMN cuentas.saldo_periodo_actual IS 'Saldo variable del periodo de pago. Inicia en fecha de corte con gastos+MSI pendientes, aumenta con nuevos gastos, disminuye con pagos. Se recalcula cada corte.';
COMMENT ON COLUMN cuentas.saldo_arrastre IS 'Deuda no pagada que se arrastra de periodos anteriores. Se acumula cuando no se paga el total en la fecha límite.';
COMMENT ON COLUMN cuentas.porcentaje_cat IS 'Costo Anual Total (CAT) en porcentaje - Incluye intereses, comisiones y seguros';
COMMENT ON COLUMN cuentas.anualidad IS 'Costo anual por tener la tarjeta en pesos';
COMMENT ON COLUMN cuentas.gasto_exencion_anualidad IS 'Compras anuales para no pagar anualidad';
COMMENT ON COLUMN cuentas.porcentaje_cashback IS 'Porcentaje de dinero que regresa por compras realizadas';
COMMENT ON COLUMN cuentas.puntos_por_peso IS 'Cantidad de puntos de recompensa por cada peso gastado';
COMMENT ON COLUMN cuentas.dias_gracia IS 'Días sin intereses después del corte si se paga el total';
COMMENT ON COLUMN cuentas.notas IS 'Información adicional: promociones, beneficios especiales, meses sin intereses disponibles, etc.';


-- ==================================================================
-- 5) Crear tabla de miembros de grupos
-- ==================================================================

-- 5.1) Miembros de grupos y su participación porcentual
CREATE TABLE miembros_grupo (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  grupo_id        UUID             NOT NULL REFERENCES grupos_usuario(id) ON DELETE CASCADE, -- Grupo al que pertenece
  usuario_id      UUID             NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,      -- Usuario miembro (con FK a profiles para permitir JOINs desde cliente)
  porcentaje_participacion NUMERIC(5,2) NOT NULL DEFAULT 0,               -- Porcentaje de participación (25.00%)
  rol             rol_grupo        NOT NULL DEFAULT 'miembro',             -- Rol dentro del grupo
  fecha_creacion  TIMESTAMPTZ      NOT NULL DEFAULT now(),                -- Cuándo se unió al grupo
  activo        BOOLEAN          NOT NULL DEFAULT TRUE,               -- Si el miembro está activo en el grupo
  
  -- Restricción: un usuario solo puede estar una vez en cada grupo
  CONSTRAINT unico_usuario_por_grupo UNIQUE(grupo_id, usuario_id)
);
-- Índices para mejorar consultas
CREATE INDEX ON miembros_grupo(grupo_id);   -- Buscar miembros por grupo
CREATE INDEX ON miembros_grupo(usuario_id); -- Buscar grupos por usuario

-- Comentarios explicativos
COMMENT ON TABLE miembros_grupo IS 'Relaciona usuarios con grupos y define roles. RLS deshabilitado para evitar problemas de permisos.';
COMMENT ON COLUMN miembros_grupo.usuario_id IS 'UUID del usuario miembro (con FK a profiles para permitir JOINs desde el cliente)';
COMMENT ON COLUMN miembros_grupo.grupo_id IS 'Referencia al grupo (grupos_usuario)';
COMMENT ON COLUMN miembros_grupo.porcentaje_participacion IS 'Porcentaje de participación en gastos compartidos';
COMMENT ON COLUMN miembros_grupo.rol IS 'Rol del usuario en el grupo: miembro, administrador, owner';


-- ==================================================================
-- 6) Crear tabla de reglas de reparto
-- ==================================================================

-- 6.1) Reglas de distribución por tipo de recurso en grupos
CREATE TABLE reglas_reparto_grupo (
  id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  grupo_id       UUID           NOT NULL REFERENCES grupos_usuario(id),  -- Grupo al que aplica
  tipo_recurso   TEXT           NOT NULL,                                 -- Tipo: 'deuda', 'ahorro', 'gasto_fijo', etc.
  usuario_id     UUID           NOT NULL REFERENCES profiles(id),        -- Usuario afectado por la regla
  porcentaje_participacion NUMERIC(5,2) NOT NULL,                       -- Porcentaje de responsabilidad
  fecha_creacion TIMESTAMPTZ    NOT NULL DEFAULT now(),                 -- Cuándo se creó la regla
  
  -- Restricción: una regla por usuario-grupo-tipo de recurso
  CONSTRAINT unico_grupo_recurso_usuario UNIQUE(grupo_id, tipo_recurso, usuario_id)
);
-- Índice para consultas por grupo y tipo de recurso
CREATE INDEX ON reglas_reparto_grupo(grupo_id, tipo_recurso);


-- ==================================================================
-- 7) Crear tabla de historial de saldos
-- ==================================================================

-- 7.1) Historial de saldos de cuentas
CREATE TABLE historial_saldos (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  cuenta_id       UUID             NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
  saldo_anterior  NUMERIC(14,2)    NOT NULL,
  saldo_nuevo     NUMERIC(14,2)    NOT NULL,
  fecha           TIMESTAMPTZ      NOT NULL DEFAULT now(),
  metadatos       JSONB
);
-- Índice para consultas por cuenta y fecha
CREATE INDEX ON historial_saldos(cuenta_id, fecha DESC);


-- ==================================================================
-- Mensaje de confirmación
-- ==================================================================
DO $$
BEGIN
  RAISE NOTICE '✓ Archivo 03_tablas_grupos_y_cuentas.sql ejecutado correctamente';
  RAISE NOTICE '  - Tablas creadas: grupos_usuario, cuentas, miembros_grupo, reglas_reparto_grupo, historial_saldos';
  RAISE NOTICE '  - Función creada: crear_grupo_con_propietario()';
END $$;
