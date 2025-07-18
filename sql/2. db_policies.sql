-- ===================================================
-- POLÍTICAS DE SEGURIDAD (RLS) PARA BASE DE DATOS FINHEAL
-- Archivo: 2. db_policies_es.sql
-- Descripción: Políticas de Row Level Security para controlar acceso a datos
-- ===================================================

-- ===================================================
-- 1) Activar RLS (Row Level Security) en todas las tablas
-- ===================================================
-- Se habilita la seguridad a nivel de fila para controlar el acceso a los datos
ALTER TABLE grupos_usuario         ENABLE ROW LEVEL SECURITY;  -- Grupos familiares/compartidos
ALTER TABLE grupos_categoria       ENABLE ROW LEVEL SECURITY;  -- Agrupadores de categorías
ALTER TABLE categorias             ENABLE ROW LEVEL SECURITY;  -- Categorías específicas
ALTER TABLE niveles                ENABLE ROW LEVEL SECURITY;  -- Niveles de prioridad
ALTER TABLE periodicidades         ENABLE ROW LEVEL SECURITY;  -- Frecuencias para recurrencias
ALTER TABLE cuentas                ENABLE ROW LEVEL SECURITY;  -- Cuentas financieras
ALTER TABLE miembros_grupo         ENABLE ROW LEVEL SECURITY;  -- Miembros de grupos
ALTER TABLE reglas_reparto_grupo   ENABLE ROW LEVEL SECURITY;  -- Reglas de distribución grupal
ALTER TABLE transacciones          ENABLE ROW LEVEL SECURITY;  -- Transacciones financieras
ALTER TABLE divisiones_transaccion ENABLE ROW LEVEL SECURITY;  -- División de gastos grupales
ALTER TABLE compras_deuda          ENABLE ROW LEVEL SECURITY;  -- Compras a plazos
ALTER TABLE cuotas_deuda           ENABLE ROW LEVEL SECURITY;  -- Cuotas de deudas
ALTER TABLE reglas_recurrentes     ENABLE ROW LEVEL SECURITY;  -- Reglas de transacciones automáticas
ALTER TABLE metas                  ENABLE ROW LEVEL SECURITY;  -- Metas financieras
ALTER TABLE notificaciones         ENABLE ROW LEVEL SECURITY;  -- Notificaciones del sistema
ALTER TABLE bancos                 ENABLE ROW LEVEL SECURITY;  -- Catálogo de bancos
ALTER TABLE tarjetas_credito       ENABLE ROW LEVEL SECURITY;  -- Información de tarjetas de crédito
ALTER TABLE compras_msi            ENABLE ROW LEVEL SECURITY;  -- Compras en meses sin intereses
ALTER TABLE jerarquias_usuario     ENABLE ROW LEVEL SECURITY;  -- Jerarquías de usuario

-- ===================================================
-- 2) Funciones auxiliares para evitar recursión en políticas RLS
-- ===================================================
-- Estas funciones optimizan las consultas de políticas y evitan problemas de recursión

-- Verifica si un usuario es miembro de un grupo específico
CREATE OR REPLACE FUNCTION public.es_miembro_grupo(_grupo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET row_security = OFF
AS $$
  SELECT EXISTS(
    SELECT 1 FROM miembros_grupo
     WHERE grupo_id = _grupo_id
       AND usuario_id = id_usuario_sesion()
  );
$$;

-- Verifica si un usuario es administrador de un grupo específico
CREATE OR REPLACE FUNCTION public.es_admin_grupo(_grupo_id UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET row_security = OFF
AS $$
  SELECT EXISTS(
    SELECT 1 FROM miembros_grupo
     WHERE grupo_id = _grupo_id
       AND usuario_id = id_usuario_sesion()
       AND rol = 'administrador'
  );
$$;

-- ===================================================
-- 3) POLÍTICAS PARA GRUPOS DE USUARIOS
-- ===================================================

-- SELECT - Para ver grupos a los que pertenece
DROP POLICY IF EXISTS select_grupos_usuario ON grupos_usuario;
CREATE POLICY select_grupos_usuario ON grupos_usuario
  FOR SELECT USING (
    es_miembro_grupo(id)
  );

-- INSERT - Para crear nuevos grupos
DROP POLICY IF EXISTS insert_grupos_usuario ON grupos_usuario;
CREATE POLICY insert_grupos_usuario ON grupos_usuario
  FOR INSERT WITH CHECK (
    propietario_id = id_usuario_sesion()
  );

-- UPDATE - Para actualizar grupos (solo propietarios)
DROP POLICY IF EXISTS update_grupos_usuario ON grupos_usuario;
CREATE POLICY update_grupos_usuario ON grupos_usuario
  FOR UPDATE 
  USING (
    propietario_id = id_usuario_sesion()
  )
  WITH CHECK (
    propietario_id = id_usuario_sesion()
  );

-- DELETE - Para eliminar grupos (solo propietarios)
DROP POLICY IF EXISTS delete_grupos_usuario ON grupos_usuario;
CREATE POLICY delete_grupos_usuario ON grupos_usuario
  FOR DELETE USING (
    propietario_id = id_usuario_sesion()
  );

-- ===================================================
-- 4) POLÍTICAS PARA GRUPOS DE CATEGORÍAS
-- ===================================================

-- SELECT - Para ver grupos de categorías públicos o propios
DROP POLICY IF EXISTS select_grupos_categoria ON grupos_categoria;
CREATE POLICY select_grupos_categoria ON grupos_categoria
  FOR SELECT USING (
       es_publico = TRUE
    OR usuario_id = id_usuario_sesion()
    OR es_miembro_grupo(grupo_usuario_id)
  );

-- INSERT - Para crear nuevos grupos de categorías
DROP POLICY IF EXISTS insert_grupos_categoria ON grupos_categoria;
CREATE POLICY insert_grupos_categoria ON grupos_categoria
  FOR INSERT WITH CHECK (
    -- Solo puede insertar si:
    -- 1. Es privado personal (usuario_id = usuario actual)
    -- 2. Es privado grupal (es admin del grupo)
    (es_publico = FALSE AND usuario_id = id_usuario_sesion() AND grupo_usuario_id IS NULL)
    OR (es_publico = FALSE AND usuario_id IS NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- UPDATE - Para actualizar grupos de categorías
DROP POLICY IF EXISTS update_grupos_categoria ON grupos_categoria;
CREATE POLICY update_grupos_categoria ON grupos_categoria
  FOR UPDATE 
  USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  )
  WITH CHECK (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- DELETE - Para eliminar grupos de categorías
DROP POLICY IF EXISTS delete_grupos_categoria ON grupos_categoria;
CREATE POLICY delete_grupos_categoria ON grupos_categoria
  FOR DELETE USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- ===================================================
-- 5) POLÍTICAS PARA CATEGORÍAS
-- ===================================================

-- SELECT - Para ver categorías públicas o propias
DROP POLICY IF EXISTS select_categorias ON categorias;
CREATE POLICY select_categorias ON categorias
  FOR SELECT USING (
       es_publico = TRUE
    OR usuario_id = id_usuario_sesion()
    OR es_miembro_grupo(grupo_usuario_id)
  );

-- INSERT - Para crear nuevas categorías
DROP POLICY IF EXISTS insert_categorias ON categorias;
CREATE POLICY insert_categorias ON categorias
  FOR INSERT WITH CHECK (
    (es_publico = FALSE AND usuario_id = id_usuario_sesion() AND grupo_usuario_id IS NULL)
    OR (es_publico = FALSE AND usuario_id IS NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- UPDATE - Para actualizar categorías
DROP POLICY IF EXISTS update_categorias ON categorias;
CREATE POLICY update_categorias ON categorias
  FOR UPDATE 
  USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  )
  WITH CHECK (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- DELETE - Para eliminar categorías
DROP POLICY IF EXISTS delete_categorias ON categorias;
CREATE POLICY delete_categorias ON categorias
  FOR DELETE USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- ===================================================
-- 6) POLÍTICAS PARA NIVELES
-- ===================================================

-- SELECT - Para ver niveles públicos o propios
DROP POLICY IF EXISTS select_niveles ON niveles;
CREATE POLICY select_niveles ON niveles
  FOR SELECT USING (
       es_publico = TRUE
    OR usuario_id = id_usuario_sesion()
    OR es_miembro_grupo(grupo_usuario_id)
  );

-- INSERT - Para crear nuevos niveles
DROP POLICY IF EXISTS insert_niveles ON niveles;
CREATE POLICY insert_niveles ON niveles
  FOR INSERT WITH CHECK (
    (es_publico = FALSE AND usuario_id = id_usuario_sesion() AND grupo_usuario_id IS NULL)
    OR (es_publico = FALSE AND usuario_id IS NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- UPDATE - Para actualizar niveles
DROP POLICY IF EXISTS update_niveles ON niveles;
CREATE POLICY update_niveles ON niveles
  FOR UPDATE 
  USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  )
  WITH CHECK (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- DELETE - Para eliminar niveles
DROP POLICY IF EXISTS delete_niveles ON niveles;
CREATE POLICY delete_niveles ON niveles
  FOR DELETE USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- ===================================================
-- 7) POLÍTICAS PARA BANCOS
-- ===================================================

-- SELECT - Para ver bancos públicos o propios
DROP POLICY IF EXISTS select_bancos ON bancos;
CREATE POLICY select_bancos ON bancos
  FOR SELECT USING (
       es_publico = TRUE
    OR usuario_id = id_usuario_sesion()
    OR es_miembro_grupo(grupo_usuario_id)
  );

-- INSERT - Para crear nuevos bancos
DROP POLICY IF EXISTS insert_bancos ON bancos;
CREATE POLICY insert_bancos ON bancos
  FOR INSERT WITH CHECK (
    (es_publico = FALSE AND usuario_id = id_usuario_sesion() AND grupo_usuario_id IS NULL)
    OR (es_publico = FALSE AND usuario_id IS NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- UPDATE - Para actualizar bancos
DROP POLICY IF EXISTS update_bancos ON bancos;
CREATE POLICY update_bancos ON bancos
  FOR UPDATE 
  USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  )
  WITH CHECK (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- DELETE - Para eliminar bancos
DROP POLICY IF EXISTS delete_bancos ON bancos;
CREATE POLICY delete_bancos ON bancos
  FOR DELETE USING (
    (usuario_id = id_usuario_sesion())
    OR (grupo_usuario_id IS NOT NULL AND es_admin_grupo(grupo_usuario_id))
  );

-- ===================================================
-- 8) POLÍTICAS PARA PERIODICIDADES (tabla de solo lectura)
-- ===================================================

-- Las periodicidades son datos de catálogo que todos pueden leer
DROP POLICY IF EXISTS select_periodicidades ON periodicidades;
CREATE POLICY select_periodicidades ON periodicidades
  FOR SELECT USING (true);

-- ===================================================
-- 9) POLÍTICAS PARA CUENTAS
-- ===================================================

-- SELECT - Para ver cuentas propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_cuentas ON cuentas;
CREATE POLICY select_cuentas ON cuentas
  FOR SELECT USING (
    creada_por = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas cuentas
DROP POLICY IF EXISTS insert_cuentas ON cuentas;
CREATE POLICY insert_cuentas ON cuentas
  FOR INSERT WITH CHECK (
    creada_por = id_usuario_sesion()
    AND (
      grupo_usuario_id IS NULL 
      OR es_miembro_grupo(grupo_usuario_id)
    )
  );

-- UPDATE - Para actualizar cuentas
DROP POLICY IF EXISTS update_cuentas ON cuentas;
CREATE POLICY update_cuentas ON cuentas
  FOR UPDATE 
  USING (
    creada_por = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  )
  WITH CHECK (
    creada_por = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar cuentas
DROP POLICY IF EXISTS delete_cuentas ON cuentas;
CREATE POLICY delete_cuentas ON cuentas
  FOR DELETE USING (
    creada_por = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- ===================================================
-- 10) POLÍTICAS PARA TARJETAS DE CRÉDITO
-- ===================================================

-- SELECT - Para ver tarjetas de crédito propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_tarjetas_credito ON tarjetas_credito;
CREATE POLICY select_tarjetas_credito ON tarjetas_credito
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = tarjetas_credito.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas tarjetas de crédito
DROP POLICY IF EXISTS insert_tarjetas_credito ON tarjetas_credito;
CREATE POLICY insert_tarjetas_credito ON tarjetas_credito
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = tarjetas_credito.cuenta_id
      AND c.creada_por = id_usuario_sesion()
    )
  );

-- UPDATE - Para actualizar tarjetas de crédito
DROP POLICY IF EXISTS update_tarjetas_credito ON tarjetas_credito;
CREATE POLICY update_tarjetas_credito ON tarjetas_credito
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = tarjetas_credito.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = tarjetas_credito.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- DELETE - Para eliminar tarjetas de crédito
DROP POLICY IF EXISTS delete_tarjetas_credito ON tarjetas_credito;
CREATE POLICY delete_tarjetas_credito ON tarjetas_credito
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = tarjetas_credito.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- ===================================================
-- 11) POLÍTICAS PARA COMPRAS MSI
-- ===================================================

-- SELECT - Para ver compras MSI propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_compras_msi ON compras_msi;
CREATE POLICY select_compras_msi ON compras_msi
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
      WHERE tc.cuenta_id = compras_msi.cuenta_tarjeta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas compras MSI
DROP POLICY IF EXISTS insert_compras_msi ON compras_msi;
CREATE POLICY insert_compras_msi ON compras_msi
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM cuentas c
      JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
      WHERE tc.cuenta_id = compras_msi.cuenta_tarjeta_id
      AND c.creada_por = id_usuario_sesion()
    )
  );

-- UPDATE - Para actualizar compras MSI
DROP POLICY IF EXISTS update_compras_msi ON compras_msi;
CREATE POLICY update_compras_msi ON compras_msi
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
      WHERE tc.cuenta_id = compras_msi.cuenta_tarjeta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM cuentas c
      JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
      WHERE tc.cuenta_id = compras_msi.cuenta_tarjeta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- DELETE - Para eliminar compras MSI
DROP POLICY IF EXISTS delete_compras_msi ON compras_msi;
CREATE POLICY delete_compras_msi ON compras_msi
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
      WHERE tc.cuenta_id = compras_msi.cuenta_tarjeta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- ===================================================
-- 12) POLÍTICAS PARA COMPRAS A DEUDA
-- ===================================================

-- SELECT - Para ver compras a plazos propias o de grupos
DROP POLICY IF EXISTS select_compras_deuda ON compras_deuda;
CREATE POLICY select_compras_deuda ON compras_deuda
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = compras_deuda.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(c.grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas compras a plazos
DROP POLICY IF EXISTS insert_compras_deuda ON compras_deuda;
CREATE POLICY insert_compras_deuda ON compras_deuda
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
    AND EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = compras_deuda.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar compras a plazos
DROP POLICY IF EXISTS update_compras_deuda ON compras_deuda;
CREATE POLICY update_compras_deuda ON compras_deuda
  FOR UPDATE 
  USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = compras_deuda.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = compras_deuda.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar compras a plazos
DROP POLICY IF EXISTS delete_compras_deuda ON compras_deuda;
CREATE POLICY delete_compras_deuda ON compras_deuda
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = compras_deuda.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- ===================================================
-- 13) POLÍTICAS PARA CUOTAS DE DEUDA
-- ===================================================

-- SELECT - Para ver cuotas de deuda propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_cuotas_deuda ON cuotas_deuda;
CREATE POLICY select_cuotas_deuda ON cuotas_deuda
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM compras_deuda cd
      WHERE cd.id = cuotas_deuda.compra_id
      AND (
        cd.usuario_id = id_usuario_sesion()
        OR EXISTS (
          SELECT 1 FROM cuentas c
          WHERE c.id = cd.cuenta_id
          AND c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas cuotas
DROP POLICY IF EXISTS insert_cuotas_deuda ON cuotas_deuda;
CREATE POLICY insert_cuotas_deuda ON cuotas_deuda
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM compras_deuda cd
      WHERE cd.id = cuotas_deuda.compra_id
      AND cd.usuario_id = id_usuario_sesion()
    )
  );

-- UPDATE - Para actualizar cuotas
DROP POLICY IF EXISTS update_cuotas_deuda ON cuotas_deuda;
CREATE POLICY update_cuotas_deuda ON cuotas_deuda
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM compras_deuda cd
      WHERE cd.id = cuotas_deuda.compra_id
      AND (
        cd.usuario_id = id_usuario_sesion()
        OR EXISTS (
          SELECT 1 FROM cuentas c
          WHERE c.id = cd.cuenta_id
          AND c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM compras_deuda cd
      WHERE cd.id = cuotas_deuda.compra_id
      AND (
        cd.usuario_id = id_usuario_sesion()
        OR EXISTS (
          SELECT 1 FROM cuentas c
          WHERE c.id = cd.cuenta_id
          AND c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- DELETE - Para eliminar cuotas
DROP POLICY IF EXISTS delete_cuotas_deuda ON cuotas_deuda;
CREATE POLICY delete_cuotas_deuda ON cuotas_deuda
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM compras_deuda cd
      WHERE cd.id = cuotas_deuda.compra_id
      AND (
        cd.usuario_id = id_usuario_sesion()
        OR EXISTS (
          SELECT 1 FROM cuentas c
          WHERE c.id = cd.cuenta_id
          AND c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- ===================================================
-- 14) POLÍTICAS PARA MIEMBROS DE GRUPO
-- ===================================================

-- SELECT - Para ver miembros de grupos a los que pertenece
DROP POLICY IF EXISTS select_miembros_grupo ON miembros_grupo;
CREATE POLICY select_miembros_grupo ON miembros_grupo
  FOR SELECT USING (
    es_miembro_grupo(grupo_id)
  );

-- INSERT - Para agregar nuevos miembros (solo admins)
DROP POLICY IF EXISTS insert_miembros_grupo ON miembros_grupo;
CREATE POLICY insert_miembros_grupo ON miembros_grupo
  FOR INSERT WITH CHECK (
    es_admin_grupo(grupo_id)
  );

-- UPDATE - Para actualizar información de miembros (solo admins)
DROP POLICY IF EXISTS update_miembros_grupo ON miembros_grupo;
CREATE POLICY update_miembros_grupo ON miembros_grupo
  FOR UPDATE 
  USING (
    es_admin_grupo(grupo_id)
  )
  WITH CHECK (
    es_admin_grupo(grupo_id)
  );

-- DELETE - Para eliminar miembros (admins o usuario se retira)
DROP POLICY IF EXISTS delete_miembros_grupo ON miembros_grupo;
CREATE POLICY delete_miembros_grupo ON miembros_grupo
  FOR DELETE USING (
    es_admin_grupo(grupo_id)
    OR usuario_id = id_usuario_sesion()
  );

-- ===================================================
-- 15) POLÍTICAS PARA REGLAS DE REPARTO GRUPAL
-- ===================================================

-- SELECT - Para ver reglas de reparto de grupos a los que pertenece
DROP POLICY IF EXISTS select_reglas_reparto_grupo ON reglas_reparto_grupo;
CREATE POLICY select_reglas_reparto_grupo ON reglas_reparto_grupo
  FOR SELECT USING (
    es_miembro_grupo(grupo_id)
  );

-- INSERT - Para crear nuevas reglas (solo admins)
DROP POLICY IF EXISTS insert_reglas_reparto_grupo ON reglas_reparto_grupo;
CREATE POLICY insert_reglas_reparto_grupo ON reglas_reparto_grupo
  FOR INSERT WITH CHECK (
    es_admin_grupo(grupo_id)
  );

-- UPDATE - Para actualizar reglas (solo admins)
DROP POLICY IF EXISTS update_reglas_reparto_grupo ON reglas_reparto_grupo;
CREATE POLICY update_reglas_reparto_grupo ON reglas_reparto_grupo
  FOR UPDATE 
  USING (
    es_admin_grupo(grupo_id)
  )
  WITH CHECK (
    es_admin_grupo(grupo_id)
  );

-- DELETE - Para eliminar reglas (solo admins)
DROP POLICY IF EXISTS delete_reglas_reparto_grupo ON reglas_reparto_grupo;
CREATE POLICY delete_reglas_reparto_grupo ON reglas_reparto_grupo
  FOR DELETE USING (
    es_admin_grupo(grupo_id)
  );

-- ===================================================
-- 16) POLÍTICAS PARA TRANSACCIONES
-- ===================================================

-- SELECT - Para ver transacciones propias o de cuentas de grupos a los que pertenece
DROP POLICY IF EXISTS select_transacciones ON transacciones;
CREATE POLICY select_transacciones ON transacciones
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = transacciones.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(c.grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas transacciones
DROP POLICY IF EXISTS insert_transacciones ON transacciones;
CREATE POLICY insert_transacciones ON transacciones
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
    AND EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = transacciones.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar transacciones
DROP POLICY IF EXISTS update_transacciones ON transacciones;
CREATE POLICY update_transacciones ON transacciones
  FOR UPDATE 
  USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = transacciones.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = transacciones.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar transacciones
DROP POLICY IF EXISTS delete_transacciones ON transacciones;
CREATE POLICY delete_transacciones ON transacciones
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = transacciones.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- ===================================================
-- 17) POLÍTICAS PARA DIVISIONES DE TRANSACCIONES
-- ===================================================

-- SELECT - Para ver divisiones de transacciones
DROP POLICY IF EXISTS select_divisiones_transaccion ON divisiones_transaccion;
CREATE POLICY select_divisiones_transaccion ON divisiones_transaccion
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM transacciones t
      JOIN cuentas c ON t.cuenta_id = c.id
      WHERE t.id = divisiones_transaccion.transaccion_id
      AND (
        t.usuario_id = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas divisiones
DROP POLICY IF EXISTS insert_divisiones_transaccion ON divisiones_transaccion;
CREATE POLICY insert_divisiones_transaccion ON divisiones_transaccion
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM transacciones t
      JOIN cuentas c ON t.cuenta_id = c.id
      WHERE t.id = divisiones_transaccion.transaccion_id
      AND (
        t.usuario_id = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar divisiones
DROP POLICY IF EXISTS update_divisiones_transaccion ON divisiones_transaccion;
CREATE POLICY update_divisiones_transaccion ON divisiones_transaccion
  FOR UPDATE 
  USING (
    EXISTS (
      SELECT 1 FROM transacciones t
      JOIN cuentas c ON t.cuenta_id = c.id
      WHERE t.id = divisiones_transaccion.transaccion_id
      AND (
        t.usuario_id = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM transacciones t
      JOIN cuentas c ON t.cuenta_id = c.id
      WHERE t.id = divisiones_transaccion.transaccion_id
      AND (
        t.usuario_id = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- DELETE - Para eliminar divisiones
DROP POLICY IF EXISTS delete_divisiones_transaccion ON divisiones_transaccion;
CREATE POLICY delete_divisiones_transaccion ON divisiones_transaccion
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM transacciones t
      JOIN cuentas c ON t.cuenta_id = c.id
      WHERE t.id = divisiones_transaccion.transaccion_id
      AND (
        t.usuario_id = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_admin_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- ===================================================
-- 18) POLÍTICAS PARA REGLAS RECURRENTES
-- ===================================================

-- SELECT - Para ver reglas recurrentes propias o de grupos
DROP POLICY IF EXISTS select_reglas_recurrentes ON reglas_recurrentes;
CREATE POLICY select_reglas_recurrentes ON reglas_recurrentes
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = reglas_recurrentes.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(c.grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas reglas recurrentes
DROP POLICY IF EXISTS insert_reglas_recurrentes ON reglas_recurrentes;
CREATE POLICY insert_reglas_recurrentes ON reglas_recurrentes
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
    AND EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = reglas_recurrentes.cuenta_id
      AND (
        c.creada_por = id_usuario_sesion()
        OR (
          c.grupo_usuario_id IS NOT NULL 
          AND es_miembro_grupo(c.grupo_usuario_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar reglas recurrentes
DROP POLICY IF EXISTS update_reglas_recurrentes ON reglas_recurrentes;
CREATE POLICY update_reglas_recurrentes ON reglas_recurrentes
  FOR UPDATE 
  USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = reglas_recurrentes.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = reglas_recurrentes.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar reglas recurrentes
DROP POLICY IF EXISTS delete_reglas_recurrentes ON reglas_recurrentes;
CREATE POLICY delete_reglas_recurrentes ON reglas_recurrentes
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
    OR EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = reglas_recurrentes.cuenta_id
      AND c.grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(c.grupo_usuario_id)
    )
  );

-- ===================================================
-- 19) POLÍTICAS PARA METAS
-- ===================================================

-- SELECT - Para ver metas propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_metas ON metas;
CREATE POLICY select_metas ON metas
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas metas
DROP POLICY IF EXISTS insert_metas ON metas;
CREATE POLICY insert_metas ON metas
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
    AND (
      grupo_usuario_id IS NULL
      OR es_admin_grupo(grupo_usuario_id)
    )
  );

-- UPDATE - Para actualizar metas
DROP POLICY IF EXISTS update_metas ON metas;
CREATE POLICY update_metas ON metas
  FOR UPDATE 
  USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar metas
DROP POLICY IF EXISTS delete_metas ON metas;
CREATE POLICY delete_metas ON metas
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- ===================================================
-- 20) POLÍTICAS PARA NOTIFICACIONES
-- ===================================================

-- SELECT - Para ver notificaciones propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_notificaciones ON notificaciones;
CREATE POLICY select_notificaciones ON notificaciones
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_miembro_grupo(grupo_usuario_id)
    )
  );

-- INSERT - Para crear nuevas notificaciones (sistema o admins)
DROP POLICY IF EXISTS insert_notificaciones ON notificaciones;
CREATE POLICY insert_notificaciones ON notificaciones
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- UPDATE - Para actualizar notificaciones (marcar como leída, etc.)
DROP POLICY IF EXISTS update_notificaciones ON notificaciones;
CREATE POLICY update_notificaciones ON notificaciones
  FOR UPDATE 
  USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- DELETE - Para eliminar notificaciones
DROP POLICY IF EXISTS delete_notificaciones ON notificaciones;
CREATE POLICY delete_notificaciones ON notificaciones
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
    OR (
      grupo_usuario_id IS NOT NULL 
      AND es_admin_grupo(grupo_usuario_id)
    )
  );

-- ===================================================
-- POLÍTICAS RLS PARA JERARQUÍAS DE USUARIO
-- ===================================================

-- Habilitar RLS
ALTER TABLE jerarquias_usuario ENABLE ROW LEVEL SECURITY;

-- SELECT - Ver solo sus propias jerarquías
CREATE POLICY select_jerarquias_usuario ON jerarquias_usuario
  FOR SELECT USING (
    usuario_id = id_usuario_sesion()
  );

-- INSERT - Solo crear sus propias jerarquías
CREATE POLICY insert_jerarquias_usuario ON jerarquias_usuario
  FOR INSERT WITH CHECK (
    usuario_id = id_usuario_sesion()
  );

-- UPDATE - Solo actualizar sus propias jerarquías
CREATE POLICY update_jerarquias_usuario ON jerarquias_usuario
  FOR UPDATE USING (
    usuario_id = id_usuario_sesion()
  )
  WITH CHECK (
    usuario_id = id_usuario_sesion()
  );

-- DELETE - Solo eliminar sus propias jerarquías
CREATE POLICY delete_jerarquias_usuario ON jerarquias_usuario
  FOR DELETE USING (
    usuario_id = id_usuario_sesion()
  );
