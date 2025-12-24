-- ==================================================================
-- ARCHIVO: 06_triggers_y_funciones_auxiliares.sql
-- ==================================================================
-- Descripción: Funciones auxiliares, triggers y funciones de soporte general
--              para el sistema de gestión financiera.
--
-- Dependencias:
--   - 01_extensiones_y_tipos.sql (tipos ENUM)
--   - 02_tablas_catalogos.sql (tablas de catálogos)
--   - 03_tablas_grupos_y_cuentas.sql (tablas de grupos, cuentas, historial)
--   - 04_tablas_transacciones.sql (tabla transacciones)
--   - 05_tablas_transacciones_periodicas.sql (tabla transacciones_periodicas)
--
-- Orden de ejecución: 6/12
--
-- Funciones incluidas:
--   - guardar_historial_saldo() + trigger
--   - expirar_invitaciones_vencidas()
--   - dividir_gasto_grupal()
--   - aceptar_invitacion_grupo()
--   - actualizar_saldo_periodo_gasto() + trigger
--   - calcular_total_msi_pendiente()
--   - recalcular_saldo_en_corte()
--   - inicializar_jerarquias_usuario()
--   - auto_inicializar_jerarquias() + trigger
--   - obtener_niveles_usuario()
--   - id_usuario_sesion()
--   - Comentarios descriptivos de tablas
-- ==================================================================


-- ==================================================================
-- 7) Funciones auxiliares y triggers generales
-- ==================================================================

-- 7.1) Función para guardar historial de saldos automáticamente
CREATE OR REPLACE FUNCTION guardar_historial_saldo()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Solo guardar si el saldo cambió
  IF (TG_OP = 'UPDATE' AND OLD.saldo IS DISTINCT FROM NEW.saldo) OR TG_OP = 'INSERT' THEN
    INSERT INTO historial_saldos (
      cuenta_id,
      saldo_anterior,
      saldo_nuevo,
      diferencia,
      tipo_cambio
    ) VALUES (
      NEW.id,
      CASE WHEN TG_OP = 'UPDATE' THEN OLD.saldo ELSE NULL END,
      NEW.saldo,
      CASE WHEN TG_OP = 'UPDATE' THEN (NEW.saldo - OLD.saldo) ELSE NEW.saldo END,
      CASE WHEN TG_OP = 'INSERT' THEN 'creacion_cuenta' ELSE 'actualizacion_saldo' END
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger para historial de saldos
DROP TRIGGER IF EXISTS trigger_historial_saldo ON cuentas;
CREATE TRIGGER trigger_historial_saldo
  AFTER INSERT OR UPDATE OF saldo ON cuentas
  FOR EACH ROW
  EXECUTE FUNCTION guardar_historial_saldo();


-- 7.2) Función para expirar invitaciones vencidas
CREATE OR REPLACE FUNCTION expirar_invitaciones_vencidas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE invitaciones_grupo
  SET estado = 'expirada',
      fecha_respuesta = now()
  WHERE estado = 'pendiente'
    AND fecha_expiracion < now();
END;
$$;


-- 7.3) Función para dividir gastos grupales automáticamente
CREATE OR REPLACE FUNCTION dividir_gasto_grupal(
  p_transaccion_id UUID,
  p_grupo_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_monto_total NUMERIC(14,2);
  v_miembro RECORD;
BEGIN
  -- Obtener el monto total de la transacción
  SELECT monto INTO v_monto_total
  FROM transacciones
  WHERE id = p_transaccion_id;
  
  -- Dividir entre todos los miembros activos del grupo
  FOR v_miembro IN 
    SELECT usuario_id, porcentaje_participacion
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
  LOOP
    INSERT INTO divisiones_transaccion (
      transaccion_id,
      usuario_id,
      porcentaje_participacion,
      monto
    ) VALUES (
      p_transaccion_id,
      v_miembro.usuario_id,
      v_miembro.porcentaje_participacion,
      ROUND((v_monto_total * v_miembro.porcentaje_participacion / 100), 2)
    );
  END LOOP;
END;
$$;


-- 7.4) Función para aceptar invitación a grupo
-- ===================================================
-- FUNCIÓN PARA ACEPTAR INVITACIONES A GRUPOS
-- ===================================================

-- Eliminar cualquier versión anterior de la función
DROP FUNCTION IF EXISTS aceptar_invitacion_grupo(UUID);
DROP FUNCTION IF EXISTS aceptar_invitacion_grupo(UUID, UUID);
DROP FUNCTION IF EXISTS public.aceptar_invitacion_grupo(UUID);
DROP FUNCTION IF EXISTS public.aceptar_invitacion_grupo(UUID, UUID);

CREATE OR REPLACE FUNCTION public.aceptar_invitacion_grupo(
    p_invitacion_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitacion RECORD;
    v_usuario_id UUID;
    v_member_id UUID;
BEGIN
    -- Obtener ID del usuario actual
    v_usuario_id := auth.uid();
    
    IF v_usuario_id IS NULL THEN
        RAISE EXCEPTION 'Usuario no autenticado';
    END IF;

    -- Obtener información de la invitación
    SELECT * INTO v_invitacion
    FROM invitaciones_grupo
    WHERE id = p_invitacion_id
      AND email_invitado = (
          SELECT email FROM auth.users WHERE id = v_usuario_id
      )
      AND estado = 'pendiente';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitación no encontrada o no válida';
    END IF;

    -- Verificar si la invitación ha expirado
    IF v_invitacion.expires_at IS NOT NULL AND v_invitacion.expires_at < NOW() THEN
        -- Marcar como expirada
        UPDATE invitaciones_grupo
        SET estado = 'pendiente'  -- Mantener pendiente pero no procesar
        WHERE id = p_invitacion_id;
        
        RAISE EXCEPTION 'La invitación ha expirado';
    END IF;

    -- Verificar si el usuario ya es miembro del grupo
    IF EXISTS (
        SELECT 1 FROM miembros_grupo
        WHERE grupo_id = v_invitacion.grupo_id
          AND usuario_id = v_usuario_id
    ) THEN
        -- Actualizar estado de invitación
        UPDATE invitaciones_grupo
        SET estado = 'aceptada',
            updated_at = NOW()
        WHERE id = p_invitacion_id;
        
        RAISE EXCEPTION 'Ya eres miembro de este grupo';
    END IF;

    -- Verificar límite de miembros
    IF EXISTS (
        SELECT 1 FROM grupos
        WHERE id = v_invitacion.grupo_id
          AND limite_miembros IS NOT NULL
          AND (
              SELECT COUNT(*) FROM miembros_grupo WHERE grupo_id = v_invitacion.grupo_id
          ) >= limite_miembros
    ) THEN
        RAISE EXCEPTION 'El grupo ha alcanzado su límite de miembros';
    END IF;

    -- Agregar usuario como miembro del grupo
    INSERT INTO miembros_grupo (
        grupo_id,
        usuario_id,
        rol,
        porcentaje_participacion
    ) VALUES (
        v_invitacion.grupo_id,
        v_usuario_id,
        v_invitacion.rol_asignado,
        0  -- Peso inicial en 0, debe ser ajustado por admin
    )
    RETURNING id INTO v_member_id;

    -- Actualizar estado de invitación
    UPDATE invitaciones_grupo
    SET estado = 'aceptada',
        updated_at = NOW()
    WHERE id = p_invitacion_id;

    -- Crear notificación para el invitador
    INSERT INTO notificaciones (
        usuario_id,
        titulo,
        mensaje,
        tipo,
        relacionado_id,
        grupo_usuario_id
    )
    SELECT 
        v_invitacion.invitado_por,
        'Invitación aceptada',
        (SELECT email FROM auth.users WHERE id = v_usuario_id) || ' ha aceptado tu invitación',
        'exito',
        v_invitacion.grupo_id,
        v_invitacion.grupo_id
    WHERE v_invitacion.invitado_por IS NOT NULL;

    -- Retornar información del nuevo miembro
    RETURN json_build_object(
        'success', true,
        'member_id', v_member_id,
        'grupo_id', v_invitacion.grupo_id,
        'message', 'Te has unido al grupo exitosamente'
    );

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION '%', SQLERRM;
END;
$$;

COMMENT ON FUNCTION aceptar_invitacion_grupo IS 'Permite a un usuario aceptar una invitación a un grupo. Valida expiración, límites y duplicados. Crea notificación al invitador.';


-- 7.5) Función para actualizar saldo_periodo_actual al registrar gastos
-- NUEVA LÓGICA: Ya no filtrar por periodo, sino usar Total Usado - Total MSI
CREATE OR REPLACE FUNCTION actualizar_saldo_periodo_gasto()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_cuenta RECORD;
    v_deuda_total NUMERIC;
    v_deuda_msi NUMERIC;
BEGIN
    -- Solo procesar gastos normales (no MSI) en tarjetas de crédito
    IF NEW.tipo != 'gasto' OR (NEW.metadatos->>'msi_id') IS NOT NULL THEN
        RETURN NEW;
    END IF;
    
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = NEW.cuenta_id
        AND tipo = 'credit_card'
        AND dia_corte IS NOT NULL;
    
    -- Si no es tarjeta de crédito, no hacer nada
    IF NOT FOUND THEN
        RETURN NEW;
    END IF;
    
    -- Recalcular usando la nueva lógica: (Total Usado - Total MSI) + Cuota MSI del periodo
    v_deuda_total := v_cuenta.limite_credito - v_cuenta.credito_disponible;
    v_deuda_msi := calcular_total_msi_pendiente(NEW.cuenta_id);
    
    -- Calcular solo para recalcular completamente el saldo
    PERFORM recalcular_saldo_en_corte(NEW.cuenta_id);
    
    RETURN NEW;
END;
$$;

-- Trigger para actualizar saldo_periodo_actual al insertar gastos
DROP TRIGGER IF EXISTS trigger_actualizar_saldo_periodo ON transacciones;
CREATE TRIGGER trigger_actualizar_saldo_periodo
    AFTER INSERT ON transacciones
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_saldo_periodo_gasto();


-- 7.5d) Función auxiliar para calcular total de MSI (completo, no solo pendiente)
DROP FUNCTION IF EXISTS calcular_total_msi_pendiente(UUID);
CREATE OR REPLACE FUNCTION calcular_total_msi_pendiente(
    p_cuenta_id UUID
)
RETURNS NUMERIC
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
SET row_security = OFF
AS $$
DECLARE
    v_total_msi NUMERIC := 0;
    v_msi_record RECORD;
    v_saldo_msi NUMERIC := 0;
BEGIN
    -- Sumar el saldo PENDIENTE de cada MSI activo
    -- Saldo pendiente = monto_total_msi - (meses_pagados * monto_por_mes)
    FOR v_msi_record IN
        SELECT 
            monto_total_msi,
            meses_pagados,
            monto_por_mes
        FROM transacciones_periodicas
        WHERE cuenta_id = p_cuenta_id
            AND es_msi = TRUE
            AND activa = TRUE
    LOOP
        -- Calcular saldo pendiente de este MSI
        v_saldo_msi := v_msi_record.monto_total_msi - (v_msi_record.meses_pagados * v_msi_record.monto_por_mes);
        v_total_msi := v_total_msi + GREATEST(v_saldo_msi, 0);
    END LOOP;
    
    RETURN v_total_msi;
END;
$$;

COMMENT ON FUNCTION calcular_total_msi_pendiente IS 'Calcula el saldo PENDIENTE de todos los MSI activos (monto_total - meses_pagados * cuota). Este es el monto que aún falta por pagar de todos los MSI.';


-- 7.6) Función para recalcular saldo_periodo_actual en fecha de corte
-- NUEVA LÓGICA: saldo_periodo_actual = (Total Usado - Total MSI) + Cuota MSI del periodo
CREATE OR REPLACE FUNCTION recalcular_saldo_en_corte(
    p_cuenta_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_cuenta RECORD;
    v_fechas RECORD;
    v_deuda_total NUMERIC := 0;
    v_deuda_msi NUMERIC := 0;
    v_cuotas_msi_periodo NUMERIC := 0;
    v_cuotas_msi_futuras NUMERIC := 0;
    v_nuevo_saldo_periodo NUMERIC := 0;
    v_msi RECORD;
    v_msi_sig RECORD;
    v_saldo_pendiente_msi NUMERIC;
    v_cuota_este_periodo NUMERIC;
BEGIN
    -- Obtener información de la cuenta
    SELECT * INTO v_cuenta
    FROM cuentas
    WHERE id = p_cuenta_id
        AND tipo = 'credit_card'
        AND dia_corte IS NOT NULL;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cuenta no encontrada o no es tarjeta de crédito';
    END IF;
    
    -- Calcular fechas del periodo actual (para actualizar proxima_fecha_corte y proxima_fecha_pago)
    SELECT * INTO v_fechas
    FROM calcular_fechas_periodo_tarjeta(
        v_cuenta.dia_corte,
        v_cuenta.dia_pago,
        CURRENT_DATE
    );
    
    -- LÓGICA CORREGIDA: Calcular deuda total usada
    v_deuda_total := v_cuenta.limite_credito - v_cuenta.credito_disponible;
    
    -- Calcular total de MSI (monto total de todos los MSI activos)
    v_deuda_msi := calcular_total_msi_pendiente(p_cuenta_id);
    
    -- OPCIÓN 1 (HÍBRIDO): Consultar transacciones reales para cuotas MSI
    
    -- Calcular cuotas MSI FUTURAS (después del periodo actual)
    SELECT COALESCE(SUM(monto), 0)
    INTO v_cuotas_msi_futuras
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND es_cuota_msi = TRUE
        AND fecha_ocurrencia > v_fechas.periodo_actual_fin
        AND estado_msi IN ('programada', 'pendiente_pago')
        AND deleted_at IS NULL;
    
    -- Calcular cuota MSI del periodo ACTUAL
    SELECT COALESCE(SUM(monto), 0)
    INTO v_cuotas_msi_periodo
    FROM transacciones
    WHERE cuenta_id = p_cuenta_id
        AND es_cuota_msi = TRUE
        AND fecha_ocurrencia >= v_fechas.periodo_actual_inicio
        AND fecha_ocurrencia <= v_fechas.periodo_actual_fin
        AND estado_msi IN ('programada', 'pendiente_pago')
        AND deleted_at IS NULL;
    
    -- El saldo del periodo actual es: (Deuda Total - Total MSI) + Cuota MSI del Periodo
    -- Esto da: deuda no diferida + cuota del periodo actual únicamente
    v_nuevo_saldo_periodo := GREATEST((v_deuda_total - v_deuda_msi) + v_cuotas_msi_periodo, 0);
    
    -- Actualizar saldo_periodo_actual con la nueva lógica
    UPDATE cuentas
    SET saldo_periodo_actual = v_nuevo_saldo_periodo,
        proxima_fecha_corte = v_fechas.fecha_corte_siguiente,
        proxima_fecha_pago = v_fechas.fecha_pago_siguiente,
        fecha_actualizacion = NOW()
    WHERE id = p_cuenta_id;
END;
$$;

COMMENT ON FUNCTION recalcular_saldo_en_corte IS 'Recalcula el saldo_periodo_actual usando la fórmula: (Deuda Total - Total MSI) + Cuota MSI Periodo Actual. Esto muestra solo la deuda no diferida más la cuota del mes actual, sin incluir cuotas futuras.';


-- ==================================================================
-- 8) Funciones para gestión de jerarquías personalizadas
-- ==================================================================

-- 8.1) Función para inicializar jerarquías de usuario
DROP FUNCTION IF EXISTS inicializar_jerarquias_usuario(UUID);

CREATE OR REPLACE FUNCTION inicializar_jerarquias_usuario(p_usuario_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insertar jerarquías basadas en los niveles públicos y privados del usuario
  INSERT INTO jerarquias_usuario (usuario_id, nivel_id, jerarquia_personalizada)
  SELECT 
    p_usuario_id,
    n.id,
    CASE 
      -- Los niveles públicos mantienen su jerarquía original
      WHEN n.es_publico = TRUE THEN n.jerarquia
      -- Los niveles privados se añaden después de los públicos
      ELSE (
        SELECT COALESCE(MAX(pub.jerarquia), 0) + 
               ROW_NUMBER() OVER (ORDER BY n.jerarquia, n.fecha_creacion)
        FROM niveles pub 
        WHERE pub.es_publico = TRUE
      )
    END
  FROM niveles n
  WHERE 
    -- Incluir niveles públicos y privados del usuario
    (n.es_publico = TRUE OR n.usuario_id = p_usuario_id)
    -- Solo si no existe ya una jerarquía personalizada
    AND NOT EXISTS (
      SELECT 1 FROM jerarquias_usuario ju 
      WHERE ju.usuario_id = p_usuario_id AND ju.nivel_id = n.id
    )
  ORDER BY 
    n.es_publico DESC,  -- Públicos primero
    n.jerarquia,        -- Luego por jerarquía
    n.fecha_creacion;   -- Finalmente por fecha de creación
END;
$$;

-- 8.2) Trigger para auto-inicializar jerarquías al crear niveles
-- IMPORTANTE: Eliminar el trigger ANTES de la función para evitar errores de dependencia
DROP TRIGGER IF EXISTS trigger_auto_inicializar_jerarquias ON niveles;
DROP FUNCTION IF EXISTS auto_inicializar_jerarquias();

CREATE OR REPLACE FUNCTION auto_inicializar_jerarquias()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Si se crea un nuevo nivel privado, añadirlo a la jerarquía del usuario
  IF NEW.es_publico = FALSE AND NEW.usuario_id IS NOT NULL THEN
    INSERT INTO jerarquias_usuario (usuario_id, nivel_id, jerarquia_personalizada)
    SELECT 
      NEW.usuario_id,
      NEW.id,
      COALESCE(MAX(ju.jerarquia_personalizada), 0) + 1
    FROM jerarquias_usuario ju
    WHERE ju.usuario_id = NEW.usuario_id;
  END IF;
  
  RETURN NEW;
END;
$$;

-- Aplicar trigger a la tabla niveles
CREATE TRIGGER trigger_auto_inicializar_jerarquias
  AFTER INSERT ON niveles
  FOR EACH ROW
  EXECUTE FUNCTION auto_inicializar_jerarquias();

-- 8.3) Función para obtener niveles ordenados por usuario
DROP FUNCTION IF EXISTS obtener_niveles_usuario(UUID);

CREATE OR REPLACE FUNCTION obtener_niveles_usuario(p_usuario_id UUID)
RETURNS TABLE (
  id UUID,
  nombre TEXT,
  color VARCHAR(20),
  es_publico BOOLEAN,
  jerarquia INT,
  jerarquia_personalizada INT,
  usuario_id UUID,
  fecha_creacion TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Inicializar jerarquías si no existen
  PERFORM inicializar_jerarquias_usuario(p_usuario_id);
  
  -- Retornar niveles ordenados por jerarquía personalizada
  RETURN QUERY
  SELECT 
    n.id,
    n.nombre,
    n.color,
    n.es_publico,
    n.jerarquia,
    ju.jerarquia_personalizada,
    n.usuario_id,
    n.fecha_creacion
  FROM niveles n
  JOIN jerarquias_usuario ju ON n.id = ju.nivel_id
  WHERE 
    ju.usuario_id = p_usuario_id
    AND (n.es_publico = TRUE OR n.usuario_id = p_usuario_id)
  ORDER BY ju.jerarquia_personalizada;
END;
$$;


-- ==================================================================
-- 10) Función auxiliar para obtener el ID del usuario en sesión
-- ==================================================================
-- Esta función se ejecuta una sola vez por consulta para obtener el usuario autenticado
-- Es usada por las políticas RLS (Row Level Security) para filtrar datos por usuario
CREATE OR REPLACE FUNCTION public.id_usuario_sesion()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT auth.uid();  -- Obtiene el UUID del usuario autenticado en Supabase
$$;


-- ==================================================================
-- 11) Comentarios descriptivos de las tablas principales
-- ==================================================================

-- Comentarios para grupos de usuarios
COMMENT ON TABLE grupos_usuario IS 'Grupos familiares o de convivencia para compartir gastos y presupuestos';
COMMENT ON COLUMN grupos_usuario.propietario_id IS 'Usuario que creó el grupo y tiene permisos de administrador';
COMMENT ON COLUMN grupos_usuario.nombre IS 'Nombre descriptivo del grupo (ej: "Familia García", "Casa Estudiantes")';
COMMENT ON COLUMN grupos_usuario.descripcion IS 'Descripción opcional del propósito del grupo';

-- Comentarios para grupos de categorías  
COMMENT ON TABLE grupos_categoria IS 'Agrupadores principales de categorías de gastos (Hogar, Transporte, Alimentación, etc.)';
COMMENT ON COLUMN grupos_categoria.tipo IS 'Tipo de transacción del grupo: gasto, ingreso, transferencia. Las categorías del grupo heredan este tipo para filtrado contextual';
COMMENT ON COLUMN grupos_categoria.es_publico IS 'Si TRUE: disponible para todos los usuarios. Si FALSE: privado del usuario/grupo';
COMMENT ON COLUMN grupos_categoria.color IS 'Color representativo en formato hexadecimal (#FF5722) para la interfaz';
COMMENT ON COLUMN grupos_categoria.biblioteca_iconos IS 'Librería de iconos a usar: primevue o material';
COMMENT ON COLUMN grupos_categoria.nombre_icono IS 'Nombre específico del icono dentro de la librería seleccionada';

-- Comentarios para categorías específicas
COMMENT ON TABLE categorias IS 'Categorías específicas de gastos e ingresos (Gasolina, Supermercado, Salario, etc.)';
COMMENT ON COLUMN categorias.grupo_id IS 'Grupo de categorías al que pertenece (obligatorio)';

-- Comentarios para niveles de prioridad
COMMENT ON TABLE niveles IS 'Niveles de prioridad o importancia para clasificar gastos e ingresos';
COMMENT ON COLUMN niveles.nombre IS 'Nombre del nivel (ej: "Necesario", "Deseo", "Lujo", "Emergencia")';
COMMENT ON COLUMN niveles.color IS 'Color representativo que puede estar en formato hex, nombre o código';

-- Comentarios para periodicidades
COMMENT ON TABLE periodicidades IS 'Catálogo de frecuencias para transacciones recurrentes y metas de ahorro';
COMMENT ON COLUMN periodicidades.codigo IS 'Código interno del sistema (diario, semanal, mensual, etc.)';
COMMENT ON COLUMN periodicidades.etiqueta IS 'Texto amigable para mostrar al usuario';
COMMENT ON COLUMN periodicidades.cantidad_intervalo IS 'Multiplicador del intervalo (ej: cada 2 semanas = cantidad_intervalo: 2)';

-- Comentarios para cuentas financieras
COMMENT ON TABLE cuentas IS 'Cuentas financieras del usuario: efectivo, cuentas bancarias, tarjetas de débito/crédito';
COMMENT ON COLUMN cuentas.tipo IS 'Tipo de cuenta: efectivo, bancaria, tarjeta_credito, tarjeta_debito, ahorro, inversion';
COMMENT ON COLUMN cuentas.metadatos IS 'Información adicional en JSON: últimos 4 dígitos, número de cuenta, etc.';
COMMENT ON COLUMN cuentas.saldo IS 'Saldo actual de la cuenta en la moneda base (pesos mexicanos)';

-- Comentarios para miembros de grupo
COMMENT ON TABLE miembros_grupo IS 'Usuarios que pertenecen a un grupo y su nivel de participación';
COMMENT ON COLUMN miembros_grupo.porcentaje_participacion IS 'Porcentaje general de participación en gastos grupales (0-100)';
COMMENT ON COLUMN miembros_grupo.rol IS 'Rol del usuario: miembro normal o administrador con permisos especiales';

-- Comentarios para reglas de reparto
COMMENT ON TABLE reglas_reparto_grupo IS 'Reglas específicas de distribución de gastos por tipo de recurso';
COMMENT ON COLUMN reglas_reparto_grupo.tipo_recurso IS 'Tipo de gasto/recurso: deuda, ahorro, gasto_fijo, gasto_variable, etc.';
COMMENT ON COLUMN reglas_reparto_grupo.porcentaje_participacion IS 'Porcentaje específico para este tipo de recurso';

-- Comentarios para transacciones
COMMENT ON TABLE transacciones IS 'Registro histórico de todas las transacciones financieras del sistema';
COMMENT ON COLUMN transacciones.tipo IS 'Clasificación: gasto, ingreso, transferencia, pago_deuda, pago_credito';
COMMENT ON COLUMN transacciones.severidad IS 'Nivel de importancia para alertas y notificaciones';
COMMENT ON COLUMN transacciones.fecha_ocurrencia IS 'Fecha real cuando ocurrió la transacción (puede ser diferente a fecha_creacion)';
COMMENT ON COLUMN transacciones.url_recibo IS 'URL del comprobante almacenado en Supabase Storage';
COMMENT ON COLUMN transacciones.metadatos IS 'Datos adicionales: referencia a deuda, cuota, promoción MSI, etc.';

-- Comentarios para divisiones de transacciones
COMMENT ON TABLE divisiones_transaccion IS 'División de gastos grupales entre múltiples usuarios';
COMMENT ON COLUMN divisiones_transaccion.porcentaje_participacion IS 'Porcentaje de responsabilidad de este usuario en el gasto';
COMMENT ON COLUMN divisiones_transaccion.monto IS 'Monto específico que le corresponde pagar a este usuario';

-- Comentarios para compras a plazos
COMMENT ON TABLE compras_deuda IS 'Compras financiadas a meses con o sin intereses';
COMMENT ON COLUMN compras_deuda.meses IS 'Número de meses para liquidar la compra';
COMMENT ON COLUMN compras_deuda.fecha_inicio IS 'Fecha de la primera cuota o cargo';

-- Comentarios para cuotas de deuda
COMMENT ON TABLE cuotas_deuda IS 'Cuotas individuales de cada compra financiada';
COMMENT ON COLUMN cuotas_deuda.numero_cuota IS 'Número secuencial de la cuota (1, 2, 3, etc.)';
COMMENT ON COLUMN cuotas_deuda.pagada IS 'Estado del pago: TRUE si ya se pagó, FALSE si está pendiente';
COMMENT ON COLUMN cuotas_deuda.transaccion_id IS 'Referencia a la transacción de pago (si ya se pagó)';

-- Comentarios para reglas recurrentes
COMMENT ON TABLE reglas_recurrentes IS 'Reglas para generar transacciones automáticas periódicas';
COMMENT ON COLUMN reglas_recurrentes.proxima_ejecucion IS 'Fecha calculada para la próxima ejecución automática';
COMMENT ON COLUMN reglas_recurrentes.activa IS 'Si la regla está habilitada para ejecutarse automáticamente';

-- Comentarios para metas financieras
COMMENT ON TABLE metas IS 'Metas de ahorro, compras planificadas y control de presupuesto';
COMMENT ON COLUMN metas.tipo IS 'Clasificación: ahorro (para emergencias), compra (auto/casa), presupuesto (control mensual)';
COMMENT ON COLUMN metas.monto_objetivo IS 'Cantidad total que se quiere alcanzar';
COMMENT ON COLUMN metas.monto_actual IS 'Progreso actual hacia la meta';
COMMENT ON COLUMN metas.monto_periodo IS 'Cantidad sugerida a ahorrar por período (opcional)';
COMMENT ON COLUMN metas.estado IS 'Estado actual: pendiente, en_progreso, completada, cancelada, pausada';

-- Comentarios para notificaciones
COMMENT ON TABLE notificaciones IS 'Sistema de notificaciones y bitácora de eventos importantes';
COMMENT ON COLUMN notificaciones.tipo IS 'Tipo de evento: alerta_presupuesto, meta_completada, pago_vencido, etc.';
COMMENT ON COLUMN notificaciones.id_relacionado IS 'UUID del objeto relacionado (transacción, meta, cuenta, etc.)';
COMMENT ON COLUMN notificaciones.metadatos IS 'Datos adicionales necesarios para procesar la notificación';
COMMENT ON COLUMN notificaciones.leida IS 'Estado de lectura para el usuario destinatario';

-- Comentarios para bancos
COMMENT ON TABLE bancos IS 'Catálogo de instituciones financieras (bancos, fintech, cooperativas)';
COMMENT ON COLUMN bancos.ruta_logo IS 'Ruta del archivo de logo almacenado en Supabase Storage';


-- ==================================================================
-- CONFIRMACIÓN DE EJECUCIÓN
-- ==================================================================
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '✅ Archivo 06_triggers_y_funciones_auxiliares.sql ejecutado correctamente';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE 'Funciones y triggers creados:';
    RAISE NOTICE '  - guardar_historial_saldo() + trigger';
    RAISE NOTICE '  - expirar_invitaciones_vencidas()';
    RAISE NOTICE '  - dividir_gasto_grupal()';
    RAISE NOTICE '  - aceptar_invitacion_grupo()';
    RAISE NOTICE '  - actualizar_saldo_periodo_gasto() + trigger';
    RAISE NOTICE '  - calcular_total_msi_pendiente()';
    RAISE NOTICE '  - recalcular_saldo_en_corte()';
    RAISE NOTICE '  - inicializar_jerarquias_usuario()';
    RAISE NOTICE '  - auto_inicializar_jerarquias() + trigger';
    RAISE NOTICE '  - obtener_niveles_usuario()';
    RAISE NOTICE '  - id_usuario_sesion()';
    RAISE NOTICE '  - Comentarios descriptivos agregados';
    RAISE NOTICE '==================================================================';
    RAISE NOTICE '';
END $$;
