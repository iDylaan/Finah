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



-- ===================================================
-- Activar RLS en las tablas de tarjetas
-- ===================================================
ALTER TABLE credit_cards        ENABLE ROW LEVEL SECURITY;
ALTER TABLE msi_purchases       ENABLE ROW LEVEL SECURITY;
ALTER TABLE debt_installments   ENABLE ROW LEVEL SECURITY;

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

-- ===================================================
-- POLÍTICAS ADICIONALES PARA DEBT_INSTALLMENTS
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
-- POLÍTICAS PARA DEBT_PURCHASES (Actualización)
-- ===================================================

-- Si aún no existen políticas para debt_purchases, añadirlas:

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

DROP POLICY IF EXISTS insert_debt_purchases ON debt_purchases;
CREATE POLICY insert_debt_purchases ON debt_purchases
  FOR INSERT WITH CHECK (
    -- Puede insertar una compra a plazos si:
    -- 1. Es el propietario de la compra (user_id = session_user_id())
    -- 2. Es admin del grupo de la cuenta asociada
    user_id = session_user_id()
    AND EXISTS (
      SELECT 1 FROM accounts a
      WHERE a.id = debt_purchases.account_id
      AND (
        a.created_by = session_user_id()
        OR (
          a.user_group_id IS NOT NULL 
          AND is_group_admin(a.user_group_id)
        )
      )
    )
  );

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