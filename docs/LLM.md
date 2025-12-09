# Contexto para LLM - Aplicación Finah

## Información General
- **Nombre**: Finah (FinaH)
- **Tipo**: Aplicación de gestión financiera personal
- **Stack Tecnológico**: Vue 3 (Composition API), PrimeVue, Tailwind CSS, Supabase
- **Arquitectura**: SPA con Vite como bundler

## Estructura del Proyecto

### Carpetas Principales
```
src/
├── assets/           # Estilos globales, constantes, imágenes
├── components/       # Componentes reutilizables
├── layout/          # Layout de la aplicación (Sidebar, Topbar, Footer)
├── lib/             # Utilidades (Supabase client, utils)
├── locale/          # Traducciones (español)
├── router/          # Vue Router
├── stores/          # Pinia stores (estado global)
├── views/           # Vistas/páginas principales
└── utils/           # Funciones auxiliares

public/
└── imgs/            # Recursos estáticos (logos SVG)

sql/                 # Scripts de base de datos Supabase
docs/                # Documentación del proyecto
```

## Arquitectura y Patrones

### Sistema de Temas
- **Framework**: PrimeVue con tema personalizable
- **Modos**: Claro y Oscuro
- **Implementación**: 
  - Store: `src/stores/ui.js` con `toggleDarkMode()` y `executeDarkModeToggle()`
  - Usa View Transitions API para animaciones suaves
  - Persistencia en localStorage
  - Variables CSS: `--p-primary-color`, `--p-surface-0` a `--p-surface-950`

### Gestión de Estado (Pinia Stores)
1. **accounts.js**: Gestión de cuentas financieras (ahorro, corriente, tarjetas de crédito)
   - `calcularGastosPeriodoActual()`: Calcula saldo del periodo incluyendo MSI pendientes
2. **categories.js**: Categorías de transacciones con grupos jerárquicos
3. **transactions.js**: Transacciones (ingresos, gastos, transferencias)
   - `deleteTransaction()`: Eliminar transacciones (usado al convertir a MSI)
4. **recurring-transactions.js**: Sistema de transacciones periódicas y MSI
   - **Transacciones Periódicas**:
     - `fetchRecurringTransactions()`: Obtener todas las transacciones periódicas
     - `createRecurringTransaction(data)`: Crear transacción periódica genérica
     - `updateRecurringTransaction(id, updates)`: Actualizar configuración
     - `deleteRecurringTransaction(id)`: Eliminar transacción periódica
     - `toggleRecurringTransaction(id)`: Pausar/reanudar transacción
   - **MSI (Meses Sin Intereses)**:
     - `createMSI(msiData)`: Crear MSI usando RPC `crear_msi_tarjeta_credito`
     - `updateMSIPaidMonths(msiId, mesesPagados)`: Actualizar meses pagados (bidireccional)
   - **Ejecuciones**:
     - `fetchPendingExecutions()`: Obtener ejecuciones pendientes
     - `confirmExecution(id)`: Confirmar ejecución programada
     - `cancelExecution(id)`: Cancelar ejecución programada
   - `deleteRecurringTransaction(id)`: Eliminar transacción periódica
   - `toggleRecurringTransaction(id)`: Pausar/reanudar
   - `fetchPendingExecutions()`: Obtener ejecuciones pendientes
   - `confirmExecution(id)`: Confirmar ejecución manual
   - `cancelExecution(id)`: Cancelar ejecución específica
   - Computed: `msiTransactions`, `activeTransactions`, `transactionsRequiringConfirmation`
5. **session.js**: Autenticación y sesión de usuario (Supabase Auth)
6. **ui.js**: Estado de UI (tema, sidebar, mobile detection)
7. **ui-modals.js**: Control de modales y preselecciones
   - `categoryGroupModal`: Estado del modal de grupos de categorías
   - `categoryModal`: Estado del modal de categorías individuales
   - `openCategoryGroupModal()`: Abrir modal de creación/edición de grupo
   - `openNewCategoryModal(groupId)`: Abrir modal para nueva categoría en grupo
   - `closeCategoryGroupModal()`: Cerrar modal de grupo
   - `closeCategoryModal()`: Cerrar modal de categoría
   - Gestión de `preselectedAccountId` para transferencias

### Sistema de Transacciones

#### Tipos de Transacciones
- **Ingreso**: Entrada de dinero a una cuenta
- **Gasto**: Salida de dinero de una cuenta
- **Transferencia**: Movimiento entre cuentas propias
  - 4 escenarios para tarjetas de crédito:
    1. Transferencia normal entre cuentas regulares
    2. De tarjeta crédito → otra cuenta (reduce deuda)
    3. De cuenta regular → tarjeta crédito (pago de deuda)
    4. Entre tarjetas de crédito (transferencia de deuda)

#### Características Especiales
- **Tarjetas de Crédito**:
  - Modal de pago específico (`CreditCardPaymentModal.vue`)
  - Dos modos: Manual (ingreso directo) o Transferencia (desde otra cuenta)
  - Botones rápidos: Pago Mínimo, Pago Total, Personalizado
  - Validación: monto ≤ saldo pendiente, fondos suficientes
- **Transferencias con Preselección**:
  - Desde menú de cuenta se puede iniciar transferencia con origen preseleccionado
  - Store `ui-modals.js` maneja `preselectedAccountId`

### Componentes Globales Importantes

#### CategoryPicker.vue
- Selector de categorías con grupos jerárquicos
- Props: modelValue, categoryGroups, label, placeholder, required, error, hint
- Muestra iconos y colores de grupo
- Indentación (pl-5) para categorías dentro de grupos
- Usado en: IngresoForm, GastoForm, TransferenciaForm, CreditCardPaymentModal

#### PageLayout.vue
- Layout wrapper para vistas principales
- Props: title, showBackButton, backRoute
- Provee estructura consistente

#### Modales
Todos los modales implementan:
- Responsive con breakpoints: `{ '768px': '100vw' }`
- Mobile: 100vw x 100vh (pantalla completa)
- Desktop: maxWidth específico (28rem - 42rem)
- Clase: `mobile-fullscreen-dialog`
- contentStyle: `maxHeight: calc(100vh - 120px)`, overflowY: auto

### Dashboard y Estadísticas

**Dashboard.vue** muestra:
- Balance total de todas las cuentas
- Estadísticas: totalIngresos, totalGastos (incluye transferencias), balance
- Gráficos:
  - Gastos por categoría (incluye tipo 'transferencia')
  - Balance mensual (incluye transferencias en gastos)
  - Evolución del balance (transferencias restan del balance)

### Sistema de Autenticación

**Auth.vue**:
- Dos versiones: Mobile y Desktop
- Mobile: Layout vertical con header, tabs, formulario
- Desktop: Card centrada con gradiente de borde primario
- Logo: Isotipo SVG con color primario (`var(--p-primary-color)`)
- Toggle de tema: Botón sol/luna en esquina superior derecha (desktop) y header (mobile)
- Componentes: Signin.vue, Signup.vue

### Estilos y Diseño

#### Variables de Color Surface
- `--p-surface-0`: Fondo más claro (blanco en light mode)
- `--p-surface-50` a `--p-surface-950`: Escala de grises
- `--p-surface-900`: Texto oscuro (light mode)
- Adaptación automática con clase `.dark`

#### SVG y Assets
- **Logo**: `public/imgs/FinahLogo.svg` (texto "Fina" + isotipo)
- **Isotipo**: `public/imgs/FinahIsotipo.svg` (solo símbolo gráfico)
- Ambos usan `fill="var(--p-primary-color)"` para adaptarse al tema
- No usar `<style>` tags dentro de SVG inline en Vue (causa errores)

#### Tailwind + PrimeVue
- Tailwind para utilities
- PrimeVue para componentes (Button, Dialog, Dropdown, etc.)
- SCSS global en `src/assets/styles.scss`
- Layout específico en `src/assets/layout/`

### Base de Datos (Supabase)

#### Tablas Principales
- **profiles**: Perfiles de usuario
- **cuentas**: Cuentas financieras
- **categorias**: Categorías de transacciones
- **grupo_categorias**: Grupos de categorías
- **transacciones**: Registro de transacciones
- **transacciones_periodicas**: Plantillas de transacciones recurrentes/programadas
- **ejecuciones_transacciones_periodicas**: Historial de ejecuciones de transacciones periódicas
- **bancos**: Catálogo de instituciones financieras
- **niveles_cuentas**: Niveles/carpetas para organizar cuentas

#### Políticas RLS
- Row Level Security habilitado
- Políticas por usuario (user_id = auth.uid())
- Scripts en `sql/2. db_policies.sql`

#### Scripts de Base de Datos

**Orden de Ejecución (CRÍTICO)**:
```sql
-- 1. Estructura completa de la base de datos
-- Ejecutar: sql/1. db_finah.sql
-- Contiene: DROP de tablas/tipos, CREATE de tipos ENUM, tablas y funciones
-- Importante: Incluye sistema de transacciones periódicas integrado

-- 2. Políticas de seguridad (RLS)
-- Ejecutar: sql/2. db_policies.sql
-- Contiene: ALTER TABLE ENABLE RLS + políticas para todas las tablas

-- 3. Datos iniciales públicos
-- Ejecutar: sql/3. finah_carga_inicial.sql
-- Contiene: INSERT de niveles, categorías, bancos predefinidos
```

**Proceso de Rollback Completo**:
1. Los scripts están diseñados para **rollback completo automático**
2. El archivo `1. db_finah.sql` comienza con `DROP TABLE IF EXISTS ... CASCADE`
3. Elimina todos los tipos ENUM con `DROP TYPE IF EXISTS ... CASCADE`
4. Al ejecutar los 3 scripts en orden, se recrea toda la BD desde cero
5. ⚠️ **ADVERTENCIA**: Esto elimina TODOS los datos existentes irreversiblemente

**Documentación de Rollback**: Ver `sql/ROLLBACK_Y_RECREACION.md` para guía detallada

**Métodos de Ejecución**:

1. **Supabase SQL Editor** (Recomendado):
   - Dashboard → SQL Editor → New Query
   - Copiar y pegar contenido completo de cada archivo
   - Ejecutar en orden: 1 → 2 → 3
   
2. **psql (Terminal)**:
   ```bash
   psql -h db.xxxxxxxxxxxx.supabase.co -p 5432 -d postgres -U postgres
   \i "1. db_finah.sql"
   \i "2. db_policies.sql"
   \i "3. finah_carga_inicial.sql"
   ```

3. **Script Único Concatenado**:
   ```powershell
   # PowerShell
   Get-Content "1. db_finah.sql", "2. db_policies.sql", "3. finah_carga_inicial.sql" | Set-Content "0. db_completa.sql"
   ```

**Verificación Post-Ejecución**:
```sql
-- Verificar tablas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- Verificar tipos ENUM
SELECT typname FROM pg_type 
WHERE typnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND typtype = 'e' ORDER BY typname;

-- Verificar funciones
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' ORDER BY routine_name;

-- Verificar RLS activo
SELECT tablename, rowsecurity FROM pg_tables 
WHERE schemaname = 'public' ORDER BY tablename;

-- Verificar datos iniciales
SELECT COUNT(*) FROM niveles WHERE es_publico = TRUE; -- Expect: 3
SELECT COUNT(*) FROM categorias WHERE es_publico = TRUE; -- Expect: ~45
SELECT COUNT(*) FROM bancos WHERE es_publico = TRUE; -- Expect: ~15
```

### Buenas Prácticas del Proyecto

1. **Componentes Reutilizables**: Extraer lógica duplicada (ej: CategoryPicker)
2. **Mobile First**: Todos los modales deben ser fullscreen en mobile
3. **Tema Consistente**: Usar variables CSS de PrimeVue, no colores hardcoded
4. **Validaciones**: Siempre validar en frontend antes de enviar a Supabase
5. **Feedback Visual**: Toasts para confirmaciones/errores
6. **Accesibilidad**: Tooltips, labels, aria-attributes
7. **Jerarquía Visual**: Indentación (pl-5) para elementos anidados

### Funcionalidades Recientes Implementadas

1. **Transferencias desde Menú de Cuenta**: 
   - Opción en menú contextual de cuenta
   - Abre modal con cuenta origen preseleccionada

2. **Pagos de Tarjetas de Crédito**:
   - Modal especializado con dos modos (manual/transferencia)
   - Botones de pago rápido
   - Validaciones específicas para tarjetas

3. **Dashboard Mejorado**:
   - Ahora incluye transferencias como gastos en todas las estadísticas
   - Gráficos actualizados para reflejar transferencias

4. **CategoryPicker Global**:
   - Componente extraído y reutilizable
   - Elimina ~320 líneas de código duplicado

5. **Modales Mobile-First**:
   - Todos los modales ahora son fullscreen en mobile (<768px)
   - CSS global en styles.scss para `.mobile-fullscreen-dialog`

6. **Toggle de Tema en Auth**:
   - Botón sol/luna en páginas de login/signup
   - Disponible antes de iniciar sesión
   - Usa View Transitions API

7. **Sistema de Modales Globales** (Diciembre 2024):
   - Store `ui-modals.js` para gestión centralizada de modales
   - `GlobalCategoryGroupModal.vue` y `GlobalCategoryModal.vue`
   - Modales reutilizables sin necesidad de navegación con router
   - Integrado en CategoryPicker para creación rápida de categorías/grupos
   - Solución a problemas de timing con nextTick() para asegurar actualización del DOM

8. **Corrección de Lógica de Fechas en Tarjetas de Crédito** (Diciembre 2024):
   - Función `calcularFechasAutomaticas()` en AccountForm.vue
   - Lógica: Si día_pago < día_corte → fecha_pago es del mes siguiente
   - Ejemplo: Corte=25, Pago=10 → Pago es el 10 del mes siguiente al corte

9. **Sistema de Transacciones Periódicas/Programadas** (Diciembre 2024):
   - **Tablas nuevas**:
     - `transacciones_periodicas`: Configuración de recurrencias
     - `ejecuciones_transacciones_periodicas`: Tracking de ejecuciones
   - **Tipos ENUM nuevos**:
     - `dia_semana`: 'lunes', 'martes', 'miercoles', etc.
     - `frecuencia_transaccion`: 11 frecuencias (diaria, semanal, mensual, MSI, días naturales, etc.)
     - `criterio_finalizacion`: 'sin_fin', 'fecha_fin', 'numero_repeticiones'
   - **Funciones SQL**:
     - `calcular_proxima_ejecucion()`: Calcula siguiente fecha según frecuencia
     - `crear_msi_tarjeta_credito()`: Crea MSI completo con ejecuciones automáticas
   - **Store**: `recurring-transactions.js` con funciones CRUD completas
   - **Configuración avanzada**:
     - Mensual: Día específico del mes (1-31)
     - Semanal: Múltiples días (ej: lunes, miércoles, viernes)
     - Anual: Mes y día específico
     - Días naturales: Intervalo personalizado (ej: cada 30 días)
     - MSI: Auto-integración con fechas de corte de tarjetas
   - **Casos de uso soportados**:
     - Ingresos periódicos (salario quincenal, mensual)
     - Gastos recurrentes (renta, suscripciones, servicios)
     - MSI con tracking de cuotas (nuevos o en progreso)
     - Transferencias programadas
     - Metas de ahorro con límites temporales
   - **Documentación**: `docs/TRANSACCIONES_PERIODICAS.md`

10. **Expansión Completa de Keywords de Iconos** (Diciembre 2024):
   - PrimeIcons: 313 iconos con palabras clave en español
   - Material Icons: 240+ iconos con keywords bilingües
   - Búsqueda mejorada en IconPicker por keywords en español
   - Archivo: `src/assets/constants/icon-keywords.js`

### Problemas Comunes y Soluciones

**Error: "Tags with side effect are ignored"**
- Solución: No usar `<style>` tags dentro de SVG inline en Vue
- Usar atributos `fill`, `stroke` directamente o `currentColor`

**SVGs no cambian de color con tema**
- Solución: Usar `var(--p-primary-color)` o `var(--p-surface-XXX)` en atributo `fill`
- Alternativamente: `fill="currentColor"` y controlar color con clase del elemento padre

**Modal no fullscreen en mobile**
- Solución: Agregar breakpoints `{ '768px': '100vw' }` y clase `mobile-fullscreen-dialog`

**Categorías sin jerarquía visual**
- Solución: Usar `pl-5` en opciones de categorías, no en grupos

**Modales no se muestran en CategoryPicker u otros componentes**
- Problema: Timing de Vue - el modal intenta abrirse antes de que el DOM se actualice
- Solución: Usar `nextTick()` antes de mostrar el modal
  ```javascript
  import { nextTick } from 'vue'
  
  const handleAction = async () => {
    await nextTick()
    modalsStore.openCategoryModal()
  }
  ```

**Modales se auto-abren al recargar página**
- Problema: Query params en URL persisten y triggean modales en `onMounted`
- Solución: Eliminar lógica de query params de `onMounted`, usar solo eventos de usuario

**Error en cálculo de fechas de tarjetas de crédito**
- Problema: Fecha de pago calculada incorrectamente cuando es menor al día de corte
- Solución: Comparar día de pago vs día de corte
  ```javascript
  if (diaPago < diaCorte) {
    // Fecha de pago es del mes SIGUIENTE al corte
    fechaPago = (mesDeCorte + 1) + '-' + diaPago
  }
  ```

**Transacciones periódicas no calculan próxima ejecución correctamente**
- Problema: Lógica manual de cálculo de fechas propensa a errores
- Solución: Usar función SQL `calcular_proxima_ejecucion(transaccion_id, fecha_base)`
  - Maneja todos los casos: diaria, semanal, mensual, MSI, días naturales, anual
  - Considera meses con menos días (ej: 31 en febrero → último día del mes)
  - Valida criterios de finalización automáticamente

### Comandos Útiles

```bash
# Desarrollo
npm run dev

# Build
npm run build

# Preview
npm run preview

# Linting
npm run lint
```

### Notas para Futuras Conversaciones

- El proyecto está en español (UI, comentarios, documentación)
- Se prefiere usar Composition API sobre Options API
- Evitar crear archivos .md de resumen a menos que se solicite explícitamente
- Usar `multi_replace_string_in_file` para ediciones múltiples (eficiencia)
- Siempre incluir 3-5 líneas de contexto en replacements para evitar ambigüedad
- No anunciar qué herramienta se está usando (transparencia para el usuario)

#### Arquitectura de Modales Globales
- Los modales reutilizables (categorías, grupos) deben estar en componentes wrapper globales
- Los wrappers se registran en `App.vue` para estar disponibles en toda la app
- El store `ui-modals.js` maneja el estado (visible, modo edición, IDs)
- Componentes individuales llaman a métodos del store, NO usan `router.push()`
- Ventaja: Evita navegación innecesaria, mejor UX, menos complejidad

#### Sistema de Transacciones Periódicas y MSI

##### Arquitectura General
El sistema maneja DOS tipos de transacciones automáticas de forma **complementaria pero independiente**:

1. **MSI (Meses Sin Intereses)** - Específico para tarjetas de crédito
2. **Transacciones Periódicas** - Para cualquier recurrencia (suscripciones, nómina, servicios)

##### Tablas Principales
```sql
-- Tabla principal que almacena AMBOS tipos
transacciones_periodicas (
  -- Campos comunes
  id, usuario_id, nombre, descripcion, tipo, monto,
  frecuencia, criterio_fin, activa,
  cuenta_id, categoria_id, 
  fecha_inicio, proxima_ejecucion,
  
  -- Específicos para MSI
  es_msi BOOLEAN,                    -- TRUE = MSI, FALSE = recurrencia normal
  monto_total_msi DECIMAL,           -- Monto total de la compra
  numero_meses_total INTEGER,        -- 3, 6, 9, 12, 18, 24 meses
  meses_pagados INTEGER,             -- Meses ya completados
  monto_por_mes DECIMAL,             -- Cuota mensual (puede ser personalizada)
  
  -- Configuración de recurrencia (para NO-MSI)
  intervalo_dias INTEGER,            -- Para 'dias_naturales'
  dia_del_mes INTEGER,               -- Para 'mensual'
  dias_semana dia_semana[],          -- Para 'semanal'
  mes_del_anio INTEGER,              -- Para 'anual'
  
  -- Control de ejecución
  requiere_confirmacion BOOLEAN,     -- FALSE para MSI, TRUE para otros
  auto_ejecutar BOOLEAN              -- TRUE para MSI, FALSE para otros
)

-- Tabla que registra cada ejecución individual
ejecuciones_transacciones_periodicas (
  id, transaccion_periodica_id, transaccion_id,
  estado VARCHAR(20),                -- 'pendiente', 'ejecutada', 'confirmada', 'cancelada'
  fecha_programada DATE,
  fecha_ejecutada TIMESTAMP,
  monto_programado DECIMAL,
  monto_ejecutado DECIMAL,
  numero_cuota INTEGER,              -- Número de cuota (para MSI)
  notas TEXT
)
```

##### 1. Sistema MSI (Meses Sin Intereses)

**Propósito**: Seguimiento de compras diferidas en tarjetas de crédito

**Características**:
- Se ejecuta automáticamente según el día de corte de la tarjeta
- NO requiere confirmación manual del usuario
- Soporta registro de meses ya pagados (para compras previas al sistema)
- Permite montos personalizados por cuota (automático, redondeado, manual)
- Actualización bidireccional de meses pagados (aumentar/disminuir)

**Creación** (usando función SQL):
```javascript
// Frontend: src/stores/recurring-transactions.js
const createMSI = async (msiData) => {
  const params = {
    p_usuario_id: userId,
    p_cuenta_id: msiData.cuenta_id,           // Tarjeta de crédito
    p_categoria_id: msiData.categoria_id,
    p_nombre: msiData.nombre,
    p_descripcion: msiData.descripcion,
    p_monto_total: msiData.monto_total,       // Ej: 25091.25
    p_numero_meses: msiData.numero_meses,     // Ej: 12
    p_meses_ya_pagados: msiData.meses_ya_pagados || 0,  // Ej: 8
    p_monto_personalizado_por_mes: msiData.monto_por_mes || null  // Opcional
  }
  
  await supabase.rpc('crear_msi_tarjeta_credito', params)
}
```

**Lo que hace la función SQL** `crear_msi_tarjeta_credito`:
1. Valida que la cuenta sea una tarjeta de crédito con día de corte
2. Calcula el monto mensual (personalizado o automático)
3. Crea 1 registro en `transacciones_periodicas` con `es_msi = TRUE`
4. Crea N registros en `ejecuciones_transacciones_periodicas`:
   - Meses ya pagados → `estado = 'ejecutada'`
   - Meses restantes → `estado = 'pendiente'`
5. Cada ejecución se programa según el día de corte de la tarjeta

**Edición de meses pagados** (bidireccional):
```javascript
// Aumentar meses pagados: 8 → 10
// Marca las siguientes 2 ejecuciones pendientes como 'ejecutada'

// Disminuir meses pagados: 10 → 8  
// Revierte las últimas 2 ejecuciones ejecutadas a 'pendiente'

const updateMSIPaidMonths = async (msiId, nuevosMesesPagados) => {
  // 1. Actualiza transacciones_periodicas.meses_pagados
  // 2. Calcula diferencia vs meses anteriores
  // 3. Si aumentó: marca N ejecuciones como ejecutadas
  // 4. Si disminuyó: revierte N ejecuciones a pendiente
}
```

**Cálculo de saldo del periodo**:
```javascript
// src/stores/accounts.js
const calcularGastosPeriodoActual = async (cuentaId) => {
  // 1. Suma gastos normales del periodo
  // 2. Obtiene ejecuciones MSI pendientes del mes actual
  // 3. Suma solo las cuotas con estado 'pendiente' o 'confirmada'
  // 4. NO incluye las ya 'ejecutadas' (ya pagadas)
  
  return gastosPeriodo + cuotasMSIPendientes
}
```

##### 2. Transacciones Periódicas (NO-MSI)

**Propósito**: Cualquier gasto o ingreso recurrente fuera de MSI

**Frecuencias soportadas**:
- `diaria`: Todos los días
- `semanal`: Días específicos de la semana (array)
- `quincenal`: Cada 15 días
- `mensual`: Día específico del mes (1-31)
- `bimestral`, `trimestral`, `semestral`, `anual`
- `dias_naturales`: Cada X días
- `unica`: Una sola vez en fecha específica

**Criterios de finalización**:
- `sin_fin`: Se repite indefinidamente
- `fecha_fin`: Hasta una fecha específica
- `numero_repeticiones`: X veces y termina

**Ejemplos de uso**:

```javascript
// Netflix - Mensual
{
  nombre: 'Netflix Premium',
  tipo: 'gasto',
  monto: 279.00,
  frecuencia: 'mensual',
  dia_del_mes: 5,              // Se cobra el día 5
  criterio_fin: 'sin_fin',
  cuenta_id: cuenta_debito_id,
  categoria_id: suscripciones_id,
  requiere_confirmacion: true,
  auto_ejecutar: false
}

// Nómina - Quincenal
{
  nombre: 'Nómina',
  tipo: 'ingreso',
  monto: 15000.00,
  frecuencia: 'quincenal',
  criterio_fin: 'sin_fin',
  cuenta_id: cuenta_bancaria_id,
  requiere_confirmacion: false,
  auto_ejecutar: true
}

// Gym - Cada 30 días
{
  nombre: 'Gimnasio',
  tipo: 'gasto',
  monto: 500.00,
  frecuencia: 'dias_naturales',
  intervalo_dias: 30,
  criterio_fin: 'sin_fin',
  cuenta_id: efectivo_id
}

// Ahorro temporal - 10 meses
{
  nombre: 'Ahorro vacaciones',
  tipo: 'gasto',
  monto: 1000.00,
  frecuencia: 'mensual',
  dia_del_mes: 1,
  criterio_fin: 'numero_repeticiones',
  numero_total_repeticiones: 10,
  cuenta_id: ahorro_id
}
```

##### Diferencias Clave MSI vs Transacciones Periódicas

| Característica | MSI | Transacciones Periódicas |
|---|---|---|
| **Tipo de cuenta** | Solo tarjetas de crédito | Cualquier cuenta |
| **Ejecución** | Automática (día de corte) | Manual o automática |
| **Confirmación** | NO requiere | Configurable |
| **Meses pagados** | Soporta edición bidireccional | N/A |
| **Propósito** | Compras diferidas | Suscripciones, nómina, servicios |
| **Campo `es_msi`** | `TRUE` | `FALSE` |
| **Tabla** | `transacciones_periodicas` | `transacciones_periodicas` |

##### Componentes de Interfaz

**Para MSI**:
- `MSIConfig.vue`: Configurar nuevo MSI con opciones avanzadas
- `MSIListModal.vue`: Lista de MSI activos de una tarjeta
- `MSIEditModal.vue`: Editar meses pagados de un MSI existente

**Para Transacciones Periódicas**:
- `RecurringTransactionForm.vue`: Crear/editar transacción periódica
- `RecurringTransactionsList.vue`: Listar todas las transacciones programadas
- `PendingExecutionsView.vue`: Ver y confirmar ejecuciones pendientes

##### Flujo de Trabajo

**Crear MSI desde transacción existente**:
1. Usuario ve transacción de gasto en tarjeta de crédito
2. Click en "Diferir" en la tabla de transacciones
3. Se abre `MSIConfig.vue` con datos pre-llenados
4. Usuario configura meses, meses ya pagados, tipo de cuota
5. Se llama `createMSI()` → ejecuta `crear_msi_tarjeta_credito()`
6. Se elimina la transacción original (ya está en MSI)
7. MSI aparece en `MSIListModal` de la tarjeta

**Editar meses pagados de MSI**:
1. Usuario abre lista de MSI de la tarjeta
2. Click en "Editar" (icono lápiz)
3. `MSIEditModal` muestra progreso actual
4. Usuario ajusta meses pagados (ej: de 8 a 10)
5. `updateMSIPaidMonths()` marca 2 ejecuciones como ejecutadas
6. Saldo del periodo se actualiza automáticamente

**Registrar pago del periodo**:
1. `calcularGastosPeriodoActual()` suma gastos + MSI pendientes
2. Usuario ve saldo total del periodo (ej: $5,000 gastos + $2,090.94 MSI = $7,090.94)
3. Usuario registra pago de $7,090.94
4. Sistema marca ejecuciones MSI del mes como ejecutadas
5. Saldo del periodo se actualiza para el siguiente mes

##### Notas Importantes

**NO usar tablas antiguas**:
- ❌ `compras_msi` (obsoleta)
- ❌ `reglas_recurrentes` (obsoleta)
- ✅ `transacciones_periodicas` + `ejecuciones_transacciones_periodicas` (nueva arquitectura)

**Siempre usar funciones SQL**:
- Para crear MSI: `crear_msi_tarjeta_credito()`
- Para calcular próxima fecha: `calcular_proxima_ejecucion()`
- Evita inconsistencias y duplicación de lógica

**Saldo del periodo**:
- Incluye gastos normales del mes
- Incluye SOLO cuotas MSI con estado 'pendiente' o 'confirmada'
- NO incluye cuotas ya ejecutadas ni de meses futuros
- Resultado: saldo real a pagar en el periodo actual

#### Manejo de Fechas en Tarjetas de Crédito
- Siempre comparar `dia_pago` vs `dia_corte` para calcular mes correcto
- Si `dia_pago < dia_corte` → fecha de pago es del MES SIGUIENTE al corte
- Ejemplo: Corte día 25, Pago día 10 → Si corte es 25/Enero, pago es 10/Febrero
- Usar funciones SQL cuando sea posible para evitar inconsistencias

#### Gestión de Base de Datos
- **NUNCA** ejecutar scripts SQL fuera de orden (siempre 1 → 2 → 3)
- **SIEMPRE** verificar que el rollback completo funcionó antes de reportar éxito
- Los scripts están diseñados para ser **idempotentes** (se pueden ejecutar múltiples veces)
- Usar `CASCADE` en todos los `DROP` para evitar errores de dependencias
- Mantener `sql/ROLLBACK_Y_RECREACION.md` actualizado con cualquier cambio estructural

---

**Última actualización**: Diciembre 9, 2025  
**Rama actual**: dev  
**Repositorio**: github.com/iDylaan/Finah
