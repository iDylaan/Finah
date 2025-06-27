-- 5.1) Periodicidades
INSERT INTO periodicities (code, label, interval_count)
VALUES
  ('daily',      'Diaria',       1),
  ('weekly',     'Semanal',      1),
  ('biweekly',   'Quincenal',    2),
  ('monthly',    'Mensual',      1),
  ('bimonthly',  'Bimestral',    2),
  ('quarterly',  'Trimestral',   3),
  ('yearly',     'Anual',        1),
  ('custom',     'Personalizada',1);


-- 5.2) Niveles de gasto/ingreso
INSERT INTO levels (name, color, is_public)
VALUES
  ('No negociable', 'red', TRUE),
  ('Necesario',     'blue', TRUE),
  ('Deseo',         'cyam', TRUE),
  ('Lujo',          'oramge', TRUE);

-- 5.3) Grupos de categorías
INSERT INTO category_groups (name, is_public, color, icon_library, icon_name)
VALUES
  ('Hogar',           TRUE, '#3F51B5','material','home'),
  ('Transporte',      TRUE, '#009688','material','directions_car'),
  ('Alimentación',    TRUE, '#FF5722','material','restaurant'),
  ('Salud',           TRUE, '#4CAF50','material','local_hospital'),
  ('Educación',       TRUE, '#673AB7','material','school'),
  ('Entretenimiento', TRUE, '#E91E63','material','movie'),
  ('Servicios',       TRUE, '#795548','material','build');


-- 5.4) Categorías por grupo
INSERT INTO categories (name, group_id, is_public, icon_library, icon_name)
VALUES
  -- Hogar
  ('Renta',        (SELECT id FROM category_groups WHERE name='Hogar'), TRUE,'material','meeting_room'),
  ('Luz',          (SELECT id FROM category_groups WHERE name='Hogar'), TRUE,'material','wb_sunny'),
  ('Agua',         (SELECT id FROM category_groups WHERE name='Hogar'), TRUE,'material','water_damage'),
  ('Gas',          (SELECT id FROM category_groups WHERE name='Hogar'), TRUE,'material','local_gas_station'),

  -- Transporte
  ('Gasolina',     (SELECT id FROM category_groups WHERE name='Transporte'), TRUE,'material','local_gas_station'),
  ('Transp. público',(SELECT id FROM category_groups WHERE name='Transporte'),TRUE,'material','commute'),
  ('Mantenimiento',(SELECT id FROM category_groups WHERE name='Transporte'), TRUE,'material','build'),

  -- Alimentación
  ('Supermercado', (SELECT id FROM category_groups WHERE name='Alimentación'), TRUE,'material','local_grocery_store'),
  ('Restaurantes', (SELECT id FROM category_groups WHERE name='Alimentación'), TRUE,'material','restaurant_menu'),

  -- Salud
  ('Farmacia',     (SELECT id FROM category_groups WHERE name='Salud'), TRUE,'material','local_pharmacy'),
  ('Clínica',      (SELECT id FROM category_groups WHERE name='Salud'), TRUE,'material','healing'),

  -- Educación
  ('Colegiaturas', (SELECT id FROM category_groups WHERE name='Educación'), TRUE,'material','school'),
  ('Libros',       (SELECT id FROM category_groups WHERE name='Educación'), TRUE,'material','book'),

  -- Entretenimiento
  ('Cine',         (SELECT id FROM category_groups WHERE name='Entretenimiento'), TRUE,'material','movie'),
  ('Conciertos',   (SELECT id FROM category_groups WHERE name='Entretenimiento'), TRUE,'material','music_note'),

  -- Servicios
  ('Internet',     (SELECT id FROM category_groups WHERE name='Servicios'), TRUE,'material','wifi'),
  ('Teléfono',     (SELECT id FROM category_groups WHERE name='Servicios'), TRUE,'material','phone'),
  ('Suscripciones',(SELECT id FROM category_groups WHERE name='Servicios'), TRUE,'material','subscriptions');


-- 5.5) Bancos más usados en México
INSERT INTO banks (name, is_public, color, icon_library, icon_name)
VALUES
  ('BBVA',         TRUE, '#002366','material','account_balance'),
  ('Banorte',      TRUE, '#EE3124','material','account_balance'),
  ('Santander',    TRUE, '#E2231A','material','account_balance'),
  ('Citibanamex',  TRUE, '#0066B1','material','account_balance'),
  ('HSBC',         TRUE, '#DB0011','material','account_balance'),
  ('Scotiabank',   TRUE, '#CC0000','material','account_balance'),
  ('Inbursa',      TRUE, '#006ABC','material','account_balance'),
  ('BanCoppel',    TRUE, '#FFD700','material','account_balance'),
  ('Banco Azteca', TRUE, '#D71921','material','account_balance');