-- ============================================
-- TRANSACCIONES PERIÓDICAS / PROGRAMADAS
-- ============================================

-- Tipos de recurrencia
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

-- Tipo ENUM para días de la semana
CREATE TYPE dia_semana AS ENUM (
    'lunes',
    'martes',
    'miercoles',
    'jueves',
    'viernes',
    'sabado',
    'domingo'
);

-- Tipo ENUM para criterios de finalización
CREATE TYPE criterio_finalizacion AS ENUM (
    'sin_fin',              -- Se repite indefinidamente
    'fecha_fin',            -- Se repite hasta una fecha específica
    'numero_repeticiones'   -- Se repite X veces
);

-- Tabla principal de transacciones periódicas
CREATE TABLE transacciones_periodicas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Información básica
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    tipo tipo_transaccion NOT NULL, -- 'ingreso', 'gasto', 'transferencia'
    
    -- Monto
    monto DECIMAL(15, 2) NOT NULL CHECK (monto > 0),
    
    -- ========================================
    -- CONFIGURACIÓN DE RECURRENCIA AVANZADA
    -- ========================================
    
    frecuencia frecuencia_transaccion NOT NULL,
    
    -- Para frecuencia 'dias_naturales': cada X días
    intervalo_dias INTEGER, -- Ej: 30 para cada 30 días
    
    -- Para frecuencia 'mensual': día específico del mes
    dia_del_mes INTEGER CHECK (dia_del_mes >= 1 AND dia_del_mes <= 31),
    
    -- Para frecuencia 'semanal': días de la semana
    dias_semana dia_semana[], -- Array de días ['lunes', 'miercoles', 'viernes']
    
    -- Para frecuencia 'anual': mes y día específico
    mes_del_anio INTEGER CHECK (mes_del_anio >= 1 AND mes_del_anio <= 12),
    dia_del_anio INTEGER CHECK (dia_del_anio >= 1 AND dia_del_anio <= 31),
    
    -- ========================================
    -- CRITERIOS DE FINALIZACIÓN
    -- ========================================
    
    criterio_fin criterio_finalizacion NOT NULL DEFAULT 'sin_fin',
    
    -- Si criterio_fin = 'fecha_fin'
    fecha_fin DATE,
    
    -- Si criterio_fin = 'numero_repeticiones'
    numero_total_repeticiones INTEGER,
    repeticiones_completadas INTEGER DEFAULT 0,
    
    -- ========================================
    -- ESPECÍFICO PARA MSI
    -- ========================================
    
    es_msi BOOLEAN DEFAULT FALSE,
    monto_total_msi DECIMAL(15, 2), -- Monto total del MSI
    numero_meses_total INTEGER, -- Total de meses del MSI
    meses_pagados INTEGER DEFAULT 0, -- Meses ya pagados (para registros avanzados)
    monto_por_mes DECIMAL(15, 2), -- Monto mensual calculado (auto-calculado)
    
    -- ========================================
    -- CUENTA(S) INVOLUCRADA(S)
    -- ========================================
    
    cuenta_id UUID REFERENCES cuentas(id) ON DELETE CASCADE,
    cuenta_destino_id UUID REFERENCES cuentas(id) ON DELETE SET NULL, -- Para transferencias
    categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
    
    -- ========================================
    -- PROGRAMACIÓN Y ESTADO
    -- ========================================
    
    fecha_inicio DATE NOT NULL,
    proxima_ejecucion TIMESTAMP WITH TIME ZONE,
    
    -- ========================================
    -- CONTROL DE EJECUCIÓN
    -- ========================================
    
    activa BOOLEAN DEFAULT TRUE,
    requiere_confirmacion BOOLEAN DEFAULT TRUE, -- FALSE para MSI en tarjetas de crédito
    auto_ejecutar BOOLEAN DEFAULT FALSE, -- TRUE para MSI, FALSE para otras
    
    -- ========================================
    -- METADATA
    -- ========================================
    
    etiquetas TEXT[],
    notas TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- ========================================
    -- CONSTRAINTS
    -- ========================================
    
    -- MSI debe tener todos los campos requeridos
    CONSTRAINT chk_msi_completo CHECK (
        NOT es_msi OR (
            monto_total_msi IS NOT NULL AND
            numero_meses_total IS NOT NULL AND
            monto_por_mes IS NOT NULL AND
            cuenta_id IS NOT NULL AND
            frecuencia = 'msi'
        )
    ),
    
    -- Validar que si usa días_naturales tenga intervalo_dias
    CONSTRAINT chk_dias_naturales CHECK (
        frecuencia != 'dias_naturales' OR intervalo_dias IS NOT NULL
    ),
    
    -- Validar que si es mensual tenga dia_del_mes
    CONSTRAINT chk_mensual CHECK (
        frecuencia != 'mensual' OR dia_del_mes IS NOT NULL
    ),
    
    -- Validar que si es semanal tenga dias_semana
    CONSTRAINT chk_semanal CHECK (
        frecuencia != 'semanal' OR (dias_semana IS NOT NULL AND array_length(dias_semana, 1) > 0)
    ),
    
    -- Validar que si es anual tenga mes y día
    CONSTRAINT chk_anual CHECK (
        frecuencia != 'anual' OR (mes_del_anio IS NOT NULL AND dia_del_anio IS NOT NULL)
    ),
    
    -- Validar criterios de finalización
    CONSTRAINT chk_fecha_fin CHECK (
        criterio_fin != 'fecha_fin' OR fecha_fin IS NOT NULL
    ),
    
    CONSTRAINT chk_numero_repeticiones CHECK (
        criterio_fin != 'numero_repeticiones' OR numero_total_repeticiones IS NOT NULL
    )
);

-- Tabla para trackear cada ejecución de transacciones periódicas
CREATE TABLE ejecuciones_transacciones_periodicas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaccion_periodica_id UUID NOT NULL REFERENCES transacciones_periodicas(id) ON DELETE CASCADE,
    transaccion_id UUID REFERENCES transacciones(id) ON DELETE SET NULL, -- NULL si está pendiente
    
    -- Estado
    estado VARCHAR(20) NOT NULL DEFAULT 'pendiente', -- 'pendiente', 'confirmada', 'ejecutada', 'cancelada', 'fallida'
    
    -- Fechas
    fecha_programada DATE NOT NULL,
    fecha_ejecutada TIMESTAMP WITH TIME ZONE,
    fecha_confirmada TIMESTAMP WITH TIME ZONE,
    
    -- Monto (puede variar si el usuario lo ajusta)
    monto_programado DECIMAL(15, 2) NOT NULL,
    monto_ejecutado DECIMAL(15, 2),
    
    -- Para MSI
    numero_cuota INTEGER, -- Número de cuota (1, 2, 3, etc.)
    
    -- Notas
    notas TEXT,
    error_mensaje TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_transacciones_periodicas_usuario ON transacciones_periodicas(usuario_id);
CREATE INDEX idx_transacciones_periodicas_cuenta ON transacciones_periodicas(cuenta_id);
CREATE INDEX idx_transacciones_periodicas_proxima_ejecucion ON transacciones_periodicas(proxima_ejecucion) WHERE activa = TRUE;
CREATE INDEX idx_transacciones_periodicas_activa ON transacciones_periodicas(activa);
CREATE INDEX idx_ejecuciones_periodica_id ON ejecuciones_transacciones_periodicas(transaccion_periodica_id);
CREATE INDEX idx_ejecuciones_estado ON ejecuciones_transacciones_periodicas(estado);
CREATE INDEX idx_ejecuciones_fecha_programada ON ejecuciones_transacciones_periodicas(fecha_programada);

-- Trigger para updated_at
CREATE TRIGGER update_transacciones_periodicas_updated_at
    BEFORE UPDATE ON transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ejecuciones_periodicas_updated_at
    BEFORE UPDATE ON ejecuciones_transacciones_periodicas
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- RLS (Row Level Security)
ALTER TABLE transacciones_periodicas ENABLE ROW LEVEL SECURITY;
ALTER TABLE ejecuciones_transacciones_periodicas ENABLE ROW LEVEL SECURITY;

-- Políticas para transacciones_periodicas
CREATE POLICY "Los usuarios pueden ver sus propias transacciones periódicas"
    ON transacciones_periodicas FOR SELECT
    USING (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden crear sus propias transacciones periódicas"
    ON transacciones_periodicas FOR INSERT
    WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden actualizar sus propias transacciones periódicas"
    ON transacciones_periodicas FOR UPDATE
    USING (auth.uid() = usuario_id)
    WITH CHECK (auth.uid() = usuario_id);

CREATE POLICY "Los usuarios pueden eliminar sus propias transacciones periódicas"
    ON transacciones_periodicas FOR DELETE
    USING (auth.uid() = usuario_id);

-- Políticas para ejecuciones_transacciones_periodicas
CREATE POLICY "Los usuarios pueden ver ejecuciones de sus transacciones periódicas"
    ON ejecuciones_transacciones_periodicas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.id = ejecuciones_transacciones_periodicas.transaccion_periodica_id
            AND tp.usuario_id = auth.uid()
        )
    );

CREATE POLICY "Los usuarios pueden crear ejecuciones de sus transacciones periódicas"
    ON ejecuciones_transacciones_periodicas FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.id = ejecuciones_transacciones_periodicas.transaccion_periodica_id
            AND tp.usuario_id = auth.uid()
        )
    );

CREATE POLICY "Los usuarios pueden actualizar ejecuciones de sus transacciones periódicas"
    ON ejecuciones_transacciones_periodicas FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.id = ejecuciones_transacciones_periodicas.transaccion_periodica_id
            AND tp.usuario_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.id = ejecuciones_transacciones_periodicas.transaccion_periodica_id
            AND tp.usuario_id = auth.uid()
        )
    );

CREATE POLICY "Los usuarios pueden eliminar ejecuciones de sus transacciones periódicas"
    ON ejecuciones_transacciones_periodicas FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM transacciones_periodicas tp
            WHERE tp.id = ejecuciones_transacciones_periodicas.transaccion_periodica_id
            AND tp.usuario_id = auth.uid()
        )
    );

-- ============================================
-- FUNCIÓN PARA CALCULAR PRÓXIMA EJECUCIÓN
-- ============================================

CREATE OR REPLACE FUNCTION calcular_proxima_ejecucion(
    p_transaccion_periodica_id UUID,
    p_fecha_base TIMESTAMP WITH TIME ZONE DEFAULT NOW()
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
AS $$
DECLARE
    v_record RECORD;
    v_proxima_fecha TIMESTAMP WITH TIME ZONE;
    v_temp_date DATE;
    v_dia_semana_actual INTEGER;
    v_dias_hasta_proximo INTEGER;
    v_encontrado BOOLEAN := FALSE;
BEGIN
    -- Obtener configuración de la transacción
    SELECT * INTO v_record
    FROM transacciones_periodicas
    WHERE id = p_transaccion_periodica_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Transacción periódica no encontrada';
    END IF;
    
    -- Calcular según frecuencia
    CASE v_record.frecuencia
        
        -- DIARIA: siguiente día
        WHEN 'diaria' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '1 day';
        
        -- SEMANAL: siguiente día de la semana especificado
        WHEN 'semanal' THEN
            -- Obtener día de la semana actual (1=lunes, 7=domingo)
            v_dia_semana_actual := EXTRACT(ISODOW FROM p_fecha_base);
            
            -- Buscar el próximo día en el array dias_semana
            v_temp_date := p_fecha_base::DATE;
            
            FOR i IN 1..7 LOOP
                v_temp_date := v_temp_date + INTERVAL '1 day';
                v_dia_semana_actual := EXTRACT(ISODOW FROM v_temp_date);
                
                -- Convertir a nombre de día y verificar si está en el array
                IF (
                    (v_dia_semana_actual = 1 AND 'lunes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 2 AND 'martes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 3 AND 'miercoles' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 4 AND 'jueves' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 5 AND 'viernes' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 6 AND 'sabado' = ANY(v_record.dias_semana)) OR
                    (v_dia_semana_actual = 7 AND 'domingo' = ANY(v_record.dias_semana))
                ) THEN
                    v_proxima_fecha := v_temp_date;
                    EXIT;
                END IF;
            END LOOP;
        
        -- QUINCENAL: cada 15 días
        WHEN 'quincenal' THEN
            v_proxima_fecha := p_fecha_base + INTERVAL '15 days';
        
        -- MENSUAL: mismo día del próximo mes
        WHEN 'mensual' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month')::DATE;
            
            -- Ajustar al día específico del mes
            v_temp_date := v_temp_date + (v_record.dia_del_mes - 1) || ' days';
            
            -- Si el día no existe en ese mes (ej: 31 en febrero), usar el último día
            IF EXTRACT(DAY FROM v_temp_date) != v_record.dia_del_mes THEN
                v_temp_date := (DATE_TRUNC('month', v_temp_date) + INTERVAL '1 month - 1 day')::DATE;
            END IF;
            
            v_proxima_fecha := v_temp_date;
        
        -- BIMESTRAL: cada 2 meses
        WHEN 'bimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '2 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- TRIMESTRAL: cada 3 meses
        WHEN 'trimestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '3 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- SEMESTRAL: cada 6 meses
        WHEN 'semestral' THEN
            v_temp_date := (DATE_TRUNC('month', p_fecha_base) + INTERVAL '6 months')::DATE;
            v_temp_date := v_temp_date + (COALESCE(v_record.dia_del_mes, 1) - 1) || ' days';
            v_proxima_fecha := v_temp_date;
        
        -- ANUAL: mismo día y mes del próximo año
        WHEN 'anual' THEN
            v_temp_date := MAKE_DATE(
                EXTRACT(YEAR FROM p_fecha_base)::INTEGER + 1,
                v_record.mes_del_anio,
                v_record.dia_del_anio
            );
            v_proxima_fecha := v_temp_date;
        
        -- DÍAS NATURALES: cada X días
        WHEN 'dias_naturales' THEN
            v_proxima_fecha := p_fecha_base + (v_record.intervalo_dias || ' days')::INTERVAL;
        
        -- MSI: mensual basado en día de corte de tarjeta
        WHEN 'msi' THEN
            -- Obtener día de corte de la tarjeta
            SELECT 
                CASE 
                    WHEN dia_corte <= EXTRACT(DAY FROM p_fecha_base) THEN
                        (DATE_TRUNC('month', p_fecha_base) + INTERVAL '1 month' + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                    ELSE
                        (DATE_TRUNC('month', p_fecha_base) + (dia_corte - 1 || ' days')::INTERVAL)::DATE
                END INTO v_temp_date
            FROM cuentas
            WHERE id = v_record.cuenta_id;
            
            v_proxima_fecha := v_temp_date;
        
        -- ÚNICA: misma fecha de inicio
        WHEN 'unica' THEN
            v_proxima_fecha := v_record.fecha_inicio;
        
        ELSE
            RAISE EXCEPTION 'Frecuencia no soportada: %', v_record.frecuencia;
    END CASE;
    
    -- Verificar si alcanzó el criterio de finalización
    IF v_record.criterio_fin = 'fecha_fin' AND v_proxima_fecha::DATE > v_record.fecha_fin THEN
        RETURN NULL; -- Ya no debe ejecutarse más
    END IF;
    
    IF v_record.criterio_fin = 'numero_repeticiones' AND 
       v_record.repeticiones_completadas >= v_record.numero_total_repeticiones THEN
        RETURN NULL; -- Ya completó todas las repeticiones
    END IF;
    
    RETURN v_proxima_fecha;
END;
$$;

-- ============================================
-- FUNCIÓN PARA CREAR MSI EN TARJETA DE CRÉDITO
-- ============================================

CREATE OR REPLACE FUNCTION crear_msi_tarjeta_credito(
    p_usuario_id UUID,
    p_cuenta_id UUID,
    p_categoria_id UUID,
    p_nombre VARCHAR,
    p_descripcion TEXT,
    p_monto_total DECIMAL,
    p_numero_meses INTEGER,
    p_meses_ya_pagados INTEGER DEFAULT 0
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_transaccion_periodica_id UUID;
    v_monto_mensual DECIMAL;
    v_fecha_corte INTEGER;
    v_proxima_fecha_corte DATE;
    v_meses_restantes INTEGER;
    v_fecha_ejecucion DATE;
    i INTEGER;
BEGIN
    -- Validaciones
    IF p_numero_meses <= 0 OR p_numero_meses > 48 THEN
        RAISE EXCEPTION 'El número de meses debe estar entre 1 y 48';
    END IF;
    
    IF p_meses_ya_pagados < 0 OR p_meses_ya_pagados >= p_numero_meses THEN
        RAISE EXCEPTION 'Los meses ya pagados deben ser menores al total de meses';
    END IF;
    
    -- Obtener día de corte de la tarjeta
    SELECT dia_corte INTO v_fecha_corte
    FROM cuentas
    WHERE id = p_cuenta_id AND creada_por = p_usuario_id AND tipo = 'credit_card';
    
    IF v_fecha_corte IS NULL THEN
        RAISE EXCEPTION 'La cuenta debe ser una tarjeta de crédito con día de corte configurado';
    END IF;
    
    -- Calcular monto mensual
    v_monto_mensual := ROUND(p_monto_total / p_numero_meses, 2);
    v_meses_restantes := p_numero_meses - p_meses_ya_pagados;
    
    -- Calcular próxima fecha de corte
    v_proxima_fecha_corte := (
        SELECT proxima_fecha_corte::DATE 
        FROM cuentas 
        WHERE id = p_cuenta_id
    );
    
    IF v_proxima_fecha_corte IS NULL THEN
        -- Calcular manualmente si no existe
        IF v_fecha_corte <= EXTRACT(DAY FROM CURRENT_DATE) THEN
            v_proxima_fecha_corte := (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month' + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        ELSE
            v_proxima_fecha_corte := (DATE_TRUNC('month', CURRENT_DATE) + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        END IF;
    END IF;
    
    -- Crear transacción periódica
    INSERT INTO transacciones_periodicas (
        usuario_id,
        nombre,
        descripcion,
        tipo,
        monto,
        frecuencia,
        criterio_fin,
        numero_total_repeticiones,
        repeticiones_completadas,
        es_msi,
        monto_total_msi,
        numero_meses_total,
        meses_pagados,
        monto_por_mes,
        cuenta_id,
        categoria_id,
        fecha_inicio,
        proxima_ejecucion,
        dia_del_mes,
        activa,
        requiere_confirmacion,
        auto_ejecutar
    ) VALUES (
        p_usuario_id,
        p_nombre,
        COALESCE(p_descripcion, 'Pago MSI a ' || p_numero_meses || ' meses'),
        'gasto',
        v_monto_mensual,
        'msi',
        'numero_repeticiones',
        p_numero_meses,
        p_meses_ya_pagados,
        TRUE,
        p_monto_total,
        p_numero_meses,
        p_meses_ya_pagados,
        v_monto_mensual,
        p_cuenta_id,
        p_categoria_id,
        v_proxima_fecha_corte,
        v_proxima_fecha_corte,
        v_fecha_corte,
        TRUE,
        FALSE, -- No requiere confirmación
        TRUE   -- Se ejecuta automáticamente
    ) RETURNING id INTO v_transaccion_periodica_id;
    
    -- Crear ejecuciones programadas para cada mes restante
    v_fecha_ejecucion := v_proxima_fecha_corte;
    
    FOR i IN (p_meses_ya_pagados + 1)..p_numero_meses LOOP
        INSERT INTO ejecuciones_transacciones_periodicas (
            transaccion_periodica_id,
            estado,
            fecha_programada,
            monto_programado,
            numero_cuota
        ) VALUES (
            v_transaccion_periodica_id,
            'pendiente',
            v_fecha_ejecucion,
            v_monto_mensual,
            i
        );
        
        -- Calcular siguiente fecha de corte (próximo mes)
        IF v_fecha_corte <= EXTRACT(DAY FROM v_fecha_ejecucion) THEN
            v_fecha_ejecucion := (DATE_TRUNC('month', v_fecha_ejecucion) + INTERVAL '1 month' + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        ELSE
            v_fecha_ejecucion := (DATE_TRUNC('month', v_fecha_ejecucion) + INTERVAL '1 month' + (v_fecha_corte - 1 || ' days')::INTERVAL)::DATE;
        END IF;
    END LOOP;
    
    RETURN v_transaccion_periodica_id;
END;
$$;

-- ============================================
-- COMENTARIOS Y DOCUMENTACIÓN
-- ============================================

COMMENT ON TABLE transacciones_periodicas IS 'Transacciones programadas y recurrentes - soporta ingresos periódicos, gastos recurrentes, MSI, etc.';
COMMENT ON TABLE ejecuciones_transacciones_periodicas IS 'Registro de cada ejecución individual de una transacción periódica';

-- Comentarios sobre configuración de recurrencia
COMMENT ON COLUMN transacciones_periodicas.frecuencia IS 'Tipo de frecuencia: diaria, semanal, mensual, etc.';
COMMENT ON COLUMN transacciones_periodicas.intervalo_dias IS 'Para frecuencia dias_naturales: ejecutar cada X días (ej: cada 30 días)';
COMMENT ON COLUMN transacciones_periodicas.dia_del_mes IS 'Para frecuencia mensual: día específico del mes (1-31)';
COMMENT ON COLUMN transacciones_periodicas.dias_semana IS 'Para frecuencia semanal: array de días [''lunes'', ''miercoles'', ''viernes'']';
COMMENT ON COLUMN transacciones_periodicas.mes_del_anio IS 'Para frecuencia anual: mes específico (1-12)';
COMMENT ON COLUMN transacciones_periodicas.dia_del_anio IS 'Para frecuencia anual: día específico (1-31)';

-- Comentarios sobre criterios de finalización
COMMENT ON COLUMN transacciones_periodicas.criterio_fin IS 'Cómo determinar cuándo termina: sin_fin, fecha_fin, numero_repeticiones';
COMMENT ON COLUMN transacciones_periodicas.fecha_fin IS 'Fecha límite si criterio_fin = fecha_fin';
COMMENT ON COLUMN transacciones_periodicas.numero_total_repeticiones IS 'Total de veces a repetir si criterio_fin = numero_repeticiones';
COMMENT ON COLUMN transacciones_periodicas.repeticiones_completadas IS 'Contador de repeticiones completadas';

-- Comentarios sobre MSI
COMMENT ON COLUMN transacciones_periodicas.es_msi IS 'TRUE si es un pago a Meses Sin Intereses';
COMMENT ON COLUMN transacciones_periodicas.monto_total_msi IS 'Monto total de la compra MSI';
COMMENT ON COLUMN transacciones_periodicas.numero_meses_total IS 'Total de meses del MSI (3, 6, 9, 12, 18, 24)';
COMMENT ON COLUMN transacciones_periodicas.meses_pagados IS 'Meses ya pagados (útil para registrar MSI en progreso)';
COMMENT ON COLUMN transacciones_periodicas.monto_por_mes IS 'Monto mensual calculado (monto_total / numero_meses)';

-- Ejemplos de uso
COMMENT ON TYPE frecuencia_transaccion IS '
EJEMPLOS DE USO:

1. SALARIO QUINCENAL (cada 15 del mes):
   frecuencia = ''mensual''
   dia_del_mes = 15
   criterio_fin = ''sin_fin''

2. RENTA (cada 1 del mes):
   frecuencia = ''mensual''
   dia_del_mes = 1
   criterio_fin = ''sin_fin''

3. NETFLIX (cada martes):
   frecuencia = ''semanal''
   dias_semana = ARRAY[''martes'']::dia_semana[]
   criterio_fin = ''sin_fin''

4. GYM (cada 30 días naturales):
   frecuencia = ''dias_naturales''
   intervalo_dias = 30
   criterio_fin = ''sin_fin''

5. CUMPLEAÑOS (15 de junio cada año):
   frecuencia = ''anual''
   mes_del_anio = 6
   dia_del_anio = 15
   criterio_fin = ''sin_fin''

6. MSI 12 MESES (ya van 4 meses pagados):
   frecuencia = ''msi''
   es_msi = TRUE
   monto_total_msi = 12000
   numero_meses_total = 12
   meses_pagados = 4
   criterio_fin = ''numero_repeticiones''
   numero_total_repeticiones = 12

7. PROYECTO TEMPORAL (10 pagos semanales):
   frecuencia = ''semanal''
   dias_semana = ARRAY[''viernes'']::dia_semana[]
   criterio_fin = ''numero_repeticiones''
   numero_total_repeticiones = 10

8. AHORRO HASTA FIN DE AÑO:
   frecuencia = ''mensual''
   dia_del_mes = 1
   criterio_fin = ''fecha_fin''
   fecha_fin = ''2025-12-31''
';
    IF v_ultima_ejecucion IS NULL THEN
        v_ultima_ejecucion := NOW();
    END IF;
    
    -- Calcular según frecuencia
    CASE v_frecuencia
        WHEN 'diaria' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '1 day';
        WHEN 'semanal' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '1 week';
        WHEN 'quincenal' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '2 weeks';
        WHEN 'mensual', 'msi' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '1 month';
            -- Ajustar al día específico si está configurado
            IF v_dia_ejecucion IS NOT NULL THEN
                v_proxima := DATE_TRUNC('month', v_proxima) + (v_dia_ejecucion - 1 || ' days')::INTERVAL;
            END IF;
        WHEN 'bimestral' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '2 months';
        WHEN 'trimestral' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '3 months';
        WHEN 'semestral' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '6 months';
        WHEN 'anual' THEN
            v_proxima := v_ultima_ejecucion + INTERVAL '1 year';
        ELSE
            v_proxima := NULL;
    END CASE;
    
    RETURN v_proxima;
END;
$$;

COMMENT ON TABLE transacciones_periodicas IS 'Almacena transacciones programadas, recurrentes y MSI';
COMMENT ON TABLE ejecuciones_transacciones_periodicas IS 'Trackea cada ejecución individual de transacciones periódicas';
COMMENT ON FUNCTION crear_msi_tarjeta_credito IS 'Crea un MSI con todas sus cuotas programadas automáticamente';
