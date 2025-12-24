-- ==================================================================
-- SCRIPT 01: EXTENSIONES Y TIPOS ENUM
-- ==================================================================
-- Descripción: Crea las extensiones necesarias y todos los tipos ENUM 
--              personalizados utilizados en la base de datos
-- Dependencias: Ninguna
-- Orden de ejecución: 1
-- ==================================================================

-- ==================================================================
-- 0) Extensiones necesarias
-- ==================================================================
-- Extensión para generar UUIDs aleatorios seguros
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ==================================================================
-- 1) Eliminar tipos ENUM existentes
-- ==================================================================
-- Se eliminan tipos personalizados para poder recrearlos
DROP TYPE  IF EXISTS estado_invitacion     CASCADE;  -- Estados de invitaciones a grupos
DROP TYPE  IF EXISTS criterio_finalizacion CASCADE;  -- Criterios de finalización de recurrencias
DROP TYPE  IF EXISTS dia_semana            CASCADE;  -- Días de la semana
DROP TYPE  IF EXISTS frecuencia_transaccion CASCADE; -- Frecuencias para transacciones periódicas
DROP TYPE  IF EXISTS severidad             CASCADE;  -- Nivel de importancia de notificaciones
DROP TYPE  IF EXISTS biblioteca_iconos     CASCADE;  -- Librería de iconos (PrimeVue, Material, etc.)
DROP TYPE  IF EXISTS periodicidad          CASCADE;  -- Frecuencia de repetición
DROP TYPE  IF EXISTS tipo_meta             CASCADE;  -- Tipo de meta financiera
DROP TYPE  IF EXISTS tipo_transaccion      CASCADE;  -- Clasificación de transacciones
DROP TYPE  IF EXISTS rol_grupo             CASCADE;  -- Rol del usuario en un grupo


-- ==================================================================
-- 2) Crear tipos ENUM personalizados
-- ==================================================================

-- Tipos de transacciones financieras
CREATE TYPE tipo_transaccion AS ENUM (
  'gasto',           -- Gastos en general (comida, servicios, etc.)
  'ingreso',         -- Ingresos (salario, ventas, etc.)
  'transferencia',   -- Movimientos entre cuentas propias
  'pago_deuda',      -- Pagos de préstamos o deudas
  'pago_credito'     -- Pagos de tarjetas de crédito
);

-- Tipos de metas financieras
CREATE TYPE tipo_meta AS ENUM (
  'ahorro',          -- Meta de ahorro (vacaciones, emergencias)
  'compra',          -- Meta para una compra específica (auto, casa)
  'presupuesto'      -- Control de presupuesto mensual/anual
);

-- Frecuencias para repetición de transacciones y metas
CREATE TYPE periodicidad AS ENUM (
  'diario',          -- Todos los días
  'semanal',         -- Cada semana
  'quincenal',       -- Cada 15 días
  'mensual',         -- Cada mes
  'bimestral',       -- Cada 2 meses
  'trimestral',      -- Cada 3 meses
  'anual',           -- Cada año
  'personalizado'    -- Intervalo personalizado
);

-- Librerías de iconos disponibles
CREATE TYPE biblioteca_iconos AS ENUM (
  'primevue',        -- Iconos de PrimeVue
  'material'         -- Material Design Icons
);

-- Niveles de severidad para notificaciones y alertas
CREATE TYPE severidad AS ENUM (
  'exito',           -- Operaciones exitosas, ingresos
  'informacion',     -- Información general
  'advertencia',     -- Advertencias suaves (presupuesto cerca del límite)
  'peligro',         -- Gastos críticos, límites excedidos
  'secundario',      -- Neutro por defecto
  'contraste'        -- Para resaltar elementos importantes
);

-- Roles de usuarios dentro de grupos familiares/compartidos
CREATE TYPE rol_grupo AS ENUM (
  'miembro',         -- Usuario normal del grupo
  'administrador',   -- Administrador con permisos especiales
  'owner'            -- Propietario del grupo
);

-- Estados de invitaciones a grupos
CREATE TYPE estado_invitacion AS ENUM (
  'pendiente',       -- Invitación enviada, esperando respuesta
  'aceptada',        -- Invitación aceptada por el usuario
  'rechazada',       -- Invitación rechazada por el usuario
  'expirada',        -- Invitación que venció sin respuesta
  'cancelada'        -- Invitación cancelada por el invitador
);

-- Tipo ENUM para días de la semana (para transacciones periódicas)
CREATE TYPE dia_semana AS ENUM (
  'lunes',
  'martes',
  'miercoles',
  'jueves',
  'viernes',
  'sabado',
  'domingo'
);

-- Tipo ENUM para frecuencias de transacciones periódicas
CREATE TYPE frecuencia_transaccion AS ENUM (
  'diaria',           -- Todos los días
  'semanal',          -- Cada semana (con días específicos)
  'quincenal',        -- Cada 15 días
  'mensual',          -- Cada mes (con día específico del mes)
  'bimestral',        -- Cada 2 meses
  'trimestral',       -- Cada 3 meses
  'semestral',        -- Cada 6 meses
  'anual',            -- Cada año
  'dias_naturales',   -- Cada X días naturales (ej: cada 30 días)
  'msi',              -- Meses Sin Intereses (mensual con contador)
  'unica'             -- Una sola vez (para programar transacciones futuras)
);

-- Tipo ENUM para criterios de finalización de transacciones periódicas
CREATE TYPE criterio_finalizacion AS ENUM (
  'sin_fin',              -- Se repite indefinidamente
  'fecha_fin',            -- Se repite hasta una fecha específica
  'numero_repeticiones'   -- Se repite X veces
);


-- ==================================================================
-- MENSAJE DE CONFIRMACIÓN
-- ==================================================================
DO $$
BEGIN
    RAISE NOTICE '✅ Script 01: Extensiones y tipos ENUM creados exitosamente';
    RAISE NOTICE '📊 Extensiones: 1 (pgcrypto)';
    RAISE NOTICE '🔧 Tipos ENUM: 10';
END $$;
