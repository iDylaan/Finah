-- ============================================
-- Script de Verificación Post-Migración MSI
-- ============================================
-- Ejecutar DESPUÉS de aplicar la migración
-- para verificar que todo funciona correctamente

-- ========================================
-- 1. Verificar estructura de transacciones
-- ========================================
DO $$
BEGIN
    -- Verificar que existen las nuevas columnas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transacciones' AND column_name = 'es_cuota_msi'
    ) THEN
        RAISE EXCEPTION '❌ Falta columna es_cuota_msi en transacciones';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transacciones' AND column_name = 'msi_id'
    ) THEN
        RAISE EXCEPTION '❌ Falta columna msi_id en transacciones';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transacciones' AND column_name = 'numero_cuota_msi'
    ) THEN
        RAISE EXCEPTION '❌ Falta columna numero_cuota_msi en transacciones';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'transacciones' AND column_name = 'estado_msi'
    ) THEN
        RAISE EXCEPTION '❌ Falta columna estado_msi en transacciones';
    END IF;
    
    RAISE NOTICE '✅ Todas las columnas MSI existen en transacciones';
END $$;

-- ========================================
-- 2. Verificar índices
-- ========================================
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'transacciones' AND indexname = 'idx_transacciones_msi_id'
    ) THEN
        RAISE WARNING '⚠️  Falta índice idx_transacciones_msi_id';
    ELSE
        RAISE NOTICE '✅ Índice idx_transacciones_msi_id existe';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'transacciones' AND indexname = 'idx_transacciones_periodo_msi'
    ) THEN
        RAISE WARNING '⚠️  Falta índice idx_transacciones_periodo_msi';
    ELSE
        RAISE NOTICE '✅ Índice idx_transacciones_periodo_msi existe';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'transacciones' AND indexname = 'idx_transacciones_estado_msi'
    ) THEN
        RAISE WARNING '⚠️  Falta índice idx_transacciones_estado_msi';
    ELSE
        RAISE NOTICE '✅ Índice idx_transacciones_estado_msi existe';
    END IF;
END $$;

-- ========================================
-- 3. Verificar funciones modificadas
-- ========================================
DO $$
BEGIN
    -- Verificar crear_msi_tarjeta_credito
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'crear_msi_tarjeta_credito'
    ) THEN
        RAISE EXCEPTION '❌ Falta función crear_msi_tarjeta_credito';
    ELSE
        RAISE NOTICE '✅ Función crear_msi_tarjeta_credito existe';
    END IF;
    
    -- Verificar eliminar_msi_tarjeta_credito
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'eliminar_msi_tarjeta_credito'
    ) THEN
        RAISE EXCEPTION '❌ Falta función eliminar_msi_tarjeta_credito';
    ELSE
        RAISE NOTICE '✅ Función eliminar_msi_tarjeta_credito existe';
    END IF;
    
    -- Verificar obtener_gastos_periodo_tarjeta
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'obtener_gastos_periodo_tarjeta'
    ) THEN
        RAISE EXCEPTION '❌ Falta función obtener_gastos_periodo_tarjeta';
    ELSE
        RAISE NOTICE '✅ Función obtener_gastos_periodo_tarjeta existe';
    END IF;
    
    -- Verificar recalcular_saldo_en_corte
    IF NOT EXISTS (
        SELECT 1 FROM pg_proc 
        WHERE proname = 'recalcular_saldo_en_corte'
    ) THEN
        RAISE EXCEPTION '❌ Falta función recalcular_saldo_en_corte';
    ELSE
        RAISE NOTICE '✅ Función recalcular_saldo_en_corte existe';
    END IF;
END $$;

-- ========================================
-- 4. Verificar MSI existentes
-- ========================================
SELECT 
    '📊 MSI EXISTENTES' as seccion,
    COUNT(*) as total_msi,
    SUM(CASE WHEN activa = TRUE THEN 1 ELSE 0 END) as activos,
    SUM(CASE WHEN activa = FALSE THEN 1 ELSE 0 END) as inactivos
FROM transacciones_periodicas
WHERE es_msi = TRUE;

-- ========================================
-- 5. Verificar cuotas MSI creadas
-- ========================================
SELECT 
    '📋 CUOTAS MSI' as seccion,
    tp.nombre as msi_nombre,
    tp.numero_meses_total as cuotas_esperadas,
    COUNT(t.id) as cuotas_creadas,
    ROUND(tp.monto_total_msi, 2) as monto_total,
    ROUND(tp.monto_por_mes, 2) as cuota_mensual,
    tp.meses_pagados,
    SUM(CASE WHEN t.estado_msi = 'pagada' THEN 1 ELSE 0 END) as cuotas_pagadas,
    SUM(CASE WHEN t.estado_msi = 'pendiente_pago' THEN 1 ELSE 0 END) as cuotas_pendientes,
    SUM(CASE WHEN t.estado_msi = 'programada' THEN 1 ELSE 0 END) as cuotas_programadas,
    CASE 
        WHEN COUNT(t.id) = tp.numero_meses_total THEN '✅ OK'
        WHEN COUNT(t.id) = 0 THEN '⚠️  NO MIGRADO'
        ELSE '❌ INCOMPLETO'
    END as estado
FROM transacciones_periodicas tp
LEFT JOIN transacciones t ON t.msi_id = tp.id AND t.es_cuota_msi = TRUE
WHERE tp.es_msi = TRUE AND tp.activa = TRUE
GROUP BY tp.id, tp.nombre, tp.numero_meses_total, tp.monto_total_msi, tp.monto_por_mes, tp.meses_pagados
ORDER BY tp.fecha_inicio DESC;

-- ========================================
-- 6. Verificar crédito disponible
-- ========================================
SELECT 
    '💳 TARJETAS DE CRÉDITO' as seccion,
    c.nombre,
    ROUND(c.limite_credito, 2) as limite,
    ROUND(c.credito_disponible, 2) as disponible,
    ROUND(c.limite_credito - c.credito_disponible, 2) as deuda_total,
    (
        SELECT COALESCE(SUM(tp.monto_total_msi - (tp.meses_pagados * tp.monto_por_mes)), 0)
        FROM transacciones_periodicas tp
        WHERE tp.cuenta_id = c.id
          AND tp.es_msi = TRUE
          AND tp.activa = TRUE
    ) as deuda_msi_pendiente,
    (
        SELECT COUNT(*)
        FROM transacciones_periodicas tp
        WHERE tp.cuenta_id = c.id
          AND tp.es_msi = TRUE
          AND tp.activa = TRUE
    ) as msi_activos
FROM cuentas c
WHERE c.tipo = 'credit_card'
ORDER BY c.nombre;

-- ========================================
-- 7. Verificar integridad de datos
-- ========================================

-- 7.1 Verificar que no haya cuotas sin MSI padre
SELECT 
    '⚠️  CUOTAS HUÉRFANAS' as problema,
    COUNT(*) as cantidad
FROM transacciones t
WHERE t.es_cuota_msi = TRUE
  AND t.msi_id IS NULL;

-- 7.2 Verificar que no haya cuotas con MSI inexistente
SELECT 
    '⚠️  CUOTAS CON MSI INEXISTENTE' as problema,
    COUNT(*) as cantidad
FROM transacciones t
LEFT JOIN transacciones_periodicas tp ON t.msi_id = tp.id
WHERE t.es_cuota_msi = TRUE
  AND t.msi_id IS NOT NULL
  AND tp.id IS NULL;

-- 7.3 Verificar que todas las cuotas tengan numero_cuota_msi
SELECT 
    '⚠️  CUOTAS SIN NÚMERO' as problema,
    COUNT(*) as cantidad
FROM transacciones t
WHERE t.es_cuota_msi = TRUE
  AND t.numero_cuota_msi IS NULL;

-- 7.4 Verificar que todas las cuotas tengan estado
SELECT 
    '⚠️  CUOTAS SIN ESTADO' as problema,
    COUNT(*) as cantidad
FROM transacciones t
WHERE t.es_cuota_msi = TRUE
  AND t.estado_msi IS NULL;

-- 7.5 Verificar consistencia de estados
SELECT 
    '📊 DISTRIBUCIÓN DE ESTADOS' as seccion,
    estado_msi,
    COUNT(*) as cantidad,
    ROUND(SUM(monto), 2) as monto_total
FROM transacciones
WHERE es_cuota_msi = TRUE
  AND deleted_at IS NULL
GROUP BY estado_msi
ORDER BY 
    CASE estado_msi
        WHEN 'pagada' THEN 1
        WHEN 'pendiente_pago' THEN 2
        WHEN 'programada' THEN 3
        WHEN 'vencida' THEN 4
    END;

-- ========================================
-- 8. Test de funciones (opcional)
-- ========================================
-- NOTA: Solo ejecutar si tienes una tarjeta de crédito configurada

-- Obtener primera tarjeta
DO $$
DECLARE
    v_tarjeta_id UUID;
    v_dia_corte INTEGER;
    v_dia_pago INTEGER;
    v_fechas RECORD;
BEGIN
    SELECT id, dia_corte, dia_pago INTO v_tarjeta_id, v_dia_corte, v_dia_pago
    FROM cuentas
    WHERE tipo = 'credit_card'
      AND dia_corte IS NOT NULL
    LIMIT 1;
    
    IF v_tarjeta_id IS NULL THEN
        RAISE NOTICE '⚠️  No hay tarjetas de crédito configuradas para testear';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Testeando con tarjeta: %', v_tarjeta_id;
    
    -- Test calcular_fechas_periodo_tarjeta
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(v_dia_corte, v_dia_pago, CURRENT_DATE);
    
    RAISE NOTICE '  ✅ calcular_fechas_periodo_tarjeta: % a %', 
        v_fechas.periodo_actual_inicio, v_fechas.periodo_actual_fin;
    
    -- Test recalcular_saldo_en_corte
    PERFORM recalcular_saldo_en_corte(v_tarjeta_id);
    RAISE NOTICE '  ✅ recalcular_saldo_en_corte ejecutado';
    
    -- Test obtener_gastos_periodo_tarjeta
    DECLARE
        v_gastos RECORD;
    BEGIN
        SELECT * INTO v_gastos
        FROM obtener_gastos_periodo_tarjeta(
            v_tarjeta_id,
            v_fechas.periodo_actual_inicio,
            v_fechas.periodo_actual_fin
        );
        
        RAISE NOTICE '  ✅ obtener_gastos_periodo_tarjeta: gastos_normales=%, cuotas_msi=%',
            v_gastos.gastos_normales, v_gastos.cuotas_msi;
    END;
END $$;

-- ========================================
-- RESUMEN FINAL
-- ========================================
SELECT 
    '📝 RESUMEN MIGRACIÓN' as titulo,
    '=========================' as separador;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM transacciones WHERE es_cuota_msi = TRUE) > 0 
        THEN '✅ HAY CUOTAS MSI CREADAS'
        ELSE '⚠️  NO HAY CUOTAS MSI (ejecutar script de migración si tienes MSI existentes)'
    END as estado_cuotas;

SELECT 
    CASE 
        WHEN (
            SELECT COUNT(*) 
            FROM transacciones t
            LEFT JOIN transacciones_periodicas tp ON t.msi_id = tp.id
            WHERE t.es_cuota_msi = TRUE AND tp.id IS NULL
        ) = 0
        THEN '✅ TODAS LAS CUOTAS TIENEN MSI PADRE'
        ELSE '❌ HAY CUOTAS HUÉRFANAS'
    END as integridad_datos;

SELECT 
    CASE 
        WHEN (
            SELECT COUNT(*)
            FROM transacciones
            WHERE es_cuota_msi = TRUE
              AND (numero_cuota_msi IS NULL OR estado_msi IS NULL)
        ) = 0
        THEN '✅ TODAS LAS CUOTAS TIENEN DATOS COMPLETOS'
        ELSE '❌ HAY CUOTAS CON DATOS INCOMPLETOS'
    END as datos_completos;

RAISE NOTICE '========================================';
RAISE NOTICE '✅ VERIFICACIÓN COMPLETADA';
RAISE NOTICE '========================================';
RAISE NOTICE '';
RAISE NOTICE 'Si todos los checks pasaron, la migración fue exitosa.';
RAISE NOTICE 'Si hay warnings, revisa el documento MIGRACION_MSI_HIBRIDO.md';
RAISE NOTICE '';
