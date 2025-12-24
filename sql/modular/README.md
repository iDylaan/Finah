# Scripts Modulares de Base de Datos - Sistema Finah

Este directorio contiene los scripts SQL modulares del sistema Finah, divididos en archivos más pequeños y manejables para facilitar el mantenimiento y la comprensión del esquema de base de datos.

## 📋 Orden de Ejecución

Los scripts deben ejecutarse en el siguiente orden estricto para respetar las dependencias entre tablas y funciones:

### 1️⃣ **01_extensiones_y_tipos.sql**
- **Descripción**: Crea las extensiones necesarias (pgcrypto) y todos los tipos ENUM personalizados
- **Dependencias**: Ninguna
- **Contenido**:
  - Extensión `pgcrypto` para UUIDs
  - 10 tipos ENUM: `tipo_transaccion`, `tipo_meta`, `periodicidad`, `biblioteca_iconos`, `severidad`, `rol_grupo`, `estado_invitacion`, `dia_semana`, `frecuencia_transaccion`, `criterio_finalizacion`

### 2️⃣ **02_tablas_catalogos.sql**
- **Descripción**: Crea las tablas de catálogos básicos del sistema
- **Dependencias**: Script 01
- **Contenido**:
  - Tabla `grupos_categoria` - Grupos de categorías (Hogar, Transporte, etc.)
  - Tabla `categorias` - Categorías específicas (Gasolina, Supermercado, etc.)
  - Tabla `niveles` - Niveles de prioridad (Necesario, Lujo, etc.)
  - Tabla `periodicidades` - Catálogo de frecuencias
  - Tabla `bancos` - Instituciones bancarias
  - Tabla `jerarquias_usuario` - Jerarquías personalizadas de niveles

### 3️⃣ **03_tablas_grupos_y_cuentas.sql**
- **Descripción**: Crea las tablas de grupos de usuarios y cuentas financieras
- **Dependencias**: Scripts 01, 02
- **Contenido**:
  - Tabla `grupos_usuario` - Grupos familiares/compartidos
  - Función `crear_grupo_con_propietario()` - Evita recursión RLS
  - Tabla `cuentas` - Cuentas financieras (efectivo, bancarias, tarjetas)
  - Tabla `miembros_grupo` - Miembros y roles en grupos
  - Tabla `reglas_reparto_grupo` - Distribución de gastos
  - Tabla `historial_saldos` - Auditoría de cambios en saldos

### 4️⃣ **04_tablas_transacciones.sql**
- **Descripción**: Crea las tablas relacionadas con transacciones y compras
- **Dependencias**: Scripts 01, 02, 03
- **Contenido**:
  - Tabla `transacciones` - Todas las transacciones financieras (con soporte MSI)
  - Tabla `divisiones_transaccion` - División de gastos grupales
  - Tabla `compras_deuda` - Compras financiadas
  - Tabla `cuotas_deuda` - Cuotas de financiamientos
  - Tabla `compras_msi` - Meses Sin Intereses
  - Tabla `reglas_recurrentes` - Transacciones automáticas
  - Tabla `metas` - Metas financieras
  - Tabla `notificaciones` - Notificaciones del sistema

### 5️⃣ **05_tablas_transacciones_periodicas.sql**
- **Descripción**: Crea las tablas para transacciones periódicas y programadas
- **Dependencias**: Scripts 01, 02, 03, 04
- **Contenido**:
  - Función `update_updated_at_column()` - Actualización automática de timestamps
  - Tabla `transacciones_periodicas` - Transacciones recurrentes y MSI
  - Tabla `ejecuciones_transacciones_periodicas` - Registro de ejecuciones
  - Foreign key `transacciones.msi_id` → `transacciones_periodicas.id`
  - Triggers para updated_at

### 6️⃣ **06_triggers_y_funciones_auxiliares.sql**
- **Descripción**: Funciones auxiliares y triggers del sistema
- **Dependencias**: Scripts 01-05
- **Contenido**:
  - `guardar_historial_saldo()` + trigger
  - `expirar_invitaciones_vencidas()`
  - `dividir_gasto_grupal()`
  - `aceptar_invitacion_grupo()`
  - `actualizar_saldo_periodo_gasto()` + trigger
  - `calcular_total_msi_pendiente()`
  - `recalcular_saldo_en_corte()`
  - `inicializar_jerarquias_usuario()`
  - `auto_inicializar_jerarquias()` + trigger
  - `obtener_niveles_usuario()`
  - `id_usuario_sesion()`

### 7️⃣ **07_funciones_tarjetas_credito.sql**
- **Descripción**: Funciones específicas para gestión de tarjetas de crédito
- **Dependencias**: Scripts 01-06
- **Contenido**:
  - `recalcular_todas_tarjetas()`
  - `inicializar_saldo_periodo_tarjeta()` + trigger
  - `procesar_corte_tarjeta()`
  - `calcular_fechas_periodo_tarjeta()`
  - `obtener_gastos_periodo_tarjeta()`
  - `calcular_transacciones_programadas_periodo()`
  - `registrar_pago_periodo_tarjeta()`
  - `obtener_resumen_periodos_tarjeta()`

### 8️⃣ **08_funciones_msi_y_periodicas.sql**
- **Descripción**: Funciones para MSI y transacciones periódicas
- **Dependencias**: Scripts 01-07
- **Contenido**:
  - `actualizar_saldo_periodo_msi()` + trigger
  - `calcular_proxima_ejecucion()`
  - `crear_msi_tarjeta_credito()`
  - `incrementar_repeticiones_completadas()`
  - `calcular_siguiente_fecha()`
  - `eliminar_msi_tarjeta_credito()`

### 9️⃣ **09_sistema_grupos_fase1.sql**
- **Descripción**: Sistema de grupos - Fase 1 (funcionalidad grupal avanzada)
- **Dependencias**: Scripts 01-08
- **Contenido**:
  - Modificaciones a `grupos_usuario` (límite de miembros, etc.)
  - Tabla `invitaciones_grupo` - Sistema de invitaciones
  - Modificaciones a tablas existentes (agregar soporte de grupos)
  - Tabla `metas` modificada (soporte personal/grupo)
  - Tabla `aportaciones_meta_grupo`
  - Tabla `historial_ingresos`
  - Triggers del sistema de grupos
  - `recalcular_pesos_grupo()`
  - `calcular_division_gasto()`
  - `rechazar_invitacion_grupo()`
  - `salir_de_grupo()`

### 🔟 **10_politicas_rls.sql**
- **Descripción**: Políticas de Row Level Security para control de acceso
- **Dependencias**: Scripts 01-09
- **Contenido**:
  - Habilitación de RLS en tablas principales
  - 24 políticas RLS para:
    - `grupos_usuario` (4 políticas)
    - `miembros_grupo` (4 políticas)
    - `invitaciones_grupo` (3 políticas)
    - `metas` (4 políticas)
    - `aportaciones_meta_grupo` (3 políticas)
    - `historial_ingresos` (2 políticas)
  - Índices adicionales para performance

---

## 🚀 Ejecución Completa

Para ejecutar todos los scripts en orden, puedes usar este comando en PostgreSQL/Supabase:

```sql
-- Ejecutar en orden
\i 01_extensiones_y_tipos.sql
\i 02_tablas_catalogos.sql
\i 03_tablas_grupos_y_cuentas.sql
\i 04_tablas_transacciones.sql
\i 05_tablas_transacciones_periodicas.sql
\i 06_triggers_y_funciones_auxiliares.sql
\i 07_funciones_tarjetas_credito.sql
\i 08_funciones_msi_y_periodicas.sql
\i 09_sistema_grupos_fase1.sql
\i 10_politicas_rls.sql
```

O en Supabase SQL Editor, ejecuta cada script copiando y pegando su contenido en el orden indicado.

---

## 📊 Resumen de Componentes

| Componente | Cantidad |
|------------|----------|
| **Tipos ENUM** | 10 |
| **Tablas principales** | 23 |
| **Funciones** | ~30 |
| **Triggers** | ~15 |
| **Políticas RLS** | 24 |
| **Índices** | ~50+ |

---

## ⚠️ Notas Importantes

1. **Orden Estricto**: Los scripts DEBEN ejecutarse en el orden indicado debido a las dependencias entre ellos.

2. **Permisos**: Algunos scripts requieren permisos de `SECURITY DEFINER` para funciones que evitan problemas de RLS.

3. **Esquema**: Todos los scripts asumen que estás trabajando en el esquema `public`.

4. **Supabase**: Si usas Supabase, asegúrate de que la tabla `profiles` existe y está referenciada por `auth.users`.

5. **Drops**: Todos los scripts incluyen `DROP TABLE IF EXISTS CASCADE` para permitir recreación limpia. **¡Ten cuidado en producción!**

6. **Compatibilidad**: Scripts probados en PostgreSQL 14+ y Supabase.

---

## 🔄 Scripts Existentes Adicionales

Además de estos scripts modulares, el proyecto incluye otros scripts complementarios en la carpeta `sql/`:

- **0. user_manager.sql** - Gestión de usuarios (ejecutar ANTES del script 01)
- **2. db_policies.sql** - Políticas RLS adicionales (si es diferente del script 10)
- **3. finah_carga_inicial.sql** - Datos iniciales de catálogos públicos
- **4. ejemplos_uso.sql** - Ejemplos de uso del sistema

---

## 📝 Mantenimiento

### Modificar un Script

Si necesitas modificar alguna funcionalidad:

1. Identifica el script correspondiente según el componente
2. Edita el script
3. Si modificas dependencias, verifica los scripts posteriores
4. Prueba en un ambiente de desarrollo antes de aplicar en producción

### Agregar Nueva Funcionalidad

Para agregar nueva funcionalidad:

1. Identifica el script más apropiado o crea uno nuevo
2. Si creas un nuevo script, agrégalo al orden de ejecución
3. Actualiza este README con la nueva información
4. Documenta las dependencias

---

## 📧 Soporte

Para preguntas o problemas con los scripts, consulta la documentación en la carpeta `docs/` o contacta al equipo de desarrollo.

---

**Última actualización**: Diciembre 2025  
**Versión del esquema**: 1.0.0
