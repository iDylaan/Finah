<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useSessionStore } from '@/stores/session.js';

const router = useRouter();
const toast = useToast();
const sessionStore = useSessionStore();
const emit = defineEmits(['toggle-mode']);

// Estados del formulario
const email = ref('');
const password = ref('');
const isLoading = ref(false);

// Estados de validación
const emailTouched = ref(false);
const passwordTouched = ref(false);

// Regex para validación de email
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// Validaciones computed
const isEmailValid = computed(() => {
    if (!emailTouched.value) return true;
    return email.value && emailRegex.test(email.value.toLowerCase());
});

const isPasswordValid = computed(() => {
    if (!passwordTouched.value) return true;
    return password.value && password.value.length >= 6;
});

const isFormValid = computed(() => {
    return email.value &&
        password.value &&
        emailRegex.test(email.value.toLowerCase()) &&
        password.value.length >= 6;
});

// Mensajes de error
const emailError = computed(() => {
    if (!emailTouched.value) return '';
    if (!email.value) return 'El correo electrónico es requerido';
    if (!emailRegex.test(email.value.toLowerCase())) return 'Ingresa un correo electrónico válido';
    return '';
});

const passwordError = computed(() => {
    if (!passwordTouched.value) return '';
    if (!password.value) return 'La contraseña es requerida';
    if (password.value.length < 6) return 'La contraseña debe tener al menos 6 caracteres';
    return '';
});

// Función para normalizar email (convertir a minúsculas y limpiar espacios)
const normalizeEmail = (value) => {
    return value.toLowerCase().trim();
};

// Manejadores de eventos
const handleEmailInput = (value) => {
    email.value = normalizeEmail(value);
    emailTouched.value = true;
};

const handleEmailBlur = () => {
    emailTouched.value = true;
    email.value = normalizeEmail(email.value);
};

const handlePasswordBlur = () => {
    passwordTouched.value = true;
};

// Función principal de login
async function handleLogin() {
    // Marcar todos los campos como tocados para mostrar errores
    emailTouched.value = true;
    passwordTouched.value = true;

    // Validar formulario antes de enviar
    if (!isFormValid.value) {
        toast.add({
            severity: 'warn',
            summary: 'Formulario inválido',
            detail: 'Por favor corrige los errores antes de continuar',
            life: 4000
        });
        return;
    }

    isLoading.value = true;

    try {
        const { user, error } = await sessionStore.signIn(
            normalizeEmail(email.value),
            password.value,
            { toast }
        );

        if (user) {
            toast.add({
                severity: 'success',
                summary: 'Bienvenido',
                detail: `Has iniciado sesión como ${user.email}`,
                life: 3000
            });

            // Limpiar formulario
            email.value = '';
            password.value = '';
            emailTouched.value = false;
            passwordTouched.value = false;

            // Redirigir al dashboard
            router.push('/');
        }

    } catch (error) {
        console.error('💥 Error inesperado al iniciar sesión:', error);
        toast.add({
            severity: 'error',
            summary: 'Error inesperado',
            detail: 'Ocurrió un error inesperado. Inténtalo de nuevo.',
            life: 5000
        });
    } finally {
        isLoading.value = false;
    }
}

// Función para manejar "Olvidé mi contraseña"
const handleForgotPassword = async () => {
    if (!email.value) {
        toast.add({
            severity: 'warn',
            summary: 'Email requerido',
            detail: 'Ingresa tu email para recuperar la contraseña',
            life: 4000
        });
        return;
    }

    if (!emailRegex.test(email.value.toLowerCase())) {
        toast.add({
            severity: 'warn',
            summary: 'Email inválido',
            detail: 'Ingresa un email válido para recuperar la contraseña',
            life: 4000
        });
        return;
    }

    try {
        const { error } = await sessionStore.resetPassword(normalizeEmail(email.value));

        if (error) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se pudo enviar el email de recuperación',
                life: 5000
            });
            return;
        }

        toast.add({
            severity: 'success',
            summary: 'Email enviado',
            detail: 'Revisa tu email para restablecer tu contraseña',
            life: 5000
        });

    } catch (error) {
        console.error('Error al solicitar reset de password:', error);
        toast.add({
            severity: 'error',
            summary: 'Error inesperado',
            detail: 'No se pudo procesar la solicitud',
            life: 5000
        });
    }
};
</script>

<template>
    <div>
        <form @submit.prevent="handleLogin" novalidate>
            <!-- Campo de Email -->
            <div class="mb-6">
                <label for="email1" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                    Correo electrónico *
                </label>
                <InputText id="email1" type="email" placeholder="correo@dominio.com" class="w-full"
                    :class="{ 'p-invalid': emailTouched && !isEmailValid }" :modelValue="email"
                    @input="(e) => handleEmailInput(e.target.value)" @blur="handleEmailBlur" autocomplete="email"
                    :disabled="isLoading" />
                <small v-if="emailError" class="p-error block mt-1">
                    {{ emailError }}
                </small>
                <small v-else-if="email && isEmailValid" class="text-green-600 dark:text-green-400 block mt-1">
                    ✓ Email válido
                </small>
            </div>

            <!-- Campo de Contraseña -->
            <div class="mb-4">
                <label for="password1" class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">
                    Contraseña *
                </label>
                <Password id="password1" v-model="password" placeholder="Contraseña" :toggleMask="true" class="w-full"
                    fluid :feedback="false" :class="{ 'p-invalid': passwordTouched && !isPasswordValid }"
                    @blur="handlePasswordBlur" autocomplete="current-password" :disabled="isLoading" />
                <small v-if="passwordError" class="p-error block mt-1">
                    {{ passwordError }}
                </small>
            </div>

            <!-- Enlace de contraseña olvidada -->
            <div class="flex items-center justify-end mt-2 mb-8">
                <button type="button" @click="handleForgotPassword"
                    class="font-medium no-underline text-right cursor-pointer text-primary hover:underline"
                    :disabled="isLoading">
                    ¿Olvidaste la contraseña?
                </button>
            </div>

            <!-- Botón de envío -->
            <Button type="submit" label="Iniciar Sesión" :loading="isLoading || sessionStore.loading"
                :disabled="!isFormValid" class="w-full mb-6" />
        </form>

        <!-- Enlace de registro -->
        <div class="text-center">
            <span class="text-surface-600 dark:text-surface-400 text-sm">
                ¿No tienes una cuenta?
                <button @click="$emit('toggle-mode')" class="text-primary font-semibold ml-1 hover:underline"
                    type="button" :disabled="isLoading">
                    Regístrate aquí
                </button>
            </span>
        </div>
    </div>
</template>

<style scoped>
/* Estilos para campos inválidos */
.p-invalid {
    border-color: rgb(239 68 68) !important;
}

/* Estilos para mensajes de error */
.p-error {
    color: rgb(239 68 68);
    font-size: 0.875rem;
}

/* Deshabilitado durante carga */
button:disabled,
input:disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>