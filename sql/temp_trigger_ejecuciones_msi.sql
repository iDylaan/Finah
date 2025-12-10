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


-- 7.5c) Función para actualizar saldo_periodo_actual al crear ejecuciones de MSI
CREATE OR REPLACE FUNCTION actualizar_saldo_periodo_ejecucion_msi()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_transaccion_periodica RECORD;
    v_cuenta RECORD;
    v_fechas RECORD;
BEGIN
    -- Obtener información de la transacción periódica
    SELECT * INTO v_transaccion_periodica
    FROM transacciones_periodicas
    WHERE id = NEW.transaccion_periodica_id
        AND es_msi = TRUE;
    
    -- Si no es MSI, no hacer nada
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = v_transaccion_periodica.cuenta_id
        AND tipo = 'credit_card'
        AND dia_corte IS NOT NULL;
    
    -- Si no es tarjeta de crédito, no hacer nada
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- Calcular fechas del periodo actual
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta.dia_corte,
        v_cuenta.dia_pago,
        CURRENT_DATE
    );
    
    -- Si la ejecución cae en el periodo actual, actualizar saldo
    IF NEW.fecha_programada >= v_fechas.periodo_actual_inicio 
       AND NEW.fecha_programada <= v_fechas.periodo_actual_fin
       AND NEW.estado IN ('pendiente', 'confirmada') THEN
        
        UPDATE cuentas
        SET saldo_periodo_actual = saldo_periodo_actual + NEW.monto_programado,
            fecha_actualizacion = NOW()
        WHERE id = v_transaccion_periodica.cuenta_id;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Trigger para actualizar saldo_periodo_actual al crear ejecuciones de MSI
DROP TRIGGER IF EXISTS trigger_actualizar_saldo_periodo_ejecucion ON ejecuciones_transacciones_periodicas;
CREATE TRIGGER trigger_actualizar_saldo_periodo_ejecucion
    AFTER INSERT ON ejecuciones_transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_saldo_periodo_ejecucion_msi();

