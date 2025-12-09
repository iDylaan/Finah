# Sistema de Transacciones Periódicas

## Descripción General

Sistema completo para manejar transacciones recurrentes, programadas y MSI (Meses Sin Intereses) con configuración avanzada de fechas y criterios de finalización.

## Características Principales

### ✅ Tipos de Frecuencia Soportados

1. **Diaria** - Todos los días
2. **Semanal** - Días específicos de la semana (lunes, martes, etc.)
3. **Quincenal** - Cada 15 días
4. **Mensual** - Día específico de cada mes (1-31)
5. **Bimestral** - Cada 2 meses
6. **Trimestral** - Cada 3 meses
7. **Semestral** - Cada 6 meses
8. **Anual** - Día y mes específico cada año
9. **Días Naturales** - Cada X días (ej: cada 30 días)
10. **MSI** - Meses Sin Intereses (auto-calcula en fechas de corte)
11. **Única** - Una sola vez en fecha futura

### ✅ Criterios de Finalización

1. **Sin Fin** - Se repite indefinidamente
2. **Fecha Fin** - Se repite hasta una fecha específica
3. **Número de Repeticiones** - Se repite X veces

### ✅ Configuración Avanzada

- **Para Mensual**: Especificar día del mes (1-31)
- **Para Semanal**: Seleccionar múltiples días (ej: lunes, miércoles, viernes)
- **Para Anual**: Especificar mes y día (ej: 15 de junio)
- **Para Días Naturales**: Intervalo personalizado (ej: cada 30 días)
- **Para MSI**: Auto-integración con fechas de corte de tarjetas

## Estructura de Tablas

### `transacciones_periodicas`

Tabla principal que almacena la configuración de cada transacción periódica.

**Campos principales:**
- `nombre`, `descripcion`, `tipo`, `monto`
- `frecuencia` - Tipo de recurrencia
- `criterio_fin` - Cómo determina cuándo terminar
- `fecha_inicio`, `fecha_fin`, `proxima_ejecucion`
- `activa`, `requiere_confirmacion`, `auto_ejecutar`

**Campos específicos por frecuencia:**
- `intervalo_dias` - Para 'dias_naturales'
- `dia_del_mes` - Para 'mensual', 'bimestral', etc.
- `dias_semana[]` - Para 'semanal'
- `mes_del_anio`, `dia_del_anio` - Para 'anual'

**Campos para MSI:**
- `es_msi` - Flag booleano
- `monto_total_msi` - Monto total de la compra
- `numero_meses_total` - Total de meses (3, 6, 9, 12, 18, 24)
- `meses_pagados` - Meses ya pagados (para MSI en progreso)
- `monto_por_mes` - Auto-calculado

### `ejecuciones_transacciones_periodicas`

Tabla que registra cada ejecución individual de una transacción periódica.

**Campos:**
- `transaccion_periodica_id` - Referencia a la transacción padre
- `transaccion_id` - Referencia a la transacción ejecutada (NULL si pendiente)
- `estado` - 'pendiente', 'confirmada', 'ejecutada', 'cancelada', 'fallida'
- `fecha_programada`, `fecha_ejecutada`, `fecha_confirmada`
- `monto_programado`, `monto_ejecutado`
- `numero_cuota` - Para MSI (1, 2, 3, etc.)

## Funciones SQL

### `calcular_proxima_ejecucion(p_transaccion_periodica_id, p_fecha_base)`

Calcula la próxima fecha de ejecución basándose en la configuración de frecuencia.

**Lógica por frecuencia:**
- **Diaria**: Siguiente día
- **Semanal**: Siguiente día que coincida con `dias_semana`
- **Quincenal**: +15 días
- **Mensual**: Mismo `dia_del_mes` del próximo mes
- **Anual**: Mismo `mes_del_anio` y `dia_del_anio` del próximo año
- **Días Naturales**: +`intervalo_dias` días
- **MSI**: Día de corte de la tarjeta del próximo mes

**Manejo de fechas inválidas:**
- Si el día no existe en el mes (ej: 31 de febrero), usa el último día del mes

### `crear_msi_tarjeta_credito(...)`

Crea automáticamente un MSI completo con todas sus ejecuciones programadas.

**Parámetros:**
- `p_usuario_id` - ID del usuario
- `p_cuenta_id` - ID de la tarjeta de crédito
- `p_categoria_id` - Categoría del gasto
- `p_nombre` - Nombre descriptivo
- `p_descripcion` - Descripción (opcional)
- `p_monto_total` - Monto total de la compra
- `p_numero_meses` - Total de meses (3, 6, 9, 12, 18, 24, etc.)
- `p_meses_ya_pagados` - Meses ya pagados (default: 0)

**Proceso:**
1. Valida que la cuenta sea tarjeta de crédito
2. Calcula monto mensual
3. Obtiene día de corte de la tarjeta
4. Crea registro en `transacciones_periodicas`
5. Crea N ejecuciones en `ejecuciones_transacciones_periodicas`
6. Retorna ID de la transacción periódica creada

## Ejemplos de Uso

### 1. Salario Quincenal (cada 15 del mes)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, dia_del_mes,
  criterio_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion, auto_ejecutar
) VALUES (
  'user-uuid', 'Salario', 'ingreso', 15000.00,
  'mensual', 15,
  'sin_fin',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  FALSE, TRUE
);
```

### 2. Renta Mensual (cada 1 del mes, hasta fin de año)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, dia_del_mes,
  criterio_fin, fecha_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion
) VALUES (
  'user-uuid', 'Renta', 'gasto', 8000.00,
  'mensual', 1,
  'fecha_fin', '2025-12-31',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  TRUE
);
```

### 3. Netflix (cada martes)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, dias_semana,
  criterio_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion, auto_ejecutar
) VALUES (
  'user-uuid', 'Netflix', 'gasto', 199.00,
  'semanal', ARRAY['martes']::dia_semana[],
  'sin_fin',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  FALSE, TRUE
);
```

### 4. Gym (cada 30 días naturales)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, intervalo_dias,
  criterio_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion
) VALUES (
  'user-uuid', 'Gimnasio', 'gasto', 500.00,
  'dias_naturales', 30,
  'sin_fin',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  TRUE
);
```

### 5. Cumpleaños (15 de junio cada año)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, mes_del_anio, dia_del_anio,
  criterio_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion
) VALUES (
  'user-uuid', 'Cumpleaños Mamá', 'gasto', 1000.00,
  'anual', 6, 15,
  'sin_fin',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  TRUE
);
```

### 6. MSI 12 Meses (ya van 4 pagados)

```sql
SELECT crear_msi_tarjeta_credito(
  'user-uuid',           -- usuario_id
  'tarjeta-uuid',        -- cuenta_id (tarjeta de crédito)
  'categoria-uuid',      -- categoria_id
  'iPhone 15 Pro',       -- nombre
  'Compra Apple Store',  -- descripcion
  24000.00,              -- monto_total
  12,                    -- numero_meses
  4                      -- meses_ya_pagados
);
```

### 7. Proyecto Temporal (10 pagos semanales)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, dias_semana,
  criterio_fin, numero_total_repeticiones,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion
) VALUES (
  'user-uuid', 'Proyecto Freelance', 'ingreso', 3000.00,
  'semanal', ARRAY['viernes']::dia_semana[],
  'numero_repeticiones', 10,
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  FALSE
);
```

### 8. Ahorro Mensual (hasta fin de año)

```sql
INSERT INTO transacciones_periodicas (
  usuario_id, nombre, tipo, monto,
  frecuencia, dia_del_mes,
  criterio_fin, fecha_fin,
  fecha_inicio, cuenta_id, categoria_id,
  requiere_confirmacion
) VALUES (
  'user-uuid', 'Ahorro Vacaciones', 'gasto', 2000.00,
  'mensual', 1,
  'fecha_fin', '2025-12-31',
  CURRENT_DATE, 'cuenta-uuid', 'categoria-uuid',
  TRUE
);
```

## Integración con Frontend

### Store: `recurring-transactions.js`

**Funciones disponibles:**
- `fetchRecurringTransactions()` - Obtener todas las transacciones periódicas
- `createMSI(msiData)` - Crear MSI usando la función SQL
- `createRecurringTransaction(data)` - Crear transacción periódica genérica
- `updateRecurringTransaction(id, updates)` - Actualizar
- `deleteRecurringTransaction(id)` - Eliminar
- `toggleRecurringTransaction(id)` - Pausar/reanudar
- `fetchPendingExecutions()` - Obtener ejecuciones pendientes
- `confirmExecution(id)` - Confirmar ejecución
- `cancelExecution(id)` - Cancelar ejecución

### Computed Properties:
- `msiTransactions` - Solo MSI
- `activeTransactions` - Solo activas
- `transactionsRequiringConfirmation` - Las que requieren confirmación

## Recomendaciones de Uso

### ✅ Usar MSI integrados (recomendado)

**Ventajas:**
- Sistema unificado para todo tipo de recurrencias
- Auto-cálculo en fechas de corte de tarjetas
- Tracking de cuotas parcialmente pagadas
- Sistema de confirmación/ejecución robusto

### ⚠️ Mantener `compras_msi` existentes (opcional)

**Opción 1 - Migración:**
- Migrar datos de `compras_msi` a `transacciones_periodicas`
- Deprecar tabla antigua
- Beneficio: un solo sistema

**Opción 2 - Coexistencia:**
- Usar `transacciones_periodicas` para nuevos MSI
- Mantener `compras_msi` para historial
- Beneficio: no rompe código existente

## Próximos Pasos

1. ✅ **Base de datos mejorada** - Completado
2. ⏳ **Store actualizado** - Pendiente actualizar para nuevos campos
3. ⏳ **Componente MSI** - Crear UI para configurar MSI
4. ⏳ **Componente de recurrencia avanzada** - UI para configurar todas las opciones
5. ⏳ **Vista de ejecuciones pendientes** - Dashboard de confirmaciones
6. ⏳ **Auto-ejecución** - Job/servicio para ejecutar transacciones automáticas

---

**Fecha de creación:** Diciembre 8, 2025  
**Versión:** 2.0 (Avanzada con criterios de finalización)
