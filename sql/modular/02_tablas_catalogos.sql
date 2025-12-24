-- ==================================================================
-- SCRIPT 02: TABLAS DE CATÁLOGOS
-- ==================================================================
-- Descripción: Crea las tablas de catálogos básicos: grupos de categorías,
--              categorías, niveles, periodicidades, bancos y jerarquías de usuario
-- Dependencias: 01_extensiones_y_tipos.sql
-- Orden de ejecución: 2
-- ==================================================================

-- ==================================================================
-- 1) ELIMINAR TABLAS EXISTENTES
-- ==================================================================
DROP TABLE IF EXISTS jerarquias_usuario  CASCADE;   -- Jerarquías personalizadas de usuario
DROP TABLE IF EXISTS periodicidades      CASCADE;   -- Catálogo de frecuencias (diario, mensual, etc.)
DROP TABLE IF EXISTS niveles             CASCADE;   -- Niveles de importancia de gastos
DROP TABLE IF EXISTS categorias          CASCADE;   -- Categorías específicas de gastos/ingresos
DROP TABLE IF EXISTS grupos_categoria    CASCADE;   -- Grupos de categorías (hogar, transporte, etc.)
DROP TABLE IF EXISTS bancos              CASCADE;   -- Catálogo de instituciones bancarias


-- ==================================================================
-- 2) GRUPOS DE CATEGORÍAS
-- ==================================================================
CREATE TABLE grupos_categoria (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre           TEXT             NOT NULL,                           -- Nombre del grupo (ej: "Hogar", "Transporte")
  descripcion      TEXT,                                               -- Descripción opcional
  tipo             tipo_transaccion NOT NULL DEFAULT 'gasto',          -- Tipo: 'gasto', 'ingreso', 'transferencia'
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
CREATE INDEX ON grupos_categoria(tipo);


-- ==================================================================
-- 3) CATEGORÍAS ESPECÍFICAS
-- ==================================================================
CREATE TABLE categorias (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre           TEXT             NOT NULL,                           -- Nombre de la categoría (ej: "Gasolina", "Supermercado")
  descripcion      TEXT,                                               -- Descripción opcional
  tipo             tipo_transaccion NOT NULL DEFAULT 'gasto',          -- Tipo: 'gasto', 'ingreso', 'transferencia'
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


-- ==================================================================
-- 4) NIVELES DE PRIORIDAD
-- ==================================================================
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


-- ==================================================================
-- 5) CATÁLOGO DE PERIODICIDADES
-- ==================================================================
CREATE TABLE periodicidades (
  id             UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  codigo         periodicidad     NOT NULL,                     -- Código interno (diario, mensual, etc.)
  etiqueta       TEXT             NOT NULL,                     -- Nombre amigable para mostrar al usuario
  cantidad_intervalo INT          NOT NULL DEFAULT 1,          -- Cantidad de intervalos (ej: cada 2 semanas)
  fecha_creacion TIMESTAMPTZ      NOT NULL DEFAULT now()       -- Cuándo se creó este registro
);


-- ==================================================================
-- 6) CATÁLOGO DE BANCOS
-- ==================================================================
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


-- ==================================================================
-- 7) JERARQUÍAS PERSONALIZADAS DE USUARIO
-- ==================================================================
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
-- MENSAJE DE CONFIRMACIÓN
-- ==================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Script 02: Tablas de catálogos creadas exitosamente';
    RAISE NOTICE '📊 Tablas: 6 (grupos_categoria, categorias, niveles, periodicidades, bancos, jerarquias_usuario)';
END $$;
