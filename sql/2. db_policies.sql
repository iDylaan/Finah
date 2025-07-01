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
ALTER TABLE credit_cards        ENABLE ROW LEVEL SECURITY;
ALTER TABLE msi_purchases       ENABLE ROW LEVEL SECURITY;

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



-- Las tablas credit_cards, msi_purchases y debt_installments ya están habilitadas arriba

-- ===================================================
-- POLÍTICAS PARA CREDIT_CARDS
-- ===================================================

-- SELECT - Para ver tarjetas de crédito propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_credit_cards ON credit_cards;
CREATE POLICY select_credit_cards ON credit_cards
  FOR SELECT USING (
    -- Puede ver una tarjeta si:
    -- 1. Es el propietario de la cuenta asociada
    -- 2. Es miembro del grupo al que pertenece la cuenta
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = credit_cards.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas tarjetas de crédito
DROP POLICY IF EXISTS insert_credit_cards ON credit_cards;
CREATE POLICY insert_credit_cards ON credit_cards
  FOR INSERT WITH CHECK (
    -- Puede insertar una tarjeta si:
    -- 1. Es el propietario de la cuenta asociada
    -- 2. Es admin del grupo al que pertenece la cuenta
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = credit_cards.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar tarjetas de crédito
DROP POLICY IF EXISTS update_credit_cards ON credit_cards;
CREATE POLICY update_credit_cards ON credit_cards
  FOR UPDATE 
  USING (
    -- Puede actualizar una tarjeta si:
    -- 1. Es el propietario de la cuenta asociada
    -- 2. Es admin del grupo al que pertenece la cuenta
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = credit_cards.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = credit_cards.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- DELETE - Para eliminar tarjetas de crédito
DROP POLICY IF EXISTS delete_credit_cards ON credit_cards;
CREATE POLICY delete_credit_cards ON credit_cards
  FOR DELETE USING (
    -- Puede eliminar una tarjeta si:
    -- 1. Es el propietario de la cuenta asociada
    -- 2. Es admin del grupo al que pertenece la cuenta
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = credit_cards.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- ===================================================
-- POLÍTICAS PARA MSI_PURCHASES
-- ===================================================

-- SELECT - Para ver compras MSI propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_msi_purchases ON msi_purchases;
CREATE POLICY select_msi_purchases ON msi_purchases
  FOR SELECT USING (
    -- Puede ver una compra MSI si:
    -- 1. Está asociada a una tarjeta de crédito que le pertenece
    -- 2. Está asociada a una tarjeta de un grupo al que pertenece
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = msi_purchases.card_account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
    -- O si es el dueño de la compra a plazos asociada
    OR EXISTS (
      SELECT 1 FROM debt_purchases dp
      WHERE dp.id = msi_purchases.debt_purchase_id
      AND dp.user_id = session_user_id()
    )
  );

-- INSERT - Para crear nuevas compras MSI
DROP POLICY IF EXISTS insert_msi_purchases ON msi_purchases;
CREATE POLICY insert_msi_purchases ON msi_purchases
  FOR INSERT WITH CHECK (
    -- Puede insertar una compra MSI si:
    -- 1. Está asociada a una tarjeta de crédito que le pertenece
    -- 2. Está asociada a una tarjeta de un grupo donde es admin
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = msi_purchases.card_account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
    -- O si es el dueño de la compra a plazos asociada
    OR EXISTS (
      SELECT 1 FROM debt_purchases dp
      WHERE dp.id = msi_purchases.debt_purchase_id
      AND dp.user_id = session_user_id()
    )
  );

-- UPDATE - Para actualizar compras MSI
DROP POLICY IF EXISTS update_msi_purchases ON msi_purchases;
CREATE POLICY update_msi_purchases ON msi_purchases
  FOR UPDATE 
  USING (
    -- Puede actualizar una compra MSI si:
    -- 1. Está asociada a una tarjeta de crédito que le pertenece
    -- 2. Está asociada a una tarjeta de un grupo donde es admin
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = msi_purchases.card_account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
    -- O si es el dueño de la compra a plazos asociada
    OR EXISTS (
      SELECT 1 FROM debt_purchases dp
      WHERE dp.id = msi_purchases.debt_purchase_id
      AND dp.user_id = session_user_id()
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = msi_purchases.card_account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
    -- O si es el dueño de la compra a plazos asociada
    OR EXISTS (
      SELECT 1 FROM debt_purchases dp
      WHERE dp.id = msi_purchases.debt_purchase_id
      AND dp.user_id = session_user_id()
    )
  );

-- DELETE - Para eliminar compras MSI
DROP POLICY IF EXISTS delete_msi_purchases ON msi_purchases;
CREATE POLICY delete_msi_purchases ON msi_purchases
  FOR DELETE USING (
    -- Puede eliminar una compra MSI si:
    -- 1. Está asociada a una tarjeta de crédito que le pertenece
    -- 2. Está asociada a una tarjeta de un grupo donde es admin
    EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = msi_purchases.card_account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
    -- O si es el dueño de la compra a plazos asociada
    OR EXISTS (
      SELECT 1 FROM debt_purchases dp
      WHERE dp.id = msi_purchases.debt_purchase_id
      AND dp.user_id = session_user_id()
    )
  );

-- Las políticas para debt_installments ya están definidas arriba en el archivo

-- ===================================================
-- POLÍTICAS PARA DEBT_PURCHASES
-- ===================================================

-- SELECT - Para ver compras a plazos propias o de grupos
DROP POLICY IF EXISTS select_debt_purchases ON debt_purchases;
CREATE POLICY select_debt_purchases ON debt_purchases
  FOR SELECT USING (
    -- Puede ver una compra a plazos si:
    -- 1. Es el propietario de la compra
    -- 2. Es miembro del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_member(a.user_group_id)
    )
  );

-- INSERT - Para crear nuevas compras a plazos
DROP POLICY IF EXISTS insert_debt_purchases ON debt_purchases;
CREATE POLICY insert_debt_purchases ON debt_purchases
  FOR INSERT WITH CHECK (
    -- Puede insertar una compra a plazos si:
    -- 1. Es el propietario de la compra (user_id = session_user_id())
    -- 2. Tiene acceso a la cuenta asociada
    user_id = session_user_id()
    AND EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar compras a plazos
DROP POLICY IF EXISTS update_debt_purchases ON debt_purchases;
CREATE POLICY update_debt_purchases ON debt_purchases
  FOR UPDATE 
  USING (
    -- Puede actualizar una compra a plazos si:
    -- 1. Es el propietario de la compra
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- DELETE - Para eliminar compras a plazos
DROP POLICY IF EXISTS delete_debt_purchases ON debt_purchases;
CREATE POLICY delete_debt_purchases ON debt_purchases
  FOR DELETE USING (
    -- Puede eliminar una compra a plazos si:
    -- 1. Es el propietario de la compra
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA DEBT_INSTALLMENTS
-- ===================================================

-- SELECT - Para ver cuotas de deuda propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_debt_installments ON debt_installments;
CREATE POLICY select_debt_installments ON debt_installments
  FOR SELECT USING (
    -- Puede ver una cuota si:
    -- 1. Es el propietario de la compra asociada
    -- 2. Es miembro del grupo de la cuenta asociada a la compra
    EXISTS (
      SELECT 1 FROM debt_purchases dp
      JOIN accounts a ON dp.account_id = a.id
      WHERE dp.id = debt_installments.purchase_id
      AND (
        dp.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas cuotas
DROP POLICY IF EXISTS insert_debt_installments ON debt_installments;
CREATE POLICY insert_debt_installments ON debt_installments
  FOR INSERT WITH CHECK (
    -- Puede insertar una cuota si:
    -- 1. Es el propietario de la compra asociada
    -- 2. Es admin del grupo de la cuenta asociada a la compra
    EXISTS (
      SELECT 1 FROM debt_purchases dp
      JOIN accounts a ON dp.account_id = a.id
      WHERE dp.id = debt_installments.purchase_id
      AND (
        dp.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar cuotas
DROP POLICY IF EXISTS update_debt_installments ON debt_installments;
CREATE POLICY update_debt_installments ON debt_installments
  FOR UPDATE 
  USING (
    -- Puede actualizar una cuota si:
    -- 1. Es el propietario de la compra asociada
    -- 2. Es admin del grupo de la cuenta asociada a la compra
    EXISTS (
      SELECT 1 FROM debt_purchases dp
      JOIN accounts a ON dp.account_id = a.id
      WHERE dp.id = debt_installments.purchase_id
      AND (
        dp.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    EXISTS (
      SELECT 1 FROM debt_purchases dp
      JOIN accounts a ON dp.account_id = a.id
      WHERE dp.id = debt_installments.purchase_id
      AND (
        dp.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- DELETE - Para eliminar cuotas
DROP POLICY IF EXISTS delete_debt_installments ON debt_installments;
CREATE POLICY delete_debt_installments ON debt_installments
  FOR DELETE USING (
    -- Puede eliminar una cuota si:
    -- 1. Es el propietario de la compra asociada
    -- 2. Es admin del grupo de la cuenta asociada a la compra
    EXISTS (
      SELECT 1 FROM debt_purchases dp
      JOIN accounts a ON dp.account_id = a.id
      WHERE dp.id = debt_installments.purchase_id
      AND (
        dp.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- ===================================================
-- POLÍTICAS PARA PERIODICITIES (tabla de solo lectura)
-- ===================================================

-- Las periodicidades son datos de catálogo que todos pueden leer
DROP POLICY IF EXISTS select_periodicities ON periodicities;
CREATE POLICY select_periodicities ON periodicities
  FOR SELECT USING (true);

-- ===================================================
-- POLÍTICAS PARA ACCOUNTS
-- ===================================================

-- SELECT - Para ver cuentas propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_accounts ON accounts;
CREATE POLICY select_accounts ON accounts
  FOR SELECT USING (
    -- Puede ver una cuenta si:
    -- 1. Es el creador de la cuenta
    -- 2. Es miembro del grupo al que pertenece la cuenta
    created_by = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_member(user_group_id)
    )
  );

-- INSERT - Para crear nuevas cuentas
DROP POLICY IF EXISTS insert_accounts ON accounts;
CREATE POLICY insert_accounts ON accounts
  FOR INSERT WITH CHECK (
    -- Puede insertar una cuenta si:
    -- 1. Es el creador de la cuenta
    -- 2. Es admin del grupo (si se asigna a un grupo)
    created_by = session_user_id()
    AND (
      user_group_id IS NULL
      OR is_group_admin(user_group_id)
    )
  );

-- UPDATE - Para actualizar cuentas
DROP POLICY IF EXISTS update_accounts ON accounts;
CREATE POLICY update_accounts ON accounts
  FOR UPDATE 
  USING (
    -- Puede actualizar una cuenta si:
    -- 1. Es el creador de la cuenta
    -- 2. Es admin del grupo al que pertenece la cuenta
    created_by = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    created_by = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - Para eliminar cuentas
DROP POLICY IF EXISTS delete_accounts ON accounts;
CREATE POLICY delete_accounts ON accounts
  FOR DELETE USING (
    -- Puede eliminar una cuenta si:
    -- 1. Es el creador de la cuenta
    -- 2. Es admin del grupo al que pertenece la cuenta
    created_by = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA GROUP_MEMBERS
-- ===================================================

-- SELECT - Para ver miembros de grupos a los que pertenece
DROP POLICY IF EXISTS select_group_members ON group_members;
CREATE POLICY select_group_members ON group_members
  FOR SELECT USING (
    -- Puede ver los miembros si es miembro del grupo
    is_group_member(group_id)
  );

-- INSERT - Para agregar nuevos miembros (solo admins)
DROP POLICY IF EXISTS insert_group_members ON group_members;
CREATE POLICY insert_group_members ON group_members
  FOR INSERT WITH CHECK (
    -- Solo los admins pueden agregar nuevos miembros
    is_group_admin(group_id)
  );

-- UPDATE - Para actualizar información de miembros (solo admins)
DROP POLICY IF EXISTS update_group_members ON group_members;
CREATE POLICY update_group_members ON group_members
  FOR UPDATE 
  USING (
    -- Solo los admins pueden actualizar miembros
    is_group_admin(group_id)
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    is_group_admin(group_id)
  );

-- DELETE - Para eliminar miembros (solo admins, excepto que un usuario se retire)
DROP POLICY IF EXISTS delete_group_members ON group_members;
CREATE POLICY delete_group_members ON group_members
  FOR DELETE USING (
    -- Puede eliminar si:
    -- 1. Es admin del grupo
    -- 2. Es el propio usuario que se quiere retirar
    is_group_admin(group_id)
    OR user_id = session_user_id()
  );

-- ===================================================
-- POLÍTICAS PARA GROUP_SHARE_RULES
-- ===================================================

-- SELECT - Para ver reglas de reparto de grupos a los que pertenece
DROP POLICY IF EXISTS select_group_share_rules ON group_share_rules;
CREATE POLICY select_group_share_rules ON group_share_rules
  FOR SELECT USING (
    -- Puede ver las reglas si es miembro del grupo
    is_group_member(group_id)
  );

-- INSERT - Para crear nuevas reglas (solo admins)
DROP POLICY IF EXISTS insert_group_share_rules ON group_share_rules;
CREATE POLICY insert_group_share_rules ON group_share_rules
  FOR INSERT WITH CHECK (
    -- Solo los admins pueden crear reglas de reparto
    is_group_admin(group_id)
  );

-- UPDATE - Para actualizar reglas (solo admins)
DROP POLICY IF EXISTS update_group_share_rules ON group_share_rules;
CREATE POLICY update_group_share_rules ON group_share_rules
  FOR UPDATE 
  USING (
    -- Solo los admins pueden actualizar reglas
    is_group_admin(group_id)
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    is_group_admin(group_id)
  );

-- DELETE - Para eliminar reglas (solo admins)
DROP POLICY IF EXISTS delete_group_share_rules ON group_share_rules;
CREATE POLICY delete_group_share_rules ON group_share_rules
  FOR DELETE USING (
    -- Solo los admins pueden eliminar reglas
    is_group_admin(group_id)
  );

-- ===================================================
-- POLÍTICAS PARA TRANSACTIONS
-- ===================================================

-- SELECT - Para ver transacciones propias o de cuentas de grupos a los que pertenece
DROP POLICY IF EXISTS select_transactions ON transactions;
CREATE POLICY select_transactions ON transactions
  FOR SELECT USING (
    -- Puede ver una transacción si:
    -- 1. Es el propietario de la transacción
    -- 2. Es miembro del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = transactions.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas transacciones
DROP POLICY IF EXISTS insert_transactions ON transactions;
CREATE POLICY insert_transactions ON transactions
  FOR INSERT WITH CHECK (
    -- Puede insertar una transacción si:
    -- 1. Es el propietario de la transacción y tiene acceso a la cuenta
    user_id = session_user_id()
    AND EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = transactions.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar transacciones
DROP POLICY IF EXISTS update_transactions ON transactions;
CREATE POLICY update_transactions ON transactions
  FOR UPDATE 
  USING (
    -- Puede actualizar una transacción si:
    -- 1. Es el propietario de la transacción
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = transactions.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = transactions.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- DELETE - Para eliminar transacciones
DROP POLICY IF EXISTS delete_transactions ON transactions;
CREATE POLICY delete_transactions ON transactions
  FOR DELETE USING (
    -- Puede eliminar una transacción si:
    -- 1. Es el propietario de la transacción
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = transactions.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA TRANSACTION_SPLITS
-- ===================================================

-- SELECT - Para ver divisiones de transacciones
DROP POLICY IF EXISTS select_transaction_splits ON transaction_splits;
CREATE POLICY select_transaction_splits ON transaction_splits
  FOR SELECT USING (
    -- Puede ver una división si:
    -- 1. Es el usuario asignado en la división
    -- 2. Tiene acceso a la transacción principal
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.id = transaction_splits.transaction_id
      AND (
        t.user_id = session_user_id()
        OR a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- INSERT - Para crear nuevas divisiones
DROP POLICY IF EXISTS insert_transaction_splits ON transaction_splits;
CREATE POLICY insert_transaction_splits ON transaction_splits
  FOR INSERT WITH CHECK (
    -- Puede insertar una división si tiene acceso a la transacción
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.id = transaction_splits.transaction_id
      AND (
        t.user_id = session_user_id()
        OR a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar divisiones
DROP POLICY IF EXISTS update_transaction_splits ON transaction_splits;
CREATE POLICY update_transaction_splits ON transaction_splits
  FOR UPDATE 
  USING (
    -- Puede actualizar una división si tiene acceso a la transacción
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.id = transaction_splits.transaction_id
      AND (
        t.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.id = transaction_splits.transaction_id
      AND (
        t.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- DELETE - Para eliminar divisiones
DROP POLICY IF EXISTS delete_transaction_splits ON transaction_splits;
CREATE POLICY delete_transaction_splits ON transaction_splits
  FOR DELETE USING (
    -- Puede eliminar una división si tiene acceso a la transacción
    EXISTS (
      SELECT 1 FROM transactions t
      JOIN accounts a ON t.account_id = a.id
      WHERE t.id = transaction_splits.transaction_id
      AND (
        t.user_id = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

-- ===================================================
-- POLÍTICAS PARA RECURRING_RULES
-- ===================================================

-- SELECT - Para ver reglas recurrentes propias o de grupos
DROP POLICY IF EXISTS select_recurring_rules ON recurring_rules;
CREATE POLICY select_recurring_rules ON recurring_rules
  FOR SELECT USING (
    -- Puede ver una regla si:
    -- 1. Es el propietario de la regla
    -- 2. Es miembro del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = recurring_rules.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_member(a.user_group_id)
    )
  );

-- INSERT - Para crear nuevas reglas recurrentes
DROP POLICY IF EXISTS insert_recurring_rules ON recurring_rules;
CREATE POLICY insert_recurring_rules ON recurring_rules
  FOR INSERT WITH CHECK (
    -- Puede insertar una regla si:
    -- 1. Es el propietario y tiene acceso a la cuenta
    user_id = session_user_id()
    AND EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = recurring_rules.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_member(a.user_group_id)
        )
      )
    )
  );

-- UPDATE - Para actualizar reglas recurrentes
DROP POLICY IF EXISTS update_recurring_rules ON recurring_rules;
CREATE POLICY update_recurring_rules ON recurring_rules
  FOR UPDATE 
  USING (
    -- Puede actualizar una regla si:
    -- 1. Es el propietario de la regla
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = recurring_rules.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = recurring_rules.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- DELETE - Para eliminar reglas recurrentes
DROP POLICY IF EXISTS delete_recurring_rules ON recurring_rules;
CREATE POLICY delete_recurring_rules ON recurring_rules
  FOR DELETE USING (
    -- Puede eliminar una regla si:
    -- 1. Es el propietario de la regla
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    OR EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = recurring_rules.account_id
      AND a.user_group_id IS NOT NULL 
      AND is_group_admin(a.user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA GOALS
-- ===================================================

-- SELECT - Para ver metas propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_goals ON goals;
CREATE POLICY select_goals ON goals
  FOR SELECT USING (
    -- Puede ver una meta si:
    -- 1. Es el propietario de la meta
    -- 2. Es miembro del grupo al que pertenece la meta
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_member(user_group_id)
    )
  );

-- INSERT - Para crear nuevas metas
DROP POLICY IF EXISTS insert_goals ON goals;
CREATE POLICY insert_goals ON goals
  FOR INSERT WITH CHECK (
    -- Puede insertar una meta si:
    -- 1. Es el propietario de la meta
    -- 2. Es admin del grupo (si se asigna a un grupo)
    user_id = session_user_id()
    AND (
      user_group_id IS NULL
      OR is_group_admin(user_group_id)
    )
  );

-- UPDATE - Para actualizar metas
DROP POLICY IF EXISTS update_goals ON goals;
CREATE POLICY update_goals ON goals
  FOR UPDATE 
  USING (
    -- Puede actualizar una meta si:
    -- 1. Es el propietario de la meta
    -- 2. Es admin del grupo al que pertenece la meta
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - Para eliminar metas
DROP POLICY IF EXISTS delete_goals ON goals;
CREATE POLICY delete_goals ON goals
  FOR DELETE USING (
    -- Puede eliminar una meta si:
    -- 1. Es el propietario de la meta
    -- 2. Es admin del grupo al que pertenece la meta
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- ===================================================
-- POLÍTICAS PARA NOTIFICATIONS
-- ===================================================

-- SELECT - Para ver notificaciones propias o de grupos a los que pertenece
DROP POLICY IF EXISTS select_notifications ON notifications;
CREATE POLICY select_notifications ON notifications
  FOR SELECT USING (
    -- Puede ver una notificación si:
    -- 1. Es el destinatario de la notificación
    -- 2. Es miembro del grupo al que pertenece la notificación
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_member(user_group_id)
    )
  );

-- INSERT - Para crear nuevas notificaciones (sistema o admins)
DROP POLICY IF EXISTS insert_notifications ON notifications;
CREATE POLICY insert_notifications ON notifications
  FOR INSERT WITH CHECK (
    -- Puede insertar una notificación si:
    -- 1. Es para el propio usuario
    -- 2. Es admin del grupo (si es notificación grupal)
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- UPDATE - Para actualizar notificaciones (marcar como leída, etc.)
DROP POLICY IF EXISTS update_notifications ON notifications;
CREATE POLICY update_notifications ON notifications
  FOR UPDATE 
  USING (
    -- Puede actualizar una notificación si:
    -- 1. Es el destinatario de la notificación
    -- 2. Es admin del grupo al que pertenece la notificación
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  )
  WITH CHECK (
    -- Los mismos permisos para el resultado actualizado
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );

-- DELETE - Para eliminar notificaciones
DROP POLICY IF EXISTS delete_notifications ON notifications;
CREATE POLICY delete_notifications ON notifications
  FOR DELETE USING (
    -- Puede eliminar una notificación si:
    -- 1. Es el destinatario de la notificación
    -- 2. Es admin del grupo al que pertenece la notificación
    user_id = session_user_id()
    OR (
      user_group_id IS NOT NULL 
      AND is_group_admin(user_group_id)
    )
  );