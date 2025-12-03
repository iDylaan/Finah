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
