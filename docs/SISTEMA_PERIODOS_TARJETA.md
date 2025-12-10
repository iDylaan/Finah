# Sistema de Gestión de Periodos de Tarjeta de Crédito

## 📋 Descripción

Sistema completo para gestionar periodos de tarjetas de crédito, permitiendo:

- ✅ **Visualizar gastos del periodo actual** (desde último corte hasta hoy)
- ✅ **Proyectar gastos del periodo siguiente** (gastos futuros registrados)
- ✅ **Registrar pagos que descuenten del periodo** (marca cuotas MSI como pagadas)
- ✅ **Cálculo automático de fechas** de corte y pago
- ✅ **Distribución inteligente de pagos** entre cuotas MSI pendientes

---

## 🚀 Migración de Base de Datos

### Paso 1: Ejecutar el Script SQL

Ejecuta el archivo `sql/6. periodos_tarjeta_credito.sql` en el editor SQL de Supabase:

```sql
-- Este archivo contiene 4 funciones principales:
-- 1. calcular_fechas_periodo_tarjeta()
-- 2. obtener_gastos_periodo_tarjeta()
-- 3. registrar_pago_periodo_tarjeta()
-- 4. obtener_resumen_periodos_tarjeta()
```

### Paso 2: Verificar la Instalación

```sql
-- Verificar que las funciones se crearon correctamente
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%periodo%tarjeta%';

-- Deberías ver:
-- - calcular_fechas_periodo_tarjeta
-- - obtener_gastos_periodo_tarjeta
-- - registrar_pago_periodo_tarjeta
-- - obtener_resumen_periodos_tarjeta
```

---

## 📚 Funciones SQL Creadas

### 1. `calcular_fechas_periodo_tarjeta()`

Calcula las fechas de inicio/fin de periodo actual y siguiente.

**Parámetros:**
- `p_dia_corte` (INTEGER): Día del mes en que corta la tarjeta (1-31)
- `p_dia_pago` (INTEGER): Días después del corte para pagar
- `p_fecha_referencia` (DATE): Fecha de referencia (default: HOY)

**Retorna:**
```sql
{
  periodo_actual_inicio,
  periodo_actual_fin,
  periodo_siguiente_inicio,
  periodo_siguiente_fin,
  fecha_corte_actual,
  fecha_pago_actual,
  fecha_corte_siguiente,
  fecha_pago_siguiente
}
```

**Ejemplo:**
```sql
SELECT * FROM calcular_fechas_periodo_tarjeta(11, 21, '2025-12-09');
```

---

### 2. `obtener_gastos_periodo_tarjeta()`

Obtiene gastos normales y cuotas MSI de un periodo específico.

**Parámetros:**
- `p_cuenta_id` (UUID): ID de la tarjeta de crédito
- `p_fecha_inicio` (DATE): Inicio del periodo
- `p_fecha_fin` (DATE): Fin del periodo

**Retorna:**
```sql
{
  total_gastos_normales,  -- Suma de gastos normales
  total_cuotas_msi,       -- Suma de cuotas MSI pendientes
  total_periodo,          -- Total a pagar en el periodo
  cuotas_msi              -- Array JSON con detalle de cuotas
}
```

**Ejemplo:**
```sql
SELECT * FROM obtener_gastos_periodo_tarjeta(
  '123e4567-e89b-12d3-a456-426614174000',
  '2025-11-12',
  '2025-12-11'
);
```

---

### 3. `registrar_pago_periodo_tarjeta()` ⭐

Registra un pago de tarjeta que automáticamente:
- Crea la transacción de pago
- Actualiza el crédito disponible
- Marca cuotas MSI del periodo como pagadas
- Incrementa contador de meses pagados en MSI
- Finaliza MSI cuando se completan todos los meses

**Parámetros:**
- `p_cuenta_tarjeta_id` (UUID): ID de la tarjeta
- `p_monto_pago` (NUMERIC): Monto del pago
- `p_categoria_id` (UUID): Categoría del pago
- `p_fecha_pago` (DATE): Fecha del pago
- `p_descripcion` (TEXT): Descripción opcional
- `p_tipo_pago` (TEXT): 'manual' o 'transfer'
- `p_cuenta_origen_id` (UUID): ID de cuenta origen (si es transfer)

**Retorna:**
- UUID de la transacción creada

**Ejemplo - Pago Manual:**
```sql
SELECT registrar_pago_periodo_tarjeta(
  p_cuenta_tarjeta_id := '123e4567-e89b-12d3-a456-426614174000',
  p_monto_pago := 5091.00,
  p_categoria_id := 'categoria-id-pagos',
  p_fecha_pago := '2025-12-09',
  p_descripcion := 'Pago periodo diciembre',
  p_tipo_pago := 'manual'
);
```

**Ejemplo - Pago desde Cuenta:**
```sql
SELECT registrar_pago_periodo_tarjeta(
  p_cuenta_tarjeta_id := '123e4567-e89b-12d3-a456-426614174000',
  p_monto_pago := 5091.00,
  p_categoria_id := 'categoria-id-pagos',
  p_fecha_pago := '2025-12-09',
  p_tipo_pago := 'transfer',
  p_cuenta_origen_id := 'cuenta-debito-id'
);
```

---

### 4. `obtener_resumen_periodos_tarjeta()`

Obtiene un resumen completo con ambos periodos (actual y siguiente).

**Parámetros:**
- `p_cuenta_id` (UUID): ID de la tarjeta

**Retorna JSON:**
```json
{
  "cuenta_id": "uuid",
  "limite_credito": 100000.00,
  "credito_disponible": 93118.75,
  "credito_utilizado": 6881.25,
  "fechas": {
    "periodo_actual": {
      "inicio": "2025-11-12",
      "fin": "2025-12-11",
      "fecha_corte": "2025-12-11",
      "fecha_pago": "2026-01-01"
    },
    "periodo_siguiente": {
      "inicio": "2025-12-12",
      "fin": "2026-01-11",
      "fecha_corte": "2026-01-11",
      "fecha_pago": "2026-02-01"
    }
  },
  "periodo_actual": {
    "gastos_normales": 3000.00,
    "cuotas_msi": 2091.00,
    "total": 5091.00,
    "cuotas_detalle": [...]
  },
  "periodo_siguiente": {
    "gastos_normales": 1500.00,
    "cuotas_msi": 2091.00,
    "total": 3591.00,
    "cuotas_detalle": [...]
  }
}
```

**Ejemplo:**
```sql
SELECT obtener_resumen_periodos_tarjeta('123e4567-e89b-12d3-a456-426614174000');
```

---

## 💻 Funciones Frontend (Store)

### `obtenerResumenPeriodosTarjeta(cuentaId)`

Obtiene el resumen completo de periodos desde el frontend.

```javascript
import { useAccountsStore } from '@/stores/accounts';

const accountsStore = useAccountsStore();

const resumen = await accountsStore.obtenerResumenPeriodosTarjeta(tarjetaId);

console.log('Periodo actual:', resumen.periodo_actual.total);
console.log('Periodo siguiente:', resumen.periodo_siguiente.total);
```

---

### `registrarPagoPeriodoTarjeta(pagoData, { toast })`

Registra un pago de tarjeta con actualización automática.

```javascript
await accountsStore.registrarPagoPeriodoTarjeta({
  cuenta_tarjeta_id: tarjetaId,
  monto_pago: 5091.00,
  categoria_id: categoriaId,
  fecha_pago: new Date(),
  descripcion: 'Pago periodo diciembre',
  tipo_pago: 'manual', // o 'transfer'
  cuenta_origen_id: null // solo si es 'transfer'
}, { toast });
```

---

## 🎨 Componentes Actualizados

### `CreditCardInfo.vue`

Ahora muestra:
- **Periodo Actual**: Saldo a pagar en este periodo
- **Periodo Siguiente**: Proyección de gastos futuros

```vue
<!-- Periodo Actual (verde) -->
<div class="p-2 bg-green-50 dark:bg-green-900/20">
  <div class="text-xs">Saldo del periodo actual</div>
  <div class="text-sm font-bold">$5,091.00</div>
</div>

<!-- Periodo Siguiente (azul) -->
<div class="p-2 bg-blue-50 dark:bg-blue-900/20">
  <div class="text-xs">Proyección periodo siguiente</div>
  <div class="text-sm font-bold">$3,591.00</div>
</div>
```

---

### `CreditCardPaymentModal.vue`

Ahora usa `registrarPagoPeriodoTarjeta()` que automáticamente:
1. Crea la transacción
2. Actualiza crédito disponible
3. Marca cuotas MSI como pagadas
4. Incrementa meses pagados en MSI

---

## 🔄 Flujo Completo de Pago

### 1. Usuario registra un pago de $5,091.00

```javascript
await accountsStore.registrarPagoPeriodoTarjeta({
  cuenta_tarjeta_id: 'tarjeta-oro-id',
  monto_pago: 5091.00,
  categoria_id: 'pagos-tarjeta-id',
  fecha_pago: '2025-12-09',
  tipo_pago: 'manual'
});
```

### 2. Sistema ejecuta automáticamente:

**a) Crea transacción de ingreso**
```sql
INSERT INTO transacciones (tipo, monto, cuenta_id, ...)
VALUES ('ingreso', 5091.00, 'tarjeta-oro-id', ...);
```

**b) Actualiza crédito disponible**
```sql
UPDATE cuentas
SET credito_disponible = credito_disponible + 5091.00
WHERE id = 'tarjeta-oro-id';
-- Antes: $93,118.75
-- Después: $98,209.75
```

**c) Marca cuotas MSI como pagadas**
```sql
-- Encuentra cuotas MSI del periodo con estado 'pendiente'
-- Marca cada cuota como 'ejecutada' hasta agotar el monto

UPDATE ejecuciones_transacciones_periodicas
SET estado = 'ejecutada',
    fecha_ejecutada = NOW(),
    monto_ejecutado = 2091.00
WHERE id = 'cuota-1-id';

-- Si el monto cubre más cuotas, continúa marcando...
```

**d) Incrementa meses pagados en MSI**
```sql
UPDATE transacciones_periodicas
SET meses_pagados = meses_pagados + 1
WHERE id = 'msi-samsung-id';
```

**e) Finaliza MSI si está completo**
```sql
-- Si meses_pagados >= numero_meses_total
UPDATE transacciones_periodicas
SET activa = FALSE,
    fecha_finalizacion = NOW()
WHERE id = 'msi-samsung-id'
  AND meses_pagados >= numero_meses_total;
```

### 3. Resultado Final

- ✅ Crédito disponible aumentado
- ✅ Cuotas MSI marcadas como pagadas
- ✅ Progreso de MSI actualizado (10/12 meses)
- ✅ Saldo del periodo actual se reduce
- ✅ Se muestra próximo saldo proyectado

---

## 📊 Ventajas del Nuevo Sistema

### ✅ **Gestión Automática**
No necesitas buscar y marcar manualmente las cuotas MSI, el sistema lo hace automáticamente.

### ✅ **Visibilidad de Periodos**
Ves tanto el periodo actual como la proyección del siguiente.

### ✅ **Distribución Inteligente**
El pago se distribuye automáticamente entre las cuotas MSI en orden cronológico.

### ✅ **Actualización en Cascada**
Un solo llamado actualiza:
- Transacciones
- Crédito disponible
- Cuotas MSI
- Contador de meses pagados
- Estado de finalización de MSI

### ✅ **Soporte para Transferencias**
Puedes pagar desde otra cuenta, creando automáticamente el egreso correspondiente.

---

## 🧪 Pruebas Recomendadas

### 1. Verificar cálculo de fechas
```sql
SELECT * FROM calcular_fechas_periodo_tarjeta(11, 21, CURRENT_DATE);
```

### 2. Ver gastos de periodo actual
```sql
SELECT * FROM obtener_gastos_periodo_tarjeta(
  'tu-tarjeta-id',
  '2025-11-12',
  '2025-12-11'
);
```

### 3. Registrar pago de prueba
```javascript
// Desde la UI, usar el botón "Realizar Pago"
// Ingresar monto: $5,091.00
// Verificar que:
// - Crédito disponible aumenta
// - Saldo del periodo disminuye
// - Cuotas MSI se marcan como pagadas
```

### 4. Verificar periodo siguiente
```javascript
// Registrar un gasto con fecha futura (después del próximo corte)
// Verificar que aparece en "Proyección periodo siguiente"
```

---

## 🐛 Solución de Problemas

### Error: "Usuario no autenticado"
**Causa**: No hay sesión activa de Supabase
**Solución**: Verificar que `auth.uid()` retorna un UUID válido

### Error: "Tarjeta de crédito no encontrada"
**Causa**: ID de tarjeta incorrecto o no pertenece al usuario
**Solución**: Verificar que el `cuenta_id` es correcto y `tipo = 'credit_card'`

### El saldo del periodo no disminuye
**Causa**: Las cuotas MSI no se están marcando como pagadas
**Solución**: Verificar que existen cuotas con estado 'pendiente' en el rango de fechas del periodo

### Periodo siguiente no muestra gastos
**Causa**: No hay gastos con `fecha_ocurrencia` después del próximo corte
**Solución**: Registrar gastos con fechas futuras para probar la proyección

---

## 📝 Notas Importantes

1. **Los pagos solo afectan el periodo actual**, no periodos pasados
2. **Las cuotas MSI se pagan en orden cronológico** (fecha_programada ASC)
3. **Un pago puede cubrir múltiples cuotas MSI** si el monto es suficiente
4. **Los gastos futuros** (después del corte) se contabilizan en el periodo siguiente
5. **Los MSI se finalizan automáticamente** cuando `meses_pagados >= numero_meses_total`

---

## 🎯 Próximos Pasos

1. ✅ Ejecutar migración SQL
2. ✅ Probar registro de pago
3. ✅ Verificar actualización de cuotas MSI
4. ✅ Registrar gastos futuros
5. ✅ Verificar proyección de periodo siguiente
6. 📝 Documentar en `LLM.md` (opcional)

---

## 🤝 Contribución

Si encuentras algún bug o tienes sugerencias de mejora, por favor:
1. Verifica los logs en la consola del navegador
2. Revisa los logs de Supabase SQL
3. Documenta el error y los pasos para reproducirlo

---

**¡Sistema de Periodos de Tarjeta completamente funcional! 🎉**
