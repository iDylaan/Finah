-- ==================================================================
-- ARCHIVO: 07_funciones_tarjetas_credito.sql
-- ==================================================================
-- Descripción: Funciones para gestión avanzada de tarjetas de crédito,
--              incluyendo cálculo de periodos, procesamiento de cortes,
--              registro de pagos y obtención de resúmenes detallados.
--
-- Dependencias:
--   - 01_extensiones_y_tipos.sql (tipos ENUM)
--   - 02_tablas_catalogos.sql (tablas de catálogos)
--   - 03_tablas_grupos_y_cuentas.sql (tabla cuentas)
--   - 04_tablas_transacciones.sql (tabla transacciones)
--   - 05_tablas_transacciones_periodicas.sql (tabla transacciones_periodicas)
--   - 06_triggers_y_funciones_auxiliares.sql (funciones auxiliares)
--
-- Orden de ejecución: 7/12
--
-- Funciones incluidas:
--   - recalcular_todas_tarjetas()
--   - inicializar_saldo_periodo_tarjeta() + trigger
--   - procesar_corte_tarjeta()
--   - calcular_fechas_periodo_tarjeta()
--   - obtener_gastos_periodo_tarjeta()
--   - calcular_transacciones_programadas_periodo()
--   - registrar_pago_periodo_tarjeta()
--   - obtener_resumen_periodos_tarjeta()
-- ==================================================================


-- ==================================================================
-- FUNCIONES PARA GESTIÓN DE PERIODOS DE TARJETA DE CRÉDITO
-- ==================================================================

-- 7.7) Función auxiliar para recalcular TODAS las tarjetas manualmente
CREATE OR REPLACE FUNCTION recalcular_todas_tarjetas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_tarjeta RECORD;
BEGIN
    FOR v_tarjeta IN (
        SELECT id 
        FROM cuentas 
        WHERE tipo = 'credit_card' 
            AND deleted_at IS NULL
            AND dia_corte IS NOT NULL
    ) LOOP
        PERFORM recalcular_saldo_en_corte(v_tarjeta.id);
    END LOOP;
END;
$$;

COMMENT ON FUNCTION recalcular_todas_tarjetas IS 'Recalcula el saldo_periodo_actual de todas las tarjetas de crédito activas usando la nueva lógica: (Total Usado - MSI Pendiente) = Periodo Actual';


-- 7.8) Trigger para calcular saldo_periodo_actual al crear tarjeta de crédito
CREATE OR REPLACE FUNCTION inicializar_saldo_periodo_tarjeta()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Solo aplicar a tarjetas de crédito con día de corte
    IF NEW.tipo = 'credit_card' AND NEW.dia_corte IS NOT NULL THEN
        -- Calcular el saldo del periodo actual al crear la tarjeta
        PERFORM recalcular_saldo_en_corte(NEW.id);
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_inicializar_saldo_periodo ON cuentas;
CREATE TRIGGER trigger_inicializar_saldo_periodo
    AFTER INSERT ON cuentas
    FOR EACH ROW
    EXECUTE FUNCTION inicializar_saldo_periodo_tarjeta();

COMMENT ON FUNCTION inicializar_saldo_periodo_tarjeta IS 'Inicializa el saldo_periodo_actual al crear una tarjeta de crédito';


-- ==================================================================
-- 0) Función para procesar arrastre de deuda en fecha de corte
-- ==================================================================
DROP FUNCTION IF EXISTS procesar_corte_tarjeta(UUID);
CREATE OR REPLACE FUNCTION procesar_corte_tarjeta(
    p_cuenta_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_cuenta RECORD;
    v_fechas RECORD;
    v_saldo_actual NUMERIC;
    v_saldo_arrastre_anterior NUMERIC;
    v_nuevo_saldo_arrastre NUMERIC;
    v_resultado JSONB;
BEGIN
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = p_cuenta_id
        AND tipo = 'credit_card'
        AND dia_corte IS NOT NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada o no es tarjeta de crédito';
    END IF;
    
    -- Verificar que HOY sea fecha de corte
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta.dia_corte,
        v_cuenta.dia_pago,
        CURRENT_DATE
    );
    
    -- Solo procesar si HOY es fecha de corte
    IF v_fechas.fecha_corte_actual != CURRENT_DATE THEN
        RETURN JSONB_BUILD_OBJECT(
            'procesado', false,
            'mensaje', 'Hoy no es fecha de corte',
            'fecha_corte_actual', v_fechas.fecha_corte_actual
        );
    END IF;
    
    v_saldo_actual := v_cuenta.saldo_periodo_actual;
    v_saldo_arrastre_anterior := v_cuenta.saldo_arrastre;
    
    -- REGLA DE NEGOCIO: Al corte, la deuda no pagada se arrastra
    -- saldo_arrastre += saldo_periodo_actual
    v_nuevo_saldo_arrastre := v_saldo_arrastre_anterior + v_saldo_actual;
    
    RAISE NOTICE '📅 PROCESO DE CORTE - Cuenta: %', v_cuenta.nombre;
    RAISE NOTICE '  Fecha de corte: %', CURRENT_DATE;
    RAISE NOTICE '  Saldo periodo que cierra: $%', v_saldo_actual;
    RAISE NOTICE '  Arrastre anterior: $%', v_saldo_arrastre_anterior;
    RAISE NOTICE '  Nuevo arrastre total: $%', v_nuevo_saldo_arrastre;
    
    -- Actualizar la cuenta
    UPDATE cuentas
    SET saldo_arrastre = v_nuevo_saldo_arrastre,
        saldo_periodo_actual = 0, -- Reiniciar periodo
        proxima_fecha_corte = v_fechas.fecha_corte_siguiente,
        proxima_fecha_pago = v_fechas.fecha_pago_siguiente,
        fecha_actualizacion = NOW()
    WHERE id = p_cuenta_id;
    
    -- Recalcular saldo del nuevo periodo (cuotas MSI del nuevo periodo)
    PERFORM recalcular_saldo_en_corte(p_cuenta_id);
    
    -- Registrar en historial
    INSERT INTO historial_saldos (
        cuenta_id,
        saldo_anterior,
        saldo_nuevo,
        diferencia,
        fecha,
        tipo_cambio,
        notas
    ) VALUES (
        p_cuenta_id,
        v_saldo_arrastre_anterior,
        v_nuevo_saldo_arrastre,
        v_saldo_actual,
        NOW(),
        'corte_mensual',
        'Deuda no pagada arrastrada del periodo anterior'
    );
    
    v_resultado := JSONB_BUILD_OBJECT(
        'procesado', true,
        'fecha_corte', CURRENT_DATE,
        'saldo_arrastrado', v_saldo_actual,
        'arrastre_anterior', v_saldo_arrastre_anterior,
        'arrastre_total', v_nuevo_saldo_arrastre,
        'nuevo_periodo_inicio', v_fechas.periodo_siguiente_inicio,
        'nuevo_periodo_fin', v_fechas.periodo_siguiente_fin
    );
    
    RAISE NOTICE '  ✅ Arrastre procesado correctamente';
    
    RETURN v_resultado;
END;
$$;

COMMENT ON FUNCTION procesar_corte_tarjeta IS 'Procesa el cierre de periodo en fecha de corte: arrastra la deuda no pagada, reinicia el periodo actual, y recalcula el nuevo periodo. Debe ejecutarse automáticamente en fecha de corte (job programado) o manualmente.';


-- ==================================================================
-- 1) Función para calcular fechas de periodo de tarjeta
-- ==================================================================
DROP FUNCTION IF EXISTS calcular_fechas_periodo_tarjeta(INTEGER, INTEGER, DATE);
CREATE OR REPLACE FUNCTION calcular_fechas_periodo_tarjeta(
    p_dia_corte INTEGER,
    p_dia_pago INTEGER,
    p_fecha_referencia DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    periodo_actual_inicio DATE,
    periodo_actual_fin DATE,
    periodo_siguiente_inicio DATE,
    periodo_siguiente_fin DATE,
    fecha_corte_actual DATE,
    fecha_pago_actual DATE,
    fecha_corte_siguiente DATE,
    fecha_pago_siguiente DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_corte_mes_actual DATE;
    v_corte_mes_anterior DATE;
    v_corte_mes_siguiente DATE;
    v_fecha_corte_inicio_periodo DATE;
    v_fecha_corte_fin_periodo DATE;
    v_fecha_pago_periodo DATE;
    v_fecha_corte_siguiente DATE;
    v_fecha_pago_siguiente DATE;
    v_dias_diferencia INTEGER;
BEGIN
    -- Calcular corte del mes actual (mes de la fecha de referencia)
    v_corte_mes_actual := DATE_TRUNC('month', p_fecha_referencia)::DATE + (p_dia_corte - 1);
    
    -- Calcular corte del mes anterior
    v_corte_mes_anterior := (DATE_TRUNC('month', p_fecha_referencia) - INTERVAL '1 month')::DATE + (p_dia_corte - 1);
    
    -- Calcular corte del mes siguiente
    v_corte_mes_siguiente := (DATE_TRUNC('month', p_fecha_referencia) + INTERVAL '1 month')::DATE + (p_dia_corte - 1);
    
    -- Determinar en qué periodo estamos
    -- Si ya pasó el corte del mes actual, estamos en el periodo que va de corte_actual → corte_siguiente
    -- Si NO ha pasado, estamos en el periodo que va de corte_anterior → corte_actual
    IF EXTRACT(DAY FROM p_fecha_referencia) >= p_dia_corte THEN
        -- Ya pasó el corte: periodo actual va del corte de este mes al corte del siguiente mes
        v_fecha_corte_inicio_periodo := v_corte_mes_actual;
        v_fecha_corte_fin_periodo := v_corte_mes_siguiente;
        v_fecha_corte_siguiente := (DATE_TRUNC('month', p_fecha_referencia) + INTERVAL '2 months')::DATE + (p_dia_corte - 1);
    ELSE
        -- NO ha pasado el corte: periodo actual va del corte del mes anterior al corte de este mes
        v_fecha_corte_inicio_periodo := v_corte_mes_anterior;
        v_fecha_corte_fin_periodo := v_corte_mes_actual;
        v_fecha_corte_siguiente := v_corte_mes_siguiente;
    END IF;
    
    -- Calcular fecha de pago del periodo actual
    -- La fecha de pago puede estar en el mismo mes o en el siguiente, dependiendo del día
    IF p_dia_pago >= p_dia_corte THEN
        -- Pago en el mismo mes del corte
        v_fecha_pago_periodo := DATE_TRUNC('month', v_fecha_corte_fin_periodo)::DATE + (p_dia_pago - 1);
    ELSE
        -- Pago en el mes siguiente al corte
        v_fecha_pago_periodo := (DATE_TRUNC('month', v_fecha_corte_fin_periodo) + INTERVAL '1 month')::DATE + (p_dia_pago - 1);
    END IF;
    
    -- Calcular fecha de pago del siguiente periodo
    IF p_dia_pago >= p_dia_corte THEN
        v_fecha_pago_siguiente := DATE_TRUNC('month', v_fecha_corte_siguiente)::DATE + (p_dia_pago - 1);
    ELSE
        v_fecha_pago_siguiente := (DATE_TRUNC('month', v_fecha_corte_siguiente) + INTERVAL '1 month')::DATE + (p_dia_pago - 1);
    END IF;
    
    -- Retornar todas las fechas
    -- Periodo actual: desde el día DESPUÉS del corte inicio hasta el día del corte fin
    RETURN QUERY
    SELECT 
        v_fecha_corte_inicio_periodo AS periodo_actual_inicio,
        (v_fecha_corte_fin_periodo - INTERVAL '1 day')::DATE AS periodo_actual_fin,
        v_fecha_corte_fin_periodo AS periodo_siguiente_inicio,
        (v_fecha_corte_siguiente - INTERVAL '1 day')::DATE AS periodo_siguiente_fin,
        v_fecha_corte_fin_periodo AS fecha_corte_actual,
        v_fecha_pago_periodo AS fecha_pago_actual,
        v_fecha_corte_siguiente AS fecha_corte_siguiente,
        v_fecha_pago_siguiente AS fecha_pago_siguiente;
END;
$$;

COMMENT ON FUNCTION calcular_fechas_periodo_tarjeta IS 'Calcula las fechas de inicio y fin del periodo actual y siguiente de una tarjeta de crédito';


-- ==================================================================
-- 2) Función para obtener gastos del periodo (actual o siguiente)
-- ==================================================================
DROP FUNCTION IF EXISTS obtener_gastos_periodo_tarjeta(UUID, DATE, DATE);
CREATE OR REPLACE FUNCTION obtener_gastos_periodo_tarjeta(
    p_cuenta_id UUID,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS TABLE (
    total_gastos_normales NUMERIC,
    total_cuotas_msi NUMERIC,
    total_periodo NUMERIC,
    cuotas_msi JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_gastos_normales NUMERIC := 0;
    v_cuotas_msi NUMERIC := 0;
    v_cuotas_detalle JSONB;
BEGIN
    -- NUEVO ENFOQUE SIMPLIFICADO: Consultar directamente transacciones
    -- Ahora es una simple query por fecha_ocurrencia en el periodo
    
    -- 1. Obtener gastos normales (NO MSI) del periodo
    SELECT COALESCE(SUM(monto), 0)
    INTO v_gastos_normales
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND tipo = 'gasto'
        AND fecha_ocurrencia >= p_fecha_inicio
        AND fecha_ocurrencia <= p_fecha_fin
        AND (metadatos->>'msi_id') IS NULL -- No MSI
        AND es_cuota_msi = FALSE
        AND deleted_at IS NULL;
    
    -- 2. Obtener cuotas MSI del periodo
    SELECT 
        COALESCE(SUM(monto), 0),
        JSONB_AGG(
            JSONB_BUILD_OBJECT(
                'transaccion_id', id,
                'msi_id', msi_id,
                'numero_cuota', numero_cuota_msi,
                'monto', monto,
                'fecha', fecha_ocurrencia,
                'estado', estado_msi,
                'descripcion', descripcion
            ) ORDER BY fecha_ocurrencia
        )
    INTO v_cuotas_msi, v_cuotas_detalle
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND es_cuota_msi = TRUE
        AND fecha_ocurrencia >= p_fecha_inicio
        AND fecha_ocurrencia <= p_fecha_fin
        AND estado_msi IN ('programada', 'pendiente_pago')
        AND deleted_at IS NULL;
    
    -- Si no hay cuotas MSI, inicializar cuotas_detalle como array vacío
    IF v_cuotas_detalle IS NULL THEN
        v_cuotas_detalle := '[]'::JSONB;
    END IF;
    
    RETURN QUERY
    SELECT 
        v_gastos_normales,
        v_cuotas_msi,
        v_gastos_normales + v_cuotas_msi,
        v_cuotas_detalle;
END;
$$;

COMMENT ON FUNCTION obtener_gastos_periodo_tarjeta IS 'Obtiene el desglose de gastos de un periodo de tarjeta: gastos normales, cuotas MSI y total. OPCIÓN 1 HÍBRIDO: consulta directamente transacciones reales.';


-- ==================================================================
-- 2b) Función para calcular transacciones programadas de un periodo
-- ==================================================================
DROP FUNCTION IF EXISTS calcular_transacciones_programadas_periodo(UUID, DATE, DATE);
CREATE OR REPLACE FUNCTION calcular_transacciones_programadas_periodo(
    p_cuenta_id UUID,
    p_fecha_inicio DATE,
    p_fecha_fin DATE
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_total_programado NUMERIC := 0;
    v_transaccion RECORD;
    v_fecha_ejecucion DATE;
    v_contador INTEGER;
BEGIN
    -- Recorrer todas las transacciones periódicas activas de la cuenta (NO MSI)
    FOR v_transaccion IN
        SELECT 
            tp.id,
            tp.monto,
            tp.fecha_inicio,
            tp.frecuencia,
            tp.dia_del_mes,
            tp.criterio_fin,
            tp.fecha_fin,
            tp.numero_total_repeticiones,
            tp.repeticiones_completadas
        FROM transacciones_periodicas tp
        WHERE tp.cuenta_id = p_cuenta_id
            AND tp.activa = TRUE
            AND tp.tipo = 'gasto'
            AND COALESCE(tp.es_msi, FALSE) = FALSE
    LOOP
        -- Calcular la próxima fecha de ejecución desde la fecha de inicio
        v_fecha_ejecucion := v_transaccion.fecha_inicio;
        v_contador := 0;
        
        -- Simular ejecuciones hasta encontrar las que caen en el periodo
        WHILE v_contador < 100 LOOP
            -- Verificar si la fecha de ejecucion está dentro del periodo
            IF v_fecha_ejecucion >= p_fecha_inicio AND v_fecha_ejecucion <= p_fecha_fin THEN
                v_total_programado := v_total_programado + v_transaccion.monto;
            END IF;
            
            -- Calcular siguiente fecha según frecuencia
            v_fecha_ejecucion := calcular_siguiente_fecha(
                v_fecha_ejecucion,
                v_transaccion.frecuencia,
                v_transaccion.dia_del_mes
            );
            
            -- Verificar criterios de finalización
            IF v_transaccion.criterio_fin = 'fecha_fin' THEN
                IF v_fecha_ejecucion > v_transaccion.fecha_fin THEN
                    EXIT;
                END IF;
            ELSIF v_transaccion.criterio_fin = 'numero_repeticiones' THEN
                IF v_contador >= v_transaccion.numero_total_repeticiones THEN
                    EXIT;
                END IF;
            END IF;
            
            -- Si la fecha de ejecución ya pasó el fin del periodo, salir
            IF v_fecha_ejecucion > p_fecha_fin THEN
                EXIT;
            END IF;
            
            v_contador := v_contador + 1;
        END LOOP;
    END LOOP;
    
    RETURN COALESCE(v_total_programado, 0);
END;
$$;

COMMENT ON FUNCTION calcular_transacciones_programadas_periodo IS 'Calcula la simulación de gastos programados que caerán en un periodo específico de tarjeta de crédito';


-- ==================================================================
-- 3) Función para registrar pago de periodo de tarjeta
-- ==================================================================
DROP FUNCTION IF EXISTS registrar_pago_periodo_tarjeta(UUID, NUMERIC, UUID, DATE, TEXT, TEXT, UUID);
CREATE OR REPLACE FUNCTION registrar_pago_periodo_tarjeta(
    p_cuenta_tarjeta_id UUID,
    p_monto_pago NUMERIC,
    p_categoria_id UUID,
    p_fecha_pago DATE,
    p_descripcion TEXT DEFAULT NULL,
    p_tipo_pago TEXT DEFAULT 'manual', -- 'manual' o 'transfer'
    p_cuenta_origen_id UUID DEFAULT NULL -- Solo si es transferencia
)
RETURNS UUID -- Retorna el ID de la transacción creada
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_usuario_id UUID;
    v_transaccion_id UUID;
    v_cuenta_tarjeta RECORD;
    v_fechas_periodo RECORD;
    v_monto_restante NUMERIC;
    v_cuota RECORD;
    v_monto_a_pagar_cuota NUMERIC;
BEGIN
    -- Obtener usuario en sesión
    v_usuario_id := auth.uid();
    
    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;
    
    -- Validar que la cuenta existe y es una tarjeta de crédito
    SELECT * INTO v_cuenta_tarjeta
    FROM cuentas
    WHERE id = p_cuenta_tarjeta_id
        AND creada_por = v_usuario_id
        AND tipo = 'credit_card'
        AND deleted_at IS NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tarjeta de crédito no encontrada o no autorizada';
    END IF;
    
    -- Validar monto
    IF p_monto_pago <= 0 THEN
        RAISE EXCEPTION 'El monto del pago debe ser mayor a 0';
    END IF;
    
    -- Obtener fechas del periodo actual
    SELECT * INTO v_fechas_periodo
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta_tarjeta.dia_corte,
        v_cuenta_tarjeta.dia_pago,
        p_fecha_pago
    );
    
    -- Crear la transacción de pago (ingreso a la tarjeta)
    INSERT INTO transacciones (
        usuario_id,
        cuenta_id,
        tipo,
        monto,
        fecha_ocurrencia,
        categoria_id,
        descripcion,
        metadatos
    ) VALUES (
        v_usuario_id,
        p_cuenta_tarjeta_id,
        'ingreso',
        p_monto_pago,
        p_fecha_pago,
        p_categoria_id,
        COALESCE(p_descripcion, 'Pago de tarjeta ' || v_cuenta_tarjeta.nombre),
        JSONB_BUILD_OBJECT(
            'tipo_pago', p_tipo_pago,
            'periodo_inicio', v_fechas_periodo.periodo_actual_inicio,
            'periodo_fin', v_fechas_periodo.periodo_actual_fin,
            'es_pago_periodo', TRUE
        )
    ) RETURNING id INTO v_transaccion_id;
    
    -- Si es transferencia, crear el egreso en la cuenta origen
    IF p_tipo_pago = 'transfer' AND p_cuenta_origen_id IS NOT NULL THEN
        -- Validar que la cuenta origen existe
        IF NOT EXISTS (
            SELECT 1 FROM cuentas 
            WHERE id = p_cuenta_origen_id 
                AND creada_por = v_usuario_id 
                AND deleted_at IS NULL
        ) THEN
            RAISE EXCEPTION 'Cuenta de origen no encontrada o no autorizada';
        END IF;
        
        -- Crear egreso en cuenta origen
        INSERT INTO transacciones (
            usuario_id,
            cuenta_id,
            tipo,
            monto,
            fecha_ocurrencia,
            categoria_id,
            descripcion,
            metadatos
        ) VALUES (
            v_usuario_id,
            p_cuenta_origen_id,
            'gasto',
            p_monto_pago,
            p_fecha_pago,
            p_categoria_id,
            'Pago de tarjeta ' || v_cuenta_tarjeta.nombre,
            JSONB_BUILD_OBJECT(
                'es_transferencia', TRUE,
                'cuenta_destino_id', p_cuenta_tarjeta_id,
                'transaccion_relacionada_id', v_transaccion_id
            )
        );
        
        -- Actualizar saldo de cuenta origen
        UPDATE cuentas
        SET saldo = saldo - p_monto_pago,
            fecha_actualizacion = NOW()
        WHERE id = p_cuenta_origen_id;
    END IF;
    
    -- Actualizar crédito disponible y descontar del arrastre PRIMERO
    DECLARE
        v_pago_a_arrastre NUMERIC := 0;
        v_pago_a_periodo_actual NUMERIC := 0;
        v_saldo_arrastre_actual NUMERIC;
    BEGIN
        v_saldo_arrastre_actual := v_cuenta_tarjeta.saldo_arrastre;
        
        -- PRIORIDAD 1: Descontar del arrastre primero
        IF v_saldo_arrastre_actual > 0 THEN
            v_pago_a_arrastre := LEAST(p_monto_pago, v_saldo_arrastre_actual);
            v_pago_a_periodo_actual := p_monto_pago - v_pago_a_arrastre;
            
            RAISE NOTICE '💳 Distribución del pago:';
            RAISE NOTICE '  Total a pagar: $%', p_monto_pago;
            RAISE NOTICE '  Aplicado a arrastre: $%', v_pago_a_arrastre;
            RAISE NOTICE '  Aplicado a periodo actual: $%', v_pago_a_periodo_actual;
        ELSE
            -- No hay arrastre, todo va al periodo actual
            v_pago_a_periodo_actual := p_monto_pago;
        END IF;
        
        -- Actualizar cuenta
        UPDATE cuentas
        SET credito_disponible = LEAST(
                credito_disponible + p_monto_pago,
                limite_credito
            ),
            saldo_arrastre = GREATEST(saldo_arrastre - v_pago_a_arrastre, 0),
            saldo_periodo_actual = GREATEST(saldo_periodo_actual - v_pago_a_periodo_actual, 0),
            fecha_actualizacion = NOW()
        WHERE id = p_cuenta_tarjeta_id;
    END;
    
    -- ========================================
    -- DISTRIBUCIÓN DEL PAGO (solo para tracking, no afecta saldo_periodo_actual)
    -- ========================================
    -- El saldo_periodo_actual ya se redujo arriba
    -- Aquí solo marcamos transacciones individuales como pagadas para auditoría
    
    v_monto_restante := p_monto_pago;
    
    -- PASO 1: Marcar gastos normales como pagados (del periodo actual solamente)
    FOR v_cuota IN (
        SELECT 
            id,
            monto,
            fecha_ocurrencia
        FROM transacciones
        WHERE cuenta_id = p_cuenta_tarjeta_id
            AND tipo = 'gasto'
            AND fecha_ocurrencia >= v_fechas_periodo.periodo_actual_inicio
            AND fecha_ocurrencia <= v_fechas_periodo.periodo_actual_fin
            AND (metadatos->>'msi_id') IS NULL -- Solo gastos normales
            AND COALESCE((metadatos->>'pagado_en_periodo')::BOOLEAN, FALSE) = FALSE -- No pagados aún
            AND deleted_at IS NULL
        ORDER BY fecha_ocurrencia ASC  -- Más antiguos primero
    ) LOOP
        -- Si aún hay monto disponible, marcar el gasto como pagado
        IF v_monto_restante >= v_cuota.monto THEN
            -- Marcar gasto como pagado en este periodo
            UPDATE transacciones
            SET 
                metadatos = COALESCE(metadatos, '{}'::JSONB) || 
                    JSONB_BUILD_OBJECT(
                        'pagado_en_periodo', TRUE,
                        'periodo_pago_inicio', v_fechas_periodo.periodo_actual_inicio,
                        'periodo_pago_fin', v_fechas_periodo.periodo_actual_fin,
                        'pago_transaccion_id', v_transaccion_id,
                        'fecha_pago', p_fecha_pago
                    ),
                fecha_actualizacion = NOW()
            WHERE id = v_cuota.id;
            
            -- Descontar del monto restante
            v_monto_restante := v_monto_restante - v_cuota.monto;
        ELSE
            -- No hay suficiente monto para cubrir este gasto
            EXIT;
        END IF;
    END LOOP;
    
    -- PASO 2: Marcar cuotas MSI del periodo como pagadas
    FOR v_cuota IN (
        SELECT 
            e.id,
            e.monto_programado,
            e.transaccion_periodica_id,
            tp.meses_pagados,
            tp.numero_meses_total
        FROM ejecuciones_transacciones_periodicas e
        INNER JOIN transacciones_periodicas tp ON e.transaccion_periodica_id = tp.id
        WHERE tp.cuenta_id = p_cuenta_tarjeta_id
            AND tp.es_msi = TRUE
            AND tp.activa = TRUE
            AND e.fecha_programada >= v_fechas_periodo.periodo_actual_inicio
            AND e.fecha_programada <= v_fechas_periodo.periodo_actual_fin
            AND e.estado IN ('pendiente', 'confirmada')
        ORDER BY e.fecha_programada ASC, e.numero_cuota ASC
    ) LOOP
        -- Si aún hay monto disponible, marcar la cuota como pagada
        IF v_monto_restante >= v_cuota.monto_programado THEN
            -- Marcar la cuota como ejecutada
            UPDATE ejecuciones_transacciones_periodicas
            SET 
                estado = 'ejecutada',
                fecha_ejecutada = NOW(),
                monto_ejecutado = v_cuota.monto_programado,
                notas = COALESCE(notas, '') || ' Pagado con transacción ' || v_transaccion_id
            WHERE id = v_cuota.id;
            
            -- Incrementar meses pagados del MSI
            UPDATE transacciones_periodicas
            SET meses_pagados = meses_pagados + 1,
                updated_at = NOW()
            WHERE id = v_cuota.transaccion_periodica_id;
            
            -- Descontar del monto restante
            v_monto_restante := v_monto_restante - v_cuota.monto_programado;
            
            -- Si ya se pagó completamente el MSI, marcarlo como inactivo
            IF (v_cuota.meses_pagados + 1) >= v_cuota.numero_meses_total THEN
                UPDATE transacciones_periodicas
                SET activa = FALSE,
                    updated_at = NOW()
                WHERE id = v_cuota.transaccion_periodica_id;
            END IF;
        ELSE
            -- No hay suficiente monto para cubrir esta cuota
            EXIT;
        END IF;
    END LOOP;
    
    RETURN v_transaccion_id;
END;
$$;

COMMENT ON FUNCTION registrar_pago_periodo_tarjeta IS 'Registra un pago de tarjeta de crédito por periodo. Distribuye el pago priorizando gastos más antiguos primero (incluye gastos no pagados de periodos anteriores), luego cuotas MSI del periodo actual. Los gastos no cubiertos se arrastran automáticamente al siguiente periodo.';


-- ==================================================================
-- 4) Función auxiliar para obtener resumen completo de periodos
-- ==================================================================
DROP FUNCTION IF EXISTS obtener_resumen_periodos_tarjeta(UUID);
CREATE OR REPLACE FUNCTION obtener_resumen_periodos_tarjeta(
    p_cuenta_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_cuenta RECORD;
    v_fechas RECORD;
    v_periodo_actual RECORD;
    v_periodo_siguiente RECORD;
    v_credito_utilizado NUMERIC;
    v_total_msi NUMERIC := 0;
    v_deuda_no_diferida NUMERIC := 0;
    v_cuota_msi_actual NUMERIC := 0;
    v_cuota_msi_siguiente NUMERIC := 0;
    v_msi RECORD;
    v_msi_sig RECORD;
    v_saldo_pendiente_msi NUMERIC;
    v_saldo_pendiente_msi_sig NUMERIC;
    v_cuota_este_periodo NUMERIC;
    v_cuota_siguiente_periodo NUMERIC;
    v_total_siguiente_ajustado NUMERIC;
    v_gastos_programados_actual NUMERIC := 0;
    v_gastos_programados_siguiente NUMERIC := 0;
    v_resultado JSONB;
BEGIN
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = p_cuenta_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada';
    END IF;
    
    -- Obtener fechas de periodos
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta.dia_corte,
        v_cuenta.dia_pago,
        CURRENT_DATE
    );
    
    -- Obtener gastos del periodo actual
    SELECT * INTO v_periodo_actual
    FROM obtener_gastos_periodo_tarjeta(
        p_cuenta_id,
        v_fechas.periodo_actual_inicio,
        v_fechas.periodo_actual_fin
    );
    
    -- Obtener gastos del periodo siguiente
    SELECT * INTO v_periodo_siguiente
    FROM obtener_gastos_periodo_tarjeta(
        p_cuenta_id,
        v_fechas.periodo_siguiente_inicio,
        v_fechas.periodo_siguiente_fin
    );
    
    -- Calcular crédito utilizado total
    v_credito_utilizado := v_cuenta.limite_credito - v_cuenta.credito_disponible;
    
    -- Calcular total de MSI (completo, todas las cuotas)
    v_total_msi := calcular_total_msi_pendiente(p_cuenta_id);
    
    -- Calcular deuda no diferida
    -- Es la deuda total menos TODO el MSI (porque el MSI se paga poco a poco)
    v_deuda_no_diferida := v_credito_utilizado - v_total_msi;
    
    -- OPCIÓN 1 HÍBRIDO: Calcular cuota MSI del periodo ACTUAL desde transacciones reales
    -- Ya no necesitamos el loop complejo, es una simple suma
    SELECT COALESCE(SUM(monto), 0)
    INTO v_cuota_msi_actual
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND es_cuota_msi = TRUE
        AND fecha_ocurrencia >= v_fechas.periodo_actual_inicio
        AND fecha_ocurrencia <= v_fechas.periodo_actual_fin
        AND estado_msi IN ('programada', 'pendiente_pago')
        AND deleted_at IS NULL;
    
    -- OPCIÓN 1 HÍBRIDO: Calcular cuota MSI del periodo SIGUIENTE desde transacciones reales
    SELECT COALESCE(SUM(monto), 0)
    INTO v_cuota_msi_siguiente
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND es_cuota_msi = TRUE
        AND fecha_ocurrencia >= v_fechas.periodo_siguiente_inicio
        AND fecha_ocurrencia <= v_fechas.periodo_siguiente_fin
        AND estado_msi IN ('programada', 'pendiente_pago')
        AND deleted_at IS NULL;
    
    RAISE NOTICE 'DEBUG Periodo Siguiente: Inicio=%, Fin=%, Cuotas MSI=%', 
        v_fechas.periodo_siguiente_inicio, v_fechas.periodo_siguiente_fin, v_cuota_msi_siguiente;
    
    -- ===== NUEVO: Calcular transacciones programadas =====
    v_gastos_programados_actual := calcular_transacciones_programadas_periodo(
        p_cuenta_id,
        v_fechas.periodo_actual_inicio,
        v_fechas.periodo_actual_fin
    );
    
    v_gastos_programados_siguiente := calcular_transacciones_programadas_periodo(
        p_cuenta_id,
        v_fechas.periodo_siguiente_inicio,
        v_fechas.periodo_siguiente_fin
    );
    -- ===== FIN NUEVO =====
    
    -- Ajustar proyección del siguiente periodo si excede el total adeudado
    -- La proyección no puede ser mayor que la deuda total
    v_total_siguiente_ajustado := LEAST(
        v_periodo_siguiente.total_periodo,
        v_credito_utilizado
    );
    
    -- Construir JSON de respuesta con desglose completo
    -- Para periodo_actual: usar saldo_periodo_actual (variable que aumenta con gastos y disminuye con pagos)
    -- Para periodo_siguiente: calcular proyección basada en gastos futuros ya registrados
    v_resultado := JSONB_BUILD_OBJECT(
        'cuenta_id', p_cuenta_id,
        'limite_credito', v_cuenta.limite_credito,
        'credito_disponible', v_cuenta.credito_disponible,
        'credito_utilizado', v_credito_utilizado,
        'saldo_periodo_actual', v_cuenta.saldo_periodo_actual,
        'saldo_arrastre', v_cuenta.saldo_arrastre,
        -- Desglose del periodo ACTUAL
        'desglose_deuda', JSONB_BUILD_OBJECT(
            'deuda_total', v_credito_utilizado,
            'deuda_no_diferida', v_deuda_no_diferida,
            'cuota_msi_periodo', v_cuota_msi_actual,
            'total_msi_pendiente', v_total_msi,
            'saldo_arrastre', v_cuenta.saldo_arrastre,
            'saldo_periodo_actual', v_cuenta.saldo_periodo_actual,
            'gastos_programados_periodo', v_gastos_programados_actual,
            'proyeccion_con_programados', v_cuenta.saldo_periodo_actual + v_gastos_programados_actual,
            'total_a_pagar', v_cuenta.saldo_arrastre + v_cuenta.saldo_periodo_actual
        ),
        -- Desglose del periodo SIGUIENTE (proyección)
        'desglose_siguiente_periodo', JSONB_BUILD_OBJECT(
            'cuota_msi_periodo', v_cuota_msi_siguiente,
            'gastos_futuros_registrados', v_periodo_siguiente.total_gastos_normales,
            'gastos_programados', v_gastos_programados_siguiente,
            'proyeccion_total', v_cuota_msi_siguiente + COALESCE(v_periodo_siguiente.total_gastos_normales, 0) + v_gastos_programados_siguiente
        ),
        'fechas', JSONB_BUILD_OBJECT(
            'periodo_actual', JSONB_BUILD_OBJECT(
                'inicio', v_fechas.periodo_actual_inicio,
                'fin', v_fechas.periodo_actual_fin,
                'fecha_corte', v_fechas.fecha_corte_actual,
                'fecha_pago', v_fechas.fecha_pago_actual
            ),
            'periodo_siguiente', JSONB_BUILD_OBJECT(
                'inicio', v_fechas.periodo_siguiente_inicio,
                'fin', v_fechas.periodo_siguiente_fin,
                'fecha_corte', v_fechas.fecha_corte_siguiente,
                'fecha_pago', v_fechas.fecha_pago_siguiente
            )
        ),
        'periodo_actual', JSONB_BUILD_OBJECT(
            'gastos_normales', v_periodo_actual.total_gastos_normales,
            'cuotas_msi', v_periodo_actual.total_cuotas_msi,
            'total', v_cuenta.saldo_periodo_actual,
            'total_calculado', v_periodo_actual.total_periodo,
            'cuotas_detalle', v_periodo_actual.cuotas_msi
        ),
        'periodo_siguiente', JSONB_BUILD_OBJECT(
            'gastos_normales', v_periodo_siguiente.total_gastos_normales,
            'cuotas_msi', v_periodo_siguiente.total_cuotas_msi,
            'total', v_total_siguiente_ajustado,
            'total_original', v_periodo_siguiente.total_periodo,
            'ajustado', v_periodo_siguiente.total_periodo > v_credito_utilizado,
            'cuotas_detalle', v_periodo_siguiente.cuotas_msi
        )
    );
    
    RETURN v_resultado;
END;
$$;

COMMENT ON FUNCTION obtener_resumen_periodos_tarjeta IS 'Obtiene resumen completo de periodos de tarjeta. Periodo actual usa saldo_periodo_actual (variable), periodo siguiente es proyección de gastos futuros.';


-- ==================================================================
-- CONFIRMACIÓN DE EJECUCIÓN
-- ==================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '✅ Archivo 07_funciones_tarjetas_credito.sql ejecutado correctamente';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'Funciones creadas:';
    RAISE NOTICE '  - recalcular_todas_tarjetas()';
    RAISE NOTICE '  - inicializar_saldo_periodo_tarjeta() + trigger';
    RAISE NOTICE '  - procesar_corte_tarjeta()';
    RAISE NOTICE '  - calcular_fechas_periodo_tarjeta()';
    RAISE NOTICE '  - obtener_gastos_periodo_tarjeta()';
    RAISE NOTICE '  - calcular_transacciones_programadas_periodo()';
    RAISE NOTICE '  - registrar_pago_periodo_tarjeta()';
    RAISE NOTICE '  - obtener_resumen_periodos_tarjeta()';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '';
END $$;
