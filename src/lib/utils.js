export const handleError = (error, toast, defaultMessage = 'Ocurrió un error inesperado') => {
    console.error('Error:', error)

    let errorMessage = defaultMessage

    // Mapear errores comunes de Supabase a mensajes en español
    if (error?.message) {
        const errorMap = {
            'Invalid login credentials': 'Credenciales de inicio de sesión incorrectas',
            'Email not confirmed': 'Email no confirmado. Revisa tu bandeja de entrada',
            'User already registered': 'El usuario ya está registrado',
            'Password should be at least 6 characters': 'La contraseña debe tener al menos 6 caracteres',
            'Unable to validate email address: invalid format': 'Formato de email inválido',
            'For security purposes, you can only request this once every 60 seconds': 'Por seguridad, solo puedes solicitar esto una vez cada 60 segundos',
            'Token has expired or is invalid': 'El token ha expirado o es inválido',
            'User not found': 'Usuario no encontrado',
            'New password should be different from the old password': 'La nueva contraseña debe ser diferente a la anterior',
            'Password is too weak': 'La contraseña es muy débil',
            'Email link is invalid or has expired': 'El enlace del email es inválido o ha expirado',
            'Signup is disabled': 'El registro está deshabilitado',
            'Database error saving new user': 'Error de base de datos al guardar nuevo usuario',
            'Rate limit exceeded': 'Límite de intentos excedido. Intenta más tarde',
        }

        errorMessage = errorMap[error.message] || error.message
    }

    if (toast) {
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: errorMessage
        })
    }

    return errorMessage
}

// ==================================================================
// UTILIDADES DE FECHAS
// ==================================================================

/**
 * Calcula los días restantes hasta una fecha
 * @param {Date|string} fecha - Fecha objetivo
 * @returns {number} - Días restantes (puede ser negativo si ya pasó)
 */
export const diasHasta = (fecha) => {
    if (!fecha) return null;
    
    const hoy = new Date();
    hoy.setHours(0, 0, 0, 0);
    
    let fechaObj;
    if (typeof fecha === 'string') {
        // Si es formato YYYY-MM-DD, parsearlo en zona local
        if (/^\d{4}-\d{2}-\d{2}/.test(fecha)) {
            const [year, month, day] = fecha.split('T')[0].split('-').map(Number);
            fechaObj = new Date(year, month - 1, day);
        } else {
            fechaObj = new Date(fecha);
        }
    } else {
        fechaObj = new Date(fecha);
    }
    
    fechaObj.setHours(0, 0, 0, 0);
    
    const diffTime = fechaObj - hoy;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    return diffDays;
};

/**
 * Calcula los días transcurridos desde una fecha
 * @param {Date|string} fecha - Fecha de inicio
 * @returns {number} - Días transcurridos (positivo si ya pasó)
 */
export const diasDesde = (fecha) => {
    if (!fecha) return null;
    
    const dias = diasHasta(fecha);
    return dias !== null ? -dias : null;
};

/**
 * Verifica si una fecha es hoy
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si es hoy
 */
export const esHoy = (fecha) => {
    return diasHasta(fecha) === 0;
};

/**
 * Verifica si una fecha es mañana
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si es mañana
 */
export const esManana = (fecha) => {
    return diasHasta(fecha) === 1;
};

/**
 * Verifica si una fecha está en el pasado
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si ya pasó
 */
export const esPasado = (fecha) => {
    const dias = diasHasta(fecha);
    return dias !== null && dias < 0;
};

/**
 * Verifica si una fecha está en el futuro
 * @param {Date|string} fecha - Fecha a verificar
 * @returns {boolean} - True si está por venir
 */
export const esFuturo = (fecha) => {
    const dias = diasHasta(fecha);
    return dias !== null && dias > 0;
};

/**
 * Calcula la diferencia en días entre dos fechas
 * @param {Date|string} fechaInicio - Fecha de inicio
 * @param {Date|string} fechaFin - Fecha de fin
 * @returns {number} - Diferencia en días (positivo si fechaFin > fechaInicio)
 */
export const diferenciaEnDias = (fechaInicio, fechaFin) => {
    if (!fechaInicio || !fechaFin) return null;
    
    const parseDate = (fecha) => {
        if (typeof fecha === 'string') {
            if (/^\d{4}-\d{2}-\d{2}/.test(fecha)) {
                const [year, month, day] = fecha.split('T')[0].split('-').map(Number);
                return new Date(year, month - 1, day);
            }
            return new Date(fecha);
        }
        return new Date(fecha);
    };
    
    const inicio = parseDate(fechaInicio);
    const fin = parseDate(fechaFin);
    
    inicio.setHours(0, 0, 0, 0);
    fin.setHours(0, 0, 0, 0);
    
    const diffTime = fin - inicio;
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

/**
 * Agrega días a una fecha
 * @param {Date|string} fecha - Fecha base
 * @param {number} dias - Número de días a agregar (puede ser negativo)
 * @returns {Date} - Nueva fecha
 */
export const agregarDias = (fecha, dias) => {
    if (!fecha) return null;
    
    const parseDate = (f) => {
        if (typeof f === 'string') {
            if (/^\d{4}-\d{2}-\d{2}/.test(f)) {
                const [year, month, day] = f.split('T')[0].split('-').map(Number);
                return new Date(year, month - 1, day);
            }
            return new Date(f);
        }
        return new Date(f);
    };
    
    const fechaObj = parseDate(fecha);
    fechaObj.setDate(fechaObj.getDate() + dias);
    
    return fechaObj;
};

/**
 * Obtiene el primer día del mes actual
 * @param {Date|string} [fecha] - Fecha de referencia (default: hoy)
 * @returns {Date} - Primer día del mes
 */
export const primerDiaDelMes = (fecha = new Date()) => {
    const fechaObj = typeof fecha === 'string' ? new Date(fecha) : new Date(fecha);
    return new Date(fechaObj.getFullYear(), fechaObj.getMonth(), 1);
};

/**
 * Obtiene el último día del mes actual
 * @param {Date|string} [fecha] - Fecha de referencia (default: hoy)
 * @returns {Date} - Último día del mes
 */
export const ultimoDiaDelMes = (fecha = new Date()) => {
    const fechaObj = typeof fecha === 'string' ? new Date(fecha) : new Date(fecha);
    return new Date(fechaObj.getFullYear(), fechaObj.getMonth() + 1, 0);
};

/**
 * Formatea un número como moneda MXN
 * @param {number} monto - Monto a formatear
 * @param {boolean} sinDecimales - Si debe omitir los decimales
 * @returns {string} - Monto formateado
 */
export const formatCurrency = (monto, sinDecimales = false) => {
    if (monto === null || monto === undefined) return '$0.00';
    
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN',
        minimumFractionDigits: sinDecimales ? 0 : 2,
        maximumFractionDigits: sinDecimales ? 0 : 2
    }).format(monto);
};

/**
 * Formatea un número con separadores de miles
 * @param {number} numero - Número a formatear
 * @param {number} decimales - Número de decimales (default: 0)
 * @returns {string} - Número formateado
 */
export const formatNumber = (numero, decimales = 0) => {
    if (numero === null || numero === undefined) return '0';
    
    return new Intl.NumberFormat('es-MX', {
        minimumFractionDigits: decimales,
        maximumFractionDigits: decimales
    }).format(numero);
};

// ==================================================================
// UTILIDADES DE COLOR Y CONTRASTE
// ==================================================================

/**
 * Determina el mejor color de texto para un fondo dado
 * @param {string} backgroundColor - Color de fondo en formato hexadecimal (#RRGGBB)
 * @returns {string} - Color de texto con mejor contraste (#RRGGBB)
 */
export function getContrastTextColor(backgroundColor) {
    // Si no hay color, usar texto negro por defecto
    if (!backgroundColor) {
        return '#000000';
    }

    // Eliminar el # si existe
    const color = backgroundColor.replace('#', '');

    // Convertir a RGB
    const r = parseInt(color.substring(0, 2), 16);
    const g = parseInt(color.substring(2, 4), 16);
    const b = parseInt(color.substring(4, 6), 16);

    // Calcular luminosidad (fórmula estándar para percepción de brillo)
    const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;

    // Si la luminosidad es mayor a 0.5, el fondo es claro y necesitamos texto oscuro
    return luminance > 0.5 ? '#000000' : '#ffffff';
}

/**
 * Determina el color de texto con opacidad apropiada para mejor contraste
 * @param {string} backgroundColor - Color de fondo en formato hexadecimal
 * @returns {object} - Objeto con color y opacidad para el texto
 */
export function getContrastTextWithOpacity(backgroundColor) {
  // Valores por defecto
  if (!backgroundColor) {
    return { color: '#000000', opacity: 0.5 };
  }
  
  // Eliminar el # si existe
  const color = backgroundColor.replace('#', '');
  
  // Convertir a RGB
  const r = parseInt(color.substring(0, 2), 16);
  const g = parseInt(color.substring(2, 4), 16);
  const b = parseInt(color.substring(4, 6), 16);
  
  // Calcular luminosidad (fórmula estándar para percepción de brillo)
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  
  // Si la luminosidad es mayor a 0.5, es un color claro
  // Para fondos claros: texto negro con opacidad 50%
  // Para fondos oscuros: texto blanco con opacidad 80%
  return luminance > 0.5 
    ? { color: '#000000', opacity: 0.5 } 
    : { color: '#ffffff', opacity: 0.8 };
}

/**
 * Formatea una fecha en diferentes formatos para visualización
 * Soporta tanto objetos Date como strings de fecha
 * Todos los formatos están en español (es-MX)
 * 
 * @param {Date|string} fecha - Fecha a formatear
 * @param {string} formato - Tipo de formato deseado
 *   - 'corto': "09 dic" (día + mes abreviado)
 *   - 'medio': "09 dic 2025" (día + mes abreviado + año) [DEFAULT]
 *   - 'largo': "9 de diciembre de 2025" (día + mes completo + año)
 *   - 'completo': "sábado, 9 de diciembre de 2025" (día semana + día + mes completo + año)
 *   - 'numerico': "09/12/2025" (dd/mm/yyyy)
 *   - 'iso': "2025-12-09" (yyyy-mm-dd)
 * @returns {string} Fecha formateada según el formato especificado
 */
export const formatDate = (fecha, formato = 'medio') => {
    if (!fecha) return '';

    // Convertir a objeto Date si es string
    let dateObj;
    if (fecha instanceof Date) {
        dateObj = fecha;
    } else if (typeof fecha === 'string') {
        // Si es formato YYYY-MM-DD, parsearlo en zona local
        if (/^\d{4}-\d{2}-\d{2}/.test(fecha)) {
            const [year, month, day] = fecha.split('T')[0].split('-').map(Number);
            dateObj = new Date(year, month - 1, day);
        } else {
            dateObj = new Date(fecha);
        }
    } else {
        return '';
    }

    // Verificar que la fecha sea válida
    if (isNaN(dateObj.getTime())) {
        return '';
    }

    const opciones = {
        timeZone: 'America/Mexico_City'
    };

    switch (formato) {
        case 'corto':
            // "09 dic"
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short'
            });

        case 'medio':
            // "09 dic 2025"
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            });

        case 'largo':
            // "9 de diciembre de 2025"
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                day: 'numeric',
                month: 'long',
                year: 'numeric'
            });

        case 'completo':
            // "sábado, 9 de diciembre de 2025"
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                weekday: 'long',
                day: 'numeric',
                month: 'long',
                year: 'numeric'
            });

        case 'numerico':
            // "09/12/2025"
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: '2-digit',
                year: 'numeric'
            });

        case 'iso':
            // "2025-12-09"
            const year = dateObj.getFullYear();
            const month = String(dateObj.getMonth() + 1).padStart(2, '0');
            const day = String(dateObj.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;

        default:
            // Por defecto: formato medio
            return dateObj.toLocaleDateString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short',
                year: 'numeric'
            });
    }
};

/**
 * Formatea una fecha con hora en diferentes formatos
 * 
 * @param {Date|string} fecha - Fecha a formatear
 * @param {string} formato - Tipo de formato deseado
 *   - 'corto': "09 dic, 14:30"
 *   - 'medio': "09 dic 2025, 14:30" [DEFAULT]
 *   - 'largo': "9 de diciembre de 2025, 14:30"
 *   - 'completo': "sábado, 9 de diciembre de 2025, 14:30:45"
 * @returns {string} Fecha y hora formateadas
 */
export const formatDateTime = (fecha, formato = 'medio') => {
    if (!fecha) return '';

    let dateObj;
    if (fecha instanceof Date) {
        dateObj = fecha;
    } else {
        dateObj = new Date(fecha);
    }

    if (isNaN(dateObj.getTime())) {
        return '';
    }

    const opciones = {
        timeZone: 'America/Mexico_City'
    };

    switch (formato) {
        case 'corto':
            return dateObj.toLocaleString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short',
                hour: '2-digit',
                minute: '2-digit'
            });

        case 'medio':
            return dateObj.toLocaleString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });

        case 'largo':
            return dateObj.toLocaleString('es-MX', {
                ...opciones,
                day: 'numeric',
                month: 'long',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });

        case 'completo':
            return dateObj.toLocaleString('es-MX', {
                ...opciones,
                weekday: 'long',
                day: 'numeric',
                month: 'long',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                second: '2-digit'
            });

        default:
            return dateObj.toLocaleString('es-MX', {
                ...opciones,
                day: '2-digit',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
    }
};

/**
 * Formatea solo la hora
 * 
 * @param {Date|string} fecha - Fecha/hora a formatear
 * @param {boolean} conSegundos - Si debe incluir segundos
 * @returns {string} Hora formateada
 */
export const formatTime = (fecha, conSegundos = false) => {
    if (!fecha) return '';

    let dateObj;
    if (fecha instanceof Date) {
        dateObj = fecha;
    } else {
        dateObj = new Date(fecha);
    }

    if (isNaN(dateObj.getTime())) {
        return '';
    }

    return dateObj.toLocaleTimeString('es-MX', {
        timeZone: 'America/Mexico_City',
        hour: '2-digit',
        minute: '2-digit',
        ...(conSegundos && { second: '2-digit' })
    });
};
