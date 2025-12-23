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
INSERT INTO niveles (nombre, color, es_publico, jerarquia)
VALUES
  ('Necesario', 'green',    TRUE, 1),
  ('Lujo',     'orange',   TRUE, 2),
  ('Ahorro',         'cyan',   TRUE, 3),
  ('Otro',         'grey',   TRUE, 4);

-- ===================================================
-- 3) Grupos de categorías - Organizadores principales
-- ===================================================
INSERT INTO grupos_categoria (nombre, tipo, es_publico, color, biblioteca_iconos, nombre_icono)
VALUES
  -- GRUPOS DE GASTO --
  ('Hogar',           'gasto',   TRUE, '#3F51B5', 'material', 'home'),
  ('Transporte',      'gasto',   TRUE, '#009688', 'material', 'directions_car'),
  ('Alimentación',    'gasto',   TRUE, '#FF5722', 'material', 'restaurant'),
  ('Salud',           'gasto',   TRUE, '#4CAF50', 'material', 'local_hospital'),
  ('Educación',       'gasto',   TRUE, '#673AB7', 'material', 'school'),
  ('Entretenimiento', 'gasto',   TRUE, '#E91E63', 'material', 'movie'),
  ('Servicios',       'gasto',   TRUE, '#795548', 'material', 'build'),
  
  -- GRUPOS DE INGRESO --
  ('Ahorros',         'ingreso',   TRUE, '#2196F3', 'material', 'savings'),
  ('Ingresos',        'ingreso', TRUE, '#4CAF50', 'material', 'attach_money'),
  
  -- GRUPOS DE GASTO (OTROS) --
  ('Otros gastos',    'gasto',   TRUE, '#757575', 'material', 'more_horiz'),
  
  -- GRUPOS DE INGRESO (OTROS) --
  ('Otros ingresos',  'ingreso', TRUE, '#9E9E9E', 'material', 'more_horiz'),
  
  -- GRUPOS ESPECIALES (TRANSFERENCIAS) --
  ('Transferencias',  'transferencia', TRUE, '#607D8B', 'material', 'swap_horiz');

-- ===================================================
-- 4) Categorías específicas por grupo
-- ===================================================
INSERT INTO categorias (nombre, tipo, grupo_id, es_publico, biblioteca_iconos, nombre_icono)
VALUES
  -- CATEGORÍAS DE GASTO --
  
  -- Hogar (gastos)
  ('Hogar',           'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'home'),
  ('Renta',           'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'meeting_room'),
  ('Luz',             'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'wb_sunny'),
  ('Agua',            'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'water_damage'),
  ('Gas',             'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'local_gas_station'),
  ('Internet',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'wifi'),
  ('Telefono',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'phone'),
  ('Mantenimiento',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Hogar'), TRUE, 'material', 'home_repair_service'),

  -- Transporte (gastos)
  ('Transporte',       'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'directions_car'),
  ('Gasolina',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'local_gas_station'),
  ('Transporte publico', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'commute'),
  ('Mantenimiento vehiculo', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'build'),
  ('Estacionamiento', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'local_parking'),
  ('Seguro vehiculo', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Transporte'), TRUE, 'material', 'security'),

  -- Alimentación (gastos)
  ('Alimentación',    'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'local_grocery_store'),
  ('Supermercado',    'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'local_grocery_store'),
  ('Restaurantes',    'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'restaurant_menu'),
  ('Comida rapida',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'fastfood'),
  ('Bebidas',         'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'local_bar'),
  ('Comida diaria',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Alimentación'), TRUE, 'material', 'cookie'),

  -- Salud (gastos)
  ('Salud',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'local_hospital'),
  ('Farmacia',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'local_pharmacy'),
  ('Clinica',         'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'healing'),
  ('Dentista',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'medical_services'),
  ('Seguro medico',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'health_and_safety'),
  ('Examenes',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'biotech'),
  ('Cita médica',     'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Salud'), TRUE, 'material', 'clinical_notes'),

  -- Educación (gastos)
  ('Educación',    'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Educación'), TRUE, 'material', 'school'),
  ('Colegiaturas',    'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Educación'), TRUE, 'material', 'school'),
  ('Libros',          'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Educación'), TRUE, 'material', 'book'),
  ('Cursos',          'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Educación'), TRUE, 'material', 'psychology'),
  ('Material escolar', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Educación'), TRUE, 'material', 'edit'),

  -- Entretenimiento (gastos)
  ('Entretenimiento', 'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'movie'),
  ('Cine',            'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'movie'),
  ('Conciertos',      'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'music_note'),
  ('Deportes',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'sports_soccer'),
  ('Juegos',          'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'sports_esports'),
  ('Suscripciones',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Entretenimiento'), TRUE, 'material', 'subscriptions'),

  -- Servicios (gastos)
  ('Banca',           'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'account_balance'),
  ('Seguros',         'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'security'),
  ('Profesionales',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'work'),
  ('Gobierno',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'account_balance'),
  ('Impuestos',       'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'receipt_long'),
  ('Asesoria legal',  'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'gavel'),
  ('Contador',        'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Servicios'), TRUE, 'material', 'calculate'),

  -- CATEGORÍAS DE INGRESO --
  
  ('Salario',         'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'work'),
  ('Nomina',          'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'badge'),
  ('Aguinaldo',       'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'celebration'),
  ('Comisiones',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'trending_up'),
  ('Propinas',        'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'volunteer_activism'),
  ('Ventas',          'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'point_of_sale'),
  ('Freelance',       'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'laptop_mac'),
  ('Negocio propio',  'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'storefront'),
  ('Consultoria',     'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'business_center'),
  ('Inversiones',     'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'trending_up'),
  ('Dividendos',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'account_balance_wallet'),
  ('Intereses',       'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'percent'),
  ('Rentas',          'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'home_work'),
  ('Arrendamiento',   'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'real_estate_agent'),
  ('Bonos',           'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'card_giftcard'),
  ('Prima vacacional','ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'beach_access'),
  ('Utilidades',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'account_balance'),
  ('Reembolsos',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'payments'),
  ('Devoluciones',    'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'keyboard_return'),
  ('Regalos',         'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'redeem'),
  ('Prestamos recibidos', 'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'handshake'),
  ('Herencias',       'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'family_restroom'),
  ('Becas',           'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'school'),
  ('Subsidios',       'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'support'),
  ('Pension',         'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'elderly'),
  ('Ingreso general', 'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'attach_money'),
  ('Otros ingresos',  'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ingresos'), TRUE, 'material', 'more_horiz'),

  -- CATEGORÍAS DE AHORRO (para depositar en cuentas de ahorro - tipo ingreso) --
  
  ('Emergencias',     'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'emergency'),
  ('Vacaciones',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'flight'),
  ('Compras grandes', 'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'shopping_cart'),
  ('Jubilacion',      'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'elderly'),
  ('Ahorro',          'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'savings'),
  ('Fondo de emergencia', 'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Ahorros'), TRUE, 'material', 'e911_emergency'),

  -- CATEGORÍAS ESPECIALES --
  
  -- Otros gastos
  ('Otro gasto',      'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Otros gastos'), TRUE, 'material', 'more_horiz'),
  ('Gasto general',   'gasto', (SELECT id FROM grupos_categoria WHERE nombre='Otros gastos'), TRUE, 'material', 'payments'),
  
  -- Otros ingresos
  ('Otro ingreso',    'ingreso', (SELECT id FROM grupos_categoria WHERE nombre='Otros ingresos'), TRUE, 'material', 'more_horiz'),
  
  -- Transferencias
  ('Transferencia',   'transferencia', (SELECT id FROM grupos_categoria WHERE nombre='Transferencias'), TRUE, 'material', 'swap_horiz'),
  ('Traspaso entre cuentas', 'transferencia', (SELECT id FROM grupos_categoria WHERE nombre='Transferencias'), TRUE, 'material', 'sync_alt');

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
  ('Bradescard',      TRUE, '#C42540', 'material', 'account_balance'),
  ('Banco del Bienestar', TRUE, '#8BC34A', 'material', 'account_balance'),
  ('NU',              TRUE, '#8A05BE', 'material', 'account_balance'),
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
-- GRUPOS DE GASTO:
-- - Hogar: todo relacionado con vivienda y servicios básicos
-- - Transporte: movilidad y vehículos
-- - Alimentación: comida y bebidas
-- - Salud: medicina y bienestar
-- - Educación: formación y desarrollo
-- - Entretenimiento: ocio y diversión
-- - Servicios: financieros, legales, profesionales
-- - Otros gastos: gastos generales no clasificados
-- GRUPOS DE INGRESO:
-- - Ingresos: todas las fuentes de dinero que entra (salarios, ventas, etc.)
-- - Ahorros: diferentes propósitos de ahorro e inversiones
-- - Otros ingresos: ingresos generales no clasificados
-- GRUPOS ESPECIALES:
-- - Transferencias: movimientos entre cuentas propias

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
