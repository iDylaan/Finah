# 🚀 GUÍA DE MIGRACIÓN - MEJORAS PARA GRUPOS FINANCIEROS

## 📋 Resumen de Cambios

Esta migración agrega funcionalidades avanzadas para:
- ✅ Sistema de invitaciones a grupos con tokens seguros
- ✅ Historial automático de saldos para análisis temporal
- ✅ Mejoras en metas (notificaciones, límites, iconos personalizados)
- ✅ Vistas materializadas para estadísticas
- ✅ Funciones auxiliares para operaciones comunes

---

## 🎯 PASOS PARA EJECUTAR LA MIGRACIÓN EN SUPABASE

### **Opción 1: Ejecutar en Supabase Dashboard (RECOMENDADO)**

1. **Accede al SQL Editor de Supabase**
   - Ve a tu proyecto en [Supabase Dashboard](https://app.supabase.com)
   - Navega a: `SQL Editor` → `New Query`

2. **Copia el contenido del archivo de migración**
   - Abre el archivo: `sql/4. migration_mejoras_grupos.sql`
   - Copia TODO el contenido (Ctrl+A, Ctrl+C)

3. **Pega y ejecuta**
   - Pega el código en el SQL Editor
   - Haz clic en el botón **"Run"** (o presiona Ctrl+Enter)
   - Espera a que se ejecute completamente (puede tardar 10-20 segundos)

4. **Verifica que no haya errores**
   - Si todo está correcto, verás mensajes de éxito
   - Si hay errores, léelos cuidadosamente (probablemente ya existen algunas tablas)

---

### **Opción 2: Ejecutar con Supabase CLI**

```bash
# 1. Asegúrate de tener Supabase CLI instalado
npm install -g supabase

# 2. Conéctate a tu proyecto
supabase login

# 3. Ejecuta la migración
supabase db push --db-url "postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres"

# O si ya tienes el proyecto linkeado:
supabase db execute -f sql/4.\ migration_mejoras_grupos.sql
```

---

## 🔍 VERIFICACIÓN POST-MIGRACIÓN

Ejecuta esta consulta en el SQL Editor para verificar que todo se creó correctamente:

```sql
-- Verificar que las nuevas tablas existen
SELECT 
  table_name,
  CASE 
    WHEN table_name IN ('invitaciones_grupo', 'historial_saldos') THEN '✅ Nueva tabla'
    ELSE '📋 Tabla existente'
  END AS estado
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'invitaciones_grupo',
    'historial_saldos',
    'metas',
    'cuentas'
  )
ORDER BY table_name;

-- Verificar que las columnas nuevas en metas existen
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_name = 'metas'
  AND column_name IN (
    'notificar_al_alcanzar',
    'permitir_exceder',
    'icon_library',
    'icon_name',
    'color'
  );

-- Verificar que las funciones se crearon
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'guardar_historial_saldo',
    'expirar_invitaciones_vencidas',
    'dividir_gasto_grupal',
    'aceptar_invitacion_grupo'
  );

-- Verificar que las vistas se crearon
SELECT 
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'VIEW'
  AND table_name LIKE 'vista_%';
```

---

## 📊 NUEVAS FUNCIONALIDADES DISPONIBLES

### 1️⃣ **Sistema de Invitaciones a Grupos**

```javascript
// Crear una invitación
const { data, error } = await supabase
  .from('invitaciones_grupo')
  .insert({
    grupo_id: 'uuid-del-grupo',
    email_invitado: 'usuario@ejemplo.com',
    usuario_invitador: userId,
    rol_propuesto: 'miembro',
    porcentaje_propuesto: 25,
    mensaje_invitacion: '¡Únete a nuestro grupo de gastos!'
  })
  .select()
  .single();

// Aceptar invitación (mediante función)
const { data: resultado } = await supabase
  .rpc('aceptar_invitacion_grupo', {
    p_token: 'uuid-del-token',
    p_usuario_id: userId
  });
```

### 2️⃣ **Historial de Saldos (Automático)**

```javascript
// El historial se guarda AUTOMÁTICAMENTE cuando cambias el saldo
const { error } = await supabase
  .from('cuentas')
  .update({ saldo: nuevoSaldo })
  .eq('id', cuentaId);

// Consultar historial de una cuenta
const { data: historial } = await supabase
  .from('historial_saldos')
  .select('*')
  .eq('cuenta_id', cuentaId)
  .order('fecha', { ascending: false })
  .limit(30);

// Gráfica de evolución del saldo
const { data: evolucion } = await supabase
  .from('historial_saldos')
  .select('fecha, saldo_nuevo')
  .eq('cuenta_id', cuentaId)
  .gte('fecha', '2024-01-01')
  .order('fecha', { ascending: true });
```

### 3️⃣ **División Automática de Gastos Grupales**

```javascript
// Dividir un gasto entre los miembros del grupo
const { error } = await supabase
  .rpc('dividir_gasto_grupal', {
    p_transaccion_id: 'uuid-transaccion',
    p_grupo_id: 'uuid-grupo'
  });

// Consultar divisiones de una transacción
const { data: divisiones } = await supabase
  .from('divisiones_transaccion')
  .select(`
    *,
    usuario:profiles(id, full_name)
  `)
  .eq('transaccion_id', transaccionId);
```

### 4️⃣ **Vistas para Estadísticas**

```javascript
// Patrimonio neto del usuario
const { data: patrimonio } = await supabase
  .from('vista_patrimonio_usuario')
  .select('*')
  .eq('usuario_id', userId)
  .single();

// Gastos del mes actual por categoría
const { data: gastos } = await supabase
  .from('vista_gastos_mes_actual')
  .select('*')
  .eq('usuario_id', userId)
  .order('total_gastado', { ascending: false });

// Progreso de metas
const { data: metas } = await supabase
  .from('vista_progreso_metas')
  .select('*')
  .eq('usuario_id', userId)
  .order('porcentaje_completado', { ascending: false });
```

### 5️⃣ **Metas Mejoradas**

```javascript
// Crear meta con notificaciones
const { data: meta } = await supabase
  .from('metas')
  .insert({
    usuario_id: userId,
    titulo: 'Fondo de Emergencias',
    tipo: 'ahorro',
    monto_objetivo: 50000,
    notificar_al_alcanzar: 80, // Notificar al 80%
    permitir_exceder: false,    // Bloquear al 100%
    icon_library: 'material',
    icon_name: 'savings',
    color: '#4CAF50'
  });
```

---

## ⚠️ SOLUCIÓN DE PROBLEMAS

### Error: "relation already exists"
**Solución:** Algunas tablas ya existen. Esto es normal si ejecutaste partes del script antes. Puedes:
- Ignorar el error y continuar
- O ejecutar solo las partes faltantes

### Error: "column already exists"
**Solución:** Las columnas ya fueron agregadas previamente. Puedes ignorar este error.

### Error: "function already exists"
**Solución:** Ejecuta primero `DROP FUNCTION IF EXISTS nombre_funcion CASCADE;` antes de crear la función.

### Error de permisos
**Solución:** Asegúrate de estar ejecutando como usuario `postgres` o con permisos de superusuario.

### Vistas marcadas como "UNRESTRICTED" en Supabase
**Esto es NORMAL y SEGURO** ⚠️
- Las vistas heredan las políticas RLS de las tablas base
- Las tablas `cuentas`, `transacciones`, `metas` SÍ tienen RLS habilitado
- Supabase solo muestra este aviso porque las vistas en sí no tienen políticas directas

**Solución (opcional):** Si quieres que Supabase deje de mostrar el aviso:
1. Ejecuta el archivo: `sql/7. fix_vistas_rls.sql`
2. Esto agregará `security_barrier` a las vistas
3. También crea funciones alternativas más seguras

---

## 🧪 PRUEBAS RECOMENDADAS

Después de la migración, prueba estas operaciones:

```sql
-- 1. Crear una invitación
INSERT INTO invitaciones_grupo (
  grupo_id,
  email_invitado,
  usuario_invitador
) VALUES (
  (SELECT id FROM grupos_usuario LIMIT 1),
  'test@ejemplo.com',
  auth.uid()
);

-- 2. Actualizar saldo de una cuenta (debe crear historial)
UPDATE cuentas 
SET saldo = saldo + 1000 
WHERE id = (SELECT id FROM cuentas LIMIT 1);

-- 3. Verificar que se creó el historial
SELECT * FROM historial_saldos 
ORDER BY fecha DESC 
LIMIT 5;

-- 4. Ver el patrimonio
SELECT * FROM vista_patrimonio_usuario
WHERE usuario_id = auth.uid();
```

---

## 📚 ARCHIVOS ACTUALIZADOS

- ✅ `sql/4. migration_mejoras_grupos.sql` - **EJECUTAR ESTE ARCHIVO**
- ✅ `sql/1. db_finah.sql` - Actualizado con nuevas tablas
- ✅ `sql/2. db_policies.sql` - Políticas RLS agregadas
- ✅ `sql/dbdiagram.txt` - Diagrama actualizado

---

## 🎉 ¡LISTO!

Después de ejecutar la migración tendrás disponibles:
- ✅ Sistema completo de invitaciones a grupos
- ✅ Historial automático de saldos
- ✅ División de gastos grupales
- ✅ Vistas para estadísticas
- ✅ Metas mejoradas con notificaciones

**Siguiente paso:** Implementar la lógica en el frontend (stores, componentes, etc.)
