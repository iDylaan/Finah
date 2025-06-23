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