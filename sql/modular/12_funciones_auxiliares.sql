-- ==================================================================
-- 10. FUNCIONES AUXILIARES BÁSICAS
-- ==================================================================
-- Descripción: Funciones de utilidad general del sistema
-- Orden de ejecución: 10
-- Dependencias: Todas las tablas creadas previamente
-- ==================================================================

-- Función genérica para actualizar timestamp updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Actualiza automáticamente el campo updated_at en cualquier tabla';


-- Función para obtener el ID del usuario en sesión
CREATE OR REPLACE FUNCTION public.id_usuario_sesion()
RETURNS uuid
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT auth.uid();
$$;

COMMENT ON FUNCTION public.id_usuario_sesion IS 'Obtiene el UUID del usuario autenticado en Supabase. Usada por políticas RLS.';


-- Función para limpiar espacios del color antes de guardar
CREATE OR REPLACE FUNCTION limpiar_color_nivel()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.color IS NOT NULL THEN
    NEW.color := TRIM(NEW.color);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION limpiar_color_nivel IS 'Limpia espacios en blanco del campo color antes de insertar o actualizar';


-- Función para calcular total de MSI pendiente
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
    v_msi RECORD;
    v_saldo_msi NUMERIC := 0;
BEGIN
    -- Sumar el saldo PENDIENTE de cada MSI activo
    FOR v_msi IN (
        SELECT 
            id,
            monto_total_msi,
            numero_meses_total,
            meses_pagados,
            monto_por_mes
        FROM transacciones_periodicas
        WHERE cuenta_id = p_cuenta_id
          AND es_msi = TRUE
          AND activa = TRUE
          AND meses_pagados < numero_meses_total
    ) LOOP
        -- Calcular cuánto falta por pagar de este MSI
        v_saldo_msi := v_msi.monto_total_msi - (v_msi.meses_pagados * v_msi.monto_por_mes);
        v_total_msi := v_total_msi + v_saldo_msi;
    END LOOP;
    
    RETURN v_total_msi;
END;
$$;

COMMENT ON FUNCTION calcular_total_msi_pendiente IS 'Calcula el saldo PENDIENTE de todos los MSI activos (monto_total - meses_pagados * cuota). Este es el monto que aún falta por pagar de todos los MSI.';
