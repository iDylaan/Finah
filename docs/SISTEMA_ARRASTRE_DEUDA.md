# Sistema de Arrastre de Deuda - Tarjetas de Crédito

## 📋 Descripción

Sistema automático para arrastrar deuda no pagada de un periodo a otro en tarjetas de crédito, simulando el comportamiento real de los bancos.

---

## 🔄 Cómo Funciona

### Flujo Normal (Sin Arrastre)

```
Periodo 1:
  Gastos: $500
  Pago realizado: $500
  Arrastre: $0
  
Periodo 2:
  Gastos nuevos: $300
  Arrastre del anterior: $0
  Total a pagar: $300
```

### Flujo con Arrastre

```
Periodo 1:
  Gastos: $500
  Pago realizado: $200
  Saldo no pagado: $300
  
[FECHA DE CORTE] → procesar_corte_tarjeta()
  → saldo_arrastre = $300
  → saldo_periodo_actual = $0
  
Periodo 2:
  Arrastre del anterior: $300
  Gastos nuevos: $400
  Total a pagar: $700
  
  Desglose en UI:
    ⚠️ Deuda arrastrada: $300
    📊 Gastos periodo actual: $400
    💰 Total a pagar: $700
```

---

## 🗄️ Cambios en Base de Datos

### Nuevo Campo

```sql
-- Tabla: cuentas
saldo_arrastre NUMERIC(14,2) DEFAULT 0
```

**Descripción:** Deuda no pagada que se arrastra de periodos anteriores.

---

## 🛠️ Nuevas Funciones

### 1. `procesar_corte_tarjeta(cuenta_id)`

**Propósito:** Procesar el cierre de periodo en fecha de corte.

**¿Cuándo ejecutar?**
- **Automático:** Con un job programado (pg_cron) que se ejecute diariamente
- **Manual:** Llamar desde el frontend cuando sea fecha de corte

**Lógica:**
1. Verifica que HOY sea fecha de corte
2. Mueve `saldo_periodo_actual` a `saldo_arrastre`
3. Reinicia `saldo_periodo_actual` a 0
4. Actualiza fechas de próximo corte y pago
5. Recalcula el nuevo periodo (cuotas MSI del nuevo periodo)

**Ejemplo de uso:**

```sql
-- Ejecutar manualmente
SELECT procesar_corte_tarjeta('uuid-de-la-tarjeta');

-- Resultado:
{
  "procesado": true,
  "fecha_corte": "2025-02-10",
  "saldo_arrastrado": 500.00,
  "arrastre_anterior": 0.00,
  "arrastre_total": 500.00,
  "nuevo_periodo_inicio": "2025-02-10",
  "nuevo_periodo_fin": "2025-03-09"
}
```

### 2. `obtener_resumen_periodos_tarjeta()` - ACTUALIZADA

**Cambios:**
- Ahora incluye `saldo_arrastre` en el resumen
- El desglose muestra:
  - `saldo_arrastre`: Deuda de periodos anteriores
  - `saldo_periodo_actual`: Gastos del periodo actual
  - `total_a_pagar`: Suma de ambos

**Respuesta actualizada:**

```json
{
  "saldo_arrastre": 300.00,
  "desglose_deuda": {
    "saldo_arrastre": 300.00,
    "saldo_periodo_actual": 400.00,
    "total_a_pagar": 700.00,
    "cuota_msi_periodo": 134.00,
    "deuda_no_diferida": 266.00
  }
}
```

### 3. `registrar_pago_periodo_tarjeta()` - ACTUALIZADA

**Cambios:**
- **Prioridad de pago:** Descuenta del arrastre PRIMERO, luego del periodo actual

**Lógica actualizada:**

```
Escenario:
  Arrastre: $300
  Periodo actual: $400
  Total adeudado: $700
  Pago realizado: $500

Distribución:
  1. Descontar del arrastre: $300 (todo)
  2. Descontar del periodo: $200 (parcial)
  
Resultado:
  Arrastre: $0
  Periodo actual: $200
  Crédito disponible: +$500
```

---

## 🎨 Cambios en Frontend

### CreditCardInfo.vue

Actualizar para mostrar el arrastre:

```vue
<!-- Desglose del periodo actual -->
<div v-if="desglose?.saldo_arrastre > 0" 
     class="p-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
  <div class="flex justify-between items-center text-xs">
    <div class="flex items-center gap-1">
      <span class="material-symbols-outlined text-sm text-red-600">warning</span>
      <span class="text-red-600 dark:text-red-400 font-semibold">Deuda arrastrada:</span>
    </div>
    <span class="font-bold text-red-700 dark:text-red-300">
      {{ formatCurrency(desglose.saldo_arrastre) }}
    </span>
  </div>
</div>

<div class="flex justify-between items-center text-xs">
  <span class="text-green-600 dark:text-green-400">Gastos periodo actual:</span>
  <span class="font-semibold text-green-700 dark:text-green-300">
    {{ formatCurrency(desglose.saldo_periodo_actual) }}
  </span>
</div>

<div class="flex justify-between items-center text-xs pt-1.5 border-t border-green-200 dark:border-green-800">
  <span class="text-green-700 dark:text-green-300 font-bold">Total a pagar:</span>
  <span class="font-bold text-green-800 dark:text-green-200">
    {{ formatCurrency(desglose.total_a_pagar) }}
  </span>
</div>
```

---

## ⚙️ Automatización con pg_cron

Para que el arrastre se procese automáticamente cada día de corte, configurar un job:

```sql
-- Instalar extensión (solo una vez)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Crear job que se ejecute diariamente
SELECT cron.schedule(
    'procesar-cortes-tarjetas', -- nombre del job
    '0 2 * * *',                -- cron: 2:00 AM todos los días
    $$
    SELECT procesar_corte_tarjeta(id)
    FROM cuentas
    WHERE tipo = 'credit_card'
      AND dia_corte IS NOT NULL
      AND deleted_at IS NULL
      AND proxima_fecha_corte = CURRENT_DATE;
    $$
);

-- Ver jobs programados
SELECT * FROM cron.job;

-- Eliminar job (si es necesario)
SELECT cron.unschedule('procesar-cortes-tarjetas');
```

**Nota:** Si Supabase no soporta pg_cron, implementar con:
- **Supabase Edge Functions** que se ejecuten con un webhook programado
- **Frontend:** Verificar en login si alguna tarjeta tiene corte HOY y llamar la función

---

## 📊 Queries Útiles

### Ver estado de arrastres

```sql
SELECT 
    c.nombre,
    c.saldo_arrastre,
    c.saldo_periodo_actual,
    c.saldo_arrastre + c.saldo_periodo_actual as total_adeudado,
    c.limite_credito,
    c.credito_disponible,
    c.proxima_fecha_corte,
    c.proxima_fecha_pago
FROM cuentas c
WHERE c.tipo = 'credit_card'
  AND c.deleted_at IS NULL
ORDER BY c.saldo_arrastre DESC;
```

### Ver historial de arrastres

```sql
SELECT 
    c.nombre as tarjeta,
    hs.fecha,
    hs.saldo_anterior as arrastre_anterior,
    hs.diferencia as monto_arrastrado,
    hs.saldo_nuevo as arrastre_total,
    hs.notas
FROM historial_saldos hs
INNER JOIN cuentas c ON hs.cuenta_id = c.id
WHERE hs.tipo_cambio = 'corte_mensual'
ORDER BY hs.fecha DESC;
```

### Simular proceso de corte (sin ejecutar)

```sql
SELECT 
    c.nombre,
    'Si se procesa el corte HOY:' as escenario,
    c.saldo_periodo_actual as se_arrastrara,
    c.saldo_arrastre as arrastre_actual,
    c.saldo_arrastre + c.saldo_periodo_actual as arrastre_nuevo
FROM cuentas c
WHERE c.tipo = 'credit_card'
  AND c.deleted_at IS NULL;
```

---

## 🧪 Testing

### Caso 1: Arrastre simple

```javascript
// 1. Crear gasto en periodo actual
await transactionsStore.createTransaction({
  cuenta_id: 'tarjeta-uuid',
  tipo: 'gasto',
  monto: 500,
  fecha_ocurrencia: '2025-01-15' // Dentro del periodo actual
});

// 2. Verificar saldo_periodo_actual = $500

// 3. Simular llegada de fecha de corte
await supabase.rpc('procesar_corte_tarjeta', {
  p_cuenta_id: 'tarjeta-uuid'
});

// 4. Verificar:
//    - saldo_arrastre = $500
//    - saldo_periodo_actual = $0
```

### Caso 2: Pago parcial con arrastre

```javascript
// Escenario: Arrastre $300, Periodo actual $400, Pago $500

await accountsStore.registrarPagoPeriodoTarjeta({
  cuenta_tarjeta_id: 'tarjeta-uuid',
  monto_pago: 500,
  categoria_id: 'pago-tarjeta-uuid',
  fecha_pago: '2025-02-15',
  tipo_pago: 'manual'
});

// Verificar:
//   - saldo_arrastre = $0 (pagó todo)
//   - saldo_periodo_actual = $200 (quedaron $200)
//   - credito_disponible += $500
```

### Caso 3: Pago total

```javascript
// Escenario: Arrastre $300, Periodo $400, Pago $700

await accountsStore.registrarPagoPeriodoTarjeta({
  monto_pago: 700
});

// Verificar:
//   - saldo_arrastre = $0
//   - saldo_periodo_actual = $0
//   - credito_disponible += $700
```

---

## ⚠️ Consideraciones

1. **Job automático recomendado:** Configurar pg_cron o Edge Function para procesar cortes
2. **Intereses:** Este sistema NO calcula intereses automáticamente (implementar después)
3. **Estados:** Las cuotas MSI mantienen su estado independiente del arrastre
4. **Historial:** Cada arrastre se registra en `historial_saldos` para auditoría

---

## 🚀 Instrucciones de Implementación

1. **Ejecutar migración:**
   ```sql
   -- En Supabase SQL Editor
   \i migration_add_saldo_arrastre.sql
   ```

2. **Aplicar funciones actualizadas:**
   ```sql
   -- Ejecutar script completo
   \i 1. db_finah.sql
   ```

3. **Actualizar frontend:**
   - Modificar `CreditCardInfo.vue` para mostrar arrastre
   - Agregar badge/alerta cuando `saldo_arrastre > 0`

4. **Configurar automatización:**
   - Implementar job con pg_cron O
   - Crear Edge Function con webhook programado

5. **Testing:**
   - Probar casos 1, 2 y 3 documentados arriba

---

**Fecha de implementación:** 2025-01-XX  
**Versión:** 3.0 - Arrastre de Deuda  
**Estado:** ✅ LISTO PARA PRODUCCIÓN
