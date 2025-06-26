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

-- 5) periodicities
DROP POLICY IF EXISTS select_periodicities ON periodicities;
CREATE POLICY select_periodicities ON periodicities
  FOR SELECT USING (true);

-- 6) accounts
DROP POLICY IF EXISTS select_accounts ON accounts;
CREATE POLICY select_accounts ON accounts
  FOR SELECT USING (
       created_by = session_user_id()
    OR is_group_member(user_group_id)
  );

-- 7) group_members
DROP POLICY IF EXISTS select_group_members      ON group_members;
DROP POLICY IF EXISTS ins_group_members_admin  ON group_members;
DROP POLICY IF EXISTS upd_group_members_admin  ON group_members;
DROP POLICY IF EXISTS del_group_members_admin  ON group_members;

CREATE POLICY select_group_members ON group_members
  FOR SELECT USING (
    is_group_member(group_id)
  );

CREATE POLICY ins_group_members_admin ON group_members
  FOR INSERT WITH CHECK (
    is_group_admin(group_id)
  );

CREATE POLICY upd_group_members_admin ON group_members
  FOR UPDATE
  USING     (is_group_admin(group_id))
  WITH CHECK(is_group_admin(group_id));

CREATE POLICY del_group_members_admin ON group_members
  FOR DELETE USING (
    is_group_admin(group_id)
  );

-- 8) group_share_rules
DROP POLICY IF EXISTS select_group_share_rules ON group_share_rules;
CREATE POLICY select_group_share_rules ON group_share_rules
  FOR SELECT USING (
    is_group_member(group_id)
  );

-- 9) transactions
DROP POLICY IF EXISTS select_transactions ON transactions;
CREATE POLICY select_transactions ON transactions
  FOR SELECT USING (
       user_id = session_user_id()
    OR account_id IN (
         SELECT id FROM accounts WHERE is_group_member(user_group_id)
       )
    OR id IN (
         SELECT transaction_id FROM transaction_splits WHERE user_id = session_user_id()
       )
  );

-- 10) transaction_splits
DROP POLICY IF EXISTS select_transaction_splits ON transaction_splits;
CREATE POLICY select_transaction_splits ON transaction_splits
  FOR SELECT USING (
       user_id = session_user_id()
    OR transaction_id IN (
         SELECT id FROM transactions WHERE account_id IN (
           SELECT id FROM accounts WHERE is_group_member(user_group_id)
         )
       )
  );

-- 11) debt_purchases
DROP POLICY IF EXISTS select_debt_purchases ON debt_purchases;
CREATE POLICY select_debt_purchases ON debt_purchases
  FOR SELECT USING (
       user_id = session_user_id()
    OR account_id IN (
         SELECT id FROM accounts WHERE is_group_member(user_group_id)
       )
  );

-- 12) debt_installments
DROP POLICY IF EXISTS select_debt_installments ON debt_installments;
CREATE POLICY select_debt_installments ON debt_installments
  FOR SELECT USING (
    purchase_id IN (
      SELECT id FROM debt_purchases
       WHERE user_id = session_user_id()
          OR account_id IN (
               SELECT id FROM accounts WHERE is_group_member(user_group_id)
             )
    )
  );

-- 13) recurring_rules
DROP POLICY IF EXISTS select_recurring_rules ON recurring_rules;
CREATE POLICY select_recurring_rules ON recurring_rules
  FOR SELECT USING (
    user_id = session_user_id()
  );

-- 14) goals
DROP POLICY IF EXISTS select_goals ON goals;
CREATE POLICY select_goals ON goals
  FOR SELECT USING (
       user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- 15) notifications
DROP POLICY IF EXISTS select_notifications ON notifications;
CREATE POLICY select_notifications ON notifications
  FOR SELECT USING (
       user_id = session_user_id()
    OR is_group_member(user_group_id)
  );

-- 16) banks
DROP POLICY IF EXISTS select_banks ON banks;
CREATE POLICY select_banks ON banks
  FOR SELECT USING (
       is_public
    OR user_id = session_user_id()
    OR is_group_member(user_group_id)
  );
