-- ==================================================================
-- 0) Extensiones necesarias
-- ==================================================================
-- Extensión para generar UUIDs aleatorios seguros
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
-- Se eliminan en orden inverso para respetar las dependencias de claves foráneas
DROP TABLE IF EXISTS ejecuciones_transacciones_periodicas CASCADE; -- Ejecuciones de transacciones periódicas
DROP TABLE IF EXISTS transacciones_periodicas CASCADE;   -- Transacciones programadas/recurrentes
DROP TABLE IF EXISTS notificaciones       CASCADE;  -- Notificaciones del sistema
DROP TABLE IF EXISTS metas               CASCADE;   -- Metas de ahorro y gastos
DROP TABLE IF EXISTS reglas_recurrentes  CASCADE;   -- Reglas para transacciones automáticas
DROP TABLE IF EXISTS cuotas_deuda        CASCADE;   -- Cuotas individuales de deudas/MSI
DROP TABLE IF EXISTS compras_msi         CASCADE;   -- Compras en meses sin intereses
DROP TABLE IF EXISTS compras_deuda       CASCADE;   -- Compras a meses sin intereses o crédito
DROP TABLE IF EXISTS divisiones_transaccion CASCADE; -- División de gastos grupales
DROP TABLE IF EXISTS transacciones       CASCADE;   -- Todas las transacciones financieras
DROP TABLE IF EXISTS reglas_reparto_grupo CASCADE;  -- Reglas de reparto por tipo de gasto
DROP TABLE IF EXISTS invitaciones_grupo  CASCADE;   -- Invitaciones a grupos
DROP TABLE IF EXISTS historial_saldos  CASCADE;   -- Historial de saldos
DROP TABLE IF EXISTS miembros_grupo      CASCADE;   -- Miembros de grupos familiares/compartidos
DROP TABLE IF EXISTS cuentas             CASCADE;   -- Cuentas bancarias, efectivo, tarjetas
DROP TABLE IF EXISTS periodicidades      CASCADE;   -- Catálogo de frecuencias (diario, mensual, etc.)
DROP TABLE IF EXISTS niveles             CASCADE;   -- Niveles de importancia de gastos
DROP TABLE IF EXISTS categorias          CASCADE;   -- Categorías específicas de gastos/ingresos
DROP TABLE IF EXISTS grupos_categoria    CASCADE;   -- Grupos de categorías (hogar, transporte, etc.)
DROP TABLE IF EXISTS grupos_usuario      CASCADE;   -- Grupos familiares o compartidos
DROP TABLE IF EXISTS bancos              CASCADE;   -- Catálogo de instituciones bancarias
DROP TABLE IF EXISTS jerarquias_usuario  CASCADE;   -- Jerarquías personalizadas de usuario



-- ==================================================================
-- 2) Eliminar tipos ENUM existentes
-- ==================================================================
-- Se eliminan tipos personalizados para poder recrearlos
DROP TYPE  IF EXISTS criterio_finalizacion CASCADE;  -- Criterios de finalización de recurrencias
DROP TYPE  IF EXISTS dia_semana            CASCADE;  -- Días de la semana
DROP TYPE  IF EXISTS frecuencia_transaccion CASCADE; -- Frecuencias para transacciones periódicas
DROP TYPE  IF EXISTS severidad             CASCADE;  -- Nivel de importancia de notificaciones
DROP TYPE  IF EXISTS biblioteca_iconos     CASCADE;  -- Librería de iconos (PrimeVue, Material, etc.)
DROP TYPE  IF EXISTS periodicidad          CASCADE;  -- Frecuencia de repetición
DROP TYPE  IF EXISTS tipo_meta             CASCADE;  -- Tipo de meta financiera
DROP TYPE  IF EXISTS tipo_transaccion      CASCADE;  -- Clasificación de transacciones
DROP TYPE  IF EXISTS rol_grupo             CASCADE;  -- Rol del usuario en un grupo


-- ==================================================================
-- 3) Crear tipos ENUM personalizados
-- ==================================================================

-- Tipos de transacciones financieras
CREATE TYPE tipo_transaccion AS ENUM (
  'gasto',           -- Gastos en general (comida, servicios, etc.)
  'ingreso',         -- Ingresos (salario, ventas, etc.)
  'transferencia',   -- Movimientos entre cuentas propias
  'pago_deuda',      -- Pagos de préstamos o deudas
  'pago_credito'     -- Pagos de tarjetas de crédito
);

-- Tipos de metas financieras
CREATE TYPE tipo_meta AS ENUM (
  'ahorro',          -- Meta de ahorro (vacaciones, emergencias)
  'compra',          -- Meta para una compra específica (auto, casa)
  'presupuesto'      -- Control de presupuesto mensual/anual
);

-- Frecuencias para repetición de transacciones y metas
CREATE TYPE periodicidad AS ENUM (
  'diario',          -- Todos los días
  'semanal',         -- Cada semana
  'quincenal',       -- Cada 15 días
  'mensual',         -- Cada mes
  'bimestral',       -- Cada 2 meses
  'trimestral',      -- Cada 3 meses
  'anual',           -- Cada año
  'personalizado'    -- Intervalo personalizado
);

-- Librerías de iconos disponibles
CREATE TYPE biblioteca_iconos AS ENUM (
  'primevue',        -- Iconos de PrimeVue
  'material'         -- Material Design Icons
);

-- Niveles de severidad para notificaciones y alertas
CREATE TYPE severidad AS ENUM (
  'exito',           -- Operaciones exitosas, ingresos
  'informacion',     -- Información general
  'advertencia',     -- Advertencias suaves (presupuesto cerca del límite)
  'peligro',         -- Gastos críticos, límites excedidos
  'secundario',      -- Neutro por defecto
  'contraste'        -- Para resaltar elementos importantes
);

-- Roles de usuarios dentro de grupos familiares/compartidos
CREATE TYPE rol_grupo AS ENUM (
  'miembro',         -- Usuario normal del grupo
  'administrador'    -- Administrador con permisos especiales
);

-- Tipo ENUM para días de la semana (para transacciones periódicas)
CREATE TYPE dia_semana AS ENUM (
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo'
);

-- Tipo ENUM para frecuencias de transacciones periódicas
CREATE TYPE frecuencia_transaccion AS ENUM (
  'diaria',           -- Todos los días
  'semanal',          -- Cada semana (con días específicos)
  'quincenal',        -- Cada 15 días
  'mensual',          -- Cada mes (con día específico del mes)
  'bimestral',        -- Cada 2 meses
  'trimestral',       -- Cada 3 meses
  'semestral',        -- Cada 6 meses
  'anual',            -- Cada año
  'dias_naturales',   -- Cada X días naturales (ej: cada 30 días)
  'msi',              -- Meses Sin Intereses (mensual con contador)
  'unica'             -- Una sola vez (para programar transacciones futuras)
);

-- Tipo ENUM para criterios de finalización de transacciones periódicas
CREATE TYPE criterio_finalizacion AS ENUM (
  'sin_fin',              -- Se repite indefinidamente
  'fecha_fin',            -- Se repite hasta una fecha específica
  'numero_repeticiones'   -- Se repite X veces
);


-- ==================================================================
-- 4) Crear tablas principales del sistema
-- ==================================================================

-- 4.1) Grupos de usuarios (familia, pareja, compañeros de casa, etc.)
CREATE TABLE grupos_usuario (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  propietario_id UUID       NOT NULL REFERENCES profiles(id), -- Usuario que creó el grupo
  nombre        TEXT        NOT NULL,                          -- Nombre del grupo (ej: "Familia García")
  descripcion   TEXT,                                          -- Descripción opcional del grupo
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT now()           -- Cuándo se creó el grupo
);

-- Trigger: al crear un grupo, asignar automáticamente al creador como administrador
CREATE OR REPLACE FUNCTION asignar_propietario_como_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO miembros_grupo (
    id, grupo_id, usuario_id, porcentaje_participacion, rol, fecha_creacion
  ) VALUES (
    gen_random_uuid(),
    NEW.id,                 -- ID del grupo recién creado
    NEW.propietario_id,     -- Usuario que creó el grupo
    0,                      -- Porcentaje por defecto; se define luego en reglas
    'administrador',        -- El creador siempre es administrador
    now()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS al_crear_grupo_asignar_admin ON grupos_usuario;
CREATE TRIGGER al_crear_grupo_asignar_admin
  AFTER INSERT ON grupos_usuario
  FOR EACH ROW
  EXECUTE FUNCTION asignar_propietario_como_admin();


-- 4.2) Grupos de categorías (organizadores principales de gastos/ingresos)
CREATE TABLE grupos_categoria (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre           TEXT             NOT NULL,                           -- Nombre del grupo (ej: "Hogar", "Transporte")
  descripcion      TEXT,                                               -- Descripción opcional
  es_publico       BOOLEAN          NOT NULL DEFAULT FALSE,            -- Si está disponible para todos los usuarios
  usuario_id       UUID             REFERENCES profiles(id),           -- Propietario si es privado individual
  grupo_usuario_id UUID             REFERENCES grupos_usuario(id),     -- Grupo propietario si es compartido
  color            CHAR(7),                                            -- Color en formato hexadecimal (#RRGGBB)
  biblioteca_iconos biblioteca_iconos NOT NULL DEFAULT 'primevue',     -- Librería de iconos a usar
  nombre_icono     TEXT             NOT NULL,                          -- Nombre del icono específico
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Cuándo se creó
  
  -- Restricción: debe tener un propietario válido
  CONSTRAINT chk_propietario_grupo_categoria CHECK (
       (es_publico = TRUE  AND usuario_id IS NULL AND grupo_usuario_id IS NULL)        -- Público sin propietario
    OR (es_publico = FALSE AND usuario_id IS NOT NULL AND grupo_usuario_id IS NULL)    -- Privado individual
    OR (es_publico = FALSE AND usuario_id IS NULL AND grupo_usuario_id IS NOT NULL)    -- Privado grupal
  )
);
-- Índices para mejorar consultas
CREATE INDEX ON grupos_categoria(usuario_id);
CREATE INDEX ON grupos_categoria(grupo_usuario_id);


-- 4.3) Categorías específicas dentro de cada grupo
CREATE TABLE categorias (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre           TEXT             NOT NULL,                           -- Nombre de la categoría (ej: "Gasolina", "Supermercado")
  descripcion      TEXT,                                               -- Descripción opcional
  grupo_id         UUID             NOT NULL REFERENCES grupos_categoria(id), -- Grupo al que pertenece
  es_publico       BOOLEAN          NOT NULL DEFAULT FALSE,            -- Si está disponible para todos
  usuario_id       UUID             REFERENCES profiles(id),           -- Propietario si es privado individual
  grupo_usuario_id UUID             REFERENCES grupos_usuario(id),     -- Grupo propietario si es compartido
  biblioteca_iconos biblioteca_iconos NOT NULL DEFAULT 'primevue',     -- Librería de iconos
  nombre_icono     TEXT             NOT NULL,                          -- Icono específico de la categoría
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Cuándo se creó
  
  -- Restricción: debe tener un propietario válido
  CONSTRAINT chk_propietario_categoria CHECK (
       (es_publico = TRUE  AND usuario_id IS NULL AND grupo_usuario_id IS NULL)        -- Público sin propietario
    OR (es_publico = FALSE AND usuario_id IS NOT NULL AND grupo_usuario_id IS NULL)    -- Privado individual
    OR (es_publico = FALSE AND usuario_id IS NULL AND grupo_usuario_id IS NOT NULL)    -- Privado grupal
  )
);
-- Índices para mejorar consultas
CREATE INDEX ON categorias(grupo_id);       -- Buscar por grupo de categoría
CREATE INDEX ON categorias(usuario_id);     -- Buscar por usuario propietario
CREATE INDEX ON categorias(grupo_usuario_id); -- Buscar por grupo propietario


-- 4.4) Niveles de prioridad para gastos e ingresos
CREATE TABLE niveles (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre           TEXT             NOT NULL,                           -- Nombre del nivel (ej: "Necesario", "Lujo")
  color            VARCHAR(20),                                        -- Color representativo en cualquier formato
  es_publico       BOOLEAN          NOT NULL DEFAULT FALSE,            -- Si está disponible para todos
  jerarquia        INT              NOT NULL,                           -- Orden de importancia (1 = más importante)
  usuario_id       UUID             REFERENCES profiles(id),           -- Propietario si es privado individual
  grupo_usuario_id UUID             REFERENCES grupos_usuario(id),     -- Grupo propietario si es compartido
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Cuándo se creó
  
  -- Restricción: debe tener un propietario válido
  CONSTRAINT chk_propietario_nivel CHECK (
       (es_publico = TRUE  AND usuario_id IS NULL AND grupo_usuario_id IS NULL)        -- Público sin propietario
    OR (es_publico = FALSE AND usuario_id IS NOT NULL AND grupo_usuario_id IS NULL)    -- Privado individual
    OR (es_publico = FALSE AND usuario_id IS NULL AND grupo_usuario_id IS NOT NULL)    -- Privado grupal
  )
);
-- Índices para mejorar consultas
CREATE INDEX ON niveles(usuario_id);
CREATE INDEX ON niveles(grupo_usuario_id);

-- Trigger para limpiar espacios del color antes de guardar
CREATE OR REPLACE FUNCTION limpiar_color_nivel()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.color IS NOT NULL THEN
    NEW.color = TRIM(NEW.color);  -- Quitar espacios al inicio y final
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_limpiar_color ON niveles;
CREATE TRIGGER trigger_limpiar_color
  BEFORE INSERT OR UPDATE ON niveles
  FOR EACH ROW
  EXECUTE FUNCTION limpiar_color_nivel();


-- 4.5) Catálogo de frecuencias para metas y transacciones recurrentes
CREATE TABLE periodicidades (
  id             UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo         periodicidad     NOT NULL,                     -- Código interno (diario, mensual, etc.)
  etiqueta       TEXT             NOT NULL,                     -- Nombre amigable para mostrar al usuario
  cantidad_intervalo INT          NOT NULL DEFAULT 1,          -- Cantidad de intervalos (ej: cada 2 semanas)
  fecha_creacion TIMESTAMPTZ      NOT NULL DEFAULT now()       -- Cuándo se creó este registro
);


-- 4.6) Catálogo de instituciones bancarias
CREATE TABLE bancos (
  id              UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre          TEXT            NOT NULL,                              -- Nombre del banco (BBVA, Santander, etc.)
  es_publico      BOOLEAN         NOT NULL DEFAULT FALSE,               -- Si está disponible para todos los usuarios
  usuario_id      UUID            REFERENCES profiles(id),              -- Propietario si es privado individual
  grupo_usuario_id UUID           REFERENCES grupos_usuario(id),        -- Grupo propietario si es compartido
  color           CHAR(7),                                               -- Color representativo en formato #RRGGBB
  biblioteca_iconos biblioteca_iconos NOT NULL DEFAULT 'primevue',      -- Librería de iconos
  nombre_icono    TEXT            NOT NULL,                             -- Nombre del icono específico
  ruta_logo       TEXT,                                                 -- Ruta del logo en Supabase Storage
  fecha_creacion  TIMESTAMPTZ     NOT NULL DEFAULT now(),              -- Cuándo se registró
  
  -- Restricción: debe tener un propietario válido
  CONSTRAINT chk_propietario_banco CHECK (
       (es_publico = TRUE  AND usuario_id IS NULL AND grupo_usuario_id IS NULL)        -- Público sin propietario
    OR (es_publico = FALSE AND usuario_id IS NOT NULL AND grupo_usuario_id IS NULL)    -- Privado individual
    OR (es_publico = FALSE AND usuario_id IS NULL AND grupo_usuario_id IS NOT NULL)    -- Privado grupal
  )
);
-- Índices para mejorar consultas
CREATE INDEX ON bancos(usuario_id);        -- Buscar bancos por usuario
CREATE INDEX ON bancos(grupo_usuario_id);  -- Buscar bancos por grupo
CREATE INDEX ON bancos(es_publico);        -- Filtrar bancos públicos


-- 4.7) Cuentas financieras (efectivo, bancarias, tarjetas, etc.)
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
COMMENT ON COLUMN cuentas.porcentaje_cat IS 'Costo Anual Total (CAT) en porcentaje - Incluye intereses, comisiones y seguros';
COMMENT ON COLUMN cuentas.anualidad IS 'Costo anual por tener la tarjeta en pesos';
COMMENT ON COLUMN cuentas.gasto_exencion_anualidad IS 'Compras anuales para no pagar anualidad';
COMMENT ON COLUMN cuentas.porcentaje_cashback IS 'Porcentaje de dinero que regresa por compras realizadas';
COMMENT ON COLUMN cuentas.puntos_por_peso IS 'Cantidad de puntos de recompensa por cada peso gastado';
COMMENT ON COLUMN cuentas.dias_gracia IS 'Días sin intereses después del corte si se paga el total';
COMMENT ON COLUMN cuentas.notas IS 'Información adicional: promociones, beneficios especiales, meses sin intereses disponibles, etc.';


-- 4.8) Miembros de grupos y su participación porcentual
CREATE TABLE miembros_grupo (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  grupo_id        UUID             NOT NULL REFERENCES grupos_usuario(id), -- Grupo al que pertenece
  usuario_id      UUID             NOT NULL REFERENCES profiles(id),       -- Usuario miembro
  porcentaje_participacion NUMERIC(5,2) NOT NULL DEFAULT 0,               -- Porcentaje de participación (25.00%)
  rol             rol_grupo        NOT NULL DEFAULT 'miembro',             -- Rol dentro del grupo
  fecha_creacion  TIMESTAMPTZ      NOT NULL DEFAULT now(),                -- Cuándo se unió al grupo
  
  -- Restricción: un usuario solo puede estar una vez en cada grupo
  CONSTRAINT unico_usuario_por_grupo UNIQUE(grupo_id, usuario_id)
);
-- Índices para mejorar consultas
CREATE INDEX ON miembros_grupo(grupo_id);   -- Buscar miembros por grupo
CREATE INDEX ON miembros_grupo(usuario_id); -- Buscar grupos por usuario


-- 4.8) Reglas de distribución por tipo de recurso en grupos
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


-- 4.9) Registro de todas las transacciones financieras
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
  fecha_creacion   TIMESTAMPTZ       NOT NULL DEFAULT now(),             -- Cuándo se registró
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now(),              -- Última modificación
  deleted_at       TIMESTAMPTZ                                            -- Baja lógica: NULL = activa, con fecha = eliminada
);
-- Índices para mejorar consultas
CREATE INDEX ON transacciones(usuario_id, fecha_ocurrencia); -- Buscar por usuario y fecha
CREATE INDEX ON transacciones(cuenta_id);                    -- Buscar por cuenta
CREATE INDEX ON transacciones(categoria_id);                 -- Buscar por categoría
CREATE INDEX ON transacciones(severidad);                    -- Buscar por severidad


-- 4.10) División de gastos grupales entre miembros
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


-- 4.11) Compras financiadas (meses sin intereses o a plazos)
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


-- 4.12) Cuotas individuales de cada compra financiada
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


-- 4.13) Reglas para transacciones que se repiten automáticamente
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


-- 4.14) Metas financieras (ahorro, compras, control de presupuesto)
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


-- 4.15) Notificaciones del sistema y bitácora de eventos importantes
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


-- 4.17) Compras en Meses Sin Intereses (MSI)
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


-- 4.19) Jerarquías personalizadas de niveles por usuario
CREATE TABLE jerarquias_usuario (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  usuario_id        UUID             NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  nivel_id          UUID             NOT NULL REFERENCES niveles(id) ON DELETE CASCADE,
  jerarquia_personalizada INT        NOT NULL,                         -- Jerarquía personalizada del usuario
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now(),
  
  -- Restricciones
  CONSTRAINT unico_usuario_nivel UNIQUE(usuario_id, nivel_id),
  CONSTRAINT chk_jerarquia_positiva CHECK (jerarquia_personalizada > 0)
);

-- Índices
CREATE INDEX ON jerarquias_usuario(usuario_id);
CREATE INDEX ON jerarquias_usuario(usuario_id, jerarquia_personalizada);
CREATE INDEX ON jerarquias_usuario(nivel_id);

-- Comentarios
COMMENT ON TABLE jerarquias_usuario IS 'Jerarquías personalizadas de niveles por usuario - permite a cada usuario reordenar niveles según su preferencia';
COMMENT ON COLUMN jerarquias_usuario.usuario_id IS 'Usuario propietario de la jerarquía personalizada';
COMMENT ON COLUMN jerarquias_usuario.nivel_id IS 'Nivel al que se aplica la jerarquía personalizada';
COMMENT ON COLUMN jerarquias_usuario.jerarquia_personalizada IS 'Orden personalizado del usuario (1 = más importante)';
COMMENT ON COLUMN jerarquias_usuario.fecha_creacion IS 'Timestamp de cuando se creó la jerarquía personalizada';
COMMENT ON COLUMN jerarquias_usuario.fecha_actualizacion IS 'Timestamp de la última modificación de la jerarquía';


-- ==================================================================
-- 7) Triggers y funciones auxiliares
-- ==================================================================

-- 7.0) Función genérica para actualizar timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7.1) Función para guardar historial de saldos automáticamente
CREATE OR REPLACE FUNCTION guardar_historial_saldo()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Solo guardar si el saldo cambió
  IF (TG_OP = 'UPDATE' AND OLD.saldo IS DISTINCT FROM NEW.saldo) OR TG_OP = 'INSERT' THEN
    INSERT INTO historial_saldos (
      cuenta_id,
      saldo_anterior,
      saldo_nuevo,
      diferencia,
      tipo_cambio
    ) VALUES (
      NEW.id,
      CASE WHEN TG_OP = 'UPDATE' THEN OLD.saldo ELSE NULL END,
      NEW.saldo,
      CASE WHEN TG_OP = 'UPDATE' THEN (NEW.saldo - OLD.saldo) ELSE NEW.saldo END,
      CASE WHEN TG_OP = 'INSERT' THEN 'creacion_cuenta' ELSE 'actualizacion_saldo' END
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger para historial de saldos
DROP TRIGGER IF EXISTS trigger_historial_saldo ON cuentas;
CREATE TRIGGER trigger_historial_saldo
  AFTER INSERT OR UPDATE OF saldo ON cuentas
  FOR EACH ROW
  EXECUTE FUNCTION guardar_historial_saldo();


-- 7.2) Función para expirar invitaciones vencidas
CREATE OR REPLACE FUNCTION expirar_invitaciones_vencidas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE invitaciones_grupo
  SET estado = 'expirada',
      fecha_respuesta = now()
  WHERE estado = 'pendiente'
    AND fecha_expiracion < now();
END;
$$;


-- 7.3) Función para dividir gastos grupales automáticamente
CREATE OR REPLACE FUNCTION dividir_gasto_grupal(
  p_transaccion_id UUID,
  p_grupo_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_monto_total NUMERIC(14,2);
  v_miembro RECORD;
BEGIN
  -- Obtener el monto total de la transacción
  SELECT monto INTO v_monto_total
  FROM transacciones
  WHERE id = p_transaccion_id;
  
  -- Dividir entre todos los miembros activos del grupo
  FOR v_miembro IN 
    SELECT usuario_id, porcentaje_participacion
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
  LOOP
    INSERT INTO divisiones_transaccion (
      transaccion_id,
      usuario_id,
      porcentaje_participacion,
      monto
    ) VALUES (
      p_transaccion_id,
      v_miembro.usuario_id,
      v_miembro.porcentaje_participacion,
      ROUND((v_monto_total * v_miembro.porcentaje_participacion / 100), 2)
    );
  END LOOP;
END;
$$;


-- 7.4) Función para aceptar invitación a grupo
CREATE OR REPLACE FUNCTION aceptar_invitacion_grupo(
  p_token UUID,
  p_usuario_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitacion RECORD;
BEGIN
  -- Buscar la invitación
  SELECT * INTO v_invitacion
  FROM invitaciones_grupo
  WHERE token = p_token
    AND estado = 'pendiente'
    AND fecha_expiracion > now();
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invitación no encontrada, expirada o ya procesada'
    );
  END IF;
  
  -- Agregar al usuario como miembro del grupo
  INSERT INTO miembros_grupo (
    grupo_id,
    usuario_id,
    porcentaje_participacion,
    rol
  ) VALUES (
    v_invitacion.grupo_id,
    p_usuario_id,
    v_invitacion.porcentaje_propuesto,
    v_invitacion.rol_propuesto
  );
  
  -- Marcar invitación como aceptada
  UPDATE invitaciones_grupo
  SET estado = 'aceptada',
      fecha_respuesta = now()
  WHERE id = v_invitacion.id;
  
  RETURN jsonb_build_object(
    'success', true,
    'grupo_id', v_invitacion.grupo_id,
    'rol', v_invitacion.rol_propuesto
  );
  
EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Ya eres miembro de este grupo'
    );
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;


-- ==================================================================
-- 8) Funciones para gestión de jerarquías personalizadas
-- ==================================================================

-- 8.1) Función para inicializar jerarquías de usuario
DROP FUNCTION IF EXISTS inicializar_jerarquias_usuario(UUID);

CREATE OR REPLACE FUNCTION inicializar_jerarquias_usuario(p_usuario_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insertar jerarquías basadas en los niveles públicos y privados del usuario
  INSERT INTO jerarquias_usuario (usuario_id, nivel_id, jerarquia_personalizada)
  SELECT 
    p_usuario_id,
    n.id,
    CASE 
      -- Los niveles públicos mantienen su jerarquía original
      WHEN n.es_publico = TRUE THEN n.jerarquia
      -- Los niveles privados se añaden después de los públicos
      ELSE (
        SELECT COALESCE(MAX(pub.jerarquia), 0) + 
               ROW_NUMBER() OVER (ORDER BY n.jerarquia, n.fecha_creacion)
        FROM niveles pub 
        WHERE pub.es_publico = TRUE
      )
    END
  FROM niveles n
  WHERE 
    -- Incluir niveles públicos y privados del usuario
    (n.es_publico = TRUE OR n.usuario_id = p_usuario_id)
    -- Solo si no existe ya una jerarquía personalizada
    AND NOT EXISTS (
      SELECT 1 FROM jerarquias_usuario ju 
      WHERE ju.usuario_id = p_usuario_id AND ju.nivel_id = n.id
    )
  ORDER BY 
    n.es_publico DESC,  -- Públicos primero
    n.jerarquia,        -- Luego por jerarquía
    n.fecha_creacion;   -- Finalmente por fecha de creación
END;
$$;

-- 7.2) Trigger para auto-inicializar jerarquías al crear niveles
DROP FUNCTION IF EXISTS auto_inicializar_jerarquias();

CREATE OR REPLACE FUNCTION auto_inicializar_jerarquias()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Si se crea un nuevo nivel privado, añadirlo a la jerarquía del usuario
  IF NEW.es_publico = FALSE AND NEW.usuario_id IS NOT NULL THEN
    INSERT INTO jerarquias_usuario (usuario_id, nivel_id, jerarquia_personalizada)
    SELECT 
      NEW.usuario_id,
      NEW.id,
      COALESCE(MAX(ju.jerarquia_personalizada), 0) + 1
    FROM jerarquias_usuario ju
    WHERE ju.usuario_id = NEW.usuario_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Aplicar trigger a la tabla niveles
DROP TRIGGER IF EXISTS trigger_auto_inicializar_jerarquias ON niveles;
CREATE TRIGGER trigger_auto_inicializar_jerarquias
  AFTER INSERT ON niveles
  FOR EACH ROW
  EXECUTE FUNCTION auto_inicializar_jerarquias();

-- 7.3) Función para obtener niveles ordenados por usuario
DROP FUNCTION IF EXISTS obtener_niveles_usuario(UUID);

CREATE OR REPLACE FUNCTION obtener_niveles_usuario(p_usuario_id UUID)
RETURNS TABLE (
  id UUID,
  nombre TEXT,
  color VARCHAR(20),
  es_publico BOOLEAN,
  jerarquia INT,
  jerarquia_personalizada INT,
  usuario_id UUID,
  fecha_creacion TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Inicializar jerarquías si no existen
  PERFORM inicializar_jerarquias_usuario(p_usuario_id);
  
  -- Retornar niveles ordenados por jerarquía personalizada
  RETURN QUERY
  SELECT 
    n.id,
    n.nombre,
    n.color,
    n.es_publico,
    n.jerarquia,
    ju.jerarquia_personalizada,
    n.usuario_id,
    n.fecha_creacion
  FROM niveles n
  JOIN jerarquias_usuario ju ON n.id = ju.nivel_id
  WHERE 
    ju.usuario_id = p_usuario_id
    AND (n.es_publico = TRUE OR n.usuario_id = p_usuario_id)
  ORDER BY ju.jerarquia_personalizada;
END;
$$;


-- ==================================================================
-- 8) Tablas para transacciones periódicas y MSI
-- ==================================================================

-- 8.1) Tabla principal de transacciones periódicas
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

-- 8.2) Tabla para ejecuciones de transacciones periódicas
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


-- ==================================================================
-- 9) Funciones para transacciones periódicas
-- ==================================================================

-- 9.1) Función para calcular próxima ejecución de transacción periódica
CREATE OR REPLACE FUNCTION calcular_proxima_ejecucion(
    p_transaccion_periodica_id UUID,
    p_fecha_base TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
AS $$
DECLARE
    v_record RECORD;
    v_proxima_fecha TIMESTAMP WITH TIME ZONE;
    v_temp_date DATE;
    v_dia_semana_actual INTEGER;
    v_dias_hasta_proximo INTEGER;
    v_encontrado BOOLEAN := FALSE;
BEGIN
    -- Obtener configuración de la transacción
    SELECT * INTO v_record
    FROM transacciones_periodicas
    WHERE id = p_transaccion_periodica_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transacción periódica no encontrada';
    END IF;
    
    -- Calcular según frecuencia
    CASE v_record.frecuencia
        
        -- DIARIA: siguiente día
        WHEN 'diaria' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '1 day';
        
        -- SEMANAL: siguiente día de la semana especificado
        WHEN 'semanal' THEN
            -- Obtener día de la semana actual (1=lunes, 7=domingo)
            v_dia_semana_actual := EXTRACT(ISODOW FROM p_fecha_base);
            
            -- Buscar el próximo día en el array dias_semana
            v_temp_date := p_fecha_base::DATE;
            
            FOR i IN 1..7 LOOP
                v_temp_date := v_temp_date + INTERVAL '1 day';
                v_dia_semana_actual := EXTRACT(ISODOW FROM v_temp_date);
                
                -- Convertir a nombre de día y verificar si está en el array
                IF (
                    (v_dia_semana_actual = 1 AND 'lunes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 2 AND 'martes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 3 AND 'miercoles' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 4 AND 'jueves' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 5 AND 'viernes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 6 AND 'sabado' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 7 AND 'domingo' = ANY(v_record.dias_semana))
                ) THEN
                    v_proxima_fecha := v_temp_date;
                    EXIT;
                END IF;
            END LOOP;
        
        -- QUINCENAL: cada 15 días
        WHEN 'quincenal' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '15 days';
        
        -- MENSUAL: mismo día del próximo mes
        WHEN 'mensual' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month')::DATE;
            
            -- Ajustar al día específico del mes
            v_temp_date := v_temp_date + (v_record.dia_del_mes - 1) || ' days';
            
            -- Si el día no existe en ese mes (ej: 31 en febrero), usar el último día
            IF EXTRACT(DAY FROM v_temp_date) != v_record.dia_del_mes THEN
                v_temp_date := (DATE_TRUNC('month', v_temp_date) + INTERVAL '1 month - 1 day')::DATE;
            END IF;
            
            v_proxima_fecha := v_temp_date;
        
        -- BIMESTRAL: cada 2 meses
        WHEN 'bimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '2 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- TRIMESTRAL: cada 3 meses
        WHEN 'trimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '3 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- SEMESTRAL: cada 6 meses
        WHEN 'semestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '6 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- ANUAL: mismo día y mes del próximo año
        WHEN 'anual' THEN
            v_temp_date := MAKE_DATE(
                EXTRACT(YEAR FROM p_fecha_base)::INTEGER + 1,
                v_record.mes_del_anio,
                v_record.dia_del_anio
            );
            v_proxima_fecha := v_temp_date;
        
        -- DÍAS NATURALES: cada X días
        WHEN 'dias_naturales' THEN
            v_proxima_fecha := p_fecha_base + (v_record.intervalo_dias || ' days')::INTERVAL;
        
        -- MSI: mensual basado en día de corte de tarjeta
        WHEN 'msi' THEN
            -- Obtener día de corte de la tarjeta
            SELECT 
                CASE 
                    WHEN dia_corte <= EXTRACT(DAY FROM p_fecha_base) THEN
                        (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month' + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                    ELSE
                        (DATE_TRUNC('month', p_fecha_base) + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                END INTO v_temp_date
            FROM cuentas
            WHERE id = v_record.cuenta_id;
            
            v_proxima_fecha := v_temp_date;
        
        -- ÚNICA: misma fecha de inicio
        WHEN 'unica' THEN
            v_proxima_fecha := v_record.fecha_inicio;
        
        ELSE
            RAISE EXCEPTION 'Frecuencia no soportada: %', v_record.frecuencia;
    END CASE;
    
    -- Verificar si alcanzó el criterio de finalización
    IF v_record.criterio_fin = 'fecha_fin' AND v_proxima_fecha::DATE > v_record.fecha_fin THEN
        RETURN NULL; -- Ya no debe ejecutarse más
    END IF;
    
    IF v_record.criterio_fin = 'numero_repeticiones' AND 
       v_record.repeticiones_completadas >= v_record.numero_total_repeticiones THEN
        RETURN NULL; -- Ya completó todas las repeticiones
    END IF;
    
    RETURN v_proxima_fecha;
END;
$$;

-- 8.2) Función para crear MSI en tarjeta de crédito
DROP FUNCTION IF EXISTS crear_msi_tarjeta_credito;

CREATE OR REPLACE FUNCTION crear_msi_tarjeta_credito(
    p_usuario_id UUID,
    p_cuenta_id UUID,
    p_categoria_id UUID,
    p_nombre VARCHAR,
    p_descripcion TEXT,
    p_monto_total DECIMAL,
    p_numero_meses INTEGER,
    p_meses_ya_pagados INTEGER DEFAULT 0,
    p_monto_personalizado_por_mes DECIMAL DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_transaccion_periodica_id UUID;
    v_monto_mensual DECIMAL;
    v_saldo_pendiente DECIMAL;
    v_fecha_corte INTEGER;
    v_proxima_fecha_corte DATE;
    v_meses_restantes INTEGER;
    v_fecha_ejecucion DATE;
    i INTEGER;
BEGIN
    -- Validaciones
    IF p_numero_meses <= 0 OR p_numero_meses > 48 THEN
        RAISE EXCEPTION 'El número de meses debe estar entre 1 y 48';
    END IF;
    
    IF p_meses_ya_pagados < 0 OR p_meses_ya_pagados >= p_numero_meses THEN
        RAISE EXCEPTION 'Los meses ya pagados deben ser menores al total de meses';
    END IF;
    
    -- Obtener día de corte de la tarjeta
    SELECT dia_corte INTO v_fecha_corte
    FROM cuentas
    WHERE id = p_cuenta_id AND creada_por = p_usuario_id AND tipo = 'credit_card';
    
    IF v_fecha_corte IS NULL THEN
        RAISE EXCEPTION 'La cuenta debe ser una tarjeta de crédito con día de corte configurado';
    END IF;
    
    -- Calcular monto mensual (personalizado o automático)
    IF p_monto_personalizado_por_mes IS NOT NULL AND p_monto_personalizado_por_mes > 0 THEN
        v_monto_mensual := p_monto_personalizado_por_mes;
    ELSE
        v_monto_mensual := ROUND(p_monto_total / p_numero_meses, 2);
    END IF;
    
    v_meses_restantes := p_numero_meses - p_meses_ya_pagados;
    
    -- Calcular saldo pendiente basado en el monto total original
    -- No usar v_monto_mensual * v_meses_restantes porque puede diferir si hay redondeo
    v_saldo_pendiente := p_monto_total - (p_meses_ya_pagados * v_monto_mensual);
    
    -- Calcular próxima fecha de corte
    v_proxima_fecha_corte := (
        SELECT proxima_fecha_corte::DATE 
        FROM cuentas 
        WHERE id = p_cuenta_id
    );
    
    IF v_proxima_fecha_corte IS NULL THEN
        -- Calcular manualmente si no existe
        IF v_fecha_corte <= EXTRACT(DAY FROM CURRENT_DATE) THEN
            v_proxima_fecha_corte := (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        ELSE
            v_proxima_fecha_corte := (DATE_TRUNC('month', CURRENT_DATE) + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        END IF;
    END IF;
    
    -- Crear transacción periódica
    INSERT INTO transacciones_periodicas (
        usuario_id,
        nombre,
        descripcion,
        tipo,
        monto,
        frecuencia,
        criterio_fin,
        numero_total_repeticiones,
        repeticiones_completadas,
        es_msi,
        monto_total_msi,
        numero_meses_total,
        meses_pagados,
        monto_por_mes,
        cuenta_id,
        categoria_id,
        fecha_inicio,
        proxima_ejecucion,
        dia_del_mes,
        activa,
        requiere_confirmacion,
        auto_ejecutar
    ) VALUES (
        p_usuario_id,
        p_nombre,
        COALESCE(p_descripcion, 'Pago MSI a ' || p_numero_meses || ' meses'),
        'gasto',
        v_monto_mensual,
        'msi',
        'numero_repeticiones',
        p_numero_meses,
        p_meses_ya_pagados,
        TRUE,
        p_monto_total,
        p_numero_meses,
        p_meses_ya_pagados,
        v_monto_mensual,
        p_cuenta_id,
        p_categoria_id,
        v_proxima_fecha_corte,
        v_proxima_fecha_corte,
        v_fecha_corte,
        TRUE,
        FALSE, -- No requiere confirmación
        TRUE   -- Se ejecuta automáticamente
    ) RETURNING id INTO v_transaccion_periodica_id;
    
    -- Crear ejecuciones para TODOS los meses (ya pagados + restantes)
    v_fecha_ejecucion := v_proxima_fecha_corte;
    
    -- Retroceder a la fecha del primer mes si hay meses ya pagados
    IF p_meses_ya_pagados > 0 THEN
        v_fecha_ejecucion := v_fecha_ejecucion - (p_meses_ya_pagados || ' months')::INTERVAL;
    END IF;
    
    FOR i IN 1..p_numero_meses LOOP
        INSERT INTO ejecuciones_transacciones_periodicas (
            transaccion_periodica_id,
            estado,
            fecha_programada,
            monto_programado,
            numero_cuota,
            fecha_ejecutada,
            monto_ejecutado
        ) VALUES (
            v_transaccion_periodica_id,
            CASE 
                WHEN i <= p_meses_ya_pagados THEN 'ejecutada'
                ELSE 'pendiente'
            END,
            v_fecha_ejecucion,
            v_monto_mensual,
            i,
            CASE 
                WHEN i <= p_meses_ya_pagados THEN v_fecha_ejecucion::TIMESTAMP
                ELSE NULL
            END,
            CASE 
                WHEN i <= p_meses_ya_pagados THEN v_monto_mensual
                ELSE NULL
            END
        );
        
        -- Calcular siguiente fecha de corte (próximo mes)
        v_fecha_ejecucion := (DATE_TRUNC('month', v_fecha_ejecucion) + INTERVAL '1 month' + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
    END LOOP;
    
    -- Actualizar el crédito disponible de la tarjeta
    -- Descontar el saldo pendiente total (monto_total - lo ya pagado)
    UPDATE cuentas
    SET credito_disponible = credito_disponible - v_saldo_pendiente,
        fecha_actualizacion = NOW()
    WHERE id = p_cuenta_id;
    
    RETURN v_transaccion_periodica_id;
END;
$$;

COMMENT ON FUNCTION crear_msi_tarjeta_credito IS 'Crea un MSI con todas sus cuotas programadas, soporta monto personalizado por mes y registra cuotas ya pagadas como ejecutadas. Descuenta del crédito disponible solo el saldo pendiente (meses restantes)';


-- ==================================================================
-- 10) Función auxiliar para obtener el ID del usuario en sesión
-- ==================================================================
-- Esta función se ejecuta una sola vez por consulta para obtener el usuario autenticado
-- Es usada por las políticas RLS (Row Level Security) para filtrar datos por usuario
CREATE OR REPLACE FUNCTION public.id_usuario_sesion()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT auth.uid();  -- Obtiene el UUID del usuario autenticado en Supabase
$$;


-- ==================================================================
-- 11) Comentarios descriptivos de las tablas principales
-- ==================================================================

-- Comentarios para grupos de usuarios
COMMENT ON TABLE grupos_usuario IS 'Grupos familiares o de convivencia para compartir gastos y presupuestos';
COMMENT ON COLUMN grupos_usuario.propietario_id IS 'Usuario que creó el grupo y tiene permisos de administrador';
COMMENT ON COLUMN grupos_usuario.nombre IS 'Nombre descriptivo del grupo (ej: "Familia García", "Casa Estudiantes")';
COMMENT ON COLUMN grupos_usuario.descripcion IS 'Descripción opcional del propósito del grupo';

-- Comentarios para grupos de categorías  
COMMENT ON TABLE grupos_categoria IS 'Agrupadores principales de categorías de gastos (Hogar, Transporte, Alimentación, etc.)';
COMMENT ON COLUMN grupos_categoria.es_publico IS 'Si TRUE: disponible para todos los usuarios. Si FALSE: privado del usuario/grupo';
COMMENT ON COLUMN grupos_categoria.color IS 'Color representativo en formato hexadecimal (#FF5722) para la interfaz';
COMMENT ON COLUMN grupos_categoria.biblioteca_iconos IS 'Librería de iconos a usar: primevue o material';
COMMENT ON COLUMN grupos_categoria.nombre_icono IS 'Nombre específico del icono dentro de la librería seleccionada';

-- Comentarios para categorías específicas
COMMENT ON TABLE categorias IS 'Categorías específicas de gastos e ingresos (Gasolina, Supermercado, Salario, etc.)';
COMMENT ON COLUMN categorias.grupo_id IS 'Grupo de categorías al que pertenece (obligatorio)';

-- Comentarios para niveles de prioridad
COMMENT ON TABLE niveles IS 'Niveles de prioridad o importancia para clasificar gastos e ingresos';
COMMENT ON COLUMN niveles.nombre IS 'Nombre del nivel (ej: "Necesario", "Deseo", "Lujo", "Emergencia")';
COMMENT ON COLUMN niveles.color IS 'Color representativo que puede estar en formato hex, nombre o código';

-- Comentarios para periodicidades
COMMENT ON TABLE periodicidades IS 'Catálogo de frecuencias para transacciones recurrentes y metas de ahorro';
COMMENT ON COLUMN periodicidades.codigo IS 'Código interno del sistema (diario, semanal, mensual, etc.)';
COMMENT ON COLUMN periodicidades.etiqueta IS 'Texto amigable para mostrar al usuario';
COMMENT ON COLUMN periodicidades.cantidad_intervalo IS 'Multiplicador del intervalo (ej: cada 2 semanas = cantidad_intervalo: 2)';

-- Comentarios para cuentas financieras
COMMENT ON TABLE cuentas IS 'Cuentas financieras del usuario: efectivo, cuentas bancarias, tarjetas de débito/crédito';
COMMENT ON COLUMN cuentas.tipo IS 'Tipo de cuenta: efectivo, bancaria, tarjeta_credito, tarjeta_debito, ahorro, inversion';
COMMENT ON COLUMN cuentas.metadatos IS 'Información adicional en JSON: últimos 4 dígitos, número de cuenta, etc.';
COMMENT ON COLUMN cuentas.saldo IS 'Saldo actual de la cuenta en la moneda base (pesos mexicanos)';

-- Comentarios para miembros de grupo
COMMENT ON TABLE miembros_grupo IS 'Usuarios que pertenecen a un grupo y su nivel de participación';
COMMENT ON COLUMN miembros_grupo.porcentaje_participacion IS 'Porcentaje general de participación en gastos grupales (0-100)';
COMMENT ON COLUMN miembros_grupo.rol IS 'Rol del usuario: miembro normal o administrador con permisos especiales';

-- Comentarios para reglas de reparto
COMMENT ON TABLE reglas_reparto_grupo IS 'Reglas específicas de distribución de gastos por tipo de recurso';
COMMENT ON COLUMN reglas_reparto_grupo.tipo_recurso IS 'Tipo de gasto/recurso: deuda, ahorro, gasto_fijo, gasto_variable, etc.';
COMMENT ON COLUMN reglas_reparto_grupo.porcentaje_participacion IS 'Porcentaje específico para este tipo de recurso';

-- Comentarios para transacciones
COMMENT ON TABLE transacciones IS 'Registro histórico de todas las transacciones financieras del sistema';
COMMENT ON COLUMN transacciones.tipo IS 'Clasificación: gasto, ingreso, transferencia, pago_deuda, pago_credito';
COMMENT ON COLUMN transacciones.severidad IS 'Nivel de importancia para alertas y notificaciones';
COMMENT ON COLUMN transacciones.fecha_ocurrencia IS 'Fecha real cuando ocurrió la transacción (puede ser diferente a fecha_creacion)';
COMMENT ON COLUMN transacciones.url_recibo IS 'URL del comprobante almacenado en Supabase Storage';
COMMENT ON COLUMN transacciones.metadatos IS 'Datos adicionales: referencia a deuda, cuota, promoción MSI, etc.';

-- Comentarios para divisiones de transacciones
COMMENT ON TABLE divisiones_transaccion IS 'División de gastos grupales entre múltiples usuarios';
COMMENT ON COLUMN divisiones_transaccion.porcentaje_participacion IS 'Porcentaje de responsabilidad de este usuario en el gasto';
COMMENT ON COLUMN divisiones_transaccion.monto IS 'Monto específico que le corresponde pagar a este usuario';

-- Comentarios para compras a plazos
COMMENT ON TABLE compras_deuda IS 'Compras financiadas a meses con o sin intereses';
COMMENT ON COLUMN compras_deuda.meses IS 'Número de meses para liquidar la compra';
COMMENT ON COLUMN compras_deuda.fecha_inicio IS 'Fecha de la primera cuota o cargo';

-- Comentarios para cuotas de deuda
COMMENT ON TABLE cuotas_deuda IS 'Cuotas individuales de cada compra financiada';
COMMENT ON COLUMN cuotas_deuda.numero_cuota IS 'Número secuencial de la cuota (1, 2, 3, etc.)';
COMMENT ON COLUMN cuotas_deuda.pagada IS 'Estado del pago: TRUE si ya se pagó, FALSE si está pendiente';
COMMENT ON COLUMN cuotas_deuda.transaccion_id IS 'Referencia a la transacción de pago (si ya se pagó)';

-- Comentarios para reglas recurrentes
COMMENT ON TABLE reglas_recurrentes IS 'Reglas para generar transacciones automáticas periódicas';
COMMENT ON COLUMN reglas_recurrentes.proxima_ejecucion IS 'Fecha calculada para la próxima ejecución automática';
COMMENT ON COLUMN reglas_recurrentes.activa IS 'Si la regla está habilitada para ejecutarse automáticamente';

-- Comentarios para metas financieras
COMMENT ON TABLE metas IS 'Metas de ahorro, compras planificadas y control de presupuesto';
COMMENT ON COLUMN metas.tipo IS 'Clasificación: ahorro (para emergencias), compra (auto/casa), presupuesto (control mensual)';
COMMENT ON COLUMN metas.monto_objetivo IS 'Cantidad total que se quiere alcanzar';
COMMENT ON COLUMN metas.monto_actual IS 'Progreso actual hacia la meta';
COMMENT ON COLUMN metas.monto_periodo IS 'Cantidad sugerida a ahorrar por período (opcional)';
COMMENT ON COLUMN metas.estado IS 'Estado actual: pendiente, en_progreso, completada, cancelada, pausada';

-- Comentarios para notificaciones
COMMENT ON TABLE notificaciones IS 'Sistema de notificaciones y bitácora de eventos importantes';
COMMENT ON COLUMN notificaciones.tipo IS 'Tipo de evento: alerta_presupuesto, meta_completada, pago_vencido, etc.';
COMMENT ON COLUMN notificaciones.id_relacionado IS 'UUID del objeto relacionado (transacción, meta, cuenta, etc.)';
COMMENT ON COLUMN notificaciones.metadatos IS 'Datos adicionales necesarios para procesar la notificación';
COMMENT ON COLUMN notificaciones.leida IS 'Estado de lectura para el usuario destinatario';

-- Comentarios para bancos
COMMENT ON TABLE bancos IS 'Catálogo de instituciones financieras (bancos, fintech, cooperativas)';
COMMENT ON COLUMN bancos.ruta_logo IS 'Ruta del archivo de logo almacenado en Supabase Storage';

-- Comentarios adicionales para tarjetas de crédito
-- 4.18) Tabla de invitaciones a grupos
CREATE TABLE invitaciones_grupo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grupo_id UUID NOT NULL REFERENCES grupos_usuario(id) ON DELETE CASCADE,
  email_invitado TEXT NOT NULL,
  usuario_invitador UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rol_propuesto rol_grupo NOT NULL DEFAULT 'miembro',
  porcentaje_propuesto NUMERIC(5,2) DEFAULT 0,
  token UUID DEFAULT gen_random_uuid() UNIQUE,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  mensaje_invitacion TEXT,
  fecha_expiracion TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_respuesta TIMESTAMPTZ,
  
  -- Validaciones
  CONSTRAINT chk_estado_invitacion CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'expirada', 'cancelada')),
  CONSTRAINT chk_porcentaje_invitacion CHECK (porcentaje_propuesto >= 0 AND porcentaje_propuesto <= 100),
  CONSTRAINT chk_email_formato CHECK (email_invitado ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);
-- Índices
CREATE INDEX ON invitaciones_grupo(grupo_id);
CREATE INDEX ON invitaciones_grupo(email_invitado);
CREATE INDEX ON invitaciones_grupo(token);
CREATE INDEX ON invitaciones_grupo(estado);


-- 4.19) Historial de saldos para análisis temporal
CREATE TABLE historial_saldos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cuenta_id UUID NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
  saldo_anterior NUMERIC(14,2),
  saldo_nuevo NUMERIC(14,2) NOT NULL,
  diferencia NUMERIC(14,2),
  transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
  fecha TIMESTAMPTZ NOT NULL DEFAULT now(),
  tipo_cambio TEXT,
  notas TEXT
);
-- Índices
CREATE INDEX ON historial_saldos(cuenta_id, fecha DESC);
CREATE INDEX ON historial_saldos(fecha DESC);


-- ==================================================================
-- FUNCIONES PARA GESTIÓN DE PERIODOS DE TARJETA DE CRÉDITO
-- ==================================================================
-- Este archivo contiene funciones para:
-- 1. Calcular fechas de periodo actual y siguiente
-- 2. Obtener gastos y MSI por periodo
-- 3. Registrar pagos que descuenten del periodo actual
-- ==================================================================

-- ==================================================================
-- 1) Función para calcular fechas de periodo de tarjeta
-- ==================================================================
DROP FUNCTION IF EXISTS calcular_fechas_periodo_tarjeta(INTEGER, INTEGER, DATE);
CREATE OR REPLACE FUNCTION calcular_fechas_periodo_tarjeta(
    p_dia_corte INTEGER,
    p_dia_pago INTEGER,
    p_fecha_referencia DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    periodo_actual_inicio DATE,
    periodo_actual_fin DATE,
    periodo_siguiente_inicio DATE,
    periodo_siguiente_fin DATE,
    fecha_corte_actual DATE,
    fecha_pago_actual DATE,
    fecha_corte_siguiente DATE,
    fecha_pago_siguiente DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_fecha_corte_actual DATE;
    v_fecha_pago_actual DATE;
    v_fecha_corte_anterior DATE;
    v_fecha_corte_siguiente DATE;
    v_fecha_pago_siguiente DATE;
BEGIN
    -- Calcular fecha de corte del mes actual
    v_fecha_corte_actual := DATE_TRUNC('month', p_fecha_referencia)::DATE + (p_dia_corte - 1);
    
    -- Si la fecha de referencia es mayor al día de corte, el corte actual ya pasó
    IF p_fecha_referencia > v_fecha_corte_actual THEN
        -- El corte actual es el del próximo mes
        v_fecha_corte_actual := (DATE_TRUNC('month', v_fecha_corte_actual) + INTERVAL '1 month')::DATE + (p_dia_corte - 1);
    END IF;
    
    -- Calcular corte anterior (inicio del periodo actual)
    v_fecha_corte_anterior := (DATE_TRUNC('month', v_fecha_corte_actual) - INTERVAL '1 month')::DATE + (p_dia_corte - 1);
    
    -- Calcular corte siguiente
    v_fecha_corte_siguiente := (DATE_TRUNC('month', v_fecha_corte_actual) + INTERVAL '1 month')::DATE + (p_dia_corte - 1);
    
    -- Calcular fecha de pago actual (días después del corte)
    v_fecha_pago_actual := v_fecha_corte_actual + p_dia_pago;
    
    -- Calcular fecha de pago siguiente
    v_fecha_pago_siguiente := v_fecha_corte_siguiente + p_dia_pago;
    
    -- Retornar todas las fechas
    RETURN QUERY
    SELECT 
        v_fecha_corte_anterior + 1 AS periodo_actual_inicio,
        v_fecha_corte_actual AS periodo_actual_fin,
        v_fecha_corte_actual + 1 AS periodo_siguiente_inicio,
        v_fecha_corte_siguiente AS periodo_siguiente_fin,
        v_fecha_corte_actual AS fecha_corte_actual,
        v_fecha_pago_actual AS fecha_pago_actual,
        v_fecha_corte_siguiente AS fecha_corte_siguiente,
        v_fecha_pago_siguiente AS fecha_pago_siguiente;
END;
$$;

COMMENT ON FUNCTION calcular_fechas_periodo_tarjeta IS 'Calcula las fechas de inicio y fin del periodo actual y siguiente de una tarjeta de crédito';


-- ==================================================================
-- 2) Función para obtener gastos del periodo (actual o siguiente)
-- ==================================================================
DROP FUNCTION IF EXISTS obtener_gastos_periodo_tarjeta(UUID, DATE, DATE);
CREATE OR REPLACE FUNCTION obtener_gastos_periodo_tarjeta(
    p_cuenta_id UUID,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE (
    total_gastos_normales NUMERIC,
    total_cuotas_msi NUMERIC,
    total_periodo NUMERIC,
    cuotas_msi JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_gastos_normales NUMERIC := 0;
    v_cuotas_msi NUMERIC := 0;
    v_cuotas_detalle JSONB;
BEGIN
    -- 1. Obtener gastos normales del periodo
    SELECT COALESCE(SUM(monto), 0)
    INTO v_gastos_normales
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND tipo = 'gasto'
        AND fecha_ocurrencia >= p_fecha_inicio
        AND fecha_ocurrencia <= p_fecha_fin
        AND (metadatos->>'msi_id') IS NULL -- Excluir gastos que fueron convertidos a MSI
        AND COALESCE((metadatos->>'pagado_en_periodo')::BOOLEAN, FALSE) = FALSE -- Solo gastos NO pagados
        AND deleted_at IS NULL;
    
    -- 2. Obtener cuotas MSI del periodo
    SELECT 
        COALESCE(SUM(e.monto_programado), 0),
        COALESCE(
            JSONB_AGG(
                JSONB_BUILD_OBJECT(
                    'id', e.id,
                    'msi_id', tp.id,
                    'msi_nombre', tp.nombre,
                    'monto', e.monto_programado,
                    'fecha_programada', e.fecha_programada,
                    'numero_cuota', e.numero_cuota,
                    'estado', e.estado
                )
            ) FILTER (WHERE e.id IS NOT NULL),
            '[]'::JSONB
        )
    INTO v_cuotas_msi, v_cuotas_detalle
    FROM ejecuciones_transacciones_periodicas e
    INNER JOIN transacciones_periodicas tp ON e.transaccion_periodica_id = tp.id
    WHERE tp.cuenta_id = p_cuenta_id
        AND tp.es_msi = TRUE
        AND tp.activa = TRUE
        AND e.fecha_programada >= p_fecha_inicio
        AND e.fecha_programada <= p_fecha_fin
        AND e.estado IN ('pendiente', 'confirmada'); -- Solo las que no han sido pagadas
    
    -- 3. Retornar resultados
    RETURN QUERY
    SELECT 
        v_gastos_normales,
        v_cuotas_msi,
        v_gastos_normales + v_cuotas_msi AS total,
        v_cuotas_detalle;
END;
$$;

COMMENT ON FUNCTION obtener_gastos_periodo_tarjeta IS 'Obtiene el total de gastos pendientes (normales + MSI) de un periodo específico de tarjeta de crédito. Solo cuenta gastos no pagados y cuotas MSI pendientes.';


-- ==================================================================
-- 3) Función para registrar pago de periodo de tarjeta
-- ==================================================================
DROP FUNCTION IF EXISTS registrar_pago_periodo_tarjeta(UUID, NUMERIC, UUID, DATE, TEXT, TEXT, UUID);
CREATE OR REPLACE FUNCTION registrar_pago_periodo_tarjeta(
    p_cuenta_tarjeta_id UUID,
    p_monto_pago NUMERIC,
    p_categoria_id UUID,
    p_fecha_pago DATE,
    p_descripcion TEXT DEFAULT NULL,
    p_tipo_pago TEXT DEFAULT 'manual', -- 'manual' o 'transfer'
    p_cuenta_origen_id UUID DEFAULT NULL -- Solo si es transferencia
)
RETURNS UUID -- Retorna el ID de la transacción creada
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_usuario_id UUID;
    v_transaccion_id UUID;
    v_cuenta_tarjeta RECORD;
    v_fechas_periodo RECORD;
    v_monto_restante NUMERIC;
    v_cuota RECORD;
    v_monto_a_pagar_cuota NUMERIC;
BEGIN
    -- Obtener usuario en sesión
    v_usuario_id := auth.uid();
    
    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;
    
    -- Validar que la cuenta existe y es una tarjeta de crédito
    SELECT * INTO v_cuenta_tarjeta
    FROM cuentas
    WHERE id = p_cuenta_tarjeta_id
        AND creada_por = v_usuario_id
        AND tipo = 'credit_card'
        AND deleted_at IS NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tarjeta de crédito no encontrada o no autorizada';
    END IF;
    
    -- Validar monto
    IF p_monto_pago <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor a 0';
    END IF;
    
    -- Obtener fechas del periodo actual
    SELECT * INTO v_fechas_periodo
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta_tarjeta.dia_corte,
        v_cuenta_tarjeta.dia_pago,
        p_fecha_pago
    );
    
    -- Crear la transacción de pago (ingreso a la tarjeta)
    INSERT INTO transacciones (
        usuario_id,
        cuenta_id,
        tipo,
        monto,
        fecha_ocurrencia,
        categoria_id,
        descripcion,
        metadatos
    ) VALUES (
        v_usuario_id,
        p_cuenta_tarjeta_id,
        'ingreso',
        p_monto_pago,
        p_fecha_pago,
        p_categoria_id,
        COALESCE(p_descripcion, 'Pago de tarjeta ' || v_cuenta_tarjeta.nombre),
        JSONB_BUILD_OBJECT(
            'tipo_pago', p_tipo_pago,
            'periodo_inicio', v_fechas_periodo.periodo_actual_inicio,
            'periodo_fin', v_fechas_periodo.periodo_actual_fin,
            'es_pago_periodo', TRUE
        )
    ) RETURNING id INTO v_transaccion_id;
    
    -- Si es transferencia, crear el egreso en la cuenta origen
    IF p_tipo_pago = 'transfer' AND p_cuenta_origen_id IS NOT NULL THEN
        -- Validar que la cuenta origen existe
        IF NOT EXISTS (
            SELECT 1 FROM cuentas 
            WHERE id = p_cuenta_origen_id 
                AND creada_por = v_usuario_id 
                AND deleted_at IS NULL
        ) THEN
            RAISE EXCEPTION 'Cuenta de origen no encontrada o no autorizada';
        END IF;
        
        -- Crear egreso en cuenta origen
        INSERT INTO transacciones (
            usuario_id,
            cuenta_id,
            tipo,
            monto,
            fecha_ocurrencia,
            categoria_id,
            descripcion,
            metadatos
        ) VALUES (
            v_usuario_id,
            p_cuenta_origen_id,
            'gasto',
            p_monto_pago,
            p_fecha_pago,
            p_categoria_id,
            'Pago de tarjeta ' || v_cuenta_tarjeta.nombre,
            JSONB_BUILD_OBJECT(
                'es_transferencia', TRUE,
                'cuenta_destino_id', p_cuenta_tarjeta_id,
                'transaccion_relacionada_id', v_transaccion_id
            )
        );
        
        -- Actualizar saldo de cuenta origen
        UPDATE cuentas
        SET saldo = saldo - p_monto_pago,
            fecha_actualizacion = NOW()
        WHERE id = p_cuenta_origen_id;
    END IF;
    
    -- Actualizar crédito disponible de la tarjeta
    UPDATE cuentas
    SET credito_disponible = LEAST(
            credito_disponible + p_monto_pago,
            limite_credito
        ),
        fecha_actualizacion = NOW()
    WHERE id = p_cuenta_tarjeta_id;
    
    -- ========================================
    -- DISTRIBUCIÓN DEL PAGO
    -- ========================================
    -- 1. Primero marcar gastos normales del periodo como pagados
    -- 2. Luego marcar cuotas MSI del periodo como pagadas
    -- Solo se consideran transacciones del periodo actual
    
    v_monto_restante := p_monto_pago;
    
    -- PASO 1: Marcar gastos normales del periodo como pagados
    FOR v_cuota IN (
        SELECT 
            id,
            monto
        FROM transacciones
        WHERE cuenta_id = p_cuenta_tarjeta_id
            AND tipo = 'gasto'
            AND fecha_ocurrencia >= v_fechas_periodo.periodo_actual_inicio
            AND fecha_ocurrencia <= v_fechas_periodo.periodo_actual_fin
            AND (metadatos->>'msi_id') IS NULL -- Solo gastos normales
            AND COALESCE((metadatos->>'pagado_en_periodo')::BOOLEAN, FALSE) = FALSE -- No pagados aún
            AND deleted_at IS NULL
        ORDER BY fecha_ocurrencia ASC
    ) LOOP
        -- Si aún hay monto disponible, marcar el gasto como pagado
        IF v_monto_restante >= v_cuota.monto THEN
            -- Marcar gasto como pagado en este periodo
            UPDATE transacciones
            SET 
                metadatos = COALESCE(metadatos, '{}'::JSONB) || 
                    JSONB_BUILD_OBJECT(
                        'pagado_en_periodo', TRUE,
                        'periodo_pago_inicio', v_fechas_periodo.periodo_actual_inicio,
                        'periodo_pago_fin', v_fechas_periodo.periodo_actual_fin,
                        'pago_transaccion_id', v_transaccion_id,
                        'fecha_pago', p_fecha_pago
                    ),
                fecha_actualizacion = NOW()
            WHERE id = v_cuota.id;
            
            -- Descontar del monto restante
            v_monto_restante := v_monto_restante - v_cuota.monto;
        ELSE
            -- No hay suficiente monto para cubrir este gasto
            EXIT;
        END IF;
    END LOOP;
    
    -- PASO 2: Marcar cuotas MSI del periodo como pagadas
    FOR v_cuota IN (
        SELECT 
            e.id,
            e.monto_programado,
            e.transaccion_periodica_id,
            tp.meses_pagados,
            tp.numero_meses_total
        FROM ejecuciones_transacciones_periodicas e
        INNER JOIN transacciones_periodicas tp ON e.transaccion_periodica_id = tp.id
        WHERE tp.cuenta_id = p_cuenta_tarjeta_id
            AND tp.es_msi = TRUE
            AND tp.activa = TRUE
            AND e.fecha_programada >= v_fechas_periodo.periodo_actual_inicio
            AND e.fecha_programada <= v_fechas_periodo.periodo_actual_fin
            AND e.estado IN ('pendiente', 'confirmada')
        ORDER BY e.fecha_programada ASC, e.numero_cuota ASC
    ) LOOP
        -- Si aún hay monto disponible, marcar la cuota como pagada
        IF v_monto_restante >= v_cuota.monto_programado THEN
            -- Marcar la cuota como ejecutada
            UPDATE ejecuciones_transacciones_periodicas
            SET 
                estado = 'ejecutada',
                fecha_ejecutada = NOW(),
                monto_ejecutado = v_cuota.monto_programado,
                notas = COALESCE(notas, '') || ' Pagado con transacción ' || v_transaccion_id
            WHERE id = v_cuota.id;
            
            -- Incrementar meses pagados del MSI
            UPDATE transacciones_periodicas
            SET meses_pagados = meses_pagados + 1,
                updated_at = NOW()
            WHERE id = v_cuota.transaccion_periodica_id;
            
            -- Descontar del monto restante
            v_monto_restante := v_monto_restante - v_cuota.monto_programado;
            
            -- Si ya se pagó completamente el MSI, marcarlo como inactivo
            IF (v_cuota.meses_pagados + 1) >= v_cuota.numero_meses_total THEN
                UPDATE transacciones_periodicas
                SET activa = FALSE,
                    updated_at = NOW()
                WHERE id = v_cuota.transaccion_periodica_id;
            END IF;
        ELSE
            -- No hay suficiente monto para cubrir esta cuota
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_transaccion_id;
END;
$$;

COMMENT ON FUNCTION registrar_pago_periodo_tarjeta IS 'Registra un pago de tarjeta de crédito por periodo. Distribuye el pago primero a gastos normales, luego a cuotas MSI. Marca transacciones como pagadas solo para el periodo actual, actualizando metadatos con información del pago.';


-- ==================================================================
-- 4) Función auxiliar para obtener resumen completo de periodos
-- ==================================================================
DROP FUNCTION IF EXISTS obtener_resumen_periodos_tarjeta(UUID);
CREATE OR REPLACE FUNCTION obtener_resumen_periodos_tarjeta(
    p_cuenta_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_cuenta RECORD;
    v_fechas RECORD;
    v_periodo_actual RECORD;
    v_periodo_siguiente RECORD;
    v_resultado JSONB;
BEGIN
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = p_cuenta_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada';
    END IF;
    
    -- Obtener fechas de periodos
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta.dia_corte,
        v_cuenta.dia_pago,
        CURRENT_DATE
    );
    
    -- Obtener gastos del periodo actual
    SELECT * INTO v_periodo_actual
    FROM obtener_gastos_periodo_tarjeta(
        p_cuenta_id,
        v_fechas.periodo_actual_inicio,
        v_fechas.periodo_actual_fin
    );
    
    -- Obtener gastos del periodo siguiente
    SELECT * INTO v_periodo_siguiente
    FROM obtener_gastos_periodo_tarjeta(
        p_cuenta_id,
        v_fechas.periodo_siguiente_inicio,
        v_fechas.periodo_siguiente_fin
    );
    
    -- Construir JSON de respuesta
    v_resultado := JSONB_BUILD_OBJECT(
        'cuenta_id', p_cuenta_id,
        'limite_credito', v_cuenta.limite_credito,
        'credito_disponible', v_cuenta.credito_disponible,
        'credito_utilizado', v_cuenta.limite_credito - v_cuenta.credito_disponible,
        'fechas', JSONB_BUILD_OBJECT(
            'periodo_actual', JSONB_BUILD_OBJECT(
                'inicio', v_fechas.periodo_actual_inicio,
                'fin', v_fechas.periodo_actual_fin,
                'fecha_corte', v_fechas.fecha_corte_actual,
                'fecha_pago', v_fechas.fecha_pago_actual
            ),
            'periodo_siguiente', JSONB_BUILD_OBJECT(
                'inicio', v_fechas.periodo_siguiente_inicio,
                'fin', v_fechas.periodo_siguiente_fin,
                'fecha_corte', v_fechas.fecha_corte_siguiente,
                'fecha_pago', v_fechas.fecha_pago_siguiente
            )
        ),
        'periodo_actual', JSONB_BUILD_OBJECT(
            'gastos_normales', v_periodo_actual.total_gastos_normales,
            'cuotas_msi', v_periodo_actual.total_cuotas_msi,
            'total', v_periodo_actual.total_periodo,
            'cuotas_detalle', v_periodo_actual.cuotas_msi
        ),
        'periodo_siguiente', JSONB_BUILD_OBJECT(
            'gastos_normales', v_periodo_siguiente.total_gastos_normales,
            'cuotas_msi', v_periodo_siguiente.total_cuotas_msi,
            'total', v_periodo_siguiente.total_periodo,
            'cuotas_detalle', v_periodo_siguiente.cuotas_msi
        )
    );
    
    RETURN v_resultado;
END;
$$;

COMMENT ON FUNCTION obtener_resumen_periodos_tarjeta IS 'Obtiene un resumen completo de los periodos actual y siguiente de una tarjeta de crédito, incluyendo gastos normales y cuotas MSI';
