# Sistema de Grupos y Gestión Colaborativa - Especificación Completa

## Fecha de Creación
23 de diciembre de 2025

## Índice
1. [Visión General](#visión-general)
2. [Modelo de Datos](#modelo-de-datos)
3. [Reglas de Negocio](#reglas-de-negocio)
4. [Funcionalidades por Módulo](#funcionalidades-por-módulo)
5. [Cálculos Automáticos](#cálculos-automáticos)
6. [Plan de Implementación](#plan-de-implementación)

---

## Visión General

### Objetivo
Permitir que múltiples usuarios gestionen finanzas de manera colaborativa mediante grupos, con catálogos compartidos, cuentas grupales, división automática de gastos basada en ingresos, y seguimiento de transacciones con responsabilidad por usuario.

### Alcance
- Gestión de grupos con roles (Owner, Administrador, Miembro)
- Catálogos compartidos (niveles, categorías, bancos, cuentas)
- Cuentas compartidas del grupo
- División automática de gastos según ingresos
- Metas personales y grupales
- Registro de ingresos periódicos para cálculos automáticos

---

## Modelo de Datos

### Nuevas Tablas

#### 1. `grupos`
Almacena información de los grupos financieros.

```sql
CREATE TABLE grupos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    color VARCHAR(7), -- HEX color #RRGGBB
    imagen_url TEXT, -- URL de la imagen del grupo
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_nombre_no_vacio CHECK (TRIM(nombre) != '')
);

CREATE INDEX idx_grupos_owner ON grupos(owner_id);
CREATE INDEX idx_grupos_activo ON grupos(activo);
```

**Campos:**
- `owner_id`: Usuario que creó el grupo (rol irrevocable)
- `activo`: Para soft delete del grupo

---

#### 2. `miembros_grupo`
Relaciona usuarios con grupos y define roles.

```sql
CREATE TYPE rol_grupo AS ENUM ('owner', 'administrador', 'miembro');

CREATE TABLE miembros_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rol rol_grupo NOT NULL DEFAULT 'miembro',
    porcentaje_peso DECIMAL(5, 2) DEFAULT 50.00, -- Calculado automáticamente según ingresos
    ingreso_manual_mensual DECIMAL(15, 2), -- Si no tiene ingresos periódicos registrados
    activo BOOLEAN DEFAULT TRUE,
    fecha_ingreso TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_salida TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(grupo_id, usuario_id),
    CONSTRAINT chk_porcentaje_peso CHECK (porcentaje_peso >= 0 AND porcentaje_peso <= 100),
    CONSTRAINT chk_ingreso_manual CHECK (ingreso_manual_mensual IS NULL OR ingreso_manual_mensual >= 0)
);

CREATE INDEX idx_miembros_grupo_usuario ON miembros_grupo(usuario_id);
CREATE INDEX idx_miembros_grupo_activo ON miembros_grupo(activo);
```

**Reglas:**
- Solo puede haber UN owner por grupo
- El porcentaje_peso se calcula automáticamente basado en ingresos
- La suma de porcentajes de todos los miembros activos debe ser 100%

---

#### 3. `invitaciones_grupo`
Gestiona invitaciones pendientes a grupos.

```sql
CREATE TYPE estado_invitacion AS ENUM ('pendiente', 'aceptada', 'rechazada', 'expirada');

CREATE TABLE invitaciones_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES grupos(id) ON DELETE CASCADE,
    email_invitado VARCHAR(255) NOT NULL,
    usuario_invitado_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    invitado_por UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rol_asignado rol_grupo NOT NULL DEFAULT 'miembro',
    estado estado_invitacion DEFAULT 'pendiente',
    mensaje TEXT,
    fecha_invitacion TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    fecha_expiracion TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    fecha_respuesta TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT chk_email_valido CHECK (email_invitado ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_invitaciones_usuario ON invitaciones_grupo(usuario_invitado_id);
CREATE INDEX idx_invitaciones_estado ON invitaciones_grupo(estado);
CREATE INDEX idx_invitaciones_expiracion ON invitaciones_grupo(fecha_expiracion);
```

**Reglas:**
- Expira automáticamente después de 7 días si no se acepta
- Se puede invitar por email (si no está registrado) o directamente a un usuario
- Un trigger actualiza `usuario_invitado_id` si el email coincide con un usuario registrado

---

#### 4. Modificaciones a Tablas Existentes

**a) `niveles`** - Agregar soporte para grupos
```sql
ALTER TABLE niveles ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE;
ALTER TABLE niveles ADD COLUMN tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

-- Índice para búsquedas por grupo
CREATE INDEX idx_niveles_grupo ON niveles(grupo_id) WHERE grupo_id IS NOT NULL;
```

**b) `categorias`** - Agregar soporte para grupos
```sql
ALTER TABLE categorias ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE;
ALTER TABLE categorias ADD COLUMN tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX idx_categorias_grupo ON categorias(grupo_id) WHERE grupo_id IS NOT NULL;
```

**c) `grupos_categoria`** - Agregar soporte para grupos
```sql
ALTER TABLE grupos_categoria ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE;
ALTER TABLE grupos_categoria ADD COLUMN tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX idx_grupos_categoria_grupo ON grupos_categoria(grupo_id) WHERE grupo_id IS NOT NULL;
```

**d) `bancos`** - Agregar soporte para grupos
```sql
ALTER TABLE bancos ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE;
ALTER TABLE bancos ADD COLUMN tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('publico', 'personal', 'grupo'));

CREATE INDEX idx_bancos_grupo ON bancos(grupo_id) WHERE grupo_id IS NOT NULL;
```

**e) `cuentas`** - Agregar soporte para grupos y tipo de cuenta
```sql
ALTER TABLE cuentas ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE;
ALTER TABLE cuentas ADD COLUMN tipo_visibilidad VARCHAR(20) DEFAULT 'personal' 
    CHECK (tipo_visibilidad IN ('personal', 'grupo'));
ALTER TABLE cuentas ADD COLUMN creada_por UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX idx_cuentas_grupo ON cuentas(grupo_id) WHERE grupo_id IS NOT NULL;

COMMENT ON COLUMN cuentas.grupo_id IS 'Si es NULL, es cuenta personal. Si tiene valor, es cuenta compartida del grupo';
COMMENT ON COLUMN cuentas.creada_por IS 'Usuario que creó la cuenta (admin/owner del grupo o usuario personal)';
```

**f) `transacciones`** - Agregar información de divisiones y usuario
```sql
ALTER TABLE transacciones ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE SET NULL;
ALTER TABLE transacciones ADD COLUMN registrada_por UUID REFERENCES auth.users(id) ON DELETE SET NULL;
ALTER TABLE transacciones ADD COLUMN es_gasto_compartido BOOLEAN DEFAULT FALSE;
ALTER TABLE transacciones ADD COLUMN division_gastos JSONB; -- Almacena la división del gasto

CREATE INDEX idx_transacciones_grupo ON transacciones(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX idx_transacciones_compartido ON transacciones(es_gasto_compartido) WHERE es_gasto_compartido = TRUE;

COMMENT ON COLUMN transacciones.registrada_por IS 'Usuario que registró la transacción';
COMMENT ON COLUMN transacciones.division_gastos IS 'JSON con división del gasto entre miembros: [{usuario_id, monto, porcentaje, pagado}]';
```

**Estructura del JSONB `division_gastos`:**
```json
[
  {
    "usuario_id": "uuid",
    "usuario_nombre": "Nombre Usuario",
    "monto_asignado": 450.00,
    "porcentaje": 45.00,
    "pagado": false,
    "fecha_pago": null
  },
  {
    "usuario_id": "uuid",
    "usuario_nombre": "Nombre Usuario 2",
    "monto_asignado": 550.00,
    "porcentaje": 55.00,
    "pagado": false,
    "fecha_pago": null
  }
]
```

**g) `transacciones_periodicas`** - Agregar grupo y clasificación
```sql
ALTER TABLE transacciones_periodicas ADD COLUMN grupo_id UUID REFERENCES grupos(id) ON DELETE SET NULL;
ALTER TABLE transacciones_periodicas ADD COLUMN es_ingreso_base BOOLEAN DEFAULT FALSE;
ALTER TABLE transacciones_periodicas ADD COLUMN tipo_ingreso VARCHAR(20) 
    CHECK (tipo_ingreso IN ('quincenal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual'));

COMMENT ON COLUMN transacciones_periodicas.es_ingreso_base IS 'Marca si este ingreso se usa para calcular peso en grupo';
COMMENT ON COLUMN transacciones_periodicas.tipo_ingreso IS 'Frecuencia del ingreso para cálculos anuales';
```

---

#### 5. `metas`
Nueva tabla para metas personales y grupales.

```sql
CREATE TYPE estado_meta AS ENUM ('activa', 'completada', 'cancelada', 'pausada');
CREATE TYPE tipo_meta AS ENUM ('personal', 'grupo');

CREATE TABLE metas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    grupo_id UUID REFERENCES grupos(id) ON DELETE CASCADE,
    tipo tipo_meta NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    monto_objetivo DECIMAL(15, 2) NOT NULL CHECK (monto_objetivo > 0),
    monto_actual DECIMAL(15, 2) DEFAULT 0.00 CHECK (monto_actual >= 0),
    fecha_objetivo DATE,
    estado estado_meta DEFAULT 'activa',
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    biblioteca_iconos VARCHAR(50) DEFAULT 'material',
    nombre_icono VARCHAR(100) DEFAULT 'flag',
    color VARCHAR(7) DEFAULT '#4CAF50',
    prioridad INTEGER DEFAULT 1 CHECK (prioridad >= 1 AND prioridad <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT chk_meta_tipo CHECK (
        (tipo = 'personal' AND usuario_id IS NOT NULL AND grupo_id IS NULL) OR
        (tipo = 'grupo' AND grupo_id IS NOT NULL AND usuario_id IS NULL)
    )
);

CREATE INDEX idx_metas_usuario ON metas(usuario_id) WHERE usuario_id IS NOT NULL;
CREATE INDEX idx_metas_grupo ON metas(grupo_id) WHERE grupo_id IS NOT NULL;
CREATE INDEX idx_metas_estado ON metas(estado);
```

---

#### 6. `aportaciones_meta_grupo`
Registra aportaciones individuales a metas grupales.

```sql
CREATE TABLE aportaciones_meta_grupo (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meta_id UUID NOT NULL REFERENCES metas(id) ON DELETE CASCADE,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    monto_asignado DECIMAL(15, 2) NOT NULL, -- Calculado según peso
    monto_aportado DECIMAL(15, 2) DEFAULT 0.00,
    porcentaje_peso DECIMAL(5, 2) NOT NULL,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
    fecha_aportacion TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(meta_id, usuario_id),
    CONSTRAINT chk_montos_aportacion CHECK (monto_aportado >= 0 AND monto_aportado <= monto_asignado)
);

CREATE INDEX idx_aportaciones_meta ON aportaciones_meta_grupo(meta_id);
CREATE INDEX idx_aportaciones_usuario ON aportaciones_meta_grupo(usuario_id);
```

---

#### 7. `historial_ingresos`
Almacena histórico de ingresos para cálculos de promedios.

```sql
CREATE TABLE historial_ingresos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
    transaccion_periodica_id UUID REFERENCES transacciones_periodicas(id) ON DELETE SET NULL,
    monto DECIMAL(15, 2) NOT NULL CHECK (monto > 0),
    tipo_frecuencia VARCHAR(20) CHECK (tipo_frecuencia IN ('quincenal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual', 'variable')),
    fecha_ingreso DATE NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_historial_usuario ON historial_ingresos(usuario_id);
CREATE INDEX idx_historial_fecha ON historial_ingresos(fecha_ingreso);
CREATE INDEX idx_historial_frecuencia ON historial_ingresos(tipo_frecuencia);
```

---

## Reglas de Negocio

### 1. Gestión de Grupos

#### Límite de Miembros
- **Máximo recomendado:** 10 miembros por grupo
- Razón: Mantener gestión simplificada para finanzas personales/familiares
- Puede ajustarse en configuración del sistema

#### Roles y Permisos

| Permiso | Owner | Administrador | Miembro |
|---------|-------|---------------|---------|
| Ver cuentas compartidas | ✅ | ✅ | ✅ |
| Crear transacciones en cuentas compartidas | ✅ | ✅ | ✅ |
| Crear/editar catálogos del grupo | ✅ | ✅ | ❌ |
| Crear/editar cuentas del grupo | ✅ | ✅ | ❌ |
| Invitar miembros | ✅ | ✅ | ❌ |
| Asignar rol Administrador | ✅ | ✅ | ❌ |
| Revocar rol Administrador | ✅ | ✅* | ❌ |
| Eliminar miembros | ✅ | ❌ | ❌ |
| Disolver grupo | ✅ | ❌ | ❌ |
| Salir del grupo | ❌** | ✅ | ✅ |
| Ver cuentas personales de otros | ❌ | ❌ | ❌ |

\* Solo puede revocar a otros administradores, no a sí mismo  
\** Owner no puede salir, debe transferir ownership o disolver grupo

---

### 2. Visibilidad de Catálogos

#### Reglas de Visualización

**Al crear/editar cualquier entidad (cuenta, transacción, etc.):**

```
Catálogos Disponibles = 
    Públicos (es_publico = TRUE) 
    + Personales del Usuario (usuario_id = current_user)
    + Del Grupo (grupo_id = current_group AND usuario es miembro)

Catálogos NO Disponibles = 
    Personales de OTROS usuarios
```

**Ejemplo - Selector de Categorías:**
```
Usuario A en Grupo "Familia":
  ✅ Categorías Públicas (Alimentación, Transporte, etc.)
  ✅ Categorías Personales de A (Mi Hobby, etc.)
  ✅ Categorías del Grupo Familia (Gastos Casa, etc.)
  ❌ Categorías Personales de Usuario B
  ❌ Categorías de otros grupos donde A no está
```

---

### 3. Cuentas Compartidas vs Personales

#### Cuenta Personal
- `grupo_id = NULL`
- `tipo_visibilidad = 'personal'`
- Solo visible para el propietario (`usuario_id`)

#### Cuenta Compartida (Grupo)
- `grupo_id = <UUID del grupo>`
- `tipo_visibilidad = 'grupo'`
- Visible para todos los miembros del grupo
- Cualquier miembro puede registrar transacciones
- Creada por Admin u Owner (`creada_por`)

---

### 4. Cálculo de Peso en Grupo

#### Fórmula Automática

**Si TODOS los miembros tienen ingresos registrados:**

```
Ingreso Anual Usuario = 
    Σ(Ingresos Quincenales × 24) +
    Σ(Ingresos Mensuales × 12) +
    Σ(Ingresos Bimestrales × 6) +
    Σ(Ingresos Trimestrales × 4) +
    Σ(Ingresos Semestrales × 2) +
    Σ(Ingresos Anuales × 1)

Peso Usuario (%) = (Ingreso Anual Usuario / Σ Ingresos Anuales Grupo) × 100
```

**Si algún miembro NO tiene ingresos:**
```
Peso Usuario (%) = 100 / Número de Miembros Activos
```

**Ejemplo:**
```
Grupo de 3 personas:
- Usuario A: $10,000/mes × 12 = $120,000/año
- Usuario B: $15,000/mes × 12 = $180,000/año
- Usuario C: Sin ingresos registrados

Cálculo:
- Total Grupo = $300,000
- Peso A = (120,000 / 300,000) × 100 = 40%
- Peso B = (180,000 / 300,000) × 100 = 60%
- Peso C = No participa en división (o se divide equitativamente si admin configura ingreso manual)
```

---

### 5. Ingresos Variables

#### Manejo de Promedios

Para ingresos que varían mes a mes (comisiones, propinas, etc.):

```sql
-- Calcular estadísticas de los últimos 12 meses
SELECT 
    usuario_id,
    tipo_frecuencia,
    AVG(monto) as promedio,
    MIN(monto) as minimo,
    MAX(monto) as maximo,
    STDDEV(monto) as desviacion_estandar
FROM historial_ingresos
WHERE usuario_id = :usuario_id
    AND tipo_frecuencia = 'variable'
    AND fecha_ingreso >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY usuario_id, tipo_frecuencia;
```

**Criterio de Uso:**
- Si desviación estándar < 10% del promedio → Usar promedio
- Si desviación estándar ≥ 10% del promedio → Usar mínimo (conservador)

---

### 6. División de Gastos Compartidos

#### Proceso

1. **Usuario registra gasto compartido**
   - Marca checkbox "Compartir con grupo"
   - Selecciona miembros participantes (o todos)
   - Opción: "Redondear montos"

2. **Sistema calcula división:**
```javascript
Monto Total = $1,000
Miembros: A (40%), B (60%)

Sin Redondeo:
- A paga: $1,000 × 0.40 = $400.00
- B paga: $1,000 × 0.60 = $600.00

Con Redondeo:
- A paga: $400.00 (ya está redondeado)
- B paga: $600.00 (ya está redondeado)

Con Redondeo (caso con decimales):
Monto Total = $1,573
- A paga: CEIL($1,573 × 0.40) = CEIL($629.20) = $630.00
- B paga: $1,573 - $630 = $943.00
```

3. **Se guarda en `division_gastos`:**
```json
{
  "monto_total": 1000.00,
  "redondeado": false,
  "miembros": [
    {
      "usuario_id": "...",
      "nombre": "Usuario A",
      "porcentaje": 40.00,
      "monto": 400.00,
      "pagado": false
    },
    {
      "usuario_id": "...",
      "nombre": "Usuario B",
      "porcentaje": 60.00,
      "monto": 600.00,
      "pagado": true
    }
  ]
}
```

---

### 7. Invitaciones

#### Flujo

1. **Creación de Invitación:**
   - Admin/Owner envía invitación por email
   - Sistema verifica si email ya es usuario registrado
   - Si es usuario: `usuario_invitado_id` se llena automáticamente
   - Si no: Espera registro con ese email

2. **Notificación:**
   - Email al invitado con link único
   - Notificación in-app si usuario ya registrado

3. **Estados:**
   - `pendiente`: Esperando respuesta
   - `aceptada`: Usuario acepta y se crea `miembros_grupo`
   - `rechazada`: Usuario rechaza
   - `expirada`: Pasan 7 días sin respuesta (trigger automático)

4. **Aceptación:**
```sql
-- Trigger al aceptar invitación
INSERT INTO miembros_grupo (grupo_id, usuario_id, rol, porcentaje_peso)
VALUES (:grupo_id, :usuario_id, :rol_asignado, :porcentaje_inicial);

-- Recalcular pesos de todos los miembros
CALL recalcular_pesos_grupo(:grupo_id);
```

---

## Funcionalidades por Módulo

### Módulo 1: Gestión de Grupos

#### Funcionalidades

- **Crear Grupo**
  - Nombre, descripción, color, imagen
  - Usuario creador se asigna como Owner automáticamente
  - Peso inicial 100%

- **Editar Grupo** (Owner/Admin)
  - Modificar nombre, descripción, color, imagen
  - No puede cambiar owner

- **Ver Miembros**
  - Lista con nombre, rol, peso, fecha ingreso
  - Indicador de ingresos configurados

- **Invitar Miembros** (Owner/Admin)
  - Por email
  - Asignar rol inicial (Admin o Miembro)
  - Mensaje opcional

- **Gestionar Roles** (Owner/Admin)
  - Promover Miembro a Administrador
  - Degradar Administrador a Miembro
  - Owner no se puede cambiar

- **Eliminar Miembro** (Solo Owner)
  - Confirmar acción
  - Recalcular pesos automáticamente
  - No puede eliminar a sí mismo

- **Salir del Grupo** (Admin/Miembro)
  - Confirmar acción
  - Owner no puede salir (debe transferir o disolver)

- **Disolver Grupo** (Solo Owner)
  - Advertencia: Eliminará todas las cuentas compartidas
  - Confirmar con contraseña
  - Soft delete: `activo = FALSE`

---

### Módulo 2: Invitaciones

#### Funcionalidades

- **Visualizar Invitaciones Pendientes**
  - Badge con número de invitaciones
  - Lista de grupos que invitaron
  - Información: nombre grupo, quien invitó, mensaje

- **Aceptar Invitación**
  - Confirmar ingreso al grupo
  - Crear registro en `miembros_grupo`
  - Trigger de recalculo de pesos

- **Rechazar Invitación**
  - Cambiar estado a 'rechazada'
  - Opcionalmente enviar mensaje de rechazo

- **Expiración Automática**
  - Cron job diario que marca como 'expirada' invitaciones > 7 días

---

### Módulo 3: Catálogos de Grupo

#### Funcionalidades por Catálogo

**Niveles, Categorías, Grupos Categoría, Bancos:**

- **Crear** (Owner/Admin)
  - Formulario con opción "Tipo: Personal / Grupo"
  - Si Grupo: Seleccionar grupo
  - Validar permisos

- **Editar** (Owner/Admin)
  - Solo los creados por el usuario o del grupo
  - No puede editar públicos

- **Eliminar** (Owner/Admin)
  - Verificar que no esté en uso
  - Soft delete recomendado

- **Listar**
  - Filtro por tipo: Todos / Públicos / Personales / Grupo X
  - Indicador visual del tipo

---

### Módulo 4: Cuentas Compartidas

#### Funcionalidades

- **Crear Cuenta del Grupo** (Owner/Admin)
  - Igual que cuenta personal pero con `grupo_id`
  - Seleccionar banco del grupo o público
  - `creada_por` = usuario actual

- **Ver Cuentas del Grupo**
  - Todos los miembros ven todas las cuentas del grupo
  - Indicador de quien creó la cuenta
  - Saldo actual, tipo de cuenta

- **Registrar Transacción en Cuenta Compartida** (Todos)
  - `registrada_por` = usuario actual
  - Opción "Gasto Compartido" (checkbox)
  - Si compartido: Mostrar división calculada

- **Ver Historial de Transacciones**
  - Filtro por usuario que registró
  - Mostrar división si es gasto compartido
  - Indicador visual de transacciones compartidas

---

### Módulo 5: Gastos Compartidos

#### Funcionalidades

- **Registrar Gasto Compartido**
  - Checkbox "Dividir gasto con grupo"
  - Seleccionar participantes (por defecto todos)
  - Checkbox "Redondear montos"
  - Vista previa de división antes de guardar

- **Vista Previa de División:**
```
Monto Total: $1,573.00
División según ingresos:

✓ Usuario A (40%)  →  $629.20  [Redondeo: $630.00]
✓ Usuario B (60%)  →  $943.80  [Redondeo: $943.00]
                       -------
Total Redondeado:      $1,573.00 ✓

[Guardar]  [Cancelar]
```

- **Ver División de Gasto**
  - En detalle de transacción
  - Lista de miembros con monto asignado
  - Estado de pago (pagado/pendiente)

- **Marcar como Pagado**
  - Miembro puede marcar su parte como pagada
  - Registro de fecha de pago
  - Notificación al que registró el gasto

- **Reportes de Deudas**
  - Vista de quien debe a quien
  - Total pendiente por miembro
  - Histórico de gastos compartidos

---

### Módulo 6: Metas

#### Metas Personales

- **Crear Meta Personal**
  - Nombre, descripción, monto objetivo
  - Fecha objetivo (opcional)
  - Categoría, ícono, color
  - Prioridad (1-5)

- **Realizar Aportación**
  - Crear transacción vinculada a meta
  - Actualizar `monto_actual`
  - Calcular progreso (%)

- **Ver Progreso**
  - Barra de progreso visual
  - Monto actual vs objetivo
  - Días restantes
  - Aportación sugerida diaria/mensual

#### Metas Grupales

- **Crear Meta del Grupo** (Owner/Admin)
  - Similar a personal pero con `grupo_id`
  - Al crear: Calcular aportación por miembro según peso

- **Cálculo de Aportaciones:**
```
Meta: Vacaciones $50,000
Miembros:
- Usuario A (40%) → Debe aportar $20,000
- Usuario B (60%) → Debe aportar $30,000
```

- **Aportar a Meta Grupal** (Todos)
  - Registrar transacción individual
  - Vincular a meta y usuario
  - Actualizar `monto_aportado` en `aportaciones_meta_grupo`
  - Actualizar `monto_actual` de meta

- **Ver Progreso Grupal**
  - Barra de progreso total
  - Desglose por miembro:
    - Aportado / Asignado
    - Porcentaje completado individual
  - Ranking de aportaciones

---

## Cálculos Automáticos

### 1. Recalculo de Pesos

**Trigger:** Cuando se agrega/elimina miembro o se actualizan ingresos

```sql
CREATE OR REPLACE FUNCTION recalcular_pesos_grupo(p_grupo_id UUID)
RETURNS VOID AS $$
DECLARE
    v_total_ingresos DECIMAL(15, 2);
    v_tiene_ingresos_todos BOOLEAN;
    v_num_miembros INTEGER;
    v_peso_equitativo DECIMAL(5, 2);
BEGIN
    -- Contar miembros activos
    SELECT COUNT(*) INTO v_num_miembros
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id AND activo = TRUE;
    
    -- Verificar si todos tienen ingresos
    SELECT 
        COUNT(*) = v_num_miembros
    INTO v_tiene_ingresos_todos
    FROM miembros_grupo mg
    WHERE mg.grupo_id = p_grupo_id 
        AND mg.activo = TRUE
        AND (
            -- Tiene transacciones periódicas de ingreso
            EXISTS (
                SELECT 1 FROM transacciones_periodicas tp
                WHERE tp.usuario_id = mg.usuario_id
                    AND tp.tipo = 'ingreso'
                    AND tp.es_ingreso_base = TRUE
                    AND tp.activa = TRUE
            )
            OR
            -- O tiene ingreso manual configurado
            mg.ingreso_manual_mensual IS NOT NULL
        );
    
    IF v_tiene_ingresos_todos THEN
        -- Calcular ingreso anual de cada miembro
        WITH ingresos_anuales AS (
            SELECT 
                mg.id as miembro_id,
                mg.usuario_id,
                COALESCE(
                    -- Sumar ingresos periódicos anualizados
                    (SELECT SUM(
                        CASE 
                            WHEN tp.tipo_ingreso = 'quincenal' THEN tp.monto * 24
                            WHEN tp.tipo_ingreso = 'mensual' THEN tp.monto * 12
                            WHEN tp.tipo_ingreso = 'bimestral' THEN tp.monto * 6
                            WHEN tp.tipo_ingreso = 'trimestral' THEN tp.monto * 4
                            WHEN tp.tipo_ingreso = 'semestral' THEN tp.monto * 2
                            WHEN tp.tipo_ingreso = 'anual' THEN tp.monto
                            ELSE 0
                        END
                    )
                    FROM transacciones_periodicas tp
                    WHERE tp.usuario_id = mg.usuario_id
                        AND tp.tipo = 'ingreso'
                        AND tp.es_ingreso_base = TRUE
                        AND tp.activa = TRUE
                    ),
                    -- O usar ingreso manual mensual * 12
                    mg.ingreso_manual_mensual * 12,
                    0
                ) as ingreso_anual
            FROM miembros_grupo mg
            WHERE mg.grupo_id = p_grupo_id AND mg.activo = TRUE
        )
        SELECT SUM(ingreso_anual) INTO v_total_ingresos FROM ingresos_anuales;
        
        -- Actualizar pesos proporcionalmente
        WITH ingresos_anuales AS (
            SELECT 
                mg.id as miembro_id,
                COALESCE(
                    (SELECT SUM(
                        CASE 
                            WHEN tp.tipo_ingreso = 'quincenal' THEN tp.monto * 24
                            WHEN tp.tipo_ingreso = 'mensual' THEN tp.monto * 12
                            WHEN tp.tipo_ingreso = 'bimestral' THEN tp.monto * 6
                            WHEN tp.tipo_ingreso = 'trimestral' THEN tp.monto * 4
                            WHEN tp.tipo_ingreso = 'semestral' THEN tp.monto * 2
                            WHEN tp.tipo_ingreso = 'anual' THEN tp.monto
                            ELSE 0
                        END
                    )
                    FROM transacciones_periodicas tp
                    WHERE tp.usuario_id = mg.usuario_id
                        AND tp.tipo = 'ingreso'
                        AND tp.es_ingreso_base = TRUE
                        AND tp.activa = TRUE
                    ),
                    mg.ingreso_manual_mensual * 12,
                    0
                ) as ingreso_anual
            FROM miembros_grupo mg
            WHERE mg.grupo_id = p_grupo_id AND mg.activo = TRUE
        )
        UPDATE miembros_grupo mg
        SET porcentaje_peso = ROUND((ia.ingreso_anual / v_total_ingresos) * 100, 2)
        FROM ingresos_anuales ia
        WHERE mg.id = ia.miembro_id;
    ELSE
        -- Dividir equitativamente
        v_peso_equitativo := ROUND(100.0 / v_num_miembros, 2);
        
        UPDATE miembros_grupo
        SET porcentaje_peso = v_peso_equitativo
        WHERE grupo_id = p_grupo_id AND activo = TRUE;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

---

### 2. División de Gastos

```sql
CREATE OR REPLACE FUNCTION calcular_division_gasto(
    p_monto_total DECIMAL(15, 2),
    p_grupo_id UUID,
    p_miembros_participantes UUID[], -- Array de IDs de miembros participantes
    p_redondear BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
    v_division JSONB;
    v_miembro RECORD;
    v_monto_asignado DECIMAL(15, 2);
    v_suma_verificacion DECIMAL(15, 2) := 0;
    v_diferencia DECIMAL(15, 2);
    v_resultado JSONB := '[]'::JSONB;
BEGIN
    -- Iterar sobre miembros participantes
    FOR v_miembro IN
        SELECT 
            mg.usuario_id,
            u.email,
            mg.porcentaje_peso
        FROM miembros_grupo mg
        JOIN auth.users u ON u.id = mg.usuario_id
        WHERE mg.grupo_id = p_grupo_id
            AND mg.activo = TRUE
            AND (
                p_miembros_participantes IS NULL 
                OR mg.usuario_id = ANY(p_miembros_participantes)
            )
        ORDER BY mg.porcentaje_peso DESC
    LOOP
        -- Calcular monto
        v_monto_asignado := p_monto_total * (v_miembro.porcentaje_peso / 100);
        
        -- Redondear si se solicita
        IF p_redondear THEN
            v_monto_asignado := CEIL(v_monto_asignado);
        END IF;
        
        v_suma_verificacion := v_suma_verificacion + v_monto_asignado;
        
        -- Agregar al resultado
        v_resultado := v_resultado || JSONB_BUILD_OBJECT(
            'usuario_id', v_miembro.usuario_id,
            'usuario_email', v_miembro.email,
            'porcentaje', v_miembro.porcentaje_peso,
            'monto_asignado', v_monto_asignado,
            'pagado', FALSE,
            'fecha_pago', NULL
        );
    END LOOP;
    
    -- Ajustar diferencia por redondeo (asignar al miembro con mayor peso)
    IF p_redondear AND v_suma_verificacion != p_monto_total THEN
        v_diferencia := p_monto_total - v_suma_verificacion;
        
        -- Actualizar primer elemento (mayor peso)
        v_resultado := JSONB_SET(
            v_resultado,
            '{0,monto_asignado}',
            TO_JSONB((v_resultado->0->>'monto_asignado')::DECIMAL + v_diferencia)
        );
    END IF;
    
    RETURN JSONB_BUILD_OBJECT(
        'monto_total', p_monto_total,
        'redondeado', p_redondear,
        'miembros', v_resultado
    );
END;
$$ LANGUAGE plpgsql;
```

---

### 3. Calcular Ingresos Promedio (Variables)

```sql
CREATE OR REPLACE FUNCTION calcular_ingreso_promedio_usuario(
    p_usuario_id UUID,
    p_tipo_frecuencia VARCHAR DEFAULT NULL,
    p_meses_historial INTEGER DEFAULT 12
)
RETURNS TABLE (
    tipo_frecuencia VARCHAR,
    promedio DECIMAL(15, 2),
    minimo DECIMAL(15, 2),
    maximo DECIMAL(15, 2),
    desviacion_estandar DECIMAL(15, 2),
    num_registros INTEGER,
    usar_minimo BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        hi.tipo_frecuencia,
        AVG(hi.monto)::DECIMAL(15, 2) as promedio,
        MIN(hi.monto)::DECIMAL(15, 2) as minimo,
        MAX(hi.monto)::DECIMAL(15, 2) as maximo,
        STDDEV(hi.monto)::DECIMAL(15, 2) as desviacion_estandar,
        COUNT(*)::INTEGER as num_registros,
        (STDDEV(hi.monto) >= AVG(hi.monto) * 0.10) as usar_minimo
    FROM historial_ingresos hi
    WHERE hi.usuario_id = p_usuario_id
        AND (p_tipo_frecuencia IS NULL OR hi.tipo_frecuencia = p_tipo_frecuencia)
        AND hi.fecha_ingreso >= CURRENT_DATE - (p_meses_historial || ' months')::INTERVAL
    GROUP BY hi.tipo_frecuencia;
END;
$$ LANGUAGE plpgsql;
```

---

## Plan de Implementación

### Fase 1: Fundamentos (Semana 1-2)
**Prioridad: ALTA**

- [ ] Crear tablas base: `grupos`, `miembros_grupo`, `invitaciones_grupo`
- [ ] Modificar tablas existentes con campos `grupo_id` y `tipo_visibilidad`
- [ ] Implementar triggers de expiración de invitaciones
- [ ] Crear función `recalcular_pesos_grupo()`
- [ ] Políticas RLS para acceso a grupos

**Entregables:**
- SQL ejecutable con todas las tablas
- Funciones y triggers documentados
- Tests de políticas RLS

---

### Fase 2: UI de Gestión de Grupos (Semana 3-4)
**Prioridad: ALTA**

- [ ] Módulo de creación de grupos
- [ ] Vista de lista de grupos del usuario
- [ ] Gestión de miembros (roles, eliminar, salir)
- [ ] Sistema de invitaciones (enviar, aceptar, rechazar)
- [ ] Indicadores visuales de tipo de catálogo

**Componentes Vue:**
- `GroupList.vue`
- `GroupForm.vue`
- `GroupMembers.vue`
- `InvitationsList.vue`
- `InvitationCard.vue`

---

### Fase 3: Catálogos Compartidos (Semana 5)
**Prioridad: MEDIA**

- [ ] Modificar selectores de catálogos para filtrar por visibilidad
- [ ] Agregar toggle "Personal / Grupo" en formularios
- [ ] Actualizar funciones de store para considerar `grupo_id`
- [ ] Indicadores visuales en listas de catálogos

**Componentes a Modificar:**
- `CategoryPicker.vue`
- `LevelPicker.vue`
- `AccountPicker.vue`
- Formularios de creación de catálogos

---

### Fase 4: Cuentas Compartidas (Semana 6)
**Prioridad: ALTA**

- [ ] Modificar formulario de cuentas para soportar grupos
- [ ] Filtros de cuentas personales vs grupales
- [ ] Vista de cuentas del grupo
- [ ] Permisos de transacciones en cuentas compartidas

**Store Changes:**
- `accounts.js`: Agregar métodos para cuentas de grupo
- Filtros en queries de Supabase

---

### Fase 5: Ingresos y Cálculo de Peso (Semana 7-8)
**Prioridad: ALTA**

- [ ] Marcar transacciones periódicas como `es_ingreso_base`
- [ ] Interfaz para configurar ingresos del usuario
- [ ] Vista de resumen de ingresos anualizados
- [ ] Trigger automático de recalculo de pesos
- [ ] Dashboard de pesos del grupo

**Funcionalidades:**
- Clasificación de ingresos por frecuencia
- Cálculo automático de peso
- Configuración manual de ingresos (admin)
- Alertas de ingresos no configurados

---

### Fase 6: División de Gastos (Semana 9-10)
**Prioridad: ALTA**

- [ ] Checkbox "Gasto Compartido" en registro de transacción
- [ ] Selector de participantes del grupo
- [ ] Vista previa de división antes de guardar
- [ ] Función `calcular_division_gasto()` en backend
- [ ] Vista de detalle con división de gasto
- [ ] Marcar partes como pagadas
- [ ] Reporte de deudas entre miembros

**Componentes:**
- `ExpenseSplitter.vue`
- `SplitPreview.vue`
- `DebtsSummary.vue`
- `GroupExpenses.vue`

---

### Fase 7: Metas (Semana 11-12)
**Prioridad: MEDIA**

- [ ] Tabla `metas` y `aportaciones_meta_grupo`
- [ ] CRUD de metas personales
- [ ] CRUD de metas grupales
- [ ] Sistema de aportaciones
- [ ] Vista de progreso individual/grupal
- [ ] Cálculo de aportación sugerida

**Componentes:**
- `GoalsList.vue`
- `GoalForm.vue`
- `GoalProgress.vue`
- `GroupGoalProgress.vue`
- `ContributionModal.vue`

---

### Fase 8: Reportes y Analíticas (Semana 13)
**Prioridad: BAJA**

- [ ] Dashboard de grupo (resumen financiero)
- [ ] Reporte de gastos compartidos del mes
- [ ] Análisis de peso vs aportación real
- [ ] Gráficas de evolución de metas grupales
- [ ] Exportación de reportes

---

### Fase 9: Notificaciones (Semana 14)
**Prioridad: BAJA**

- [ ] Notificación de invitaciones
- [ ] Notificación de gastos compartidos
- [ ] Recordatorios de deudas
- [ ] Notificación de logro de metas
- [ ] Email summaries semanales

---

### Fase 10: Optimización y Testing (Semana 15-16)
**Prioridad: MEDIA**

- [ ] Tests unitarios de funciones SQL
- [ ] Tests de componentes Vue
- [ ] Tests E2E de flujos completos
- [ ] Optimización de queries
- [ ] Índices adicionales según uso
- [ ] Documentación de usuario final

---

## Notas de Implementación

### Seguridad (RLS Policies)

```sql
-- Ejemplo de política para grupos
CREATE POLICY "Usuarios pueden ver grupos donde son miembros"
ON grupos FOR SELECT
USING (
    id IN (
        SELECT grupo_id 
        FROM miembros_grupo 
        WHERE usuario_id = auth.uid() AND activo = TRUE
    )
);

-- Ejemplo de política para catálogos
CREATE POLICY "Ver catálogos públicos, personales y de grupos"
ON categorias FOR SELECT
USING (
    es_publico = TRUE
    OR usuario_id = auth.uid()
    OR (
        grupo_id IN (
            SELECT grupo_id 
            FROM miembros_grupo 
            WHERE usuario_id = auth.uid() AND activo = TRUE
        )
    )
);
```

### Performance

- Índices en todas las columnas `grupo_id`
- Índices en `miembros_grupo(usuario_id, activo)`
- Índice en `invitaciones_grupo(fecha_expiracion)` para cron job
- Caché de cálculos de peso en store Pinia
- Paginación en listas de transacciones de grupo

### Consideraciones Futuras

1. **Transferencia de Ownership:**
   - Implementar flujo de transferencia de owner a otro miembro
   - Requiere confirmación del nuevo owner

2. **Historial de Cambios:**
   - Auditoría de cambios en configuración de grupo
   - Registro de quien modificó qué

3. **Múltiples Monedas:**
   - Conversión automática para grupos internacionales
   - Almacenar en moneda base del grupo

4. **Integración Bancaria:**
   - Sincronización automática de cuentas compartidas
   - Detección de transacciones duplicadas

---

## Anexos

### A. Ejemplos de Queries Comunes

**1. Obtener todos los grupos de un usuario con rol:**
```sql
SELECT 
    g.*,
    mg.rol,
    mg.porcentaje_peso,
    COUNT(mg2.id) as total_miembros
FROM grupos g
JOIN miembros_grupo mg ON mg.grupo_id = g.id
LEFT JOIN miembros_grupo mg2 ON mg2.grupo_id = g.id AND mg2.activo = TRUE
WHERE mg.usuario_id = :usuario_id 
    AND mg.activo = TRUE
    AND g.activo = TRUE
GROUP BY g.id, mg.rol, mg.porcentaje_peso;
```

**2. Obtener gastos compartidos pendientes de un usuario:**
```sql
SELECT 
    t.*,
    c.nombre as cuenta_nombre,
    g.nombre as grupo_nombre,
    u.email as registrado_por_email,
    (division->>'monto_asignado')::DECIMAL as mi_monto,
    (division->>'pagado')::BOOLEAN as mi_pago_realizado
FROM transacciones t
JOIN cuentas c ON c.id = t.cuenta_id
JOIN grupos g ON g.id = t.grupo_id
JOIN auth.users u ON u.id = t.registrada_por
CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(t.division_gastos->'miembros') as division
WHERE (division->>'usuario_id')::UUID = :usuario_id
    AND (division->>'pagado')::BOOLEAN = FALSE
    AND t.es_gasto_compartido = TRUE
ORDER BY t.fecha_ocurrencia DESC;
```

**3. Calcular total adeudado por usuario en grupo:**
```sql
SELECT 
    (division->>'usuario_id')::UUID as usuario_id,
    SUM((division->>'monto_asignado')::DECIMAL) as total_adeudado
FROM transacciones t
CROSS JOIN LATERAL JSONB_ARRAY_ELEMENTS(t.division_gastos->'miembros') as division
WHERE t.grupo_id = :grupo_id
    AND t.es_gasto_compartido = TRUE
    AND (division->>'pagado')::BOOLEAN = FALSE
GROUP BY (division->>'usuario_id')::UUID;
```

---

### B. Diagrama ER Simplificado

```
┌─────────────┐         ┌──────────────────┐         ┌─────────────┐
│   grupos    │◄────────┤ miembros_grupo   ├────────►│    users    │
└─────────────┘ 1     n └──────────────────┘ n     1 └─────────────┘
      │                          │
      │ 1                        │ 1
      │                          │
      │ n                        │ n
┌─────▼─────────┐         ┌──────▼──────────────────┐
│   cuentas     │         │ invitaciones_grupo      │
│ (compartidas) │         └─────────────────────────┘
└───────────────┘
      │ 1
      │
      │ n
┌─────▼──────────────┐
│  transacciones     │
│ (con división)     │
└────────────────────┘
```

---

## Control de Versiones del Documento

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0 | 2025-12-23 | Sistema | Creación inicial de especificación completa |

---

**Fin del Documento**
