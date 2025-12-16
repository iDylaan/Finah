# Migración MSI: Enfoque Híbrido (Opción 1)

## 📋 Resumen de Cambios

Se ha migrado el sistema MSI (Meses Sin Intereses) de un enfoque basado en **ejecuciones calculadas** a un **enfoque híbrido** que crea **transacciones reales** para cada cuota.

### ¿Por qué este cambio?

**Problema anterior:**
- Las cuotas MSI se calculaban dinámicamente desde `ejecuciones_transacciones_periodicas`
- Queries complejas con múltiples JOINs y filtros por estado
- Difícil de rastrear y pronosticar
- Gastos del periodo se registraban incorrectamente
- El forecast no funcionaba correctamente

**Solución (Opción 1 - Híbrido):**
- ✅ Cada cuota MSI es una transacción real en `transacciones`
- ✅ Queries simples por `fecha_ocurrencia` en el periodo
- ✅ Fácil rastreo del estado de cada cuota (`programada` → `pendiente_pago` → `pagada`)
- ✅ Funciona igual que un banco real
- ✅ Mantiene `transacciones_periodicas` como control maestro
- ✅ Sincronización bidireccional

---

## 🗄️ Cambios en Base de Datos

### 1. Nuevas Columnas en `transacciones`

```sql
-- Columnas agregadas:
es_cuota_msi BOOLEAN DEFAULT FALSE NOT NULL
msi_id UUID REFERENCES transacciones_periodicas(id) ON DELETE CASCADE
numero_cuota_msi INTEGER
estado_msi VARCHAR(20) CHECK (estado_msi IN ('programada', 'pendiente_pago', 'pagada', 'vencida'))

-- Índices agregados:
CREATE INDEX idx_transacciones_msi_id ON transacciones(msi_id) WHERE es_cuota_msi = TRUE;
CREATE INDEX idx_transacciones_periodo_msi ON transacciones(cuenta_id, fecha_ocurrencia, es_cuota_msi);
CREATE INDEX idx_transacciones_estado_msi ON transacciones(estado_msi) WHERE es_cuota_msi = TRUE;
```

### 2. Funciones Modificadas

#### ✅ `crear_msi_tarjeta_credito()`
- **Antes:** Creaba solo ejecuciones en `ejecuciones_transacciones_periodicas`
- **Ahora:** Crea transacciones reales en `transacciones` con:
  - `es_cuota_msi = TRUE`
  - `msi_id` apuntando al registro maestro
  - `numero_cuota_msi` (1, 2, 3, ...)
  - `estado_msi` según el periodo:
    - `pagada` → Cuotas de meses ya pagados
    - `pendiente_pago` → Cuota del primer periodo no pagado
    - `programada` → Cuotas futuras

#### ✅ `eliminar_msi_tarjeta_credito()`
- **Antes:** Eliminaba de `ejecuciones_transacciones_periodicas`
- **Ahora:** Elimina transacciones reales con `estado_msi IN ('programada', 'pendiente_pago')`
- Mantiene las cuotas `pagadas` para historial

#### ✅ `obtener_gastos_periodo_tarjeta()`
- **Antes:** Query compleja con JOINs a `ejecuciones_transacciones_periodicas`
- **Ahora:** Query simple:
  ```sql
  SELECT * FROM transacciones
  WHERE cuenta_id = X
    AND es_cuota_msi = TRUE
    AND fecha_ocurrencia BETWEEN periodo_inicio AND periodo_fin
  ```

#### ✅ `recalcular_saldo_en_corte()`
- **Antes:** Iteraba sobre `ejecuciones_transacciones_periodicas`
- **Ahora:** Query directa a `transacciones` con `es_cuota_msi = TRUE`

### 3. Trigger Deprecado

```sql
-- ❌ DEPRECADO: actualizar_saldo_periodo_ejecucion_msi()
-- Ya no se necesita porque recalcular_saldo_en_corte() consulta transacciones directamente
```

---

## 🔄 Flujo de Negocio

### Crear MSI con 6 meses, 2 ya pagados, iniciar siguiente periodo

**Input:**
- Monto total: $1,200
- Meses totales: 6
- Meses ya pagados: 2
- Cuota mensual: $200
- Iniciar siguiente periodo: SÍ

**Resultado en `transacciones`:**
```
Cuota 1: $200, fecha_ocurrencia = feb 10, estado_msi = 'pagada'
Cuota 2: $200, fecha_ocurrencia = mar 10, estado_msi = 'pagada'
Cuota 3: $200, fecha_ocurrencia = abr 10, estado_msi = 'pendiente_pago'  ← Primera del siguiente periodo
Cuota 4: $200, fecha_ocurrencia = may 10, estado_msi = 'programada'
Cuota 5: $200, fecha_ocurrencia = jun 10, estado_msi = 'programada'
Cuota 6: $200, fecha_ocurrencia = jul 10, estado_msi = 'programada'
```

**Crédito disponible:**
- Saldo pendiente = $1,200 - (2 * $200) = $800
- `credito_disponible -= $800`

### Consultar gastos de un periodo (ej: abr 10 - may 9)

**Query simple:**
```sql
SELECT * FROM transacciones
WHERE cuenta_id = 'xxx'
  AND fecha_ocurrencia BETWEEN '2024-04-10' AND '2024-05-09'
  AND es_cuota_msi = TRUE
```

**Resultado:**
```
Cuota 3: $200, estado = 'pendiente_pago'
```

---

## 📊 Comparación Antes vs Ahora

| Aspecto | ❌ Antes (Calculado) | ✅ Ahora (Híbrido) |
|---------|---------------------|-------------------|
| **Almacenamiento cuotas** | `ejecuciones_transacciones_periodicas` | `transacciones` (reales) |
| **Consulta periodo** | JOIN complejo con filtros estado | `WHERE fecha_ocurrencia BETWEEN` |
| **Estados** | `pendiente`, `confirmada`, `ejecutada` | `programada`, `pendiente_pago`, `pagada`, `vencida` |
| **Forecast** | ❌ No funciona | ✅ Funciona nativamente |
| **Complejidad queries** | Alta (múltiples JOINs) | Baja (tabla única) |
| **Mantenimiento** | Difícil (lógica dispersa) | Simple (todo en transacciones) |
| **Historial** | Difuso | Claro (transacciones con estado) |

---

## 🚀 Instrucciones de Ejecución

### 1. Backup de la Base de Datos
```bash
# En Supabase Dashboard → Database → Backups
# O usa pg_dump si tienes acceso directo
```

### 2. Ejecutar Script SQL
```bash
# Abrir Supabase SQL Editor
# Ejecutar el archivo: sql/1. db_finah.sql
```

### 3. Migrar MSI Existentes (si los hay)

Si tienes MSI creados con el sistema antiguo, ejecuta este script:

```sql
-- Script de migración de MSI existentes
DO $$
DECLARE
    v_msi RECORD;
    v_cuenta RECORD;
    v_fechas RECORD;
    v_fecha_cuota DATE;
    v_estado VARCHAR(20);
    i INTEGER;
BEGIN
    FOR v_msi IN
        SELECT *
        FROM transacciones_periodicas
        WHERE es_msi = TRUE
          AND activa = TRUE
    LOOP
        -- Obtener cuenta y fechas
        SELECT * INTO v_cuenta FROM cuentas WHERE id = v_msi.cuenta_id;
        SELECT * INTO v_fechas FROM calcular_fechas_periodo_tarjeta(
            v_cuenta.dia_corte,
            v_cuenta.dia_pago,
            CURRENT_DATE
        );
        
        -- Crear transacciones para cada cuota
        FOR i IN 1..v_msi.numero_meses_total LOOP
            -- Calcular fecha de la cuota
            v_fecha_cuota := v_msi.fecha_inicio + (i - 1) * INTERVAL '1 month';
            
            -- Determinar estado
            IF i <= v_msi.meses_pagados THEN
                v_estado := 'pagada';
            ELSIF v_fecha_cuota >= v_fechas.periodo_actual_inicio 
              AND v_fecha_cuota <= v_fechas.periodo_actual_fin THEN
                v_estado := 'pendiente_pago';
            ELSE
                v_estado := 'programada';
            END IF;
            
            -- Insertar transacción
            INSERT INTO transacciones (
                usuario_id,
                cuenta_id,
                categoria_id,
                tipo,
                monto,
                descripcion,
                fecha_ocurrencia,
                es_cuota_msi,
                msi_id,
                numero_cuota_msi,
                estado_msi
            ) VALUES (
                v_msi.usuario_id,
                v_msi.cuenta_id,
                v_msi.categoria_id,
                'gasto',
                v_msi.monto_por_mes,
                v_msi.descripcion || ' - Cuota ' || i || '/' || v_msi.numero_meses_total,
                v_fecha_cuota,
                TRUE,
                v_msi.id,
                i,
                v_estado
            );
        END LOOP;
        
        RAISE NOTICE 'MSI migrado: % (% cuotas)', v_msi.nombre, v_msi.numero_meses_total;
    END LOOP;
END $$;
```

### 4. Verificar Migración

```sql
-- Verificar que se crearon las transacciones MSI
SELECT 
    tp.nombre as msi_nombre,
    COUNT(t.id) as cuotas_creadas,
    tp.numero_meses_total as cuotas_esperadas,
    SUM(CASE WHEN t.estado_msi = 'pagada' THEN 1 ELSE 0 END) as pagadas,
    SUM(CASE WHEN t.estado_msi = 'pendiente_pago' THEN 1 ELSE 0 END) as pendientes,
    SUM(CASE WHEN t.estado_msi = 'programada' THEN 1 ELSE 0 END) as programadas
FROM transacciones_periodicas tp
LEFT JOIN transacciones t ON t.msi_id = tp.id
WHERE tp.es_msi = TRUE
GROUP BY tp.id, tp.nombre, tp.numero_meses_total;
```

---

## 🧪 Testing

### Caso 1: Crear MSI sin meses pagados, iniciar periodo actual
```javascript
await recurringTransactionsStore.createMSI({
    cuenta_id: 'tu-tarjeta-uuid',
    categoria_id: 'categoria-uuid',
    monto_total: 1200,
    numero_meses: 6,
    fecha_inicio: '2024-01-10',
    descripcion: 'iPhone 15',
    iniciar_siguiente_periodo: false,
    meses_ya_pagados: 0
});
```

**Verificar:**
- Crédito disponible reducido en $1,200
- 6 transacciones creadas
- Primera cuota con `estado_msi = 'pendiente_pago'`
- Resto con `estado_msi = 'programada'`

### Caso 2: Crear MSI con 2 meses pagados, iniciar siguiente periodo
```javascript
await recurringTransactionsStore.createMSI({
    monto_total: 1200,
    numero_meses: 6,
    meses_ya_pagados: 2,
    iniciar_siguiente_periodo: true
});
```

**Verificar:**
- Crédito disponible reducido en $800 (no $1,200)
- 6 transacciones creadas
- Primeras 2 con `estado_msi = 'pagada'`
- Tercera con `estado_msi = 'pendiente_pago'` (primera del siguiente periodo)
- Resto `programada`

### Caso 3: Consultar gastos de un periodo
```javascript
const gastos = await obtenerGastosPeriodo('2024-04-10', '2024-05-09');
console.log(gastos.cuotas_msi); // Solo cuota 3: $200
```

### Caso 4: Eliminar MSI con 2 meses pagados
```javascript
await recurringTransactionsStore.deleteRecurringTransaction(msi_id);
```

**Verificar:**
- Crédito disponible restaurado en $800 (no $1,200)
- Solo se eliminaron transacciones con estado `programada` y `pendiente_pago`
- Transacciones `pagadas` se mantienen para historial

---

## ⚠️ Puntos Importantes

1. **Transacciones MSI NO se pueden editar manualmente**
   - Son gestionadas automáticamente por el sistema
   - Solo se pueden eliminar a través de `eliminar_msi_tarjeta_credito()`

2. **Estados de cuotas MSI:**
   - `programada` → Cuota futura, no ha llegado su periodo
   - `pendiente_pago` → Cuota del periodo actual, esperando pago
   - `pagada` → Cuota ya pagada (se marca al cerrar periodo)
   - `vencida` → Cuota no pagada pasada su fecha (futuro)

3. **Crédito disponible:**
   - Se descuenta solo el saldo pendiente: `monto_total - (meses_pagados * cuota)`
   - Los pagos mensuales NO restauran crédito, solo cambian el estado de la cuota
   - El crédito se restaura SOLO al pagar la deuda completa en fecha de pago

4. **Sincronización:**
   - `transacciones_periodicas` es el registro maestro (control del MSI)
   - `transacciones` contiene las cuotas reales
   - Al eliminar `transacciones_periodicas`, se eliminan automáticamente sus `transacciones` (CASCADE)

---

## 📝 Próximos Pasos (Futuro)

1. **Automatización de estados:**
   - Crear job que cambie `programada` → `pendiente_pago` cuando llegue el periodo
   - Crear job que cambie `pendiente_pago` → `vencida` si pasa la fecha de pago

2. **Pagos parciales:**
   - Permitir marcar cuotas como `pagada` manualmente
   - Actualizar `meses_pagados` en `transacciones_periodicas`

3. **Reportes:**
   - Dashboard con MSI activos y sus estados
   - Gráfica de deuda diferida vs no diferida
   - Proyección de pagos futuros

---

## 🆘 Troubleshooting

### "No se calculan bien los gastos del periodo"
- Verificar que `obtener_gastos_periodo_tarjeta()` esté usando `transacciones` no `ejecuciones`
- Verificar que las fechas de las cuotas sean correctas

### "El crédito disponible no se actualiza"
- Revisar que `crear_msi` calcule correctamente el saldo pendiente
- Verificar que `eliminar_msi` restaure el saldo correcto

### "Las cuotas no aparecen en el periodo"
- Verificar `fecha_ocurrencia` de las transacciones MSI
- Verificar que `estado_msi` no sea `NULL`

### "Hay cuotas duplicadas"
- Eliminar manualmente: `DELETE FROM transacciones WHERE es_cuota_msi = TRUE AND msi_id = 'xxx'`
- Volver a crear el MSI

---

## ✅ Checklist de Migración

- [ ] Backup de base de datos creado
- [ ] Script SQL ejecutado sin errores
- [ ] Transacciones MSI existentes migradas (si aplica)
- [ ] Verificación de cuotas creadas (query de verificación)
- [ ] Test Caso 1: MSI sin meses pagados
- [ ] Test Caso 2: MSI con meses pagados
- [ ] Test Caso 3: Consultar gastos periodo
- [ ] Test Caso 4: Eliminar MSI
- [ ] Frontend muestra cuotas correctamente
- [ ] Crédito disponible se actualiza correctamente
- [ ] Forecast funciona correctamente

---

**Fecha de migración:** 2024-01-XX
**Versión:** 2.0 - Enfoque Híbrido (Opción 1)
**Estado:** ✅ COMPLETADO
