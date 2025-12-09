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
2. **categories.js**: Categorías de transacciones con grupos jerárquicos
3. **transactions.js**: Transacciones (ingresos, gastos, transferencias)
4. **recurring-transactions.js**: Transacciones periódicas
5. **session.js**: Autenticación y sesión de usuario (Supabase Auth)
6. **ui.js**: Estado de UI (tema, sidebar, mobile detection)
7. **ui-modals.js**: Control de modales y preselecciones

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
- **transacciones_periodicas**: Plantillas de transacciones recurrentes
- **bancos**: Catálogo de instituciones financieras
- **niveles_cuentas**: Niveles/carpetas para organizar cuentas

#### Políticas RLS
- Row Level Security habilitado
- Políticas por usuario (user_id = auth.uid())
- Scripts en `sql/2. db_policies.sql`

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

---

**Última actualización**: Diciembre 2025  
**Rama actual**: dev  
**Repositorio**: github.com/iDylaan/Finah
