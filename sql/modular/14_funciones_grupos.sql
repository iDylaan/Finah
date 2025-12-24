-- ==================================================================
-- 11. FUNCIONES DE GRUPOS
-- ==================================================================
-- Descripción: Funciones para gestión de grupos y membresías
-- Orden de ejecución: 11
-- Dependencias: 03_tablas_grupos_usuarios.sql, 10_funciones_auxiliares.sql
-- ==================================================================

-- ==================================================================
-- ELIMINAR FUNCIONES EXISTENTES (todas las versiones)
-- ==================================================================
DO $$
DECLARE
    r RECORD;
BEGIN
    -- Eliminar todas las versiones de crear_grupo_con_propietario (función antigua)
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'crear_grupo_con_propietario'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Eliminar todas las versiones de crear_grupo_simple (función nueva)
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'crear_grupo_simple'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Eliminar todas las versiones de aceptar_invitacion_grupo
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'aceptar_invitacion_grupo'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Eliminar todas las versiones de expirar_invitaciones_vencidas
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'expirar_invitaciones_vencidas'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
    
    -- Eliminar todas las versiones de dividir_gasto_grupal
    FOR r IN 
        SELECT oid::regprocedure 
        FROM pg_proc 
        WHERE proname = 'dividir_gasto_grupal'
    LOOP
        EXECUTE 'DROP FUNCTION ' || r.oid::regprocedure || ' CASCADE';
    END LOOP;
END $$;

-- ==================================================================
-- CREAR FUNCIONES
-- ==================================================================

-- NOTA: La función crear_grupo_con_propietario fue eliminada
-- La creación de grupos ahora se maneja directamente desde el frontend
-- usando INSERT a grupos_usuario y luego INSERT a miembros_grupo

-- Función para aceptar invitación a grupo
CREATE FUNCTION public.aceptar_invitacion_grupo(
    p_invitacion_id UUID
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_invitacion RECORD;
    v_user_id UUID;
    v_member_id UUID;
BEGIN
    -- Obtener ID del usuario actual
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'No hay usuario autenticado';
    END IF;

    -- Obtener invitación
    SELECT * INTO v_invitacion
    FROM invitaciones_grupo
    WHERE id = p_invitacion_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitación no encontrada';
    END IF;

    -- Validar estado
    IF v_invitacion.estado != 'pendiente' THEN
        RAISE EXCEPTION 'La invitación ya fue procesada';
    END IF;

    -- Validar expiración
    IF v_invitacion.fecha_expiracion < NOW() THEN
        UPDATE invitaciones_grupo
        SET estado = 'expirada', updated_at = NOW()
        WHERE id = p_invitacion_id;
        
        RAISE EXCEPTION 'La invitación ha expirado';
    END IF;

    -- Validar que el usuario ya no sea miembro
    IF EXISTS (
        SELECT 1 FROM miembros_grupo
        WHERE grupo_id = v_invitacion.grupo_id
        AND usuario_id = v_user_id
    ) THEN
        RAISE EXCEPTION 'Ya eres miembro de este grupo';
    END IF;

    -- Agregar al usuario como miembro
    INSERT INTO miembros_grupo (
        grupo_id,
        usuario_id,
        porcentaje_participacion,
        rol
    ) VALUES (
        v_invitacion.grupo_id,
        v_user_id,
        v_invitacion.porcentaje_asignado,
        v_invitacion.rol_asignado
    )
    RETURNING id INTO v_member_id;

    -- Actualizar invitación
    UPDATE invitaciones_grupo
    SET estado = 'aceptada',
        fecha_respuesta = NOW(),
        updated_at = NOW()
    WHERE id = p_invitacion_id;

    -- Crear notificación para el invitador
    INSERT INTO notificaciones (
        usuario_id,
        grupo_usuario_id,
        tipo,
        severidad,
        titulo,
        mensaje,
        id_relacionado
    ) VALUES (
        v_invitacion.invitado_por,
        v_invitacion.grupo_id,
        'invitacion_aceptada',
        'exito',
        'Invitación aceptada',
        'Un usuario ha aceptado tu invitación al grupo',
        v_invitacion.grupo_id
    );

    RETURN json_build_object(
        'success', true,
        'member_id', v_member_id,
        'grupo_id', v_invitacion.grupo_id
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

COMMENT ON FUNCTION aceptar_invitacion_grupo IS 'Permite a un usuario aceptar una invitación a un grupo. Valida expiración, límites y duplicados. Crea notificación al invitador.';


-- Función para expirar invitaciones vencidas
CREATE FUNCTION expirar_invitaciones_vencidas()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE invitaciones_grupo
  SET estado = 'expirada', updated_at = NOW()
  WHERE estado = 'pendiente'
    AND fecha_expiracion < NOW();
END;
$$;

COMMENT ON FUNCTION expirar_invitaciones_vencidas IS 'Marca como expiradas todas las invitaciones pendientes que han pasado su fecha límite';


-- Función para dividir gastos grupales automáticamente
CREATE FUNCTION dividir_gasto_grupal(
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
  FOR v_miembro IN (
    SELECT 
      usuario_id,
      porcentaje_participacion
    FROM miembros_grupo
    WHERE grupo_id = p_grupo_id
  ) LOOP
    INSERT INTO divisiones_transaccion (
      transaccion_id,
      usuario_id,
      porcentaje_participacion,
      monto
    ) VALUES (
      p_transaccion_id,
      v_miembro.usuario_id,
      v_miembro.porcentaje_participacion,
      v_monto_total * (v_miembro.porcentaje_participacion / 100)
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION dividir_gasto_grupal IS 'Divide un gasto entre los miembros de un grupo según su porcentaje de participación';
