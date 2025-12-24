-- ==================================================================
-- FINAH - Sistema de Gestión Financiera
-- Archivo: 10_politicas_rls.sql
-- Descripción: Políticas de Row Level Security (RLS) para el sistema de grupos
-- ==================================================================
-- 
-- Este archivo contiene todas las políticas de seguridad a nivel de fila
-- para proteger los datos del sistema de grupos y garantizar que los usuarios
-- solo puedan acceder a la información que les corresponde.
--
-- Contenido:
-- - Habilitación de RLS en todas las tablas de grupos
-- - Políticas para grupos_usuario (4 políticas)
-- - Políticas para miembros_grupo (4 políticas)
-- - Políticas para invitaciones_grupo (3 políticas)
-- - Políticas para metas (4 políticas)
-- - Políticas para aportaciones_meta_grupo (3 políticas)
-- - Políticas para historial_ingresos (2 políticas)
-- - Índices adicionales para optimización de performance
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
-- - 09_sistema_grupos_fase1.sql
--
-- Orden de ejecución: 10
-- ==================================================================

-- ==================================================================
-- POLÍTICAS RLS (ROW LEVEL SECURITY)
-- ==================================================================

-- ==================================================================
-- FUNCIONES AUXILIARES PARA EVITAR RECURSIÓN Y PERMISOS EN RLS
-- ==================================================================

-- Esta función permite verificar membresía sin causar recursión en las políticas
CREATE OR REPLACE FUNCTION es_miembro_de_grupo(p_grupo_id UUID, p_usuario_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 
        FROM miembros_grupo 
        WHERE grupo_id = p_grupo_id 
            AND usuario_id = p_usuario_id
            AND activo = TRUE
    );
$$;

-- Esta función obtiene el email del usuario autenticado sin problemas de permisos
CREATE OR REPLACE FUNCTION obtener_email_usuario_actual()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
    SELECT email 
    FROM auth.users 
    WHERE id = auth.uid();
$$;

ALTER TABLE grupos_usuario ENABLE ROW LEVEL SECURITY;
ALTER TABLE miembros_grupo ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitaciones_grupo ENABLE ROW LEVEL SECURITY;
ALTER TABLE metas ENABLE ROW LEVEL SECURITY;
ALTER TABLE aportaciones_meta_grupo ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_ingresos ENABLE ROW LEVEL SECURITY;

-- Políticas para GRUPOS_USUARIO
-- IMPORTANTE: Solo una política SELECT para evitar recursión
DROP POLICY IF EXISTS "Ver grupos donde soy miembro" ON grupos_usuario;
DROP POLICY IF EXISTS "Ver grupos donde participo" ON grupos_usuario;
DROP POLICY IF EXISTS "Ver mis grupos" ON grupos_usuario;

CREATE POLICY "Ver mis grupos"
ON grupos_usuario FOR SELECT
USING (
    -- Solo permite ver grupos donde soy propietario
    -- Para ver grupos donde soy miembro, se debe consultar desde miembros_grupo
    propietario_id = auth.uid()
);

DROP POLICY IF EXISTS "Crear grupos propios" ON grupos_usuario;
CREATE POLICY "Crear grupos propios"
ON grupos_usuario FOR INSERT
WITH CHECK (auth.uid() = propietario_id);

DROP POLICY IF EXISTS "Actualizar grupos como owner o admin" ON grupos_usuario;
CREATE POLICY "Actualizar grupos como owner o admin"
ON grupos_usuario FOR UPDATE
USING (
    propietario_id = auth.uid()
);

DROP POLICY IF EXISTS "Eliminar grupos como owner" ON grupos_usuario;
CREATE POLICY "Eliminar grupos como owner"
ON grupos_usuario FOR DELETE
USING (propietario_id = auth.uid());

-- Políticas para MIEMBROS_GRUPO
DROP POLICY IF EXISTS "Ver miembros de mis grupos" ON miembros_grupo;
CREATE POLICY "Ver miembros de mis grupos"
ON miembros_grupo FOR SELECT
USING (
    -- Solo permite ver mis propias membresías
    -- Para ver membresías de otros usuarios en grupos que posees, 
    -- debes hacer la consulta desde grupos_usuario con JOIN
    usuario_id = auth.uid()
);

DROP POLICY IF EXISTS "Sistema puede insertar miembros" ON miembros_grupo;
CREATE POLICY "Sistema puede insertar miembros"
ON miembros_grupo FOR INSERT
WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Actualizar miembros como owner o admin" ON miembros_grupo;
CREATE POLICY "Actualizar miembros como owner o admin"
ON miembros_grupo FOR UPDATE
USING (
    -- Solo puedes actualizar tu propia membresía
    -- Para que el propietario actualice otros miembros, usar funciones SECURITY DEFINER
    usuario_id = auth.uid()
);

DROP POLICY IF EXISTS "Desactivar miembros como owner" ON miembros_grupo;
CREATE POLICY "Desactivar miembros como owner"
ON miembros_grupo FOR DELETE
USING (
    -- Solo puedes eliminar tu propia membresía (salir del grupo)
    -- Para que el propietario elimine otros miembros, usar funciones SECURITY DEFINER
    usuario_id = auth.uid()
);

-- Políticas para INVITACIONES_GRUPO
DROP POLICY IF EXISTS "Ver mis invitaciones" ON invitaciones_grupo;
CREATE POLICY "Ver mis invitaciones"
ON invitaciones_grupo FOR SELECT
USING (
    email_invitado = obtener_email_usuario_actual()
    OR invitado_por = auth.uid()
    OR grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Crear invitaciones como owner o admin" ON invitaciones_grupo;
CREATE POLICY "Crear invitaciones como owner o admin"
ON invitaciones_grupo FOR INSERT
WITH CHECK (
    grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Actualizar mis invitaciones" ON invitaciones_grupo;
CREATE POLICY "Actualizar mis invitaciones"
ON invitaciones_grupo FOR UPDATE
USING (
    email_invitado = obtener_email_usuario_actual()
);

-- Políticas para METAS
DROP POLICY IF EXISTS "Ver mis metas y metas de mis grupos" ON metas;
CREATE POLICY "Ver mis metas y metas de mis grupos"
ON metas FOR SELECT
USING (
    (ambito = 'personal' AND usuario_id = auth.uid())
    OR (ambito = 'grupo' AND grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    ))
    OR (ambito = 'grupo' AND grupo_id IN (
        SELECT grupo_id FROM miembros_grupo WHERE usuario_id = auth.uid() AND activo = TRUE
    ))
);

DROP POLICY IF EXISTS "Crear metas personales" ON metas;
CREATE POLICY "Crear metas personales"
ON metas FOR INSERT
WITH CHECK (
    (ambito = 'personal' AND usuario_id = auth.uid())
    OR (ambito = 'grupo' AND grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    ))
);

DROP POLICY IF EXISTS "Actualizar mis metas" ON metas;
CREATE POLICY "Actualizar mis metas"
ON metas FOR UPDATE
USING (
    (ambito = 'personal' AND usuario_id = auth.uid())
    OR (ambito = 'grupo' AND grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    ))
);

DROP POLICY IF EXISTS "Eliminar mis metas" ON metas;
CREATE POLICY "Eliminar mis metas"
ON metas FOR DELETE
USING (
    (ambito = 'personal' AND usuario_id = auth.uid())
    OR (ambito = 'grupo' AND grupo_id IN (
        SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
    ))
);

-- Políticas para APORTACIONES_META_GRUPO
DROP POLICY IF EXISTS "Ver aportaciones de mis grupos" ON aportaciones_meta_grupo;
CREATE POLICY "Ver aportaciones de mis grupos"
ON aportaciones_meta_grupo FOR SELECT
USING (
    meta_id IN (
        SELECT id FROM metas 
        WHERE ambito = 'grupo' 
            AND (grupo_id IN (
                SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid()
            )
            OR grupo_id IN (
                SELECT grupo_id FROM miembros_grupo WHERE usuario_id = auth.uid() AND activo = TRUE
            ))
    )
);

DROP POLICY IF EXISTS "Sistema puede crear aportaciones" ON aportaciones_meta_grupo;
CREATE POLICY "Sistema puede crear aportaciones"
ON aportaciones_meta_grupo FOR INSERT
WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Actualizar mis aportaciones" ON aportaciones_meta_grupo;
CREATE POLICY "Actualizar mis aportaciones"
ON aportaciones_meta_grupo FOR UPDATE
USING (usuario_id = auth.uid());

-- Políticas para HISTORIAL_INGRESOS
DROP POLICY IF EXISTS "Ver mi historial de ingresos" ON historial_ingresos;
CREATE POLICY "Ver mi historial de ingresos"
ON historial_ingresos FOR SELECT
USING (usuario_id = auth.uid());

DROP POLICY IF EXISTS "Crear mi historial de ingresos" ON historial_ingresos;
CREATE POLICY "Crear mi historial de ingresos"
ON historial_ingresos FOR INSERT
WITH CHECK (usuario_id = auth.uid());

-- ==================================================================
-- ÍNDICES ADICIONALES PARA PERFORMANCE
-- ==================================================================

DROP INDEX IF EXISTS idx_miembros_grupo_activo_rol;
CREATE INDEX idx_miembros_grupo_activo_rol ON miembros_grupo(grupo_id, activo, rol);

DROP INDEX IF EXISTS idx_invitaciones_pendientes_email;
CREATE INDEX idx_invitaciones_pendientes_email ON invitaciones_grupo(email_invitado, estado) WHERE estado = 'pendiente';

DROP INDEX IF EXISTS idx_metas_activas;
CREATE INDEX idx_metas_activas ON metas(usuario_id, estado) WHERE estado = 'activa';

DROP INDEX IF EXISTS idx_transacciones_grupo_compartidas;
CREATE INDEX idx_transacciones_grupo_compartidas ON transacciones(grupo_id, es_gasto_compartido) WHERE es_gasto_compartido = TRUE;

-- ==================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ==================================================================

DO $$
BEGIN
    RAISE NOTICE '✅ Políticas RLS configuradas exitosamente';
    RAISE NOTICE '🔒 Tablas protegidas: 6 (grupos_usuario, miembros_grupo, invitaciones_grupo, metas, aportaciones_meta_grupo, historial_ingresos)';
    RAISE NOTICE '📋 Políticas creadas para grupos_usuario: 4';
    RAISE NOTICE '📋 Políticas creadas para miembros_grupo: 4';
    RAISE NOTICE '📋 Políticas creadas para invitaciones_grupo: 3';
    RAISE NOTICE '📋 Políticas creadas para metas: 4';
    RAISE NOTICE '📋 Políticas creadas para aportaciones_meta_grupo: 3';
    RAISE NOTICE '📋 Políticas creadas para historial_ingresos: 2';
    RAISE NOTICE '⚡ Índices de performance: 4 adicionales';
    RAISE NOTICE '✨ Sistema de seguridad RLS completo';
END $$;
