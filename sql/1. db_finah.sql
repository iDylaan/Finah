-- ==================================================================
-- 0) Extensión para UUIDs
-- ==================================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==================================================================
-- 1) Eliminar tablas existentes (orden inverso de dependencias)
-- ==================================================================
DROP TABLE IF EXISTS notifications        CASCADE;
DROP TABLE IF EXISTS goals                CASCADE;
DROP TABLE IF EXISTS recurring_rules      CASCADE;
DROP TABLE IF EXISTS debt_installments    CASCADE;
DROP TABLE IF EXISTS debt_purchases       CASCADE;
DROP TABLE IF EXISTS transaction_splits   CASCADE;
DROP TABLE IF EXISTS transactions         CASCADE;
DROP TABLE IF EXISTS group_share_rules    CASCADE;
DROP TABLE IF EXISTS group_members        CASCADE;
DROP TABLE IF EXISTS accounts             CASCADE;
DROP TABLE IF EXISTS periodicities        CASCADE;
DROP TABLE IF EXISTS levels               CASCADE;
DROP TABLE IF EXISTS categories           CASCADE;
DROP TABLE IF EXISTS category_groups      CASCADE;
DROP TABLE IF EXISTS user_groups          CASCADE;
DROP TABLE IF EXISTS banks                CASCADE;
DROP TABLE IF EXISTS credit_cards         CASCADE;
DROP TABLE IF EXISTS msi_purchases       CASCADE;



-- ==================================================================
-- 2) Eliminar tipos ENUM existentes
-- ==================================================================
DROP TYPE  IF EXISTS severity             CASCADE;
DROP TYPE  IF EXISTS icon_library         CASCADE;
DROP TYPE  IF EXISTS periodicity          CASCADE;
DROP TYPE  IF EXISTS goal_type            CASCADE;
DROP TYPE  IF EXISTS transaction_type     CASCADE;
DROP TYPE  IF EXISTS group_role           CASCADE;


-- ==================================================================
-- 3) Crear tipos ENUM
-- ==================================================================
CREATE TYPE transaction_type AS ENUM (
  'expense','income','transfer','debt_payment','credit_payment'
);

CREATE TYPE goal_type AS ENUM (
  'saving','purchase','budget'
);

CREATE TYPE periodicity AS ENUM (
  'daily','weekly','biweekly','monthly',
  'bimonthly','quarterly','yearly','custom'
);

CREATE TYPE icon_library AS ENUM (
  'primevue','material'
);

CREATE TYPE severity AS ENUM (
  'success',    -- ingresos, cobros
  'info',       -- info general
  'warn',       -- advertencias suaves
  'danger',     -- gastos críticos
  'secondary',  -- neutro por defecto
  'contrast'    -- para resaltar
);

CREATE TYPE group_role AS ENUM (
  'member',     -- usuario normal
  'admin'       -- administrador del grupo
);


-- ==================================================================
-- 4) Crear tablas principales
-- ==================================================================

-- 4.1) Grupos de usuarios (familia, pareja, proyecto…)
CREATE TABLE user_groups (
  id            UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  owner_id      UUID        NOT NULL REFERENCES profiles(id),
  name          TEXT        NOT NULL,
  description   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- Trigger: al crear un grupo, asignar al owner como admin en group_members
CREATE OR REPLACE FUNCTION trg_assign_group_owner_admin()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO group_members (
    id, group_id, user_id, share_percent, role, created_at
  ) VALUES (
    gen_random_uuid(),
    NEW.id,
    NEW.owner_id,
    0,            -- porcentaje por defecto; puede definirse luego en reglas
    'admin',      -- el creador siempre es admin
    now()
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_user_group_insert_admin ON user_groups;
CREATE TRIGGER on_user_group_insert_admin
  AFTER INSERT ON user_groups
  FOR EACH ROW
  EXECUTE FUNCTION trg_assign_group_owner_admin();


-- 4.2) Catálogos de grupos de categorías
CREATE TABLE category_groups (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT             NOT NULL,
  description      TEXT,
  is_public        BOOLEAN          NOT NULL DEFAULT FALSE,
  user_id          UUID             REFERENCES profiles(id),
  user_group_id    UUID             REFERENCES user_groups(id),
  color            CHAR(7),         -- '#RRGGBB'
  icon_library     icon_library     NOT NULL DEFAULT 'primevue',
  icon_name        TEXT             NOT NULL,
  created_at       TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT chk_category_groups_owner CHECK (
       (is_public = TRUE  AND user_id       IS NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NOT NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NULL AND user_group_id IS NOT NULL)
  )
);
CREATE INDEX ON category_groups(user_id);
CREATE INDEX ON category_groups(user_group_id);


-- 4.3) Categorías individuales
CREATE TABLE categories (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT             NOT NULL,
  description      TEXT,
  group_id         UUID             NOT NULL REFERENCES category_groups(id),
  is_public        BOOLEAN          NOT NULL DEFAULT FALSE,
  user_id          UUID             REFERENCES profiles(id),
  user_group_id    UUID             REFERENCES user_groups(id),
  icon_library     icon_library     NOT NULL DEFAULT 'primevue',
  icon_name        TEXT             NOT NULL,
  created_at       TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT chk_categories_owner CHECK (
       (is_public = TRUE  AND user_id       IS NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NOT NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NULL AND user_group_id IS NOT NULL)
  )
);
CREATE INDEX ON categories(group_id);
CREATE INDEX ON categories(user_id);
CREATE INDEX ON categories(user_group_id);


-- 4.4) Niveles de gasto/ingreso
CREATE TABLE levels (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  name             TEXT             NOT NULL,
  color            VARCHAR(20),     -- Cambiado de CHAR(7) a VARCHAR(20) para acomodar diferentes formatos
  is_public        BOOLEAN          NOT NULL DEFAULT FALSE,
  user_id          UUID             REFERENCES profiles(id),
  user_group_id    UUID             REFERENCES user_groups(id),
  created_at       TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT chk_levels_owner CHECK (
       (is_public = TRUE  AND user_id       IS NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NOT NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NULL AND user_group_id IS NOT NULL)
  )
);
CREATE INDEX ON levels(user_id);
CREATE INDEX ON levels(user_group_id);

-- Trigger para aplicar TRIM() a la columna 'color' antes de insertar o actualizar
CREATE OR REPLACE FUNCTION trg_levels_trim_color()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.color IS NOT NULL THEN
    NEW.color = TRIM(NEW.color);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS levels_trim_color_trigger ON levels;
CREATE TRIGGER levels_trim_color_trigger
  BEFORE INSERT OR UPDATE ON levels
  FOR EACH ROW
  EXECUTE FUNCTION trg_levels_trim_color();


-- 4.5) Periodicidades para metas y reglas recurrentes
CREATE TABLE periodicities (
  id             UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  code           periodicity      NOT NULL,
  label          TEXT             NOT NULL,
  interval_count INT              NOT NULL DEFAULT 1,
  created_at     TIMESTAMPTZ      NOT NULL DEFAULT now()
);


-- 4.6) Cuentas (efectivo, tarjeta, ahorro…)
CREATE TABLE accounts (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  created_by       UUID             NOT NULL REFERENCES profiles(id),
  user_group_id    UUID             REFERENCES user_groups(id),
  name             TEXT             NOT NULL,
  type             TEXT             NOT NULL,  -- e.g. 'cash','bank','credit_card'
  metadata         JSONB,                       -- { last4:"1234",bank:"..." }
  balance          NUMERIC(14,2)    NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ      NOT NULL DEFAULT now()
);
CREATE INDEX ON accounts(created_by);
CREATE INDEX ON accounts(user_group_id);


-- 4.7) Miembros de grupo y porcentaje de participación
CREATE TABLE group_members (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id        UUID             NOT NULL REFERENCES user_groups(id),
  user_id         UUID             NOT NULL REFERENCES profiles(id),
  share_percent   NUMERIC(5,2)     NOT NULL DEFAULT 0,     -- ej. 25.00%
  role            group_role       NOT NULL DEFAULT 'member',
  created_at      TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT unq_group_user UNIQUE(group_id,user_id)
);
CREATE INDEX ON group_members(group_id);
CREATE INDEX ON group_members(user_id);


-- 4.8) Reglas de reparto por tipo de recurso (deuda, ahorro, gasto…)
CREATE TABLE group_share_rules (
  id             UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id       UUID           NOT NULL REFERENCES user_groups(id),
  resource_type  TEXT           NOT NULL,  -- p.ej. 'debt','saving','expense'
  user_id        UUID           NOT NULL REFERENCES profiles(id),
  share_percent  NUMERIC(5,2)   NOT NULL,
  created_at     TIMESTAMPTZ    NOT NULL DEFAULT now(),
  CONSTRAINT unq_grp_res_user UNIQUE(group_id, resource_type, user_id)
);
CREATE INDEX ON group_share_rules(group_id, resource_type);


-- 4.9) Transacciones
CREATE TABLE transactions (
  id               UUID              DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID              NOT NULL REFERENCES profiles(id),
  account_id       UUID              NOT NULL REFERENCES accounts(id),
  category_id      UUID              NOT NULL REFERENCES categories(id),
  level_id         UUID              REFERENCES levels(id),
  type             transaction_type  NOT NULL,
  severity         severity          NOT NULL DEFAULT 'secondary',
  amount           NUMERIC(14,2)     NOT NULL,
  occurred_at      DATE              NOT NULL,
  description      TEXT,
  receipt_url      TEXT,
  metadata         JSONB,             -- { debt_id, installment_id, … }
  created_at       TIMESTAMPTZ        NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ        NOT NULL DEFAULT now()
);
CREATE INDEX ON transactions(user_id, occurred_at);
CREATE INDEX ON transactions(account_id);
CREATE INDEX ON transactions(category_id);
CREATE INDEX ON transactions(severity);


-- 4.10) Divisiones de transacciones grupales
CREATE TABLE transaction_splits (
  id              UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id  UUID             NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  user_id         UUID             NOT NULL REFERENCES profiles(id),
  share_percent   NUMERIC(5,2)     NOT NULL,
  amount          NUMERIC(14,2)    NOT NULL,
  created_at      TIMESTAMPTZ      NOT NULL DEFAULT now()
);
CREATE INDEX ON transaction_splits(transaction_id);


-- 4.11) Compras a plazos / MSI
CREATE TABLE debt_purchases (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID             NOT NULL REFERENCES profiles(id),
  account_id       UUID             NOT NULL REFERENCES accounts(id),
  description      TEXT,
  total_amount     NUMERIC(14,2)    NOT NULL,
  months           INT              NOT NULL,
  start_date       DATE             NOT NULL,
  created_at       TIMESTAMPTZ      NOT NULL DEFAULT now()
);


-- 4.12) Cuotas de cada compra a plazos
CREATE TABLE debt_installments (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  purchase_id       UUID             NOT NULL REFERENCES debt_purchases(id) ON DELETE CASCADE,
  installment_no    INT              NOT NULL,
  due_date          DATE             NOT NULL,
  amount            NUMERIC(14,2)    NOT NULL,
  paid              BOOLEAN          NOT NULL DEFAULT FALSE,
  paid_at           TIMESTAMPTZ,
  transaction_id    UUID             REFERENCES transactions(id),
  created_at        TIMESTAMPTZ      NOT NULL DEFAULT now(),
  CONSTRAINT unq_purchase_installment UNIQUE(purchase_id,installment_no)
);


-- 4.13) Reglas de transacciones recurrentes
CREATE TABLE recurring_rules (
  id               UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID             NOT NULL REFERENCES profiles(id),
  name             TEXT             NOT NULL,
  type             transaction_type NOT NULL,
  account_id       UUID             NOT NULL REFERENCES accounts(id),
  category_id      UUID             NOT NULL REFERENCES categories(id),
  level_id         UUID             REFERENCES levels(id),
  amount           NUMERIC(14,2)    NOT NULL,
  periodicity_id   UUID             NOT NULL REFERENCES periodicities(id),
  start_date       DATE             NOT NULL,
  end_date         DATE,
  next_run         DATE,
  metadata         JSONB,
  active           BOOLEAN          NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ       NOT NULL DEFAULT now()
);
CREATE INDEX ON recurring_rules(next_run);


-- 4.14) Metas de ahorro/compra/presupuesto
CREATE TABLE goals (
  id                UUID           DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id           UUID           NOT NULL REFERENCES profiles(id),
  user_group_id     UUID           REFERENCES user_groups(id),
  type              goal_type      NOT NULL,
  title             TEXT           NOT NULL,
  target_amount     NUMERIC(14,2)  NOT NULL,
  current_amount    NUMERIC(14,2)  NOT NULL DEFAULT 0,
  start_date        DATE           NOT NULL,
  end_date          DATE,
  periodicity_id    UUID           REFERENCES periodicities(id),
  period_amount     NUMERIC(14,2),
  category_id       UUID           REFERENCES categories(id),
  status            TEXT           NOT NULL DEFAULT 'pending',
  created_at        TIMESTAMPTZ    NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX ON goals(user_id);
CREATE INDEX ON goals(user_group_id);


-- 4.15) Notificaciones y bitácora de eventos
CREATE TABLE notifications (
  id               UUID           DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID           NOT NULL REFERENCES profiles(id),
  user_group_id    UUID           REFERENCES user_groups(id),
  type             TEXT           NOT NULL,
  related_id       UUID,
  title            TEXT           NOT NULL,
  message          TEXT           NOT NULL,
  metadata         JSONB,
  is_read          BOOLEAN        NOT NULL DEFAULT FALSE,
  created_at       TIMESTAMPTZ    NOT NULL DEFAULT now()
);
CREATE INDEX ON notifications(user_id,is_read);
CREATE INDEX ON notifications(user_group_id);


-- 4.16) Catálogo de bancos (banks)
CREATE TABLE banks (
  id              UUID            DEFAULT gen_random_uuid() PRIMARY KEY,
  name            TEXT            NOT NULL,
  is_public       BOOLEAN         NOT NULL DEFAULT FALSE,
  user_id         UUID            REFERENCES profiles(id),
  user_group_id   UUID            REFERENCES user_groups(id),
  color           CHAR(7),         -- '#RRGGBB'
  icon_library    icon_library    NOT NULL DEFAULT 'primevue',
  icon_name       TEXT            NOT NULL,
  logo_path       TEXT,            -- ruta en Supabase Storage
  created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
  CONSTRAINT chk_banks_owner CHECK (
       (is_public = TRUE  AND user_id       IS NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NOT NULL AND user_group_id IS NULL)
    OR (is_public = FALSE AND user_id       IS NULL AND user_group_id IS NOT NULL)
  )
);
CREATE INDEX ON banks(user_id);
CREATE INDEX ON banks(user_group_id);
CREATE INDEX ON banks(is_public);


-- 4.17) Extensión para tarjetas de crédito (CAMPOS OPCIONALES)
CREATE TABLE credit_cards (
  account_id              UUID             PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
  bank_id                 UUID             REFERENCES banks(id),
  card_name               TEXT             NOT NULL,
  last_four_digits        CHAR(4),
  credit_limit            NUMERIC(14,2)    NOT NULL,
  available_credit        NUMERIC(14,2)    NOT NULL,
  payment_day             INT              NOT NULL, -- Día del mes para pago
  cutoff_day              INT              NOT NULL, -- Día de corte
  interest_rate           NUMERIC(5,2),    -- Tasa de interés anual
  min_payment_percent     NUMERIC(5,2),    -- Porcentaje para pago mínimo
  next_payment_date       DATE,            -- Próxima fecha de pago
  next_cutoff_date        DATE,            -- Próxima fecha de corte
  
  -- 🆕 CAMPOS OPCIONALES PARA INFORMACIÓN FINANCIERA AVANZADA
  cat_percentage          NUMERIC(5,2),    -- CAT (Costo Anual Total) - OPCIONAL
  annual_fee              NUMERIC(10,2)    DEFAULT 0, -- Anualidad - OPCIONAL (default 0)
  annual_fee_waiver_spending NUMERIC(12,2), -- Gasto para exentar anualidad - OPCIONAL
  cashback_percentage     NUMERIC(4,2),    -- Porcentaje de cashback - OPCIONAL
  rewards_points_ratio    NUMERIC(6,2),    -- Puntos por peso gastado - OPCIONAL
  grace_period_days       INTEGER,         -- Días de gracia sin intereses - OPCIONAL
  
  -- 🆕 CAMPO LIBRE PARA INFORMACIÓN ADICIONAL
  notes                   TEXT,            -- Campo libre para CAT, beneficios, etc. - OPCIONAL
  
  created_at              TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at              TIMESTAMPTZ      NOT NULL DEFAULT now(),
  
  -- ✅ CONSTRAINTS PARA VALIDACIÓN
  CONSTRAINT chk_cat_percentage CHECK (cat_percentage IS NULL OR (cat_percentage >= 0 AND cat_percentage <= 500)),
  CONSTRAINT chk_annual_fee CHECK (annual_fee >= 0),
  CONSTRAINT chk_cashback_percentage CHECK (cashback_percentage IS NULL OR (cashback_percentage >= 0 AND cashback_percentage <= 20)),
  CONSTRAINT chk_rewards_points_ratio CHECK (rewards_points_ratio IS NULL OR (rewards_points_ratio >= 0 AND rewards_points_ratio <= 100)),
  CONSTRAINT chk_grace_period_days CHECK (grace_period_days IS NULL OR (grace_period_days >= 0 AND grace_period_days <= 60))
);

-- Índices para campos que se consultarán frecuentemente
CREATE INDEX ON credit_cards(bank_id);
CREATE INDEX ON credit_cards(cat_percentage) WHERE cat_percentage IS NOT NULL;
CREATE INDEX ON credit_cards(annual_fee) WHERE annual_fee > 0;

-- Comentarios para documentar el propósito de cada campo opcional
COMMENT ON COLUMN credit_cards.cat_percentage IS 'Costo Anual Total (CAT) en porcentaje - Campo opcional para análisis financiero avanzado';
COMMENT ON COLUMN credit_cards.annual_fee IS 'Anualidad en pesos mexicanos - Por defecto 0 (sin anualidad)';
COMMENT ON COLUMN credit_cards.annual_fee_waiver_spending IS 'Monto de compras anuales requerido para exentar la anualidad - Campo opcional';
COMMENT ON COLUMN credit_cards.cashback_percentage IS 'Porcentaje de cashback otorgado - Campo opcional para tarjetas con beneficios';
COMMENT ON COLUMN credit_cards.rewards_points_ratio IS 'Puntos otorgados por cada peso gastado - Campo opcional para programas de recompensas';
COMMENT ON COLUMN credit_cards.grace_period_days IS 'Días de gracia sin intereses después del corte - Campo opcional, típicamente 20-25 días';
COMMENT ON COLUMN credit_cards.notes IS 'Campo libre para información adicional como promociones, beneficios especiales, etc.';


-- 4.18) Extensión para MSI (Meses Sin Intereses)
CREATE TABLE msi_purchases (
  id                UUID             DEFAULT gen_random_uuid() PRIMARY KEY,
  debt_purchase_id  UUID             REFERENCES debt_purchases(id) ON DELETE CASCADE,
  card_account_id   UUID             NOT NULL REFERENCES credit_cards(account_id),
  total_installments INT             NOT NULL, -- Número total de MSI (12, 18, 24, etc.)
  paid_installments INT              NOT NULL DEFAULT 0, -- Pagos ya realizados
  installment_amount NUMERIC(14,2)   NOT NULL, -- Monto mensual a pagar
  remaining_amount  NUMERIC(14,2)    NOT NULL, -- Monto restante por pagar
  promotion_end_date DATE,           -- Fecha en que termina la promoción sin intereses
  interest_rate_after NUMERIC(5,2),  -- Tasa aplicable después de la promoción
  created_at        TIMESTAMPTZ      NOT NULL DEFAULT now(),
  updated_at        TIMESTAMPTZ      NOT NULL DEFAULT now()
);
CREATE INDEX ON msi_purchases(card_account_id);


-- 5) Funcion
-- Solo se ejecuta una vez por query
CREATE OR REPLACE FUNCTION public.session_user_id()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT auth.uid();
$$;
