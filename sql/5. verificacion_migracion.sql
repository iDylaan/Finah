-- ===================================================
-- SCRIPT DE VERIFICACIÓN POST-MIGRACIÓN
-- Ejecuta estas consultas después de aplicar la migración
-- para confirmar que todo se creó correctamente
-- ===================================================

-- ===================================================
-- 1) VERIFICAR TABLAS CREADAS
-- ===================================================
SELECT 
  table_name AS "Tabla",
  CASE 
    WHEN table_name IN ('invitaciones_grupo', 'historial_saldos') THEN 'Nueva'
    ELSE 'Existente'
  END AS "Estado"
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'invitaciones_grupo',
    'historial_saldos',
    'metas',
    'cuentas',
    'grupos_usuario',
    'miembros_grupo',
    'transacciones',
    'divisiones_transaccion'
  )
ORDER BY table_name;


-- ===================================================
-- 2) VERIFICAR COLUMNAS NUEVAS EN METAS
-- ===================================================
SELECT 
  column_name AS "Columna",
  data_type AS "Tipo",
  column_default AS "Default"
FROM information_schema.columns
WHERE table_name = 'metas'
  AND column_name IN (
    'notificar_al_alcanzar',
    'permitir_exceder',
    'icon_library',
    'icon_name',
    'color'
  )
ORDER BY column_name;


-- ===================================================
-- 3) VERIFICAR FUNCIONES CREADAS
-- ===================================================
SELECT 
  routine_name AS "Función",
  routine_type AS "Tipo",
  CASE 
    WHEN routine_name = 'guardar_historial_saldo' THEN 'Trigger para historial'
    WHEN routine_name = 'expirar_invitaciones_vencidas' THEN 'Expirar invitaciones'
    WHEN routine_name = 'dividir_gasto_grupal' THEN 'División automática'
    WHEN routine_name = 'aceptar_invitacion_grupo' THEN 'Aceptar invitación'
    ELSE 'Otra función'
  END AS "Descripción"
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'guardar_historial_saldo',
    'expirar_invitaciones_vencidas',
    'dividir_gasto_grupal',
    'aceptar_invitacion_grupo',
    'es_miembro_grupo',
    'es_admin_grupo'
  )
ORDER BY routine_name;


-- ===================================================
-- 4) VERIFICAR TRIGGERS ACTIVOS
-- ===================================================
SELECT 
  trigger_name AS "Trigger",
  event_manipulation AS "Evento",
  event_object_table AS "Tabla",
  action_statement AS "Acción"
FROM information_schema.triggers
WHERE trigger_schema = 'public'
  AND trigger_name IN (
    'trigger_historial_saldo',
    'al_crear_grupo_asignar_admin'
  )
ORDER BY trigger_name;


-- ===================================================
-- 5) VERIFICAR VISTAS CREADAS
-- ===================================================
SELECT 
  table_name AS "Vista",
  CASE 
    WHEN table_name = 'vista_patrimonio_usuario' THEN 'Patrimonio neto'
    WHEN table_name = 'vista_gastos_mes_actual' THEN 'Gastos del mes'
    WHEN table_name = 'vista_progreso_metas' THEN 'Progreso de metas'
    ELSE 'Otra vista'
  END AS "Descripción"
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'VIEW'
  AND table_name LIKE 'vista_%'
ORDER BY table_name;


-- ===================================================
-- 6) VERIFICAR POLÍTICAS RLS
-- ===================================================
SELECT 
  tablename AS "Tabla",
  policyname AS "Política",
  cmd AS "Comando"
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'invitaciones_grupo',
    'historial_saldos'
  )
ORDER BY tablename, policyname;


-- ===================================================
-- 7) VERIFICAR ÍNDICES CREADOS
-- ===================================================
SELECT 
  schemaname AS "Schema",
  tablename AS "Tabla",
  indexname AS "Índice"
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
    'invitaciones_grupo',
    'historial_saldos'
  )
ORDER BY tablename, indexname;


-- ===================================================
-- 8) CONTAR REGISTROS EN NUEVAS TABLAS
-- ===================================================
SELECT 
  'invitaciones_grupo' AS tabla,
  COUNT(*) AS registros
FROM invitaciones_grupo
UNION ALL
SELECT 
  'historial_saldos' AS tabla,
  COUNT(*) AS registros
FROM historial_saldos;


-- ===================================================
-- 9) PROBAR FUNCIÓN DE DIVISIÓN DE GASTOS
-- ===================================================
-- Esta consulta solo muestra cómo se usaría, NO la ejecutes sin datos reales
/*
SELECT dividir_gasto_grupal(
  'uuid-de-transaccion'::uuid,
  'uuid-de-grupo'::uuid
);
*/


-- ===================================================
-- 10) RESUMEN COMPLETO DE LA MIGRACIÓN
-- ===================================================
SELECT 
  'Migración completada' AS estado,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('invitaciones_grupo', 'historial_saldos')) AS tablas_nuevas,
  (SELECT COUNT(*) FROM information_schema.columns 
   WHERE table_name = 'metas' 
   AND column_name IN ('notificar_al_alcanzar', 'permitir_exceder', 'icon_library', 'icon_name', 'color')) AS columnas_agregadas,
  (SELECT COUNT(*) FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name IN ('guardar_historial_saldo', 'expirar_invitaciones_vencidas', 'dividir_gasto_grupal', 'aceptar_invitacion_grupo')) AS funciones_creadas,
  (SELECT COUNT(*) FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_type = 'VIEW' 
   AND table_name LIKE 'vista_%') AS vistas_creadas;


-- ===================================================
-- 11) VERIFICAR QUE RLS ESTÁ HABILITADO
-- ===================================================
SELECT 
  tablename AS "Tabla",
  rowsecurity AS "RLS Habilitado"
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'invitaciones_grupo',
    'historial_saldos',
    'metas',
    'cuentas',
    'grupos_usuario'
  )
ORDER BY tablename;


-- ===================================================
-- RESULTADO ESPERADO
-- ===================================================
-- Si todo está correcto deberías ver:
-- ✅ 2 tablas nuevas (invitaciones_grupo, historial_saldos)
-- ✅ 5 columnas nuevas en metas
-- ✅ 4 funciones nuevas
-- ✅ 3 vistas nuevas
-- ✅ RLS habilitado en todas las tablas
-- ✅ Políticas RLS configuradas
-- ✅ Índices creados para optimización
