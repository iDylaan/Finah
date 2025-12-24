-- ==================================================================
-- ARCHIVO: 08_funciones_msi_y_periodicas.sql
-- ==================================================================
-- Descripción: Funciones para gestión de MSI (Meses Sin Intereses) y 
--              transacciones periódicas, incluyendo creación, cálculo
--              de fechas, y eliminación de MSI.
--
-- Dependencias:
--   - 01_extensiones_y_tipos.sql (tipos ENUM)
--   - 02_tablas_catalogos.sql (tablas de catálogos)
--   - 03_tablas_grupos_y_cuentas.sql (tabla cuentas)
--   - 04_tablas_transacciones.sql (tabla transacciones)
--   - 05_tablas_transacciones_periodicas.sql (tabla transacciones_periodicas)
--   - 06_triggers_y_funciones_auxiliares.sql (funciones auxiliares)
--   - 07_funciones_tarjetas_credito.sql (calcular_fechas_periodo_tarjeta)
--
-- Orden de ejecución: 8/12
--
-- Funciones incluidas:
--   - actualizar_saldo_periodo_msi() + trigger
--   - calcular_proxima_ejecucion()
--   - crear_msi_tarjeta_credito()
--   - incrementar_repeticiones_completadas()
--   - calcular_siguiente_fecha()
--   - eliminar_msi_tarjeta_credito()
-- ==================================================================


-- ==================================================================
-- FUNCIONES PARA TRANSACCIONES PERIÓDICAS Y MSI
-- ==================================================================

-- 7.5b) Función para actualizar saldo_periodo_actual al crear MSI
-- NOTA: Esta función ya NO suma las ejecuciones directamente porque el trigger
-- de ejecuciones_transacciones_periodicas lo hace automáticamente
CREATE OR REPLACE FUNCTION actualizar_saldo_periodo_msi()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Solo validar que es MSI, pero no hacer nada
    -- El trigger de ejecuciones_transacciones_periodicas se encargará de actualizar el saldo
    -- cuando se inserten las ejecuciones individuales
    RETURN NEW;
END;
$$;

-- Trigger para actualizar saldo_periodo_actual al crear MSI
DROP TRIGGER IF EXISTS trigger_actualizar_saldo_periodo_msi ON transacciones_periodicas;
CREATE TRIGGER trigger_actualizar_saldo_periodo_msi
    AFTER INSERT ON transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_saldo_periodo_msi();


-- ==================================================================
-- 9) Funciones para transacciones periódicas
-- ==================================================================

-- 9.1) Función para calcular próxima ejecución de transacción periódica
CREATE OR REPLACE FUNCTION calcular_proxima_ejecucion(
    p_transaccion_periodica_id UUID,
    p_fecha_base TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
AS $$
DECLARE
    v_record RECORD;
    v_proxima_fecha TIMESTAMP WITH TIME ZONE;
    v_temp_date DATE;
    v_dia_semana_actual INTEGER;
    v_dias_hasta_proximo INTEGER;
    v_encontrado BOOLEAN := FALSE;
BEGIN
    -- Obtener configuración de la transacción
    SELECT * INTO v_record
    FROM transacciones_periodicas
    WHERE id = p_transaccion_periodica_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transacción periódica no encontrada';
    END IF;
    
    -- Calcular según frecuencia
    CASE v_record.frecuencia
        
        -- DIARIA: siguiente día
        WHEN 'diaria' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '1 day';
        
        -- SEMANAL: siguiente día de la semana especificado
        WHEN 'semanal' THEN
            -- Obtener día de la semana actual (1=lunes, 7=domingo)
            v_dia_semana_actual := EXTRACT(ISODOW FROM p_fecha_base);
            
            -- Buscar el próximo día en el array dias_semana
            v_temp_date := p_fecha_base::DATE;
            
            FOR i IN 1..7 LOOP
                v_temp_date := v_temp_date + INTERVAL '1 day';
                v_dia_semana_actual := EXTRACT(ISODOW FROM v_temp_date);
                
                -- Convertir a nombre de día y verificar si está en el array
                IF (
                    (v_dia_semana_actual = 1 AND 'lunes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 2 AND 'martes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 3 AND 'miercoles' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 4 AND 'jueves' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 5 AND 'viernes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 6 AND 'sabado' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 7 AND 'domingo' = ANY(v_record.dias_semana))
                ) THEN
                    v_proxima_fecha := v_temp_date;
                    EXIT;
                END IF;
            END LOOP;
        
        -- QUINCENAL: cada 15 días
        WHEN 'quincenal' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '15 days';
        
        -- MENSUAL: mismo día del próximo mes
        WHEN 'mensual' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month')::DATE;
            
            -- Ajustar al día específico del mes
            v_temp_date := v_temp_date + (v_record.dia_del_mes - 1) || ' days';
            
            -- Si el día no existe en ese mes (ej: 31 en febrero), usar el último día
            IF EXTRACT(DAY FROM v_temp_date) != v_record.dia_del_mes THEN
                v_temp_date := (DATE_TRUNC('month', v_temp_date) + INTERVAL '1 month - 1 day')::DATE;
            END IF;
            
            v_proxima_fecha := v_temp_date;
        
        -- BIMESTRAL: cada 2 meses
        WHEN 'bimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '2 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- TRIMESTRAL: cada 3 meses
        WHEN 'trimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '3 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- SEMESTRAL: cada 6 meses
        WHEN 'semestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '6 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- ANUAL: mismo día y mes del próximo año
        WHEN 'anual' THEN
            v_temp_date := MAKE_DATE(
                EXTRACT(YEAR FROM p_fecha_base)::INTEGER + 1,
                v_record.mes_del_anio,
                v_record.dia_del_anio
            );
            v_proxima_fecha := v_temp_date;
        
        -- DÍAS NATURALES: cada X días
        WHEN 'dias_naturales' THEN
            v_proxima_fecha := p_fecha_base + (v_record.intervalo_dias || ' days')::INTERVAL;
        
        -- MSI: mensual basado en día de corte de tarjeta
        WHEN 'msi' THEN
            -- Obtener día de corte de la tarjeta
            SELECT 
                CASE 
                    WHEN dia_corte <= EXTRACT(DAY FROM p_fecha_base) THEN
                        (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month' + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                    ELSE
                        (DATE_TRUNC('month', p_fecha_base) + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                END INTO v_temp_date
            FROM cuentas
            WHERE id = v_record.cuenta_id;
            
            v_proxima_fecha := v_temp_date;
        
        -- ÚNICA: misma fecha de inicio
        WHEN 'unica' THEN
            v_proxima_fecha := v_record.fecha_inicio;
        
        ELSE
            RAISE EXCEPTION 'Frecuencia no soportada: %', v_record.frecuencia;
    END CASE;
    
    -- Verificar si alcanzó el criterio de finalización
    IF v_record.criterio_fin = 'fecha_fin' AND v_proxima_fecha::DATE > v_record.fecha_fin THEN
        RETURN NULL; -- Ya no debe ejecutarse más
    END IF;
    
    IF v_record.criterio_fin = 'numero_repeticiones' AND 
       v_record.repeticiones_completadas >= v_record.numero_total_repeticiones THEN
        RETURN NULL; -- Ya completó todas las repeticiones
    END IF;
    
    RETURN v_proxima_fecha;
END;
$$;

-- 8.2) Función para crear MSI en tarjeta de crédito
DROP FUNCTION IF EXISTS crear_msi_tarjeta_credito;

CREATE OR REPLACE FUNCTION crear_msi_tarjeta_credito(
    p_usuario_id UUID,
    p_cuenta_id UUID,
    p_categoria_id UUID,
    p_nombre VARCHAR,
    p_descripcion TEXT,
    p_monto_total DECIMAL,
    p_numero_meses INTEGER,
    p_meses_ya_pagados INTEGER DEFAULT 0,
    p_monto_personalizado_por_mes DECIMAL DEFAULT NULL,
    p_iniciar_siguiente_periodo BOOLEAN DEFAULT FALSE
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_transaccion_periodica_id UUID;
    v_monto_mensual DECIMAL;
    v_saldo_pendiente DECIMAL;
    v_fecha_corte INTEGER;
    v_dia_pago INTEGER;
    v_fechas RECORD;
    v_proxima_fecha_corte DATE;
    v_meses_restantes INTEGER;
    v_fecha_ejecucion DATE;
    i INTEGER;
BEGIN
    -- Validaciones
    IF p_numero_meses <= 0 OR p_numero_meses > 48 THEN
        RAISE EXCEPTION 'El número de meses debe estar entre 1 y 48';
    END IF;
    
    IF p_meses_ya_pagados < 0 OR p_meses_ya_pagados >= p_numero_meses THEN
        RAISE EXCEPTION 'Los meses ya pagados deben ser menores al total de meses';
    END IF;
    
    -- Obtener día de corte de la tarjeta
    SELECT dia_corte INTO v_fecha_corte
    FROM cuentas
    WHERE id = p_cuenta_id AND creada_por = p_usuario_id AND tipo = 'credit_card';
    
    IF v_fecha_corte IS NULL THEN
        RAISE EXCEPTION 'La cuenta debe ser una tarjeta de crédito con día de corte configurado';
    END IF;
    
    -- Calcular monto mensual (personalizado o automático)
    IF p_monto_personalizado_por_mes IS NOT NULL AND p_monto_personalizado_por_mes > 0 THEN
        v_monto_mensual := p_monto_personalizado_por_mes;
    ELSE
        v_monto_mensual := ROUND(p_monto_total / p_numero_meses, 2);
    END IF;
    
    v_meses_restantes := p_numero_meses - p_meses_ya_pagados;
    
    -- REGLA DE NEGOCIO: Saldo pendiente = monto total - (meses ya pagados * cuota)
    -- Ejemplo: $1,000 a 10 meses = $100/mes
    -- Si ya pagué 3 meses: $1,000 - ($100 * 3) = $700 a descontar del crédito
    v_saldo_pendiente := p_monto_total - (p_meses_ya_pagados * v_monto_mensual);
    
    RAISE NOTICE '💰 Cálculo de deuda:';
    RAISE NOTICE '  Monto total: $%, Cuota: $%, Meses totales: %', p_monto_total, v_monto_mensual, p_numero_meses;
    RAISE NOTICE '  Meses ya pagados: %, Meses restantes: %', p_meses_ya_pagados, v_meses_restantes;
    RAISE NOTICE '  Saldo pendiente a descontar: $%', v_saldo_pendiente;
    
    -- Obtener día de pago de la tarjeta
    SELECT dia_pago INTO v_dia_pago
    FROM cuentas
    WHERE id = p_cuenta_id;
    
    -- Calcular fechas usando la función correcta
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(v_fecha_corte, v_dia_pago, CURRENT_DATE);
    
    RAISE NOTICE 'DEBUG crear_msi_tarjeta_credito:';
    RAISE NOTICE '  Fecha actual: %', CURRENT_DATE;
    RAISE NOTICE '  Dia corte: %, Dia pago: %', v_fecha_corte, v_dia_pago;
    RAISE NOTICE '  Periodo actual: % → %', v_fechas.periodo_actual_inicio, v_fechas.periodo_actual_fin;
    RAISE NOTICE '  Fecha corte actual: %', v_fechas.fecha_corte_actual;
    RAISE NOTICE '  Fecha corte siguiente: %', v_fechas.fecha_corte_siguiente;
    RAISE NOTICE '  Iniciar siguiente periodo: %', p_iniciar_siguiente_periodo;
    
    -- Determinar la fecha de inicio según si inicia en periodo actual o siguiente
    IF p_iniciar_siguiente_periodo THEN
        -- Iniciar en el siguiente periodo: usar fecha_corte_actual (próximo corte)
        v_proxima_fecha_corte := v_fechas.fecha_corte_actual;
        RAISE NOTICE '  ✅ Primera cuota para siguiente periodo: %', v_proxima_fecha_corte;
    ELSE
        -- Iniciar en el periodo actual: usar una fecha DENTRO del periodo actual
        -- Usamos periodo_actual_inicio que es el inicio del periodo que transcurre
        v_proxima_fecha_corte := v_fechas.periodo_actual_inicio;
        RAISE NOTICE '  ✅ Primera cuota para periodo actual: %', v_proxima_fecha_corte;
    END IF;
    
    -- Crear transacción periódica
    INSERT INTO transacciones_periodicas (
        usuario_id,
        nombre,
        descripcion,
        tipo,
        monto,
        frecuencia,
        criterio_fin,
        numero_total_repeticiones,
        repeticiones_completadas,
        es_msi,
        monto_total_msi,
        numero_meses_total,
        meses_pagados,
        monto_por_mes,
        cuenta_id,
        categoria_id,
        fecha_inicio,
        proxima_ejecucion,
        dia_del_mes,
        activa,
        requiere_confirmacion,
        auto_ejecutar
    ) VALUES (
        p_usuario_id,
        p_nombre,
        COALESCE(p_descripcion, 'Pago MSI a ' || p_numero_meses || ' meses'),
        'gasto',
        v_monto_mensual,
        'msi',
        'numero_repeticiones',
        p_numero_meses,
        p_meses_ya_pagados,
        TRUE,
        p_monto_total,
        p_numero_meses,
        p_meses_ya_pagados,
        v_monto_mensual,
        p_cuenta_id,
        p_categoria_id,
        v_proxima_fecha_corte,
        v_proxima_fecha_corte,
        v_fecha_corte,
        TRUE,
        FALSE, -- No requiere confirmación
        TRUE   -- Se ejecuta automáticamente
    ) RETURNING id INTO v_transaccion_periodica_id;
    
    -- NUEVO ENFOQUE: Crear transacciones reales para cada cuota MSI
    -- Esto permite queries simples por periodo y mejor trazabilidad
    DECLARE
        v_fecha_primera_cuota_no_pagada DATE;
        v_fecha_cuota DATE;
        v_estado_cuota VARCHAR(20);
        v_transaccion_id UUID;
    BEGIN
        -- Calcular la fecha de la primera cuota NO pagada
        IF p_iniciar_siguiente_periodo THEN
            -- Si inicia en siguiente periodo, la primera cuota no pagada es en fecha_corte_actual
            v_fecha_primera_cuota_no_pagada := v_fechas.fecha_corte_actual;
        ELSE
            -- Si inicia en periodo actual, la primera cuota no pagada es HOY (o inicio del periodo)
            v_fecha_primera_cuota_no_pagada := v_fechas.periodo_actual_inicio;
        END IF;
        
        RAISE NOTICE '  Primera cuota no pagada será: %', v_fecha_primera_cuota_no_pagada;
        
        FOR i IN 1..p_numero_meses LOOP
            -- Calcular fecha de esta cuota
            IF i <= p_meses_ya_pagados THEN
                -- Cuotas ya pagadas: colocar en el PASADO (meses antes de la primera no pagada)
                v_fecha_cuota := v_fecha_primera_cuota_no_pagada - ((p_meses_ya_pagados - i + 1) || ' months')::INTERVAL;
                v_estado_cuota := 'pagada';
            ELSE
                -- Cuotas no pagadas: calcular desde la primera cuota no pagada
                -- (i - p_meses_ya_pagados - 1) da: 0 para la primera, 1 para la segunda, etc.
                v_fecha_cuota := v_fecha_primera_cuota_no_pagada + ((i - p_meses_ya_pagados - 1) || ' months')::INTERVAL;
                
                -- Determinar el estado según el periodo
                IF v_fecha_cuota >= v_fechas.periodo_actual_inicio AND v_fecha_cuota <= v_fechas.periodo_actual_fin THEN
                    v_estado_cuota := 'pendiente_pago';
                ELSE
                    v_estado_cuota := 'programada';
                END IF;
            END IF;
            
            -- Crear transacción real para esta cuota MSI
            INSERT INTO transacciones (
                usuario_id,
                tipo,
                monto,
                fecha_ocurrencia,
                descripcion,
                cuenta_id,
                categoria_id,
                es_cuota_msi,
                msi_id,
                numero_cuota_msi,
                estado_msi
            ) VALUES (
                p_usuario_id,
                'gasto',
                v_monto_mensual,
                v_fecha_cuota,
                p_nombre || ' - Cuota ' || i || '/' || p_numero_meses,
                p_cuenta_id,
                p_categoria_id,
                TRUE,
                v_transaccion_periodica_id,
                i,
                v_estado_cuota
            ) RETURNING id INTO v_transaccion_id;
            
            RAISE NOTICE '  💳 Cuota % creada: fecha=%, estado=%, transaccion_id=%', 
                i, v_fecha_cuota, v_estado_cuota, v_transaccion_id;
        END LOOP;
    END;
    
    -- Actualizar contador de meses pagados si hay cuotas ya pagadas
    IF p_meses_ya_pagados > 0 THEN
        UPDATE transacciones_periodicas
        SET meses_pagados = p_meses_ya_pagados,
            repeticiones_completadas = p_meses_ya_pagados
        WHERE id = v_transaccion_periodica_id;
        
        RAISE NOTICE '  ✅ MSI actualizado: meses_pagados=%', p_meses_ya_pagados;
    END IF;
    
    -- Actualizar el crédito disponible de la tarjeta
    -- REGLA DE NEGOCIO: Descontar solo el saldo pendiente (monto total - meses pagados)
    -- Ejemplo: $1,000 total, 3 meses pagados de $100 = descontar $700
    UPDATE cuentas
    SET credito_disponible = credito_disponible - v_saldo_pendiente,
        fecha_actualizacion = NOW()
    WHERE id = p_cuenta_id;
    
    RAISE NOTICE '  ✅ Crédito disponible reducido: -$% (saldo pendiente)', v_saldo_pendiente;
    
    -- Recalcular el saldo del periodo actual para incluir la cuota de este mes
    PERFORM recalcular_saldo_en_corte(p_cuenta_id);
    
    RETURN v_transaccion_periodica_id;
END;
$$;

COMMENT ON FUNCTION crear_msi_tarjeta_credito IS 'OPCIÓN 1 HÍBRIDO: Crea un MSI con transacciones reales para cada cuota en la tabla transacciones. Descuenta del crédito disponible solo el saldo pendiente (monto total - meses pagados * cuota). Soporta iniciar en periodo actual o siguiente, y meses ya pagados.';


-- 9.3) Función para incrementar repeticiones completadas
CREATE OR REPLACE FUNCTION public.incrementar_repeticiones_completadas(
    p_transaccion_periodica_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE transacciones_periodicas
    SET repeticiones_completadas = COALESCE(repeticiones_completadas, 0) + 1,
        updated_at = NOW()
    WHERE id = p_transaccion_periodica_id;
END;
$$;

COMMENT ON FUNCTION public.incrementar_repeticiones_completadas IS 
'Incrementa el contador de repeticiones completadas de una transacción periódica';


-- 9.4) Función para calcular siguiente fecha basándose en frecuencia
-- Nota: Esta función SQL calcula la siguiente fecha basándose en la frecuencia
CREATE OR REPLACE FUNCTION public.calcular_siguiente_fecha(
    p_fecha_base TIMESTAMP WITH TIME ZONE,
    p_frecuencia frecuencia_transaccion,
    p_dia_especifico INTEGER DEFAULT NULL
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_siguiente_fecha TIMESTAMP WITH TIME ZONE;
BEGIN
    CASE p_frecuencia
        WHEN 'diaria' THEN
            v_siguiente_fecha := p_fecha_base + INTERVAL '1 day';
        
        WHEN 'semanal' THEN
            v_siguiente_fecha := p_fecha_base + INTERVAL '1 week';
        
        WHEN 'quincenal' THEN
            v_siguiente_fecha := p_fecha_base + INTERVAL '15 days';
        
        WHEN 'mensual' THEN
            IF p_dia_especifico IS NOT NULL THEN
                -- Ir al día específico del siguiente mes
                v_siguiente_fecha := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month' + 
                                     (p_dia_especifico - 1 || ' days')::INTERVAL)::TIMESTAMP WITH TIME ZONE;
            ELSE
                v_siguiente_fecha := p_fecha_base + INTERVAL '1 month';
            END IF;
        
        WHEN 'bimestral' THEN
            IF p_dia_especifico IS NOT NULL THEN
                v_siguiente_fecha := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '2 months' + 
                                     (p_dia_especifico - 1 || ' days')::INTERVAL)::TIMESTAMP WITH TIME ZONE;
            ELSE
                v_siguiente_fecha := p_fecha_base + INTERVAL '2 months';
            END IF;
        
        WHEN 'trimestral' THEN
            IF p_dia_especifico IS NOT NULL THEN
                v_siguiente_fecha := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '3 months' + 
                                     (p_dia_especifico - 1 || ' days')::INTERVAL)::TIMESTAMP WITH TIME ZONE;
            ELSE
                v_siguiente_fecha := p_fecha_base + INTERVAL '3 months';
            END IF;
        
        WHEN 'semestral' THEN
            IF p_dia_especifico IS NOT NULL THEN
                v_siguiente_fecha := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '6 months' + 
                                     (p_dia_especifico - 1 || ' days')::INTERVAL)::TIMESTAMP WITH TIME ZONE;
            ELSE
                v_siguiente_fecha := p_fecha_base + INTERVAL '6 months';
            END IF;
        
        WHEN 'anual' THEN
            IF p_dia_especifico IS NOT NULL THEN
                v_siguiente_fecha := (DATE_TRUNC('year', p_fecha_base) + INTERVAL '1 year' + 
                                     (p_dia_especifico - 1 || ' days')::INTERVAL)::TIMESTAMP WITH TIME ZONE;
            ELSE
                v_siguiente_fecha := p_fecha_base + INTERVAL '1 year';
            END IF;
        
        ELSE
            -- Para 'unica' o cualquier otro caso
            v_siguiente_fecha := NULL;
    END CASE;
    
    RETURN v_siguiente_fecha;
END;
$$;

COMMENT ON FUNCTION public.calcular_siguiente_fecha IS 
'Calcula la siguiente fecha de ejecución basándose en la frecuencia y día específico';


-- ==================================================================
-- 9b) Función para eliminar MSI correctamente
-- ==================================================================
DROP FUNCTION IF EXISTS eliminar_msi_tarjeta_credito(UUID, UUID);
CREATE OR REPLACE FUNCTION eliminar_msi_tarjeta_credito(
    p_usuario_id UUID,
    p_transaccion_periodica_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_msi RECORD;
BEGIN
    -- Obtener información del MSI
    SELECT 
        tp.*,
        c.id as cuenta_id,
        c.tipo as tipo_cuenta
    INTO v_msi
    FROM transacciones_periodicas tp
    INNER JOIN cuentas c ON c.id = tp.cuenta_id
    WHERE tp.id = p_transaccion_periodica_id
        AND tp.usuario_id = p_usuario_id
        AND tp.es_msi = TRUE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'MSI no encontrado o no tienes permisos para eliminarlo';
    END IF;
    
    IF v_msi.tipo_cuenta != 'credit_card' THEN
        RAISE EXCEPTION 'El MSI debe estar asociado a una tarjeta de crédito';
    END IF;
    
    -- Calcular saldo pendiente del MSI
    DECLARE
        v_saldo_pendiente_msi NUMERIC;
    BEGIN
        v_saldo_pendiente_msi := v_msi.monto_total_msi - (v_msi.meses_pagados * v_msi.monto_por_mes);
        
        RAISE NOTICE 'Eliminando MSI: %', v_msi.nombre;
        RAISE NOTICE '  Monto total: $%, Cuota: $%', v_msi.monto_total_msi, v_msi.monto_por_mes;
        RAISE NOTICE '  Meses totales: %, Meses pagados: %', v_msi.numero_meses_total, v_msi.meses_pagados;
        RAISE NOTICE '  Saldo pendiente calculado: $%', v_saldo_pendiente_msi;
        
        -- Restaurar el crédito disponible
        -- REGLA DE NEGOCIO: Restaurar solo el saldo pendiente (no el monto total)
        -- Ejemplo: $1,000 total, 3 meses pagados de $100 = restaurar $700
        UPDATE cuentas
        SET credito_disponible = credito_disponible + v_saldo_pendiente_msi,
            fecha_actualizacion = NOW()
        WHERE id = v_msi.cuenta_id;
        
        RAISE NOTICE '  ✅ Crédito disponible restaurado: +$%', v_saldo_pendiente_msi;
    END;
    
    -- OPCIÓN 1 (HÍBRIDO): Eliminar transacciones reales de las cuotas MSI
    -- Solo eliminamos las que NO están pagadas (programadas o pendientes)
    DELETE FROM transacciones
    WHERE msi_id = p_transaccion_periodica_id
        AND es_cuota_msi = TRUE
        AND estado_msi IN ('programada', 'pendiente_pago');
    
    RAISE NOTICE '  ✅ Transacciones MSI pendientes eliminadas';
    
    -- Eliminar la transacción periódica (control maestro)
    DELETE FROM transacciones_periodicas
    WHERE id = p_transaccion_periodica_id;
    
    -- Recalcular el saldo del periodo actual
    PERFORM recalcular_saldo_en_corte(v_msi.cuenta_id);
    
    RAISE NOTICE '✅ MSI eliminado correctamente';
    
    RETURN TRUE;
END;
$$;

COMMENT ON FUNCTION eliminar_msi_tarjeta_credito IS 'Elimina un MSI y restaura el crédito disponible de la tarjeta. Restaura solo el saldo pendiente (monto total - meses pagados * cuota). Elimina las transacciones reales de las cuotas pendientes.';


-- ==================================================================
-- CONFIRMACIÓN DE EJECUCIÓN
-- ==================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '✅ Archivo 08_funciones_msi_y_periodicas.sql ejecutado correctamente';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'Funciones y triggers creados:';
    RAISE NOTICE '  - actualizar_saldo_periodo_msi() + trigger';
    RAISE NOTICE '  - calcular_proxima_ejecucion()';
    RAISE NOTICE '  - crear_msi_tarjeta_credito()';
    RAISE NOTICE '  - incrementar_repeticiones_completadas()';
    RAISE NOTICE '  - calcular_siguiente_fecha()';
    RAISE NOTICE '  - eliminar_msi_tarjeta_credito()';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '';
END $$;
