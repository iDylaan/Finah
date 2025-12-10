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

11. **Sistema de Diferir Transacciones a MSI** (Diciembre 2024):
   - **Ubicación**: `AccountDashboard.vue` - Tabla de transacciones
   - **Funcionalidad**: Convertir gastos existentes en pagos diferidos a meses
   - **Componentes involucrados**:
     - `AccountDashboard.vue`: Botón "Diferir" en columna de acciones
     - `MSIConfig.vue`: Modal de configuración de MSI (reutilizado)
     - Store: `recurring-transactions.js` (createMSI)
     - Store: `transactions.js` (deleteTransaction)
   - **Flujo completo**:
     1. Usuario ve gasto en tarjeta de crédito (ej: $25,091.25 - Compra Amazon)
     2. Click en botón "Diferir" → ConfirmDialog pregunta confirmación
     3. Al aceptar → Abre `MSIConfig` con datos prellenados:
        - `initial-amount`: Monto del gasto original
        - `initial-description`: Descripción del gasto
        - `category-id`: Categoría del gasto
        - `credit-card`: Tarjeta de crédito actual
     4. Usuario configura:
        - Plazo (3, 6, 9, 12, 15, 18, 24, 36 meses o personalizado)
        - Meses ya pagados (si la compra ya está en progreso)
        - Tipo de monto por cuota:
          * Automático: `total ÷ meses` (ej: $2,090.94)
          * Redondeado: `Math.ceil(total ÷ meses)` (ej: $2,091.00)
          * Manual: Usuario ingresa monto exacto
     5. `createMSI()` ejecuta función SQL `crear_msi_tarjeta_credito()`
     6. `handleMSICreatedFromTransaction()` elimina transacción original
     7. MSI queda registrado en `transacciones_periodicas` con ejecuciones programadas
   - **Validaciones**:
     - Solo gastos pueden ser diferidos (no ingresos/transferencias)
     - Solo en tarjetas de crédito (no efectivo/banco/débito)
     - Solo si NO es ya un MSI (`!data.metadatos?.msi_id`)
   - **Props de MSIConfig para diferir**:
     ```vue
     <MSIConfig 
       v-model:visible="showMSIConfigModal"
       :credit-card="account"
       :category-id="transactionToDefer?.categoria_id"
       :initial-amount="transactionToDefer?.monto"
       :initial-description="transactionToDefer?.descripcion"
       @msi-created="handleMSICreatedFromTransaction"
     />
     ```
   - **Ventajas**:
     - Reutiliza componente MSIConfig existente
     - Mantiene historial correcto (elimina transacción duplicada)
     - Permite registrar compras MSI existentes con meses ya pagados
     - Soporta montos personalizados para match exacto con bancos
   - **UI/UX**:
     - Botón solo visible en columna de acciones de tarjetas de crédito
     - Confirmación con ConfirmDialog antes de abrir modal
     - Tooltip explicativo: "Convertir en pago diferido a meses"
     - Icono: `pi pi-calendar`
     - Severity: `secondary`, `outlined`

12. **Consolidación de Utilidades en lib/utils.js** (Diciembre 2024):
   - **Migración completa**: Todas las funciones de `utils/misc.js` → `lib/utils.js`
   - **Archivo deprecated**: `utils/misc.js` ahora solo reexporta para compatibilidad
   - **Funciones centralizadas**:
     - Fechas: `diasHasta()`, `diasDesde()`, `esHoy()`, `esFuturo()`, `diferenciaEnDias()`, `agregarDias()`
     - Formato: `formatCurrency()`, `formatNumber()`, `formatDate()`, `formatDateTime()`, `formatTime()`
     - Color: `getContrastTextColor()`, `getContrastTextWithOpacity()`
     - Errores: `handleError()`
   - **Beneficios**:
     - Un solo punto de verdad para utilidades
     - Mejor organización con secciones documentadas
     - Facilita mantenimiento y testing
     - Evita duplicación de código
   - **Parsing de fechas mejorado**:
     - Detecta formato `YYYY-MM-DD` y parsea en zona horaria local
     - Previene problemas de cambio de día por UTC
     - Usado en `formatDate()` para mostrar fechas correctas
   - **Ejemplo de uso**:
     ```javascript
     import { formatDate, diasHasta, formatCurrency } from '@/lib/utils.js'
     
     // Fecha de corte se muestra correctamente
     const proximaFechaCorte = computed(() => {
       if (!creditCard?.proxima_fecha_corte) return 'No configurada'
       return formatDate(creditCard.proxima_fecha_corte, 'largo')
       // Output: "11 de diciembre de 2025" (correcto, no "10 de diciembre")
     })
     ```

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

**Opciones de Meses Disponibles**:
- **Estándar**: 3, 6, 9, 12, 18, 24 meses (opciones predefinidas)
- **15 meses**: Opción adicional común en tiendas departamentales
- **Personalizado**: El usuario puede ingresar cualquier número de meses (1-999)

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
    p_numero_meses: msiData.numero_meses,     // Ej: 12, 15, o cualquier número
    p_meses_ya_pagados: msiData.meses_ya_pagados || 0,  // Ej: 8
    p_monto_personalizado_por_mes: msiData.monto_por_mes || null  // Opcional
  }
  
  await supabase.rpc('crear_msi_tarjeta_credito', params)
}
```

**Lo que hace la función SQL** `crear_msi_tarjeta_credito`:
1. Valida que la cuenta sea una tarjeta de crédito con día de corte
2. Calcula el monto mensual según la lógica:
   - **Si se proporciona `p_monto_personalizado_por_mes`**: Usa ese monto exacto
   - **Si NO se proporciona**: Calcula automáticamente `monto_total / numero_meses`
3. Calcula el saldo pendiente de pago:
   ```sql
   v_saldo_pendiente := p_monto_total - (p_meses_ya_pagados * v_monto_por_mes)
   ```
4. Actualiza el crédito disponible de la tarjeta:
   ```sql
   UPDATE cuentas 
   SET credito_disponible = credito_disponible - v_saldo_pendiente
   WHERE id = p_cuenta_id
   ```
   Esto asegura que solo se descuente el saldo que **realmente falta por pagar**, no el monto total.
5. Crea 1 registro en `transacciones_periodicas` con `es_msi = TRUE`
6. Crea N registros en `ejecuciones_transacciones_periodicas`:
   - Meses ya pagados → `estado = 'ejecutada'`
   - Meses restantes → `estado = 'pendiente'`
7. Cada ejecución se programa según el día de corte de la tarjeta

**Casos de uso del monto personalizado**:
- **Caso 1 - Monto automático**: Usuario no especifica `monto_por_mes`
  * Total: $25,091.25 / 12 meses = $2,090.94 por mes
  * Se usa el monto calculado exacto
  
- **Caso 2 - Monto redondeado**: Usuario quiere pagar $2,100.00 por mes
  * Total: $25,091.25 / 12 meses = $2,090.94
  * Usuario elige redondear a $2,100.00
  * Se pasa `p_monto_personalizado_por_mes: 2100.00`
  
- **Caso 3 - Monto personalizado**: Usuario quiere pagar $2,500.00 por mes
  * Independiente del cálculo automático
  * Se pasa `p_monto_personalizado_por_mes: 2500.00`

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
  * Dropdown con opciones: 3, 6, 9, 12, 15, 18, 24, Personalizado
  * Si selecciona "Personalizado", muestra InputNumber para ingresar cualquier número (1-999)
  * Radio buttons para tipo de cuota: Automático, Redondeado, Manual
  * Validación: Si "Personalizado" seleccionado, debe ingresar número válido
  
- `MSIListModal.vue`: Lista de MSI activos de una tarjeta
  * Muestra iconos según `biblioteca_iconos` (PrimeVue o Material Symbols)
  * Validación: Verifica biblioteca antes de renderizar `<i>` o componente PrimeVue
  
- `MSIEditModal.vue`: Editar meses pagados de un MSI existente

**Para Transacciones Periódicas**:
- `RecurringTransactionForm.vue`: Crear/editar transacción periódica
- `RecurringTransactionsList.vue`: Listar todas las transacciones programadas
- `PendingExecutionsView.vue`: Ver y confirmar ejecuciones pendientes

**Para Gastos con MSI** (diferir desde formulario):
- `GastoForm.vue`: Formulario de registro de gastos
  * Checkbox "Diferir en MSI" (solo visible si cuenta es tarjeta de crédito)
  * Dropdown con opciones: 3, 6, 9, 12, 15, 18, 24, Personalizado
  * Si selecciona "Personalizado", muestra InputNumber adicional
  * Radio buttons para tipo de cuota
  * Validación completa antes de enviar

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

**Validaciones críticas implementadas**:

1. **Manejo de valor "personalizado" en campos numéricos**:
   - Problema: Cuando `meses === 'personalizado'`, hacer `'personalizado' - mesesYaPagados` resulta en `NaN`
   - Solución: Usar valor condicional `mesesFinal` que valida si es 'personalizado' antes de calcular
   ```javascript
   const mesesFinal = computed(() => {
     return props.meses === 'personalizado' ? mesesPersonalizados.value : props.meses
   })
   
   const mesesRestantes = computed(() => {
     if (!mesesFinal.value) return 0
     return Math.max(0, mesesFinal.value - props.mesesYaPagados)
   })
   ```

2. **Parsing de números en crédito disponible**:
   - Problema: `credito_disponible` y `limite_credito` vienen como strings desde Supabase
   - Síntoma: ProgressBar no muestra porcentaje, `porcentajeUsoCredito` es `NaN`
   - Solución: Usar `parseFloat()` en todos los cálculos numéricos
   ```javascript
   export const porcentajeUsoCredito = (creditoDisponible, limiteCredito) => {
     const disponible = parseFloat(creditoDisponible) || 0
     const limite = parseFloat(limiteCredito) || 1
     const usado = limite - disponible
     return Math.min(100, Math.max(0, (usado / limite) * 100))
   }
   ```

3. **Manejo de fechas sin cambio de zona horaria**:
   - Problema: `new Date('2025-12-11')` se interpreta como UTC medianoche, mostrando día anterior
   - Síntoma: Fecha muestra "10 de diciembre" cuando debería ser "11 de diciembre"
   - Solución: Usar `formatDate()` que parsea en hora local
   ```javascript
   export const formatDate = (dateString) => {
     if (!dateString) return ''
     const [year, month, day] = dateString.split('-')
     const date = new Date(year, month - 1, day) // Hora local, no UTC
     return new Intl.DateTimeFormat('es-MX', {
       year: 'numeric', month: 'long', day: 'numeric'
     }).format(date)
   }
   ```

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

### Sistema de Periodos de Pago de Tarjetas de Crédito (Diciembre 2024)

#### Arquitectura General

El sistema gestiona los periodos de pago de tarjetas de crédito de forma **completamente automática** mediante triggers de base de datos, permitiendo:
- **Saldo variable del periodo actual**: Se actualiza automáticamente con cada gasto, pago o MSI
- Ver saldo en tiempo real (gastos entre corte anterior y corte actual)
- Proyectar saldo del siguiente periodo (gastos futuros ya registrados)
- Registrar pagos que descuentan del `saldo_periodo_actual`
- Marcar automáticamente gastos y cuotas MSI como pagados
- Mantener separación estricta entre periodos

#### Campo `saldo_periodo_actual` en Tabla `cuentas`

**Definición**:
```sql
saldo_periodo_actual NUMERIC(14,2) DEFAULT 0
```

**Comportamiento**:
- **En fecha de corte**: Se recalcula sumando todos los gastos + MSI pendientes del nuevo periodo
- **Al registrar gasto**: Aumenta automáticamente con el monto del gasto (vía trigger)
- **Al crear MSI**: Aumenta con las cuotas que caen en el periodo actual (vía trigger)
- **Al registrar pago**: Disminuye según el monto pagado
- **Ventaja**: Un solo valor numérico actualizado en tiempo real, no requiere cálculos complejos

**Triggers que lo actualizan automáticamente**:

1. **`trigger_actualizar_saldo_periodo`** (en `transacciones`):
   ```sql
   CREATE TRIGGER trigger_actualizar_saldo_periodo
       AFTER INSERT ON transacciones
       FOR EACH ROW
       EXECUTE FUNCTION actualizar_saldo_periodo_gasto();
   ```
   - Se ejecuta cuando se inserta un gasto
   - Solo aplica si:
     * `NEW.tipo = 'gasto'`
     * Cuenta es `credit_card` con `dia_corte` configurado
     * Fecha del gasto cae dentro del periodo actual
   - **Acción**: `UPDATE cuentas SET saldo_periodo_actual = saldo_periodo_actual + NEW.monto`

2. **`trigger_actualizar_saldo_periodo_ejecucion`** (en `ejecuciones_transacciones_periodicas`):
   ```sql
   CREATE TRIGGER trigger_actualizar_saldo_periodo_ejecucion
       AFTER INSERT ON ejecuciones_transacciones_periodicas
       FOR EACH ROW
       EXECUTE FUNCTION actualizar_saldo_periodo_ejecucion_msi();
   ```
   - Se ejecuta cuando se crea una ejecución de MSI
   - Solo aplica si:
     * La transacción periódica tiene `es_msi = TRUE`
     * La cuenta es `credit_card` con `dia_corte`
     * `fecha_programada` cae dentro del periodo actual
     * `estado IN ('pendiente', 'confirmada')`
   - **Acción**: `UPDATE cuentas SET saldo_periodo_actual = saldo_periodo_actual + NEW.monto_programado`

**Script de inicialización** (ejecutar una sola vez al migrar):
```sql
-- Inicializar saldo_periodo_actual para tarjetas existentes
DO $$
DECLARE
    v_tarjeta RECORD;
    v_fechas RECORD;
    v_gastos_periodo NUMERIC;
    v_msi_periodo NUMERIC;
    v_total_periodo NUMERIC;
BEGIN
    FOR v_tarjeta IN 
        SELECT id, nombre, dia_corte, dia_pago 
        FROM cuentas 
        WHERE tipo = 'credit_card' AND dia_corte IS NOT NULL
    LOOP
        -- Calcular fechas del periodo actual
        SELECT * INTO v_fechas
        FROM calcular_fechas_periodo_tarjeta(
            v_tarjeta.dia_corte, v_tarjeta.dia_pago, CURRENT_DATE
        );
        
        -- Sumar gastos directos del periodo
        SELECT COALESCE(SUM(monto), 0) INTO v_gastos_periodo
        FROM transacciones
        WHERE cuenta_id = v_tarjeta.id
            AND tipo = 'gasto'
            AND fecha_ocurrencia >= v_fechas.periodo_actual_inicio
            AND fecha_ocurrencia <= v_fechas.periodo_actual_fin
            AND deleted_at IS NULL;
        
        -- Sumar cuotas MSI del periodo
        SELECT COALESCE(SUM(e.monto_programado), 0) INTO v_msi_periodo
        FROM ejecuciones_transacciones_periodicas e
        INNER JOIN transacciones_periodicas tp ON e.transaccion_periodica_id = tp.id
        WHERE tp.cuenta_id = v_tarjeta.id
            AND tp.es_msi = TRUE
            AND e.fecha_programada >= v_fechas.periodo_actual_inicio
            AND e.fecha_programada <= v_fechas.periodo_actual_fin
            AND e.estado IN ('pendiente', 'confirmada');
        
        -- Actualizar saldo_periodo_actual
        v_total_periodo := v_gastos_periodo + v_msi_periodo;
        UPDATE cuentas SET saldo_periodo_actual = v_total_periodo
        WHERE id = v_tarjeta.id;
        
        RAISE NOTICE 'Tarjeta %: Gastos=$% + MSI=$% = Total=$%', 
            v_tarjeta.nombre, v_gastos_periodo, v_msi_periodo, v_total_periodo;
    END LOOP;
END $$;
```

**Importante**: Este script solo se ejecuta **una vez** al migrar a la nueva arquitectura. Los triggers se encargan de mantener el saldo actualizado automáticamente a partir de ese momento.

#### Funciones SQL del Sistema

**1. `calcular_fechas_periodo_tarjeta(dia_corte, dia_pago, fecha_referencia)`**
- **Propósito**: Calcular todas las fechas relevantes de dos periodos consecutivos
- **Parámetros**:
  - `dia_corte INTEGER`: Día del mes de corte (1-31)
  - `dia_pago INTEGER`: Días después del corte para pagar (ej: 20)
  - `fecha_referencia DATE`: Fecha base (DEFAULT: hoy)
- **Retorna TABLE**:
  ```sql
  periodo_actual_inicio DATE,      -- Inicio del periodo (corte anterior + 1 día)
  periodo_actual_fin DATE,         -- Fin del periodo (próximo corte)
  periodo_siguiente_inicio DATE,   -- Inicio siguiente periodo
  periodo_siguiente_fin DATE,      -- Fin siguiente periodo
  fecha_corte_actual DATE,         -- Fecha de corte actual
  fecha_pago_actual DATE,          -- Fecha límite de pago
  fecha_corte_siguiente DATE,      -- Próximo corte
  fecha_pago_siguiente DATE        -- Próximo pago
  ```
- **Lógica**:
  - Si fecha_referencia > día_corte del mes → el corte ya pasó, usar mes siguiente
  - Calcula corte anterior restando 1 mes
  - Periodo actual = [corte_anterior + 1, corte_actual]
  - Periodo siguiente = [corte_actual + 1, corte_siguiente]
  - Fecha de pago = fecha_corte + dias_pago

**2. `obtener_gastos_periodo_tarjeta(cuenta_id, fecha_inicio, fecha_fin)`**
- **Propósito**: Obtener el total de gastos pendientes de un periodo específico
- **Parámetros**:
  - `cuenta_id UUID`: ID de la tarjeta de crédito
  - `fecha_inicio DATE`: Inicio del periodo
  - `fecha_fin DATE`: Fin del periodo
- **Retorna TABLE**:
  ```sql
  total_gastos_normales NUMERIC,   -- Suma de gastos NO pagados del periodo
  total_cuotas_msi NUMERIC,        -- Suma de cuotas MSI pendientes del periodo
  total_periodo NUMERIC,           -- Total combinado
  cuotas_msi JSONB                 -- Array con detalle de cada cuota MSI
  ```
- **Lógica**:
  - **Gastos normales**: Solo cuenta gastos con:
    - `tipo = 'gasto'`
    - `fecha_ocurrencia` dentro del periodo
    - `(metadatos->>'msi_id') IS NULL` (no son MSI)
    - `(metadatos->>'pagado_en_periodo')::BOOLEAN = FALSE` (no pagados)
    - `deleted_at IS NULL` (activos)
  - **Cuotas MSI**: Solo cuenta ejecuciones con:
    - `fecha_programada` dentro del periodo
    - `estado IN ('pendiente', 'confirmada')` (no ejecutadas)
    - Obtiene detalle completo en JSONB para mostrar en UI

**3. `registrar_pago_periodo_tarjeta(cuenta_tarjeta_id, monto_pago, categoria_id, fecha_pago, descripcion, tipo_pago, cuenta_origen_id)`**
- **Propósito**: Registrar un pago de tarjeta y reducir el `saldo_periodo_actual`
- **Parámetros**:
  - `cuenta_tarjeta_id UUID`: ID de la tarjeta
  - `monto_pago NUMERIC`: Cantidad a pagar
  - `categoria_id UUID`: Categoría del pago
  - `fecha_pago DATE`: Fecha del pago
  - `descripcion TEXT`: Descripción (opcional)
  - `tipo_pago TEXT`: 'manual' o 'transfer'
  - `cuenta_origen_id UUID`: Si es transferencia, cuenta origen
- **Retorna**: `UUID` del ID de transacción creado
- **Lógica completa**:

  1. **Validaciones**:
     ```sql
     -- Usuario autenticado
     v_usuario_id := auth.uid()
     
     -- Cuenta existe y pertenece al usuario
     SELECT * FROM cuentas 
     WHERE id = cuenta_tarjeta_id 
       AND creada_por = v_usuario_id
       AND tipo = 'credit_card'
       AND deleted_at IS NULL
     
     -- Monto válido
     IF monto_pago <= 0 THEN RAISE EXCEPTION
     ```

  2. **Crear transacción de pago**:
     ```sql
     INSERT INTO transacciones (
       tipo = 'ingreso',
       monto = p_monto_pago,
       cuenta_id = cuenta_tarjeta_id,
       metadatos = {
         'tipo_pago': 'manual' o 'transfer',
         'es_pago_periodo': true
       }
     ) RETURNING id
     ```

  3. **Si es transferencia**: Crear egreso en cuenta origen
     ```sql
     INSERT INTO transacciones (
       tipo = 'gasto',
       cuenta_id = cuenta_origen_id,
       metadatos = {
         'es_transferencia': true,
         'cuenta_destino_id': cuenta_tarjeta_id,
         'transaccion_relacionada_id': id_pago
       }
     )
     
     UPDATE cuentas 
     SET saldo = saldo - monto_pago
     WHERE id = cuenta_origen_id
     ```

  4. **Actualizar crédito disponible**:
     ```sql
     UPDATE cuentas
     SET credito_disponible = LEAST(
       credito_disponible + monto_pago,
       limite_credito
     )
     WHERE id = cuenta_tarjeta_id
     ```

  5. **Reducir saldo_periodo_actual**:
     ```sql
     UPDATE cuentas
     SET saldo_periodo_actual = GREATEST(0, saldo_periodo_actual - p_monto_pago),
         fecha_actualizacion = NOW()
     WHERE id = p_cuenta_tarjeta_id
     ```
     - Usa `GREATEST(0, ...)` para evitar valores negativos
     - Se actualiza en tiempo real, visible inmediatamente en UI

**4. `obtener_resumen_periodos_tarjeta(cuenta_id)`**
- **Propósito**: Obtener resumen completo de ambos periodos usando `saldo_periodo_actual`
- **Parámetros**: `cuenta_id UUID`
- **Retorna**: `JSONB` con estructura completa
  ```json
  {
    "cuenta_id": "uuid",
    "limite_credito": 100000.00,
    "credito_disponible": 95000.00,
    "credito_utilizado": 5000.00,
    "saldo_periodo_actual": 3091.00,  // ← Valor directo del campo
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
      "total": 3091.00,  // ← Toma directamente de cuentas.saldo_periodo_actual
      "gastos_normales": 1000.00,  // ← Calculado para detalle
      "cuotas_msi": 2091.00,  // ← Calculado para detalle
      "cuotas_detalle": [...]
    },
    "periodo_siguiente": {
      "total": 2591.00,  // ← Calculado sumando gastos futuros
      "gastos_normales": 500.00,
      "cuotas_msi": 2091.00,
      "cuotas_detalle": [...]
    }
  }
  ```
- **Lógica mejorada**:
  ```sql
  -- Periodo actual: Usar directamente saldo_periodo_actual
  periodo_actual := JSONB_BUILD_OBJECT(
    'total', v_cuenta.saldo_periodo_actual,  -- No necesita cálculo
    'gastos_normales', v_gastos_periodo.total_gastos_normales,
    'cuotas_msi', v_gastos_periodo.total_cuotas_msi,
    'cuotas_detalle', v_gastos_periodo.cuotas_msi
  );
  
  -- Periodo siguiente: Calcular gastos futuros normalmente
  SELECT * INTO v_gastos_siguiente
  FROM obtener_gastos_periodo_tarjeta(
    p_cuenta_id,
    v_fechas.periodo_siguiente_inicio,
    v_fechas.periodo_siguiente_fin
  );
  ```
- **Ventaja**: El periodo actual siempre refleja el valor actualizado por triggers, garantizando consistencia

**5. `recalcular_saldo_en_corte(cuenta_id)`**
- **Propósito**: Recalcular `saldo_periodo_actual` en fecha de corte (ejecutar automáticamente o manualmente)
- **Cuándo ejecutar**:
  - Automáticamente cada día de corte (job programado recomendado)
  - Manualmente al inicio de cada periodo
- **Lógica**:
  ```sql
  -- 1. Calcular nuevo periodo
  SELECT * INTO v_fechas FROM calcular_fechas_periodo_tarjeta(...)
  
  -- 2. Sumar gastos del nuevo periodo
  SELECT SUM(monto) INTO v_gastos FROM transacciones
  WHERE ... AND fecha_ocurrencia >= v_fechas.periodo_actual_inicio
  
  -- 3. Sumar MSI del nuevo periodo
  SELECT SUM(monto_programado) INTO v_msi FROM ejecuciones...
  WHERE ... AND fecha_programada >= v_fechas.periodo_actual_inicio
  
  -- 4. Actualizar saldo
  UPDATE cuentas SET saldo_periodo_actual = v_gastos + v_msi
  WHERE id = p_cuenta_id
  ```

#### Componentes de Interfaz

**CreditCardInfo.vue**
- Muestra información detallada de la tarjeta de crédito
- **Uso de periodos**:
  ```javascript
  const resumenPeriodos = ref(null)
  
  const loadCardInfo = async () => {
    const { data } = await accountsStore.obtenerResumenPeriodosTarjeta(props.account.id)
    resumenPeriodos.value = data
  }
  ```
- **UI del periodo actual** (caja verde):
  - Título: "Saldo del periodo actual"
  - Fechas: `{inicio} - {fin}`
  - Total adeudado: `${total}`
  - Detalle:
    - Gastos normales: `${gastos_normales}`
    - Cuotas MSI: `${cuotas_msi} ({cuotas_detalle.length} cuotas)`
- **UI del periodo siguiente** (caja azul):
  - Solo se muestra si `total > 0`
  - Título: "Proyección periodo siguiente"
  - Fechas: `{inicio} - {fin}`
  - Total proyectado: `${total}`
  - Nota: "Gastos futuros registrados"
- **Botón "Realizar Pago"**:
  - Abre `CreditCardPaymentModal`
  - Pasa resumen de periodos como prop

**CreditCardPaymentModal.vue**
- Modal especializado para pagos de tarjetas
- **Modos**:
  1. **Manual**: Registra ingreso directo
  2. **Transferencia**: Mueve dinero desde otra cuenta
- **Botones de pago rápido**:
  - Pago Mínimo: `limite * porcentaje_pago_minimo / 100`
  - Pago Total: Usa `resumenPeriodos.periodo_actual.total`
  - Personalizado: Usuario ingresa monto
- **Función de registro**:
  ```javascript
  const handleSubmit = async () => {
    await accountsStore.registrarPagoPeriodoTarjeta({
      cuenta_tarjeta_id: props.account.id,
      monto_pago: formData.amount,
      categoria_id: formData.category,
      fecha_pago: formData.date,
      descripcion: formData.description,
      tipo_pago: paymentMode.value, // 'manual' o 'transfer'
      cuenta_origen_id: formData.sourceAccount || null
    })
  }
  ```

**Store: accounts.js**
```javascript
// Obtener resumen de periodos
const obtenerResumenPeriodosTarjeta = async (cuentaId) => {
  const { data, error } = await supabase
    .rpc('obtener_resumen_periodos_tarjeta', { p_cuenta_id: cuentaId })
  
  if (error) throw error
  return { data }
}

// Registrar pago de periodo
const registrarPagoPeriodoTarjeta = async (pagoData) => {
  const fecha = typeof pagoData.fecha_pago === 'string' 
    ? pagoData.fecha_pago 
    : pagoData.fecha_pago.toISOString().split('T')[0]
  
  const params = {
    p_cuenta_tarjeta_id: pagoData.cuenta_tarjeta_id,
    p_monto_pago: pagoData.monto_pago,
    p_categoria_id: pagoData.categoria_id,
    p_fecha_pago: fecha,
    p_descripcion: pagoData.descripcion || null,
    p_tipo_pago: pagoData.tipo_pago || 'manual',
    p_cuenta_origen_id: pagoData.cuenta_origen_id || null
  }
  
  const { data, error } = await supabase
    .rpc('registrar_pago_periodo_tarjeta', params)
  
  if (error) throw error
  
  // Refrescar cuentas
  await fetchAccountsWithDetails({ force: true })
  
  return data // UUID de la transacción creada
}
```

#### Reglas de Negocio del Sistema

**1. Separación estricta de periodos**:
- Cada periodo solo considera transacciones dentro de sus fechas
- Gastos del periodo siguiente NO afectan saldo del periodo actual
- `saldo_periodo_actual` se recalcula completamente en cada fecha de corte

**2. Actualización automática del saldo**:
- **Al crear gasto**: Trigger aumenta `saldo_periodo_actual` inmediatamente
- **Al crear MSI**: Trigger suma solo las cuotas del periodo actual
- **Al registrar pago**: Función SQL resta del `saldo_periodo_actual`
- **En fecha de corte**: Función `recalcular_saldo_en_corte()` reinicia el saldo
- **Ventaja**: No hay necesidad de calcular suma de transacciones cada vez

**3. Orden de actualización del saldo**:
- Gastos normales y MSI incrementan el saldo en paralelo (no hay orden)
- Pagos reducen el saldo directamente sin distribuir entre gastos específicos
- Simplificación vs sistema anterior: No se rastrean gastos individuales pagados

**4. Gastos futuros**:
- Si registras un gasto con `fecha_ocurrencia` posterior al corte actual
- El trigger verifica periodo y NO actualiza `saldo_periodo_actual`
- Se contabiliza automáticamente en el **periodo siguiente**
- Permite planificar y ver proyección de gastos futuros

**5. Pago parcial**:
- Si `monto_pago < saldo_periodo_actual`:
  - Se resta el monto del saldo: `saldo = saldo - monto_pago`
  - Saldo restante queda pendiente para próximo pago
- Si `monto_pago >= saldo_periodo_actual`:
  - Saldo queda en $0.00
  - Periodo totalmente cubierto

**6. Actualización de crédito disponible**:
- `credito_disponible` se actualiza inmediatamente con todo el monto pagado
- Independiente del `saldo_periodo_actual`
- Fórmula: `LEAST(credito_disponible + monto_pago, limite_credito)`
- Nunca excede el límite de crédito

**7. Cálculo simplificado vs sistema anterior**:
- **Antes**: Suma de transacciones + MSI en cada consulta (lento, complejo)
- **Ahora**: Un solo campo `saldo_periodo_actual` actualizado por triggers (rápido, simple)
- **Migración**: Script de inicialización ejecuta una sola vez para datos existentes

#### Casos de Uso Comunes

**Caso 1: Pago total del periodo**
```javascript
// Usuario ve: Saldo periodo actual = $7,090.94
// Compuesto de:
//   - $5,000.00 en gastos normales (5 transacciones)
//   - $2,090.94 en MSI (1 cuota de iPhone)

// Usuario paga exactamente $7,090.94
await registrarPagoPeriodoTarjeta({
  monto_pago: 7090.94,
  tipo_pago: 'transfer',
  cuenta_origen_id: 'cuenta-debito-uuid'
})

// Resultado:
// - Los 5 gastos marcados con pagado_en_periodo: true
// - La cuota MSI marcada como ejecutada
// - Saldo del periodo = $0.00
// - Crédito disponible aumenta $7,090.94
```

**Caso 2: Pago parcial (solo gastos normales)**
```javascript
// Saldo actual: $7,090.94
// Usuario solo paga: $5,000.00

await registrarPagoPeriodoTarjeta({
  monto_pago: 5000.00,
  tipo_pago: 'manual'
})

// Resultado:
// - Los 5 gastos normales marcados como pagados
// - La cuota MSI sigue pendiente
// - Próxima consulta mostrará: Saldo = $2,090.94 (solo MSI)
```

**Caso 3: Gastos en periodo siguiente**
```javascript
// Hoy: 9 de diciembre 2025
// Corte: 11 de diciembre 2025

// Usuario registra gasto para el 15 de diciembre
await createTransaction({
  tipo: 'gasto',
  monto: 1500.00,
  fecha_ocurrencia: '2025-12-15', // Después del corte
  cuenta_id: 'tarjeta-uuid'
})

// Resultado:
// - Periodo actual (hasta 11 dic): NO cambia
// - Periodo siguiente (12 dic - 11 ene): Aumenta +$1,500.00
// - UI muestra proyección en caja azul
```

**Caso 4: Editar meses pagados de MSI**
```javascript
// MSI: iPhone 12 meses, 8 meses pagados
// Cuota: $2,090.94/mes

// Usuario actualiza a 10 meses pagados
await updateMSIPaidMonths(msi_id, 10)

// Resultado automático:
// - Marca cuotas 9 y 10 como 'ejecutada'
// - Si alguna cuota estaba en periodo actual, ya no aparece en saldo
// - Solo quedan 2 cuotas futuras (meses 11 y 12)
```

#### Validaciones y Errores Comunes

**Error: "column usuario_id does not exist"**
- Causa: Tabla `cuentas` usa `creada_por`, no `usuario_id`
- Solución: Actualizar función SQL:
  ```sql
  WHERE id = p_cuenta_tarjeta_id 
    AND creada_por = v_usuario_id  -- No usuario_id
    AND deleted_at IS NULL         -- No activa = TRUE
  ```

**Error: "column fecha_actualizacion does not exist"**
- Causa: Tabla `transacciones_periodicas` usa `updated_at`
- Solución: Usar nombre correcto:
  ```sql
  UPDATE transacciones_periodicas
  SET meses_pagados = meses_pagados + 1,
      updated_at = NOW()  -- No fecha_actualizacion
  ```

**Error: NaN en porcentaje de uso de crédito**
- Causa: `credito_disponible` y `limite_credito` son strings desde Supabase
- Solución: Parsear con `parseFloat()`:
  ```javascript
  const disponible = parseFloat(creditoDisponible) || 0
  const limite = parseFloat(limiteCredito) || 1
  ```

**Error: Fecha muestra día incorrecto**
- Causa: `new Date('2025-12-11')` se interpreta como UTC medianoche
- Solución: Usar `formatDate()` de `lib/utils.js`:
  ```javascript
  import { formatDate } from '@/lib/utils.js'
  
  const fechaMostrar = formatDate('2025-12-11', 'largo')
  // "11 de diciembre de 2025" (correcto)
  ```

#### Nombres de Columnas Correctos por Tabla

```sql
-- Tabla: cuentas
creada_por UUID              -- NO usuario_id
fecha_actualizacion TIMESTAMPTZ
deleted_at TIMESTAMPTZ       -- NO activa BOOLEAN

-- Tabla: transacciones_periodicas
usuario_id UUID
updated_at TIMESTAMP         -- NO fecha_actualizacion
activa BOOLEAN               -- Para marcar si sigue vigente

-- Tabla: transacciones
usuario_id UUID
fecha_actualizacion TIMESTAMPTZ
deleted_at TIMESTAMPTZ
```

---

**Última actualización**: Diciembre 9, 2025  
**Rama actual**: dev  
**Repositorio**: github.com/iDylaan/Finah

