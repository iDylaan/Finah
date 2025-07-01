-- ===================================================
-- CARGAS INICIALES PARA BASE DE DATOS FINHEAL
-- Archivo: 3. finah_carga_inicial.sql
-- Descripción: Datos iniciales para catálogos públicos del sistema
-- ===================================================

-- ===================================================
-- 1) Periodicidades - Frecuencias para transacciones recurrentes y metas
-- ===================================================
INSERT INTO periodicidades (codigo, etiqueta, cantidad_intervalo)
VALUES
  ('diario',        'Diaria',           1),
  ('semanal',       'Semanal',          1),
  ('quincenal',     'Quincenal',        2),
  ('mensual',       'Mensual',          1),
  ('bimestral',     'Bimestral',        2),
  ('trimestral',    'Trimestral',       3),
  ('anual',         'Anual',            1),
  ('personalizado', 'Personalizada',    1);

-- ===================================================
-- 2) Niveles de gasto/ingreso - Clasificación por prioridad
-- ===================================================
INSERT INTO niveles (nombre, color, es_publico)
VALUES
  ('No negociable', 'red',    TRUE),
  ('Necesario',     'blue',   TRUE),
  ('Deseo',         'cyan',   TRUE),
  ('Lujo',          'orange', TRUE);

-- ===================================================
-- 3) Grupos de categorías - Organizadores principales
-- ===================================================
INSERT INTO grupos_categoria (nombre, es_publico, color, biblioteca_iconos, nombre_icono)
VALUES
  ('Hogar',           TRUE, '#3F51B5', 'material', 'home'),
  ('Transporte',      TRUE, '#009688', 'material', 'directions_car'),
  ('Alimentacion',    TRUE, '#FF5722', 'material', 'restaurant'),
  ('Salud',           TRUE, '#4CAF50', 'material', 'local_hospital'),
  ('Educacion',       TRUE, '#673AB7', 'material', 'school'),
  ('Entretenimiento', TRUE, '#E91E63', 'material', 'movie'),
  ('Servicios',       TRUE, '#795548', 'material', 'build'),
  ('Ingresos',        TRUE, '#4CAF50', 'material', 'attach_money'),
  ('Ahorros',         TRUE, '#2196F3', 'material', 'savings');

-- ===================================================
-- 4) Categorías específicas por grupo
-- ===================================================
INSERT INTO categorias (nombre, grupo_id, es_publico, biblioteca_iconos, nombre_icono)
VALUES
  -- Hogar
  ('Renta',           (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'meeting_room'),
  ('Luz',             (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'wb_sunny'),
  ('Agua',            (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'water_damage'),
  ('Gas',             (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'local_gas_station'),
  ('Internet',        (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'wifi'),
  ('Telefono',        (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'phone'),
  ('Mantenimiento',   (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'home_repair_service'),

  -- Transporte
  ('Gasolina',        (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'local_gas_station'),
  ('Transporte publico', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'commute'),
  ('Mantenimiento vehiculo', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'build'),
  ('Estacionamiento', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'local_parking'),
  ('Seguro vehiculo', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'security'),

  -- Alimentación
  ('Supermercado',    (SELECT id FROM grupos_categoria WHERE nombre='Alimentacion'), TRUE, 'material', 'local_grocery_store'),
  ('Restaurantes',    (SELECT id FROM grupos_categoria WHERE nombre='Alimentacion'), TRUE, 'material', 'restaurant_menu'),
  ('Comida rapida',   (SELECT id FROM grupos_categoria WHERE nombre='Alimentacion'), TRUE, 'material', 'fastfood'),
  ('Bebidas',         (SELECT id FROM grupos_categoria WHERE nombre='Alimentacion'), TRUE, 'material', 'local_bar'),

  -- Salud
  ('Farmacia',        (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'local_pharmacy'),
  ('Clinica',         (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'healing'),
  ('Dentista',        (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'medical_services'),
  ('Seguro medico',   (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'health_and_safety'),
  ('Examenes',        (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'biotech'),

  -- Educación
  ('Colegiaturas',    (SELECT id FROM grupos_categoria WHERE nombre='Educacion'), TRUE, 'material', 'school'),
  ('Libros',          (SELECT id FROM grupos_categoria WHERE nombre='Educacion'), TRUE, 'material', 'book'),
  ('Cursos',          (SELECT id FROM grupos_categoria WHERE nombre='Educacion'), TRUE, 'material', 'psychology'),
  ('Material escolar', (SELECT id FROM grupos_categoria WHERE nombre='Educacion'), TRUE, 'material', 'edit'),

  -- Entretenimiento
  ('Cine',            (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'movie'),
  ('Conciertos',      (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'music_note'),
  ('Deportes',        (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'sports_soccer'),
  ('Juegos',          (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'sports_esports'),
  ('Suscripciones',   (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'subscriptions'),

  -- Servicios
  ('Banca',           (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'account_balance'),
  ('Seguros',         (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'security'),
  ('Profesionales',   (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'work'),
  ('Gobierno',        (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'account_balance'),

  -- Ingresos
  ('Salario',         (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'work'),
  ('Ventas',          (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'point_of_sale'),
  ('Freelance',       (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'laptop_mac'),
  ('Inversiones',     (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'trending_up'),
  ('Bonos',           (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'card_giftcard'),

  -- Ahorros
  ('Emergencias',     (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'emergency'),
  ('Vacaciones',      (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'flight'),
  ('Compras grandes', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'shopping_cart'),
  ('Jubilacion',      (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'elderly');

-- ===================================================
-- 5) Bancos más utilizados en México
-- ===================================================
INSERT INTO bancos (nombre, es_publico, color, biblioteca_iconos, nombre_icono)
VALUES
  ('BBVA',            TRUE, '#002366', 'material', 'account_balance'),
  ('Banorte',         TRUE, '#EE3124', 'material', 'account_balance'),
  ('Santander',       TRUE, '#E2231A', 'material', 'account_balance'),
  ('Citibanamex',     TRUE, '#0066B1', 'material', 'account_balance'),
  ('HSBC',            TRUE, '#DB0011', 'material', 'account_balance'),
  ('Scotiabank',      TRUE, '#CC0000', 'material', 'account_balance'),
  ('Inbursa',         TRUE, '#006ABC', 'material', 'account_balance'),
  ('BanCoppel',       TRUE, '#FFD700', 'material', 'account_balance'),
  ('Banco Azteca',    TRUE, '#D71921', 'material', 'account_balance'),
  ('Banco del Bienestar', TRUE, '#8BC34A', 'material', 'account_balance'),
  ('Nu',              TRUE, '#8A05BE', 'material', 'account_balance'),
  ('Mercado Pago',    TRUE, '#009EE3', 'material', 'payment'),
  ('Rappi Pay',       TRUE, '#FF441F', 'material', 'payment'),
  ('Clip',            TRUE, '#6B46C1', 'material', 'payment'),
  ('Efectivo',        TRUE, '#4CAF50', 'material', 'payments');

-- ===================================================
-- 6) Comentarios explicativos sobre los datos iniciales
-- ===================================================

-- Los niveles representan la prioridad de gastos según metodología de presupuesto personal:
-- - No negociable: gastos básicos de supervivencia (renta, comida básica, servicios esenciales)
-- - Necesario: gastos importantes pero con cierta flexibilidad (transporte, medicina)
-- - Deseo: gastos que mejoran calidad de vida pero son prescindibles
-- - Lujo: gastos completamente opcionales para indulgencias

-- Las categorías están organizadas por grupos lógicos para facilitar el análisis:
-- - Hogar: todo relacionado con vivienda y servicios básicos
-- - Transporte: movilidad y vehículos
-- - Alimentación: comida y bebidas
-- - Salud: medicina y bienestar
-- - Educación: formación y desarrollo
-- - Entretenimiento: ocio y diversión
-- - Servicios: financieros, legales, profesionales
-- - Ingresos: todas las fuentes de dinero que entra
-- - Ahorros: diferentes propósitos de ahorro

-- Los bancos incluyen tanto instituciones tradicionales como fintech modernas:
-- - Bancos tradicionales: BBVA, Banorte, Santander, etc.
-- - Bancos digitales: Nu (Nubank)
-- - Servicios de pago: Mercado Pago, Rappi Pay, Clip
-- - Efectivo: para transacciones en cash

-- Las periodicidades cubren todos los casos comunes de recurrencia:
-- - Diaria: para gastos muy frecuentes
-- - Semanal: gastos semanales regulares
-- - Quincenal: alineado con ciclos de pago en México
-- - Mensual: la mayoría de gastos fijos
-- - Bimestral, trimestral, anual: gastos menos frecuentes
-- - Personalizada: para intervalos únicos
