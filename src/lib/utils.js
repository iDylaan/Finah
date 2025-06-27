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