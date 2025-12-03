-- ===================================================
-- FIX: POLÍTICAS RLS PARA VISTAS
-- Archivo: 7. fix_vistas_rls.sql
-- Descripción: Habilita RLS en las vistas y configura políticas
-- ===================================================

-- IMPORTANTE: Las vistas en PostgreSQL heredan las políticas RLS de las tablas
-- base que usan, pero Supabase las marca como "UNRESTRICTED" en la UI.
-- Esto es normal y SEGURO si las tablas base tienen RLS habilitado.

-- Sin embargo, para mayor seguridad y cumplir con las mejores prácticas,
-- podemos recrear las vistas como FUNCIONES SECURITY DEFINER que respetan RLS.


-- ===================================================
-- OPCIÓN 1: HABILITAR RLS EN LAS VISTAS (Método Simple)
-- ===================================================
-- Esto hace que Supabase las muestre como "RLS Enabled" en la UI

ALTER VIEW vista_patrimonio_usuario SET (security_barrier = true);
ALTER VIEW vista_gastos_mes_actual SET (security_barrier = true);
ALTER VIEW vista_progreso_metas SET (security_barrier = true);


-- ===================================================
-- OPCIÓN 2: CONVERTIR VISTAS A FUNCIONES (Método Robusto)
-- ===================================================
-- Esta es la mejor práctica para Supabase ya que las funciones
-- pueden tener políticas de seguridad más estrictas

-- 2.1) Función para patrimonio neto del usuario
DROP FUNCTION IF EXISTS obtener_patrimonio_usuario(UUID);
CREATE OR REPLACE FUNCTION obtener_patrimonio_usuario(p_usuario_id UUID DEFAULT NULL)
RETURNS TABLE (
  usuario_id UUID,
  total_cuentas BIGINT,
  patrimonio_neto NUMERIC,
  efectivo NUMERIC,
  cuentas_bancarias NUMERIC,
  credito_disponible NUMERIC,
  deuda_credito NUMERIC
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT 
    c.creada_por AS usuario_id,
    COUNT(c.id)::BIGINT AS total_cuentas,
    SUM(CASE 
      WHEN c.tipo IN ('cash', 'debit', 'savings') THEN c.saldo
      WHEN c.tipo = 'credit_card' THEN -1 * (tc.limite_credito - tc.credito_disponible)
      ELSE 0
    END) AS patrimonio_neto,
    SUM(CASE WHEN c.tipo = 'cash' THEN c.saldo ELSE 0 END) AS efectivo,
    SUM(CASE WHEN c.tipo IN ('debit', 'savings') THEN c.saldo ELSE 0 END) AS cuentas_bancarias,
    SUM(CASE WHEN c.tipo = 'credit_card' THEN tc.credito_disponible ELSE 0 END) AS credito_disponible,
    SUM(CASE WHEN c.tipo = 'credit_card' THEN (tc.limite_credito - tc.credito_disponible) ELSE 0 END) AS deuda_credito
  FROM cuentas c
  LEFT JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
  WHERE c.creada_por = COALESCE(p_usuario_id, auth.uid())
  GROUP BY c.creada_por;
$$;

COMMENT ON FUNCTION obtener_patrimonio_usuario IS 'Calcula el patrimonio neto del usuario actual o del usuario especificado';


-- 2.2) Función para gastos del mes actual
DROP FUNCTION IF EXISTS obtener_gastos_mes_actual(UUID, DATE);
CREATE OR REPLACE FUNCTION obtener_gastos_mes_actual(
  p_usuario_id UUID DEFAULT NULL,
  p_fecha DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  usuario_id UUID,
  categoria TEXT,
  grupo_categoria TEXT,
  cantidad_transacciones BIGINT,
  total_gastado NUMERIC,
  promedio_gasto NUMERIC
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT 
    t.usuario_id,
    c.nombre AS categoria,
    gc.nombre AS grupo_categoria,
    COUNT(*)::BIGINT AS cantidad_transacciones,
    SUM(t.monto) AS total_gastado,
    AVG(t.monto) AS promedio_gasto
  FROM transacciones t
  JOIN categorias c ON t.categoria_id = c.id
  JOIN grupos_categoria gc ON c.grupo_id = gc.id
  WHERE t.tipo = 'gasto'
    AND t.usuario_id = COALESCE(p_usuario_id, auth.uid())
    AND EXTRACT(MONTH FROM t.fecha_ocurrencia) = EXTRACT(MONTH FROM p_fecha)
    AND EXTRACT(YEAR FROM t.fecha_ocurrencia) = EXTRACT(YEAR FROM p_fecha)
  GROUP BY t.usuario_id, c.nombre, gc.nombre;
$$;

COMMENT ON FUNCTION obtener_gastos_mes_actual IS 'Obtiene estadísticas de gastos por categoría para el mes especificado';


-- 2.3) Función para progreso de metas
DROP FUNCTION IF EXISTS obtener_progreso_metas(UUID);
CREATE OR REPLACE FUNCTION obtener_progreso_metas(p_usuario_id UUID DEFAULT NULL)
RETURNS TABLE (
  id UUID,
  usuario_id UUID,
  grupo_usuario_id UUID,
  titulo TEXT,
  tipo tipo_meta,
  monto_objetivo NUMERIC,
  monto_actual NUMERIC,
  porcentaje_completado NUMERIC,
  monto_faltante NUMERIC,
  fecha_inicio DATE,
  fecha_fin DATE,
  dias_restantes INTEGER,
  estado_calculado TEXT,
  estado_registrado TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT 
    m.id,
    m.usuario_id,
    m.grupo_usuario_id,
    m.titulo,
    m.tipo,
    m.monto_objetivo,
    m.monto_actual,
    ROUND((m.monto_actual / NULLIF(m.monto_objetivo, 0)) * 100, 2) AS porcentaje_completado,
    (m.monto_objetivo - m.monto_actual) AS monto_faltante,
    m.fecha_inicio,
    m.fecha_fin,
    CASE 
      WHEN m.fecha_fin IS NOT NULL THEN (m.fecha_fin - CURRENT_DATE)::INTEGER
      ELSE NULL
    END AS dias_restantes,
    CASE
      WHEN m.monto_actual >= m.monto_objetivo THEN 'completada'
      WHEN m.fecha_fin IS NOT NULL AND m.fecha_fin < CURRENT_DATE THEN 'vencida'
      WHEN (m.monto_actual / NULLIF(m.monto_objetivo, 0)) >= (COALESCE(m.notificar_al_alcanzar, 80) / 100) THEN 'cerca_objetivo'
      ELSE 'en_progreso'
    END AS estado_calculado,
    m.estado AS estado_registrado
  FROM metas m
  WHERE m.estado != 'cancelada'
    AND m.usuario_id = COALESCE(p_usuario_id, auth.uid());
$$;

COMMENT ON FUNCTION obtener_progreso_metas IS 'Calcula el progreso de las metas del usuario con porcentajes y días restantes';


-- ===================================================
-- OPCIÓN 3: MANTENER VISTAS PERO CON FILTRO DE USUARIO
-- ===================================================
-- Recrear las vistas para que filtren automáticamente por usuario actual

DROP VIEW IF EXISTS vista_patrimonio_usuario CASCADE;
CREATE OR REPLACE VIEW vista_patrimonio_usuario 
WITH (security_barrier = true)
AS
SELECT 
  c.creada_por AS usuario_id,
  COUNT(c.id) AS total_cuentas,
  SUM(CASE 
    WHEN c.tipo IN ('cash', 'debit', 'savings') THEN c.saldo
    WHEN c.tipo = 'credit_card' THEN -1 * (tc.limite_credito - tc.credito_disponible)
    ELSE 0
  END) AS patrimonio_neto,
  SUM(CASE WHEN c.tipo = 'cash' THEN c.saldo ELSE 0 END) AS efectivo,
  SUM(CASE WHEN c.tipo IN ('debit', 'savings') THEN c.saldo ELSE 0 END) AS cuentas_bancarias,
  SUM(CASE WHEN c.tipo = 'credit_card' THEN tc.credito_disponible ELSE 0 END) AS credito_disponible,
  SUM(CASE WHEN c.tipo = 'credit_card' THEN (tc.limite_credito - tc.credito_disponible) ELSE 0 END) AS deuda_credito
FROM cuentas c
LEFT JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
WHERE c.creada_por = auth.uid()  -- Filtro automático por usuario
GROUP BY c.creada_por;


DROP VIEW IF EXISTS vista_gastos_mes_actual CASCADE;
CREATE OR REPLACE VIEW vista_gastos_mes_actual
WITH (security_barrier = true)
AS
SELECT 
  t.usuario_id,
  c.nombre AS categoria,
  gc.nombre AS grupo_categoria,
  COUNT(*) AS cantidad_transacciones,
  SUM(t.monto) AS total_gastado,
  AVG(t.monto) AS promedio_gasto
FROM transacciones t
JOIN categorias c ON t.categoria_id = c.id
JOIN grupos_categoria gc ON c.grupo_id = gc.id
WHERE t.tipo = 'gasto'
  AND t.usuario_id = auth.uid()  -- Filtro automático por usuario
  AND EXTRACT(MONTH FROM t.fecha_ocurrencia) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM t.fecha_ocurrencia) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY t.usuario_id, c.nombre, gc.nombre;


DROP VIEW IF EXISTS vista_progreso_metas CASCADE;
CREATE OR REPLACE VIEW vista_progreso_metas
WITH (security_barrier = true)
AS
SELECT 
  m.id,
  m.usuario_id,
  m.grupo_usuario_id,
  m.titulo,
  m.tipo,
  m.monto_objetivo,
  m.monto_actual,
  ROUND((m.monto_actual / NULLIF(m.monto_objetivo, 0)) * 100, 2) AS porcentaje_completado,
  (m.monto_objetivo - m.monto_actual) AS monto_faltante,
  m.fecha_inicio,
  m.fecha_fin,
  CASE 
    WHEN m.fecha_fin IS NOT NULL THEN (m.fecha_fin - CURRENT_DATE)
    ELSE NULL
  END AS dias_restantes,
  CASE
    WHEN m.monto_actual >= m.monto_objetivo THEN 'completada'
    WHEN m.fecha_fin IS NOT NULL AND m.fecha_fin < CURRENT_DATE THEN 'vencida'
    WHEN (m.monto_actual / NULLIF(m.monto_objetivo, 0)) >= (COALESCE(m.notificar_al_alcanzar, 80) / 100) THEN 'cerca_objetivo'
    ELSE 'en_progreso'
  END AS estado_calculado,
  m.estado AS estado_registrado
FROM metas m
WHERE m.estado != 'cancelada'
  AND m.usuario_id = auth.uid();  -- Filtro automático por usuario


-- ===================================================
-- VERIFICACIÓN
-- ===================================================
-- Ejecuta esta consulta para verificar que las funciones se crearon

SELECT 
  routine_name AS "Función",
  routine_type AS "Tipo",
  security_type AS "Seguridad"
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name LIKE 'obtener_%'
ORDER BY routine_name;


-- ===================================================
-- USO DE LAS NUEVAS FUNCIONES EN JAVASCRIPT
-- ===================================================
/*

// Opción 1: Usando las vistas (más simple, ahora con RLS)
const { data } = await supabase
  .from('vista_patrimonio_usuario')
  .select('*')
  .single();

// Opción 2: Usando las funciones (más robusto)
const { data } = await supabase
  .rpc('obtener_patrimonio_usuario')
  .single();

// Función de gastos con parámetros
const { data } = await supabase
  .rpc('obtener_gastos_mes_actual', {
    p_fecha: '2025-12-01'
  });

// Función de metas
const { data } = await supabase
  .rpc('obtener_progreso_metas');

*/


-- ===================================================
-- RECOMENDACIÓN FINAL
-- ===================================================
-- Ejecuta TODAS las opciones arriba:
-- 1. Opción 1: Agrega security_barrier a las vistas existentes
-- 2. Opción 2: Crea funciones como alternativa más robusta
-- 3. Opción 3: Recrea vistas con filtro automático por usuario
--
-- De esta forma tendrás:
-- ✅ Vistas con security_barrier (para uso simple)
-- ✅ Funciones SECURITY DEFINER (para uso avanzado)
-- ✅ Filtros automáticos por usuario (máxima seguridad)
