# Rollback y Recreación de Base de Datos

## ✅ Cambios Integrados

Se han integrado las **transacciones periódicas** en los scripts principales de la base de datos:

### Archivos Modificados:

1. **`1. db_finah.sql`** ✅
   - ✅ Agregado DROP de tablas nuevas en sección de limpieza
   - ✅ Agregado DROP de tipos ENUM nuevos
   - ✅ Creados 3 tipos ENUM nuevos: `dia_semana`, `frecuencia_transaccion`, `criterio_finalizacion`
   - ✅ Creada tabla `transacciones_periodicas` (después de `historial_saldos`)
   - ✅ Creada tabla `ejecuciones_transacciones_periodicas`
   - ✅ Agregadas 2 funciones: `calcular_proxima_ejecucion()` y `crear_msi_tarjeta_credito()`

2. **`2. db_policies.sql`** ✅
   - ✅ Activado RLS en las 2 nuevas tablas
   - ✅ Agregadas políticas para `transacciones_periodicas` (SELECT, INSERT, UPDATE, DELETE)
   - ✅ Agregadas políticas para `ejecuciones_transacciones_periodicas` (SELECT, INSERT, UPDATE, DELETE)

3. **`3. finah_carga_inicial.sql`** ✅
   - ✅ No requiere cambios (los datos iniciales son los mismos)

---

## 📋 Pasos para Rollback y Recreación

### Opción 1: Desde Supabase SQL Editor (Recomendado)

1. **Abrir Supabase Dashboard**
   - Ir a tu proyecto en https://supabase.com
   - Seleccionar "SQL Editor" en el menú lateral

2. **Ejecutar script 1: Base de Datos**
   ```sql
   -- Copiar y pegar TODO el contenido de: 1. db_finah.sql
   ```
   - Este script automáticamente:
     - Elimina todas las tablas existentes (CASCADE)
     - Elimina todos los tipos ENUM existentes
     - Recrea todo desde cero

3. **Ejecutar script 2: Políticas RLS**
   ```sql
   -- Copiar y pegar TODO el contenido de: 2. db_policies.sql
   ```

4. **Ejecutar script 3: Datos Iniciales**
   ```sql
   -- Copiar y pegar TODO el contenido de: 3. finah_carga_inicial.sql
   ```

### Opción 2: Usando psql (Terminal)

```bash
# Conectar a la base de datos
psql -h db.xxxxxxxxxxxx.supabase.co -p 5432 -d postgres -U postgres

# Ejecutar scripts en orden
\i "1. db_finah.sql"
\i "2. db_policies.sql"
\i "3. finah_carga_inicial.sql"
```

### Opción 3: Script Único (Todo en Uno)

Si prefieres ejecutar todo de una vez, puedes concatenar los archivos:

```bash
# En PowerShell (Windows)
Get-Content "1. db_finah.sql", "2. db_policies.sql", "3. finah_carga_inicial.sql" | Set-Content "0. db_completa.sql"
```

Luego ejecutar el archivo resultante.

---

## ⚠️ Advertencias Importantes

### 🔴 **ESTO ELIMINARÁ TODOS LOS DATOS**

El script `1. db_finah.sql` incluye:
```sql
DROP TABLE IF EXISTS transacciones_periodicas CASCADE;
DROP TABLE IF EXISTS ejecuciones_transacciones_periodicas CASCADE;
-- ... y todas las demás tablas
```

**Todos los datos actuales se perderán irreversiblemente.**

### ✅ **Antes de Ejecutar:**

1. **Hacer respaldo** si tienes datos importantes:
   ```sql
   -- Exportar datos importantes
   COPY transacciones TO '/tmp/transacciones_backup.csv' CSV HEADER;
   COPY cuentas TO '/tmp/cuentas_backup.csv' CSV HEADER;
   -- etc.
   ```

2. **Verificar conexión** a la base de datos correcta

3. **Tener tiempo** - La recreación puede tomar 1-2 minutos

---

## 🎯 Qué Incluye la Nueva Base de Datos

### Tablas Nuevas:
1. **`transacciones_periodicas`** - Transacciones recurrentes y programadas
2. **`ejecuciones_transacciones_periodicas`** - Historial de ejecuciones

### Tipos ENUM Nuevos:
1. **`dia_semana`** - 'lunes', 'martes', 'miercoles', etc.
2. **`frecuencia_transaccion`** - 'diaria', 'semanal', 'mensual', 'msi', etc.
3. **`criterio_finalizacion`** - 'sin_fin', 'fecha_fin', 'numero_repeticiones'

### Funciones Nuevas:
1. **`calcular_proxima_ejecucion()`** - Calcula próxima fecha de ejecución
2. **`crear_msi_tarjeta_credito()`** - Crea MSI completo con ejecuciones

### Políticas RLS:
- ✅ Usuarios solo ven sus propias transacciones periódicas
- ✅ Usuarios solo ven ejecuciones de sus transacciones
- ✅ CRUD completo protegido por usuario

---

## ✨ Funcionalidades Nuevas Disponibles

Después de ejecutar los scripts, tendrás acceso a:

### 1. Ingresos Periódicos
- Salario quincenal (cada 15)
- Salario mensual (día específico)
- Rentas, honorarios, etc.

### 2. Gastos Recurrentes
- Renta (cada 1 del mes)
- Netflix (cada martes)
- Gym (cada 30 días naturales)
- Luz bimestral (cada 2 meses)
- Seguro anual (fecha específica)

### 3. MSI (Meses Sin Intereses)
- Crear MSI nuevos (completos)
- Registrar MSI en progreso (4 de 12 meses pagados)
- Auto-ejecución en fechas de corte
- Tracking de cuotas

### 4. Configuración Avanzada
- Finalización por fecha límite
- Finalización por número de repeticiones
- Sin fin (indefinido)
- Múltiples días de la semana
- Días naturales personalizados

---

## 🔄 Verificar que Todo Funcionó

Después de ejecutar los scripts, verifica:

```sql
-- 1. Verificar que las tablas existen
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('transacciones_periodicas', 'ejecuciones_transacciones_periodicas')
ORDER BY table_name;

-- 2. Verificar que los tipos ENUM existen
SELECT typname 
FROM pg_type 
WHERE typname IN ('dia_semana', 'frecuencia_transaccion', 'criterio_finalizacion')
ORDER BY typname;

-- 3. Verificar que las funciones existen
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('calcular_proxima_ejecucion', 'crear_msi_tarjeta_credito')
ORDER BY routine_name;

-- 4. Verificar que RLS está activo
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('transacciones_periodicas', 'ejecuciones_transacciones_periodicas');

-- 5. Verificar políticas RLS
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('transacciones_periodicas', 'ejecuciones_transacciones_periodicas')
ORDER BY tablename, policyname;

-- 6. Verificar datos iniciales
SELECT COUNT(*) as total_niveles FROM niveles WHERE es_publico = TRUE;
SELECT COUNT(*) as total_categorias FROM categorias WHERE es_publico = TRUE;
SELECT COUNT(*) as total_bancos FROM bancos WHERE es_publico = TRUE;
```

**Resultados esperados:**
- ✅ 2 tablas nuevas
- ✅ 3 tipos ENUM nuevos
- ✅ 2 funciones nuevas
- ✅ RLS activo en ambas tablas
- ✅ 8 políticas (4 por tabla)
- ✅ 3 niveles públicos
- ✅ ~45 categorías públicas
- ✅ ~15 bancos públicos

---

## 🚀 Siguiente Paso

Una vez que la base de datos esté recreada:

1. ✅ Verificar que todo funcionó (queries arriba)
2. 🔄 Actualizar el store `recurring-transactions.js` (ya está listo)
3. 📝 Crear componentes de UI para configurar transacciones periódicas
4. 🎨 Crear vista de ejecuciones pendientes

---

## 📞 Soporte

Si encuentras algún error durante la ejecución:

1. **Copia el mensaje de error completo**
2. **Identifica en qué script falló** (1, 2 o 3)
3. **Verifica que el orden de ejecución sea correcto**
4. **Asegúrate de que todos los DROP CASCADE se ejecutaron**

---

**Fecha:** Diciembre 8, 2025  
**Versión BD:** 2.0 (Con transacciones periódicas integradas)
