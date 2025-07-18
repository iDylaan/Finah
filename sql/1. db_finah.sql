-- ==================================================================
-- 0) Extensiones necesarias
-- ==================================================================
-- Extensión para generar UUIDs aleatorios seguros
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
-- Se eliminan en orden inverso para respetar las dependencias de claves foráneas
DROP TABLE IF EXISTS notificaciones       CASCADE;  -- Notificaciones del sistema
DROP TABLE IF EXISTS metas               CASCADE;   -- Metas de ahorro y gastos
DROP TABLE IF EXISTS reglas_recurrentes  CASCADE;   -- Reglas para transacciones automáticas
DROP TABLE IF EXISTS cuotas_deuda        CASCADE;   -- Cuotas individuales de deudas/MSI
DROP TABLE IF EXISTS compras_deuda       CASCADE;   -- Compras a meses sin intereses o crédito
DROP TABLE IF EXISTS divisiones_transaccion CASCADE; -- División de gastos grupales
DROP TABLE IF EXISTS transacciones       CASCADE;   -- Todas las transacciones financieras
DROP TABLE IF EXISTS reglas_reparto_grupo CASCADE;  -- Reglas de reparto por tipo de gasto
DROP TABLE IF EXISTS miembros_grupo      CASCADE;   -- Miembros de grupos familiares/compartidos
DROP TABLE IF EXISTS cuentas             CASCADE;   -- Cuentas bancarias, efectivo, tarjetas
DROP TABLE IF EXISTS periodicidades      CASCADE;   -- Catálogo de frecuencias (diario, mensual, etc.)
DROP TABLE IF EXISTS niveles             CASCADE;   -- Niveles de importancia de gastos
DROP TABLE IF EXISTS categorias          CASCADE;   -- Categorías específicas de gastos/ingresos
DROP TABLE IF EXISTS grupos_categoria    CASCADE;   -- Grupos de categorías (hogar, transporte, etc.)
DROP TABLE IF EXISTS grupos_usuario      CASCADE;   -- Grupos familiares o compartidos
DROP TABLE IF EXISTS bancos              CASCADE;   -- Catálogo de instituciones bancarias
DROP TABLE IF EXISTS tarjetas_credito    CASCADE;   -- Información específica de tarjetas de crédito
DROP TABLE IF EXISTS compras_msi         CASCADE;   -- Compras en meses sin intereses
DROP TABLE IF EXISTS jerarquias_usuario  CASCADE;   -- Jerarquías personalizadas de usuario



-- ==================================================================
-- 2) Eliminar tipos ENUM existentes
-- ==================================================================
-- Se eliminan tipos personalizados para poder recrearlos
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


-- 4.6) Cuentas financieras (efectivo, bancarias, tarjetas, etc.)
CREATE TABLE cuentas (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  creada_por       UUID             NOT NULL REFERENCES profiles(id),  -- Usuario que creó la cuenta
  grupo_usuario_id UUID             REFERENCES grupos_usuario(id),     -- Grupo al que pertenece (opcional)
  nombre           TEXT             NOT NULL,                           -- Nombre descriptivo (ej: "Efectivo cartera", "BBVA Débito")
  tipo             TEXT             NOT NULL,                           -- Tipo: 'efectivo', 'bancaria', 'tarjeta_credito', 'tarjeta_debito'
  metadatos        JSONB,                                               -- Datos adicionales en JSON (últimos 4 dígitos, etc.)
  saldo            NUMERIC(14,2)    NOT NULL DEFAULT 0,                -- Saldo actual de la cuenta
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Cuándo se creó
  fecha_actualizacion TIMESTAMPTZ   NOT NULL DEFAULT now()            -- Última modificación
);
-- Índices para mejorar consultas
CREATE INDEX ON cuentas(creada_por);        -- Buscar cuentas por usuario
CREATE INDEX ON cuentas(grupo_usuario_id);  -- Buscar cuentas por grupo


-- 4.7) Miembros de grupos y su participación porcentual
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
  cuenta_id        UUID              NOT NULL REFERENCES cuentas(id),     -- Cuenta donde se realizó
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
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now()              -- Última modificación
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
  cuenta_id        UUID             NOT NULL REFERENCES cuentas(id),    -- Cuenta donde se cargó (tarjeta de crédito)
  descripcion      TEXT,                                                -- Descripción de lo que se compró
  monto_total      NUMERIC(14,2)    NOT NULL,                          -- Monto total de la compra
  meses            INT              NOT NULL,                           -- Número de meses para pagar
  fecha_inicio     DATE             NOT NULL,                           -- Cuándo empezó a pagarse
  fecha_creacion   TIMESTAMPTZ      NOT NULL DEFAULT now()             -- Cuándo se registró
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


-- 4.16) Catálogo de instituciones bancarias
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


-- 4.17) Información específica de tarjetas de crédito
CREATE TABLE tarjetas_credito (
  cuenta_id              UUID             PRIMARY KEY REFERENCES cuentas(id) ON DELETE CASCADE,
  banco_id               UUID             REFERENCES bancos(id),              -- Banco emisor de la tarjeta
  nombre_tarjeta         TEXT             NOT NULL,                           -- Nombre comercial (ej: "BBVA Oro", "Santander Zero")
  ultimos_cuatro_digitos CHAR(4),                                            -- Últimos 4 dígitos para identificación
  limite_credito         NUMERIC(14,2)    NOT NULL,                          -- Límite máximo de crédito
  credito_disponible     NUMERIC(14,2)    NOT NULL,                          -- Crédito actualmente disponible
  dia_pago               INT              NOT NULL,                           -- Día del mes para realizar el pago
  dia_corte              INT              NOT NULL,                           -- Día de corte del estado de cuenta
  tasa_interes           NUMERIC(5,2),                                       -- Tasa de interés anual (opcional)
  porcentaje_pago_minimo NUMERIC(5,2),                                       -- Porcentaje mínimo a pagar (opcional)
  proxima_fecha_pago     DATE,                                               -- Cuándo vence el próximo pago
  proxima_fecha_corte    DATE,                                               -- Cuándo es el próximo corte
  
  -- CAMPOS OPCIONALES PARA ANÁLISIS FINANCIERO AVANZADO
  porcentaje_cat         NUMERIC(5,2),                                       -- Costo Anual Total en porcentaje
  anualidad              NUMERIC(10,2)    DEFAULT 0,                         -- Costo anual por tener la tarjeta
  gasto_exencion_anualidad NUMERIC(12,2),                                    -- Compras anuales para no pagar anualidad
  porcentaje_cashback    NUMERIC(4,2),                                       -- Porcentaje de cashback que otorga
  puntos_por_peso        NUMERIC(6,2),                                       -- Puntos de recompensa por cada peso gastado
  dias_gracia            INTEGER,                                            -- Días sin intereses después del corte
  
  -- CAMPO LIBRE PARA INFORMACIÓN ADICIONAL
  notas                  TEXT,                                               -- Promociones, beneficios especiales, MSI, etc.
  
  fecha_creacion         TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Cuándo se registró
  fecha_actualizacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),           -- Última modificación
  
  -- RESTRICCIONES PARA VALIDAR DATOS
  CONSTRAINT chk_porcentaje_cat CHECK (porcentaje_cat IS NULL OR (porcentaje_cat >= 0 AND porcentaje_cat <= 500)),
  CONSTRAINT chk_anualidad CHECK (anualidad >= 0),
  CONSTRAINT chk_porcentaje_cashback CHECK (porcentaje_cashback IS NULL OR (porcentaje_cashback >= 0 AND porcentaje_cashback <= 20)),
  CONSTRAINT chk_puntos_por_peso CHECK (puntos_por_peso IS NULL OR (puntos_por_peso >= 0 AND puntos_por_peso <= 100)),
  CONSTRAINT chk_dias_gracia CHECK (dias_gracia IS NULL OR (dias_gracia >= 0 AND dias_gracia <= 60))
);

-- Índices para consultas frecuentes
CREATE INDEX ON tarjetas_credito(banco_id);                                    -- Buscar por banco
CREATE INDEX ON tarjetas_credito(porcentaje_cat) WHERE porcentaje_cat IS NOT NULL;  -- Buscar por CAT
CREATE INDEX ON tarjetas_credito(anualidad) WHERE anualidad > 0;               -- Buscar tarjetas con anualidad

-- Comentarios explicativos para cada campo opcional
COMMENT ON COLUMN tarjetas_credito.porcentaje_cat IS 'Costo Anual Total (CAT) en porcentaje - Incluye intereses, comisiones y seguros';
COMMENT ON COLUMN tarjetas_credito.anualidad IS 'Costo anual por tener la tarjeta en pesos mexicanos';
COMMENT ON COLUMN tarjetas_credito.gasto_exencion_anualidad IS 'Compras anuales para no pagar anualidad';
COMMENT ON COLUMN tarjetas_credito.porcentaje_cashback IS 'Porcentaje de dinero que regresa por compras realizadas';
COMMENT ON COLUMN tarjetas_credito.puntos_por_peso IS 'Cantidad de puntos de recompensa por cada peso gastado';
COMMENT ON COLUMN tarjetas_credito.dias_gracia IS 'Días sin intereses después del corte si se paga el total';
COMMENT ON COLUMN tarjetas_credito.notas IS 'Información adicional: promociones, beneficios especiales, meses sin intereses disponibles, etc.';


-- 4.18) Compras en Meses Sin Intereses (MSI)
CREATE TABLE compras_msi (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  compra_deuda_id   UUID             REFERENCES compras_deuda(id) ON DELETE CASCADE,  -- Compra padre a la que pertenece
  cuenta_tarjeta_id UUID             NOT NULL REFERENCES tarjetas_credito(cuenta_id), -- Tarjeta donde se realizó la compra MSI
  cuotas_totales    INT              NOT NULL,                                         -- Número total de MSI (3, 6, 12, 18, 24 meses)
  cuotas_pagadas    INT              NOT NULL DEFAULT 0,                              -- Cuotas ya pagadas
  monto_cuota       NUMERIC(14,2)    NOT NULL,                                        -- Monto fijo a pagar cada mes
  monto_restante    NUMERIC(14,2)    NOT NULL,                                        -- Cantidad que aún falta por pagar
  fecha_fin_promocion DATE,                                                          -- Cuándo termina la promoción sin intereses
  tasa_interes_posterior NUMERIC(5,2),                                               -- Tasa de interés que aplicaría después de la promoción
  fecha_creacion    TIMESTAMPTZ      NOT NULL DEFAULT now(),                         -- Cuándo se registró la compra MSI
  fecha_actualizacion TIMESTAMPTZ    NOT NULL DEFAULT now()                          -- Última modificación del registro
);
-- Índice para buscar compras MSI por tarjeta
CREATE INDEX ON compras_msi(cuenta_tarjeta_id);

-- Comentarios explicativos para la tabla de MSI
COMMENT ON TABLE compras_msi IS 'Registro de compras realizadas con promociones de Meses Sin Intereses (MSI)';
COMMENT ON COLUMN compras_msi.compra_deuda_id IS 'Referencia a la compra padre en la tabla compras_deuda';
COMMENT ON COLUMN compras_msi.cuenta_tarjeta_id IS 'Tarjeta de crédito específica donde se realizó la compra MSI';
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
-- 7) Funciones para gestión de jerarquías personalizadas
-- ==================================================================

-- 7.1) Función para inicializar jerarquías de usuario
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
-- 8) Función auxiliar para obtener el ID del usuario en sesión
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
-- 9) Comentarios descriptivos de las tablas principales
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
COMMENT ON TABLE tarjetas_credito IS 'Información detallada de tarjetas de crédito incluyendo límites, fechas y beneficios';
COMMENT ON COLUMN tarjetas_credito.limite_credito IS 'Línea de crédito máxima otorgada por el banco';
COMMENT ON COLUMN tarjetas_credito.credito_disponible IS 'Crédito que puede usarse actualmente (límite - adeudo)';
COMMENT ON COLUMN tarjetas_credito.dia_pago IS 'Día del mes en que vence el pago (1-31)';
COMMENT ON COLUMN tarjetas_credito.dia_corte IS 'Día de corte del estado de cuenta (1-31)';
COMMENT ON COLUMN tarjetas_credito.tasa_interes IS 'Tasa de interés anual por financiamiento';
COMMENT ON COLUMN tarjetas_credito.porcentaje_pago_minimo IS 'Porcentaje mínimo a pagar del saldo total';