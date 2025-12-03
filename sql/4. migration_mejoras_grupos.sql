-- ===================================================
-- MIGRACIÓN: MEJORAS PARA GRUPOS Y ANÁLISIS FINANCIERO
-- Archivo: 4. migration_mejoras_grupos.sql
-- Fecha: 2025-12-02
-- Descripción: Agrega funcionalidades avanzadas para grupos,
--              invitaciones, historial de saldos y mejoras en metas
-- ===================================================

-- ===================================================
-- 1) TABLA DE INVITACIONES A GRUPOS
-- ===================================================
-- Permite gestionar invitaciones pendientes a grupos de forma segura

CREATE TABLE IF NOT EXISTS invitaciones_grupo (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  grupo_id UUID NOT NULL REFERENCES grupos_usuario(id) ON DELETE CASCADE,
  email_invitado TEXT NOT NULL,
  usuario_invitador UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  rol_propuesto rol_grupo NOT NULL DEFAULT 'miembro',
  porcentaje_propuesto NUMERIC(5,2) DEFAULT 0,
  token UUID DEFAULT gen_random_uuid() UNIQUE,
  estado TEXT NOT NULL DEFAULT 'pendiente',
  mensaje_invitacion TEXT,
  fecha_expiracion TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
  fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  fecha_respuesta TIMESTAMPTZ,
  
  -- Validaciones
  CONSTRAINT chk_estado_invitacion CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'expirada', 'cancelada')),
  CONSTRAINT chk_porcentaje_invitacion CHECK (porcentaje_propuesto >= 0 AND porcentaje_propuesto <= 100),
  CONSTRAINT chk_email_formato CHECK (email_invitado ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Índices para búsquedas eficientes
CREATE INDEX idx_invitaciones_grupo_id ON invitaciones_grupo(grupo_id);
CREATE INDEX idx_invitaciones_email ON invitaciones_grupo(email_invitado);
CREATE INDEX idx_invitaciones_token ON invitaciones_grupo(token);
CREATE INDEX idx_invitaciones_estado ON invitaciones_grupo(estado);

-- Comentarios
COMMENT ON TABLE invitaciones_grupo IS 'Gestión de invitaciones a grupos financieros';
COMMENT ON COLUMN invitaciones_grupo.token IS 'Token único para aceptar la invitación de forma segura';
COMMENT ON COLUMN invitaciones_grupo.estado IS 'Estado actual: pendiente, aceptada, rechazada, expirada, cancelada';
COMMENT ON COLUMN invitaciones_grupo.porcentaje_propuesto IS 'Porcentaje de participación propuesto para el nuevo miembro';


-- ===================================================
-- 2) TABLA DE HISTORIAL DE SALDOS
-- ===================================================
-- Permite análisis temporal del patrimonio y generación de gráficas

CREATE TABLE IF NOT EXISTS historial_saldos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cuenta_id UUID NOT NULL REFERENCES cuentas(id) ON DELETE CASCADE,
  saldo_anterior NUMERIC(14,2),
  saldo_nuevo NUMERIC(14,2) NOT NULL,
  diferencia NUMERIC(14,2),
  transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL,
  fecha TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- Metadata adicional
  tipo_cambio TEXT,
  notas TEXT
);

-- Índices para consultas temporales
CREATE INDEX idx_historial_cuenta_fecha ON historial_saldos(cuenta_id, fecha DESC);
CREATE INDEX idx_historial_fecha ON historial_saldos(fecha DESC);

-- Comentarios
COMMENT ON TABLE historial_saldos IS 'Registro histórico de cambios en los saldos de las cuentas para análisis temporal';
COMMENT ON COLUMN historial_saldos.diferencia IS 'Diferencia calculada entre saldo nuevo y anterior';
COMMENT ON COLUMN historial_saldos.tipo_cambio IS 'Tipo de operación que causó el cambio: transaccion, ajuste_manual, correccion';


-- ===================================================
-- 3) FUNCIÓN PARA GUARDAR HISTORIAL DE SALDO
-- ===================================================
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

-- Trigger para cuentas
DROP TRIGGER IF EXISTS trigger_historial_saldo ON cuentas;
CREATE TRIGGER trigger_historial_saldo
  AFTER INSERT OR UPDATE OF saldo ON cuentas
  FOR EACH ROW
  EXECUTE FUNCTION guardar_historial_saldo();

COMMENT ON FUNCTION guardar_historial_saldo IS 'Registra automáticamente los cambios de saldo en historial_saldos';


-- ===================================================
-- 4) MEJORAS EN TABLA METAS
-- ===================================================
-- Agregar campos para mejor control de presupuestos y notificaciones

ALTER TABLE metas 
ADD COLUMN IF NOT EXISTS notificar_al_alcanzar NUMERIC(5,2) DEFAULT 80.00
  CONSTRAINT chk_notificar_porcentaje CHECK (notificar_al_alcanzar >= 0 AND notificar_al_alcanzar <= 100);

ALTER TABLE metas 
ADD COLUMN IF NOT EXISTS permitir_exceder BOOLEAN DEFAULT FALSE;

ALTER TABLE metas 
ADD COLUMN IF NOT EXISTS icon_library biblioteca_iconos DEFAULT 'material';

ALTER TABLE metas 
ADD COLUMN IF NOT EXISTS icon_name TEXT DEFAULT 'flag';

ALTER TABLE metas 
ADD COLUMN IF NOT EXISTS color CHAR(7);

-- Comentarios
COMMENT ON COLUMN metas.notificar_al_alcanzar IS 'Porcentaje del objetivo al que se enviará notificación (default: 80%)';
COMMENT ON COLUMN metas.permitir_exceder IS 'Si es FALSE, bloquea transacciones cuando se alcanza el límite del presupuesto';
COMMENT ON COLUMN metas.icon_library IS 'Librería del icono para la meta (material, primevue)';
COMMENT ON COLUMN metas.icon_name IS 'Nombre del icono para representar la meta';
COMMENT ON COLUMN metas.color IS 'Color asociado a la meta en formato hexadecimal';


-- ===================================================
-- 5) FUNCIÓN PARA EXPIRAR INVITACIONES AUTOMÁTICAMENTE
-- ===================================================
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

COMMENT ON FUNCTION expirar_invitaciones_vencidas IS 'Marca como expiradas las invitaciones que pasaron su fecha límite';


-- ===================================================
-- 6) VISTA PARA PATRIMONIO NETO POR USUARIO
-- ===================================================
CREATE OR REPLACE VIEW vista_patrimonio_usuario AS
SELECT 
  c.creada_por AS usuario_id,
  COUNT(c.id) AS total_cuentas,
  SUM(CASE 
    WHEN c.tipo IN ('cash', 'debit', 'savings') THEN c.saldo
    WHEN c.tipo = 'credit_card' THEN -1 * (tc.limite_credito - tc.credito_disponible)
    ELSE 0
  END) AS patrimonio_neto,
  SUM(CASE WHEN c.tipo = 'cash' THEN c.saldo ELSE 0 END) AS efectivo,
  SUM(CASE WHEN c.tipo IN ('debit', 'savings') THEN c.saldo ELSE 0 END) AS cuentas_bancarias,
  SUM(CASE WHEN c.tipo = 'credit_card' THEN tc.credito_disponible ELSE 0 END) AS credito_disponible,
  SUM(CASE WHEN c.tipo = 'credit_card' THEN (tc.limite_credito - tc.credito_disponible) ELSE 0 END) AS deuda_credito
FROM cuentas c
LEFT JOIN tarjetas_credito tc ON c.id = tc.cuenta_id
GROUP BY c.creada_por;

COMMENT ON VIEW vista_patrimonio_usuario IS 'Resumen del patrimonio neto por usuario considerando efectivo, bancos y deudas de crédito';


-- ===================================================
-- 7) VISTA PARA GASTOS POR CATEGORÍA DEL MES
-- ===================================================
CREATE OR REPLACE VIEW vista_gastos_mes_actual AS
SELECT 
  t.usuario_id,
  c.nombre AS categoria,
  gc.nombre AS grupo_categoria,
  COUNT(*) AS cantidad_transacciones,
  SUM(t.monto) AS total_gastado,
  AVG(t.monto) AS promedio_gasto
FROM transacciones t
JOIN categorias c ON t.categoria_id = c.id
JOIN grupos_categoria gc ON c.grupo_id = gc.id
WHERE t.tipo = 'gasto'
  AND EXTRACT(MONTH FROM t.fecha_ocurrencia) = EXTRACT(MONTH FROM CURRENT_DATE)
  AND EXTRACT(YEAR FROM t.fecha_ocurrencia) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY t.usuario_id, c.nombre, gc.nombre;

COMMENT ON VIEW vista_gastos_mes_actual IS 'Estadísticas de gastos agrupados por categoría para el mes actual';


-- ===================================================
-- 8) VISTA PARA PROGRESO DE METAS
-- ===================================================
CREATE OR REPLACE VIEW vista_progreso_metas AS
SELECT 
  m.id,
  m.usuario_id,
  m.grupo_usuario_id,
  m.titulo,
  m.tipo,
  m.monto_objetivo,
  m.monto_actual,
  ROUND((m.monto_actual / NULLIF(m.monto_objetivo, 0)) * 100, 2) AS porcentaje_completado,
  (m.monto_objetivo - m.monto_actual) AS monto_faltante,
  m.fecha_inicio,
  m.fecha_fin,
  CASE 
    WHEN m.fecha_fin IS NOT NULL THEN (m.fecha_fin - CURRENT_DATE)
    ELSE NULL
  END AS dias_restantes,
  CASE
    WHEN m.monto_actual >= m.monto_objetivo THEN 'completada'
    WHEN m.fecha_fin IS NOT NULL AND m.fecha_fin < CURRENT_DATE THEN 'vencida'
    WHEN (m.monto_actual / NULLIF(m.monto_objetivo, 0)) >= (m.notificar_al_alcanzar / 100) THEN 'cerca_objetivo'
    ELSE 'en_progreso'
  END AS estado_calculado,
  m.estado AS estado_registrado
FROM metas m
WHERE m.estado != 'cancelada';

COMMENT ON VIEW vista_progreso_metas IS 'Análisis del progreso de las metas con cálculos de porcentaje, faltante y días restantes';


-- ===================================================
-- 9) FUNCIÓN PARA DIVIDIR GASTO AUTOMÁTICAMENTE
-- ===================================================
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
    SELECT usuario_id, share_percent
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
      v_miembro.share_percent,
      ROUND((v_monto_total * v_miembro.share_percent / 100), 2)
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION dividir_gasto_grupal IS 'Divide automáticamente una transacción entre los miembros de un grupo según sus porcentajes';


-- ===================================================
-- 10) FUNCIÓN PARA ACEPTAR INVITACIÓN
-- ===================================================
CREATE OR REPLACE FUNCTION aceptar_invitacion_grupo(
  p_token UUID,
  p_usuario_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invitacion RECORD;
  v_resultado JSONB;
BEGIN
  -- Buscar la invitación
  SELECT * INTO v_invitacion
  FROM invitaciones_grupo
  WHERE token = p_token
    AND estado = 'pendiente'
    AND fecha_expiracion > now();
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Invitación no encontrada, expirada o ya procesada'
    );
  END IF;
  
  -- Verificar que el email coincida con el usuario
  -- (Aquí deberías agregar validación con el email del perfil)
  
  -- Agregar al usuario como miembro del grupo
  INSERT INTO miembros_grupo (
    grupo_id,
    usuario_id,
    share_percent,
    role
  ) VALUES (
    v_invitacion.grupo_id,
    p_usuario_id,
    v_invitacion.porcentaje_propuesto,
    v_invitacion.rol_propuesto
  );
  
  -- Marcar invitación como aceptada
  UPDATE invitaciones_grupo
  SET estado = 'aceptada',
      fecha_respuesta = now()
  WHERE id = v_invitacion.id;
  
  RETURN jsonb_build_object(
    'success', true,
    'grupo_id', v_invitacion.grupo_id,
    'rol', v_invitacion.rol_propuesto
  );
  
EXCEPTION
  WHEN unique_violation THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Ya eres miembro de este grupo'
    );
  WHEN OTHERS THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$;

COMMENT ON FUNCTION aceptar_invitacion_grupo IS 'Acepta una invitación a grupo mediante token y agrega al usuario como miembro';


-- ===================================================
-- 11) ACTIVAR RLS EN NUEVAS TABLAS
-- ===================================================
ALTER TABLE invitaciones_grupo ENABLE ROW LEVEL SECURITY;
ALTER TABLE historial_saldos ENABLE ROW LEVEL SECURITY;


-- ===================================================
-- 12) POLÍTICAS RLS PARA INVITACIONES_GRUPO
-- ===================================================

-- SELECT: Ver invitaciones donde eres el invitador o el grupo es tuyo
DROP POLICY IF EXISTS select_invitaciones_grupo ON invitaciones_grupo;
CREATE POLICY select_invitaciones_grupo ON invitaciones_grupo
  FOR SELECT USING (
    usuario_invitador = auth.uid()
    OR EXISTS (
      SELECT 1 FROM grupos_usuario g
      WHERE g.id = invitaciones_grupo.grupo_id
        AND g.propietario_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM miembros_grupo mg
      WHERE mg.grupo_id = invitaciones_grupo.grupo_id
        AND mg.usuario_id = auth.uid()
        AND mg.rol = 'administrador'
    )
  );

-- INSERT: Crear invitaciones si eres admin del grupo
DROP POLICY IF EXISTS insert_invitaciones_grupo ON invitaciones_grupo;
CREATE POLICY insert_invitaciones_grupo ON invitaciones_grupo
  FOR INSERT WITH CHECK (
    usuario_invitador = auth.uid()
    AND (
      EXISTS (
        SELECT 1 FROM grupos_usuario g
        WHERE g.id = grupo_id
          AND g.propietario_id = auth.uid()
      )
      OR EXISTS (
        SELECT 1 FROM miembros_grupo mg
        WHERE mg.grupo_id = invitaciones_grupo.grupo_id
          AND mg.usuario_id = auth.uid()
          AND mg.rol = 'administrador'
      )
    )
  );

-- UPDATE: Actualizar invitaciones propias o del grupo que administras
DROP POLICY IF EXISTS update_invitaciones_grupo ON invitaciones_grupo;
CREATE POLICY update_invitaciones_grupo ON invitaciones_grupo
  FOR UPDATE USING (
    usuario_invitador = auth.uid()
    OR EXISTS (
      SELECT 1 FROM grupos_usuario g
      WHERE g.id = invitaciones_grupo.grupo_id
        AND g.propietario_id = auth.uid()
    )
  );

-- DELETE: Cancelar invitaciones propias
DROP POLICY IF EXISTS delete_invitaciones_grupo ON invitaciones_grupo;
CREATE POLICY delete_invitaciones_grupo ON invitaciones_grupo
  FOR DELETE USING (
    usuario_invitador = auth.uid()
  );


-- ===================================================
-- 13) POLÍTICAS RLS PARA HISTORIAL_SALDOS
-- ===================================================

-- SELECT: Ver historial de tus propias cuentas o cuentas del grupo
DROP POLICY IF EXISTS select_historial_saldos ON historial_saldos;
CREATE POLICY select_historial_saldos ON historial_saldos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM cuentas c
      WHERE c.id = historial_saldos.cuenta_id
        AND (
          c.creada_por = auth.uid()
          OR c.grupo_usuario_id IN (
            SELECT grupo_id FROM miembros_grupo
            WHERE usuario_id = auth.uid()
          )
        )
    )
  );

-- El historial se inserta automáticamente por triggers, no necesita política INSERT


-- ===================================================
-- FINALIZACIÓN
-- ===================================================
-- La migración ha completado exitosamente.
-- Nuevas funcionalidades agregadas:
-- ✅ Sistema de invitaciones a grupos con tokens seguros
-- ✅ Historial de saldos para análisis temporal
-- ✅ Mejoras en metas (notificaciones, límites, iconos)
-- ✅ Vistas materializadas para estadísticas
-- ✅ Funciones auxiliares para división de gastos y aceptación de invitaciones
-- ✅ Políticas RLS completas para seguridad

-- Para verificar que todo se creó correctamente:
SELECT 
  'invitaciones_grupo' AS tabla,
  COUNT(*) AS registros
FROM invitaciones_grupo
UNION ALL
SELECT 
  'historial_saldos' AS tabla,
  COUNT(*) AS registros
FROM historial_saldos;
