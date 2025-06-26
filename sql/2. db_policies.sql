-- ===================================================
-- 1) Activar RLS en todas las tablas
-- ===================================================
ALTER TABLE user_groups         ENABLE ROW LEVEL SECURITY;
ALTER TABLE category_groups     ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories          ENABLE ROW LEVEL SECURITY;
ALTER TABLE levels              ENABLE ROW LEVEL SECURITY;
ALTER TABLE periodicities       ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts            ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members       ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_share_rules   ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_splits  ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_purchases      ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_installments   ENABLE ROW LEVEL SECURITY;
ALTER TABLE recurring_rules     ENABLE ROW LEVEL SECURITY;
ALTER TABLE goals               ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications       ENABLE ROW LEVEL SECURITY;
ALTER TABLE banks               ENABLE ROW LEVEL SECURITY;

-- ===================================================
-- 2) Helpers para evitar recursión
-- ===================================================
CREATE OR REPLACE FUNCTION public.is_group_member(_gid UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET row_security = OFF
AS $$
  SELECT EXISTS(
    SELECT 1 FROM group_members
     WHERE group_id = _gid
       AND user_id  = session_user_id()
  );
$$;

CREATE OR REPLACE FUNCTION public.is_group_admin(_gid UUID)
RETURNS BOOLEAN
LANGUAGE sql STABLE SECURITY DEFINER
SET row_security = OFF
AS $$
  SELECT EXISTS(
    SELECT 1 FROM group_members
     WHERE group_id = _gid
       AND user_id  = session_user_id()
       AND role     = 'admin'
  );
$$;

-- ===================================================
-- 3) POLICIES
-- ===================================================

-- 1) user_groups
DROP POLICY IF EXISTS select_user_groups ON user_groups;
CREATE POLICY select_user_groups ON user_groups
  FOR SELECT USING (
    is_group_member(id)
  );

-- 2) category_groups
DROP POLICY IF EXISTS select_category_groups ON category_groups;
CREATE POLICY select_category_groups ON category_groups
  FOR SELECT USING (
       is_public
    OR user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- INSERT - NUEVA POLÍTICA
DROP POLICY IF EXISTS insert_category_groups ON category_groups;
CREATE POLICY insert_category_groups ON category_groups
  FOR INSERT WITH CHECK (
    -- Solo puede insertar si:
    -- 1. Es el propietario (user_id = session_user_id())
    -- 2. O es admin del grupo (si tiene user_group_id)
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- UPDATE - NUEVA POLÍTICA
DROP POLICY IF EXISTS update_category_groups ON category_groups;
CREATE POLICY update_category_groups ON category_groups
  FOR UPDATE 
  USING (
    -- Solo puede actualizar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - NUEVA POLÍTICA
DROP POLICY IF EXISTS delete_category_groups ON category_groups;
CREATE POLICY delete_category_groups ON category_groups
  FOR DELETE USING (
    -- Solo puede eliminar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- 3) categories
DROP POLICY IF EXISTS select_categories ON categories;
CREATE POLICY select_categories ON categories
  FOR SELECT USING (
       is_public
    OR user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- INSERT - NUEVA POLÍTICA
DROP POLICY IF EXISTS insert_categories ON categories;
CREATE POLICY insert_categories ON categories
  FOR INSERT WITH CHECK (
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- UPDATE - NUEVA POLÍTICA
DROP POLICY IF EXISTS update_categories ON categories;
CREATE POLICY update_categories ON categories
  FOR UPDATE 
  USING (
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - NUEVA POLÍTICA
DROP POLICY IF EXISTS delete_categories ON categories;
CREATE POLICY delete_categories ON categories
  FOR DELETE USING (
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- 4) levels
DROP POLICY IF EXISTS select_levels ON levels;
CREATE POLICY select_levels ON levels
  FOR SELECT USING (
       is_public
    OR user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- INSERT - NUEVA POLÍTICA
DROP POLICY IF EXISTS insert_levels ON levels;
CREATE POLICY insert_levels ON levels
  FOR INSERT WITH CHECK (
    -- Solo puede insertar si:
    -- 1. Es el propietario (user_id = session_user_id())
    -- 2. O es admin del grupo (si tiene user_group_id)
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- UPDATE - NUEVA POLÍTICA
DROP POLICY IF EXISTS update_levels ON levels;
CREATE POLICY update_levels ON levels
  FOR UPDATE 
  USING (
    -- Solo puede actualizar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - NUEVA POLÍTICA
DROP POLICY IF EXISTS delete_levels ON levels;
CREATE POLICY delete_levels ON levels
  FOR DELETE USING (
    -- Solo puede eliminar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA BANKS
-- ===================================================

-- SELECT - Ya existe pero se mantiene para referencia
DROP POLICY IF EXISTS select_banks ON banks;
CREATE POLICY select_banks ON banks
  FOR SELECT USING (
       is_public
    OR user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- INSERT - NUEVA POLÍTICA
DROP POLICY IF EXISTS insert_banks ON banks;
CREATE POLICY insert_banks ON banks
  FOR INSERT WITH CHECK (
    -- Solo puede insertar si:
    -- 1. Es el propietario (user_id = session_user_id())
    -- 2. O es admin del grupo (si tiene user_group_id)
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- UPDATE - NUEVA POLÍTICA
DROP POLICY IF EXISTS update_banks ON banks;
CREATE POLICY update_banks ON banks
  FOR UPDATE 
  USING (
    -- Solo puede actualizar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - NUEVA POLÍTICA
DROP POLICY IF EXISTS delete_banks ON banks;
CREATE POLICY delete_banks ON banks
  FOR DELETE USING (
    -- Solo puede eliminar si:
    -- 1. Es el propietario
    -- 2. O es admin del grupo
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );
