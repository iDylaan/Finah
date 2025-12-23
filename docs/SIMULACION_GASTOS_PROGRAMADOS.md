# Simulación de Gastos Programados en Tarjetas de Crédito

## Objetivo
Incluir una simulación de transacciones programadas (periódicas) que caerán dentro de cada periodo de la tarjeta de crédito, mostrando una proyección más precisa de los gastos.

## Cambios Necesarios

### 1. Función SQL: Calcular Transacciones Programadas en Periodo

Agregar esta nueva función en `sql/1. db_finah.sql` después de la línea 2420:

```sql
-- ========================================================================
-- FUNCIÓN: Calcular transacciones programadas que caerán en un periodo
-- ========================================================================
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
    -- Iterar sobre todas las transacciones periódicas activas de esta cuenta
    FOR v_transaccion IN
        SELECT 
            tp.id,
            tp.monto,
            tp.frecuencia,
            tp.dia_del_mes,
            tp.fecha_inicio,
            tp.criterio_fin,
            tp.fecha_fin,
            tp.numero_total_repeticiones,
            tp.repeticiones_completadas
        FROM transacciones_periodicas tp
        WHERE tp.cuenta_id = p_cuenta_id
            AND tp.activa = TRUE
            AND tp.tipo = 'gasto'  -- Solo gastos
            AND tp.requiere_confirmacion = FALSE  -- Solo las que no requieren confirmación
            AND tp.deleted_at IS NULL
    LOOP
        -- Calcular la próxima fecha de ejecución desde la fecha de inicio
        v_fecha_ejecucion := v_transaccion.fecha_inicio;
        v_contador := 0;
        
        -- Simular ejecuciones hasta encontrar las que caen en el periodo
        WHILE v_contador < 100 LOOP  -- Límite de seguridad
            -- Verificar si la fecha de ejecucion está dentro del periodo
            IF v_fecha_ejecucion >= p_fecha_inicio AND v_fecha_ejecucion <= p_fecha_fin THEN
                v_total_programado := v_total_programado + v_transaccion.monto;
            END IF;
            
            -- Calcular siguiente fecha según frecuencia
            v_fecha_ejecucion := calcular_siguiente_fecha(
                v_transaccion.frecuencia,
                v_fecha_ejecucion,
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
```

### 2. Modificar `obtener_resumen_periodos_tarjeta`

En la línea 2713, modificar la función para incluir gastos programados:

```sql
-- Después de la línea 2805 (justo después de calcular v_cuota_msi_siguiente), agregar:

    -- ===== NUEVO: Calcular transacciones programadas =====
    
    -- Gastos programados del periodo ACTUAL
    DECLARE
        v_gastos_programados_actual NUMERIC := 0;
        v_gastos_programados_siguiente NUMERIC := 0;
    BEGIN
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
    END;
    
    -- ===== FIN NUEVO =====
```

Luego, modificar el JSONB de respuesta (alrededor de la línea 2850):

```sql
-- Modificar 'desglose_deuda' para incluir gastos programados:
'desglose_deuda', JSONB_BUILD_OBJECT(
    'deuda_total', v_credito_utilizado,
    'deuda_no_diferida', v_deuda_no_diferida,
    'cuota_msi_periodo', v_cuota_msi_actual,
    'total_msi_pendiente', v_total_msi,
    'saldo_arrastre', v_cuenta.saldo_arrastre,
    'saldo_periodo_actual', v_cuenta.saldo_periodo_actual,
    'gastos_programados_periodo', v_gastos_programados_actual,  -- NUEVO
    'proyeccion_con_programados', v_cuenta.saldo_periodo_actual + v_gastos_programados_actual,  -- NUEVO
    'total_a_pagar', v_cuenta.saldo_arrastre + v_cuenta.saldo_periodo_actual
),

-- Modificar 'desglose_siguiente_periodo':
'desglose_siguiente_periodo', JSONB_BUILD_OBJECT(
    'cuota_msi_periodo', v_cuota_msi_siguiente,
    'gastos_futuros_registrados', v_periodo_siguiente.total_gastos_normales,
    'gastos_programados', v_gastos_programados_siguiente,  -- NUEVO
    'proyeccion_total', v_cuota_msi_siguiente + COALESCE(v_periodo_siguiente.total_gastos_normales, 0) + v_gastos_programados_siguiente  -- MODIFICADO
),
```

### 3. Actualizar `CreditCardInfo.vue`

En el template, agregar después de la línea 111 (en el desglose del periodo actual):

```vue
<div class="flex justify-between items-center text-xs">
    <span class="text-green-600 dark:text-green-400">Gastos del periodo:</span>
    <span class="font-semibold text-green-700 dark:text-green-300">
        {{ formatCurrency(desglose?.saldo_periodo_actual || 0) }}
    </span>
</div>

<!-- NUEVO: Mostrar gastos programados -->
<div v-if="desglose?.gastos_programados_periodo > 0" 
     class="flex justify-between items-center text-xs">
    <div class="flex items-center gap-1">
        <span class="material-symbols-outlined text-xs text-purple-600 dark:text-purple-400">
            event_repeat
        </span>
        <span class="text-purple-600 dark:text-purple-400">Gastos programados (simulación):</span>
    </div>
    <span class="font-semibold text-purple-700 dark:text-purple-300">
        {{ formatCurrency(desglose.gastos_programados_periodo) }}
    </span>
</div>

<!-- NUEVO: Proyección total con programados -->
<div v-if="desglose?.gastos_programados_periodo > 0"
     class="flex justify-between items-center text-xs pt-1 border-t border-green-200 dark:border-green-800">
    <span class="text-purple-700 dark:text-purple-300 font-semibold">Proyección con programados:</span>
    <span class="font-semibold text-purple-800 dark:text-purple-200">
        {{ formatCurrency(desglose.proyeccion_con_programados) }}
    </span>
</div>
<!-- FIN NUEVO -->
```

Y en el desglose del periodo siguiente (después de la línea 162):

```vue
<div class="flex justify-between items-center text-xs">
    <span class="text-blue-600 dark:text-blue-400">Gastos futuros registrados:</span>
    <span class="font-semibold text-blue-700 dark:text-blue-300">
        {{ formatCurrency(desgloseSiguiente?.gastos_futuros_registrados || 0) }}
    </span>
</div>

<!-- NUEVO: Gastos programados siguiente periodo -->
<div v-if="desgloseSiguiente?.gastos_programados > 0"
     class="flex justify-between items-center text-xs">
    <div class="flex items-center gap-1">
        <span class="material-symbols-outlined text-xs text-purple-600 dark:text-purple-400">
            event_repeat
        </span>
        <span class="text-purple-600 dark:text-purple-400">Gastos programados (simulación):</span>
    </div>
    <span class="font-semibold text-purple-700 dark:text-purple-300">
        {{ formatCurrency(desgloseSiguiente.gastos_programados) }}
    </span>
</div>
<!-- FIN NUEVO -->
```

## Resultado Esperado

Con estos cambios, la visualización de tarjetas de crédito mostrará:

### Periodo Actual:
- **Gastos del periodo**: Los gastos ya registrados
- **Gastos programados (simulación)**: Transacciones periódicas que caerán en este periodo
- **Proyección con programados**: Suma de ambos
- **Cuota MSI este periodo**: Pagos diferidos
- **Total a pagar**: Deuda total incluyendo arrastre

### Periodo Siguiente:
- **Cuota MSI siguiente periodo**: Pagos diferidos programados
- **Gastos futuros registrados**: Transacciones ya creadas para el futuro
- **Gastos programados (simulación)**: Transacciones periódicas calculadas
- **Proyección total**: Suma de todos los conceptos

## Notas Importantes

1. Solo se simulan transacciones con `requiere_confirmacion = FALSE`
2. La simulación usa la función `calcular_siguiente_fecha` que ya existe
3. El límite de 100 iteraciones previene loops infinitos
4. Los gastos programados se muestran en color púrpura para diferenciarlos de los gastos reales
5. Es una **simulación** - no afecta saldos reales hasta que las transacciones se ejecuten

## Próximos Pasos

1. Ejecutar el SQL para agregar la nueva función
2. Modificar `obtener_resumen_periodos_tarjeta` como se indica
3. Actualizar el componente `CreditCardInfo.vue`
4. Probar con tarjetas que tengan transacciones periódicas configuradas
