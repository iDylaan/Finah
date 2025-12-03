-- ===================================================
-- EJEMPLOS DE USO - NUEVAS FUNCIONALIDADES
-- Este archivo contiene ejemplos prácticos de cómo usar
-- las nuevas funcionalidades agregadas en la migración
-- ===================================================


-- ===================================================
-- 1) SISTEMA DE INVITACIONES A GRUPOS
-- ===================================================

-- 1.1) Crear una invitación a un grupo
INSERT INTO invitaciones_grupo (
  grupo_id,
  email_invitado,
  usuario_invitador,
  rol_propuesto,
  porcentaje_propuesto,
  mensaje_invitacion
) VALUES (
  (SELECT id FROM grupos_usuario WHERE propietario_id = auth.uid() LIMIT 1), -- Tu primer grupo
  'amigo@ejemplo.com',           -- Email del invitado
  auth.uid(),                    -- Tú como invitador
  'miembro',                     -- Rol propuesto
  25.00,                         -- 25% de participación
  '¡Únete a nuestro grupo de gastos compartidos!'
)
RETURNING *;


-- 1.2) Consultar invitaciones pendientes de un grupo
SELECT 
  i.id,
  i.email_invitado,
  i.rol_propuesto,
  i.porcentaje_propuesto,
  i.mensaje_invitacion,
  i.fecha_creacion,
  i.fecha_expiracion,
  p.full_name AS invitador,
  CASE 
    WHEN i.fecha_expiracion < now() THEN '⏰ Expirada'
    WHEN i.estado = 'pendiente' THEN '📤 Pendiente'
    WHEN i.estado = 'aceptada' THEN '✅ Aceptada'
    WHEN i.estado = 'rechazada' THEN '❌ Rechazada'
  END AS estado_visual
FROM invitaciones_grupo i
JOIN profiles p ON i.usuario_invitador = p.id
WHERE i.grupo_id = 'uuid-del-grupo'
ORDER BY i.fecha_creacion DESC;


-- 1.3) Aceptar una invitación (usando la función)
SELECT aceptar_invitacion_grupo(
  'uuid-del-token'::uuid,     -- Token de la invitación
  auth.uid()                  -- Usuario que acepta
);


-- 1.4) Cancelar una invitación
UPDATE invitaciones_grupo
SET estado = 'cancelada',
    fecha_respuesta = now()
WHERE id = 'uuid-invitacion'
  AND usuario_invitador = auth.uid()
  AND estado = 'pendiente';


-- 1.5) Expirar invitaciones vencidas manualmente
SELECT expirar_invitaciones_vencidas();


-- ===================================================
-- 2) HISTORIAL DE SALDOS
-- ===================================================

-- 2.1) Consultar historial de una cuenta (últimos 30 días)
SELECT 
  h.fecha,
  h.saldo_anterior,
  h.saldo_nuevo,
  h.diferencia,
  h.tipo_cambio,
  t.descripcion AS transaccion_relacionada
FROM historial_saldos h
LEFT JOIN transacciones t ON h.transaccion_id = t.id
WHERE h.cuenta_id = 'uuid-cuenta'
  AND h.fecha >= now() - interval '30 days'
ORDER BY h.fecha DESC;


-- 2.2) Evolución del saldo por mes
SELECT 
  DATE_TRUNC('month', fecha) AS mes,
  MIN(saldo_nuevo) AS saldo_minimo,
  MAX(saldo_nuevo) AS saldo_maximo,
  AVG(saldo_nuevo) AS saldo_promedio,
  saldo_nuevo - LAG(saldo_nuevo) OVER (ORDER BY fecha) AS cambio_mensual
FROM historial_saldos
WHERE cuenta_id = 'uuid-cuenta'
  AND fecha >= now() - interval '1 year'
GROUP BY DATE_TRUNC('month', fecha), saldo_nuevo
ORDER BY mes DESC;


-- 2.3) Comparar saldo actual vs hace 30 días
WITH saldo_actual AS (
  SELECT saldo FROM cuentas WHERE id = 'uuid-cuenta'
),
saldo_hace_30 AS (
  SELECT saldo_nuevo 
  FROM historial_saldos 
  WHERE cuenta_id = 'uuid-cuenta'
    AND fecha <= now() - interval '30 days'
  ORDER BY fecha DESC
  LIMIT 1
)
SELECT 
  (SELECT saldo FROM saldo_actual) AS saldo_hoy,
  (SELECT saldo_nuevo FROM saldo_hace_30) AS saldo_hace_30_dias,
  (SELECT saldo FROM saldo_actual) - (SELECT saldo_nuevo FROM saldo_hace_30) AS diferencia;


-- ===================================================
-- 3) DIVISIÓN DE GASTOS GRUPALES
-- ===================================================

-- 3.1) Dividir un gasto entre los miembros de un grupo
-- Primero crea la transacción
INSERT INTO transacciones (
  usuario_id,
  cuenta_id,
  categoria_id,
  tipo,
  monto,
  fecha_ocurrencia,
  descripcion
) VALUES (
  auth.uid(),
  'uuid-cuenta',
  'uuid-categoria-supermercado',
  'gasto',
  1500.00,
  CURRENT_DATE,
  'Compras del supermercado'
)
RETURNING id;

-- Luego divide el gasto (usa el ID que te devolvió arriba)
SELECT dividir_gasto_grupal(
  'uuid-transaccion'::uuid,    -- ID de la transacción
  'uuid-grupo'::uuid           -- ID del grupo
);


-- 3.2) Consultar cómo se dividió un gasto
SELECT 
  dt.usuario_id,
  p.full_name AS nombre_usuario,
  dt.porcentaje_participacion,
  dt.monto,
  t.descripcion AS descripcion_gasto,
  t.fecha_ocurrencia
FROM divisiones_transaccion dt
JOIN profiles p ON dt.usuario_id = p.id
JOIN transacciones t ON dt.transaccion_id = t.id
WHERE dt.transaccion_id = 'uuid-transaccion';


-- 3.3) Resumen de gastos divididos por usuario en un grupo
SELECT 
  p.full_name AS usuario,
  COUNT(DISTINCT dt.transaccion_id) AS total_gastos_compartidos,
  SUM(dt.monto) AS total_aportado,
  AVG(dt.porcentaje_participacion) AS porcentaje_promedio
FROM divisiones_transaccion dt
JOIN profiles p ON dt.usuario_id = p.id
JOIN transacciones t ON dt.transaccion_id = t.id
JOIN cuentas c ON t.cuenta_id = c.id
WHERE c.grupo_usuario_id = 'uuid-grupo'
  AND t.fecha_ocurrencia >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY p.full_name
ORDER BY total_aportado DESC;


-- ===================================================
-- 4) VISTAS PARA ESTADÍSTICAS
-- ===================================================

-- 4.1) Patrimonio neto del usuario actual
SELECT * FROM vista_patrimonio_usuario
WHERE usuario_id = auth.uid();


-- 4.2) Gastos del mes por categoría
SELECT 
  categoria,
  grupo_categoria,
  cantidad_transacciones,
  total_gastado,
  promedio_gasto,
  ROUND((total_gastado / SUM(total_gastado) OVER ()) * 100, 2) AS porcentaje_del_total
FROM vista_gastos_mes_actual
WHERE usuario_id = auth.uid()
ORDER BY total_gastado DESC;


-- 4.3) Progreso de metas activas
SELECT 
  titulo,
  tipo,
  monto_objetivo,
  monto_actual,
  porcentaje_completado,
  monto_faltante,
  dias_restantes,
  estado_calculado,
  CASE 
    WHEN porcentaje_completado >= 100 THEN '🎉 Completada'
    WHEN porcentaje_completado >= 80 THEN '🔥 Casi listo'
    WHEN porcentaje_completado >= 50 THEN '📈 Buen progreso'
    ELSE '🚀 Empezando'
  END AS emoji_progreso
FROM vista_progreso_metas
WHERE usuario_id = auth.uid()
  AND estado_registrado != 'cancelada'
ORDER BY porcentaje_completado DESC;


-- ===================================================
-- 5) METAS MEJORADAS
-- ===================================================

-- 5.1) Crear meta de ahorro con notificación al 80%
INSERT INTO metas (
  usuario_id,
  titulo,
  tipo,
  monto_objetivo,
  monto_actual,
  fecha_inicio,
  fecha_fin,
  notificar_al_alcanzar,
  permitir_exceder,
  icon_library,
  icon_name,
  color
) VALUES (
  auth.uid(),
  'Fondo de Emergencias',
  'ahorro',
  50000.00,
  0,
  CURRENT_DATE,
  CURRENT_DATE + interval '6 months',
  80.00,        -- Notificar al 80%
  false,        -- No permitir exceder
  'material',
  'savings',
  '#4CAF50'
)
RETURNING *;


-- 5.2) Crear presupuesto mensual con límite estricto
INSERT INTO metas (
  usuario_id,
  titulo,
  tipo,
  monto_objetivo,
  categoria_id,
  periodicidad_id,
  fecha_inicio,
  notificar_al_alcanzar,
  permitir_exceder,
  icon_library,
  icon_name,
  color
) VALUES (
  auth.uid(),
  'Presupuesto Supermercado',
  'presupuesto',
  8000.00,
  (SELECT id FROM categorias WHERE nombre = 'Supermercado' LIMIT 1),
  (SELECT id FROM periodicidades WHERE codigo = 'mensual' LIMIT 1),
  DATE_TRUNC('month', CURRENT_DATE),
  90.00,        -- Notificar al 90%
  false,        -- Bloquear al llegar al 100%
  'material',
  'shopping_cart',
  '#FF9800'
)
RETURNING *;


-- 5.3) Actualizar progreso de una meta
UPDATE metas
SET monto_actual = monto_actual + 5000.00,
    fecha_actualizacion = now()
WHERE id = 'uuid-meta'
  AND usuario_id = auth.uid()
RETURNING 
  titulo,
  monto_actual,
  monto_objetivo,
  ROUND((monto_actual / monto_objetivo) * 100, 2) AS porcentaje;


-- 5.4) Verificar si una meta debe notificar
SELECT 
  m.titulo,
  m.monto_actual,
  m.monto_objetivo,
  m.notificar_al_alcanzar,
  ROUND((m.monto_actual / m.monto_objetivo) * 100, 2) AS porcentaje_actual,
  CASE 
    WHEN (m.monto_actual / m.monto_objetivo * 100) >= m.notificar_al_alcanzar 
    THEN '🔔 ¡Debes notificar al usuario!'
    ELSE '⏳ Aún no'
  END AS debe_notificar
FROM metas m
WHERE m.usuario_id = auth.uid()
  AND m.estado != 'completada';


-- ===================================================
-- 6) GRUPOS FINANCIEROS
-- ===================================================

-- 6.1) Crear un grupo familiar
INSERT INTO grupos_usuario (
  propietario_id,
  nombre,
  descripcion
) VALUES (
  auth.uid(),
  'Finanzas Familiares',
  'Gastos compartidos de la familia'
)
RETURNING *;


-- 6.2) Agregar miembro a un grupo
INSERT INTO miembros_grupo (
  grupo_id,
  usuario_id,
  porcentaje_participacion,
  rol
) VALUES (
  'uuid-grupo',
  'uuid-usuario',
  50.00,
  'miembro'
)
RETURNING *;


-- 6.3) Consultar todos los miembros de un grupo
SELECT 
  mg.id,
  p.full_name,
  p.username,
  mg.porcentaje_participacion,
  mg.rol,
  mg.fecha_creacion,
  CASE 
    WHEN mg.rol = 'administrador' THEN '👑 Admin'
    ELSE '👤 Miembro'
  END AS rol_visual
FROM miembros_grupo mg
JOIN profiles p ON mg.usuario_id = p.id
WHERE mg.grupo_id = 'uuid-grupo'
ORDER BY mg.rol DESC, p.full_name;


-- 6.4) Crear cuenta compartida del grupo
INSERT INTO cuentas (
  creada_por,
  grupo_usuario_id,
  nombre,
  tipo,
  saldo
) VALUES (
  auth.uid(),
  'uuid-grupo',
  'Ahorro para vacaciones',
  'savings',
  10000.00
)
RETURNING *;


-- ===================================================
-- 7) ANÁLISIS AVANZADOS
-- ===================================================

-- 7.1) Tendencia de gastos por mes (últimos 6 meses)
SELECT 
  TO_CHAR(t.fecha_ocurrencia, 'YYYY-MM') AS mes,
  COUNT(*) AS cantidad_transacciones,
  SUM(t.monto) AS total_gastado,
  AVG(t.monto) AS promedio_por_transaccion
FROM transacciones t
WHERE t.usuario_id = auth.uid()
  AND t.tipo = 'gasto'
  AND t.fecha_ocurrencia >= CURRENT_DATE - interval '6 months'
GROUP BY TO_CHAR(t.fecha_ocurrencia, 'YYYY-MM')
ORDER BY mes DESC;


-- 7.2) Top 10 categorías con más gastos
SELECT 
  c.nombre AS categoria,
  gc.nombre AS grupo,
  COUNT(*) AS veces_usado,
  SUM(t.monto) AS total_gastado,
  AVG(t.monto) AS promedio
FROM transacciones t
JOIN categorias c ON t.categoria_id = c.id
JOIN grupos_categoria gc ON c.grupo_id = gc.id
WHERE t.usuario_id = auth.uid()
  AND t.tipo = 'gasto'
  AND t.fecha_ocurrencia >= CURRENT_DATE - interval '3 months'
GROUP BY c.nombre, gc.nombre
ORDER BY total_gastado DESC
LIMIT 10;


-- 7.3) Balance de ingresos vs gastos
SELECT 
  DATE_TRUNC('month', fecha_ocurrencia) AS mes,
  SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE 0 END) AS ingresos,
  SUM(CASE WHEN tipo = 'gasto' THEN monto ELSE 0 END) AS gastos,
  SUM(CASE WHEN tipo = 'ingreso' THEN monto ELSE -monto END) AS balance
FROM transacciones
WHERE usuario_id = auth.uid()
  AND tipo IN ('ingreso', 'gasto')
  AND fecha_ocurrencia >= CURRENT_DATE - interval '1 year'
GROUP BY DATE_TRUNC('month', fecha_ocurrencia)
ORDER BY mes DESC;


-- ===================================================
-- NOTAS IMPORTANTES
-- ===================================================
-- 
-- 1. Reemplaza 'uuid-cuenta', 'uuid-grupo', etc. con IDs reales de tu DB
-- 2. Usa auth.uid() en producción, pero en pruebas usa UUIDs específicos
-- 3. Las funciones como dividir_gasto_grupal() requieren datos existentes
-- 4. El historial de saldos se guarda AUTOMÁTICAMENTE al actualizar cuentas
-- 5. Las vistas ya están creadas, solo necesitas hacer SELECT
--
-- ===================================================
