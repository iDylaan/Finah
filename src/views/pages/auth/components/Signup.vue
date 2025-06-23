<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useSessionStore } from '@/stores/session.js';
import { useForm } from 'vee-validate';
import { toTypedSchema } from '@vee-validate/zod';
import * as z from 'zod';

const router = useRouter();
const toast = useToast();
const sessionStore = useSessionStore();
const emit = defineEmits(['toggle-mode']);

// Estados del flujo de registro
const registrationKey = ref('');
const showRegistrationForm = ref(false);
const isValidatingKey = ref(false);

// Schema de validación con Zod
const registrationSchema = toTypedSchema(
    z.object({
        firstName: z
            .string()
            .min(1, 'El nombre es requerido')
            .min(2, 'El nombre debe tener al menos 2 caracteres')
            .max(50, 'El nombre no puede exceder 50 caracteres')
            .regex(/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/, 'El nombre solo puede contener letras y espacios')
            .refine((val) => val.trim().length > 0, 'El nombre no puede estar vacío'),

        lastName: z
            .string()
            .min(1, 'Los apellidos son requeridos')
            .min(2, 'Los apellidos deben tener al menos 2 caracteres')
            .max(50, 'Los apellidos no pueden exceder 50 caracteres')
            .regex(/^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]+$/, 'Los apellidos solo pueden contener letras y espacios')
            .refine((val) => val.trim().length > 0, 'Los apellidos no pueden estar vacíos'),

        username: z
            .string()
            .min(1, 'El nombre de usuario es requerido')
            .min(3, 'El nombre de usuario debe tener al menos 3 caracteres')
            .max(30, 'El nombre de usuario no puede exceder 30 caracteres')
            .regex(/^[a-zA-Z0-9]+(?:\s[a-zA-Z0-9]+)*$/, 'Solo letras, números y espacios')
            .refine((val) => val.trim().length > 0, 'El nombre de usuario no puede estar vacío'),

        email: z
            .string()
            .min(1, 'El email es requerido')
            .email('Formato de email inválido')
            .max(100, 'El email no puede exceder 100 caracteres')
            .refine((val) => val === val.toLowerCase(), 'El email debe estar en minúsculas')
            .refine((val) => !val.includes(' '), 'El email no puede contener espacios'),

        password: z
            .string()
            .min(8, 'La contraseña debe tener al menos 8 caracteres')
            .max(100, 'La contraseña no puede exceder 100 caracteres')
            .regex(/(?=.*[a-zA-Z])/, 'La contraseña debe contener al menos una letra')
            .regex(/(?=.*\d)/, 'La contraseña debe contener al menos un número'),

        confirmPassword: z
            .string()
            .min(1, 'Debes confirmar tu contraseña'),

        acceptTerms: z
            .boolean()
            .refine((val) => val === true, 'Debes aceptar los términos y condiciones')
    })
        .refine((data) => data.password === data.confirmPassword, {
            message: 'Las contraseñas no coinciden',
            path: ['confirmPassword']
        })
);

// Configurar useForm con validación solo en blur
const { handleSubmit, defineField, errors, meta, validateField } = useForm({
    validationSchema: registrationSchema,
    validateOnMount: false,
    validateOnInput: false,
    validateOnChange: false,
    validateOnBlur: false  // Desactivamos para controlar manualmente
});

// Definir campos
const [firstName] = defineField('firstName');
const [lastName] = defineField('lastName');
const [username] = defineField('username');
const [email] = defineField('email');
const [password] = defineField('password');
const [confirmPassword] = defineField('confirmPassword');
const [acceptTerms] = defineField('acceptTerms');

// Estado de carga
const isLoading = ref(false);

// Computed para verificar si el formulario es válido
const isFormValid = computed(() => {
    return meta.value.valid &&
        firstName.value &&
        lastName.value &&
        username.value &&
        email.value &&
        password.value &&
        confirmPassword.value &&
        acceptTerms.value;
});

// Funciones para prevenir caracteres no válidos en keydown
const preventInvalidNameChars = (event) => {
    const char = event.key;

    // Permitir teclas especiales
    const allowedKeys = [
        'Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
        'Tab', 'Enter', 'Escape', 'Home', 'End', 'PageUp', 'PageDown'
    ];

    if (event.ctrlKey || event.metaKey || event.altKey || allowedKeys.includes(char)) {
        return;
    }

    // Solo permitir letras (incluyendo acentos), ñ, y espacios
    if (!/[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]/.test(char)) {
        event.preventDefault();
    }
};

const preventInvalidUsernameChars = (event) => {
    const char = event.key;

    // Permitir teclas especiales
    const allowedKeys = [
        'Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
        'Tab', 'Enter', 'Escape', 'Home', 'End', 'PageUp', 'PageDown'
    ];

    if (event.ctrlKey || event.metaKey || event.altKey || allowedKeys.includes(char)) {
        return;
    }

    // Solo permitir letras, números y espacios
    if (!/[a-zA-Z0-9\s]/.test(char)) {
        event.preventDefault();
    }
};

const preventInvalidEmailChars = (event) => {
    const char = event.key;

    // Permitir teclas especiales
    const allowedKeys = [
        'Backspace', 'Delete', 'ArrowLeft', 'ArrowRight', 'ArrowUp', 'ArrowDown',
        'Tab', 'Enter', 'Escape', 'Home', 'End', 'PageUp', 'PageDown'
    ];

    if (event.ctrlKey || event.metaKey || event.altKey || allowedKeys.includes(char)) {
        return;
    }

    // Prevenir espacios en email
    if (char === ' ') {
        event.preventDefault();
        return;
    }

    // Solo permitir caracteres válidos para email
    if (!/[a-zA-Z0-9@._-]/.test(char)) {
        event.preventDefault();
    }
};

// Funciones para manejar input (formateo)
const handleFirstNameInput = (event) => {
    let value = event.target.value;
    // Filtrar caracteres no válidos (por seguridad)
    value = value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]/g, '');
    firstName.value = value;
};

const handleLastNameInput = (event) => {
    let value = event.target.value;
    // Filtrar caracteres no válidos (por seguridad)
    value = value.replace(/[^a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s]/g, '');
    lastName.value = value;
};

const handleUsernameInput = (event) => {
    let value = event.target.value;

    // Filtrar caracteres no válidos
    value = value.replace(/[^a-zA-Z0-9\s]/g, '');

    // Limpiar espacios de manera más agresiva:
    // 1. Reemplazar múltiples espacios con uno solo
    value = value.replace(/\s+/g, ' ');

    // 2. Eliminar espacios al inicio y al final
    value = value.trim();

    // 3. Si hay espacios internos, asegurar que solo haya uno entre palabras
    value = value.replace(/\s+/g, ' ');

    // Actualizar tanto el modelo como el input
    username.value = value;
    event.target.value = value;
};

const handleEmailInput = (event) => {
    let value = event.target.value;
    // Convertir a minúsculas y eliminar espacios
    value = value.toLowerCase().replace(/\s/g, '');
    email.value = value;
};

// Función para validar un campo específico en blur
const handleFieldBlur = async (fieldName) => {
    try {
        await validateField(fieldName);
    } catch (error) {
        console.error(`Error validando campo ${fieldName}:`, error);
    }
};

// Función para validar la clave de registro
async function validateRegistrationKey() {
    if (!registrationKey.value.trim()) {
        return;
    }

    isValidatingKey.value = true;

    try {
        await new Promise(resolve => setTimeout(resolve, 800));
        const validSignupCode = import.meta.env.VITE_SIGNUP_CODE;

        if (registrationKey.value === validSignupCode) {
            showRegistrationForm.value = true;
            toast.add({
                severity: 'success',
                summary: 'Acceso autorizado',
                detail: 'Clave de registro válida',
                life: 3000
            });
        } else {
            toast.add({
                severity: 'error',
                summary: 'Clave incorrecta',
                detail: 'La clave de registro es incorrecta',
                life: 4000
            });
            registrationKey.value = '';
        }
    } catch (error) {
        console.error('Error al validar clave de registro:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Error al validar la clave de registro',
            life: 3000
        });
    } finally {
        isValidatingKey.value = false;
    }
}

// Función para manejar el registro
const handleRegister = handleSubmit(async (values) => {
    if (!isFormValid.value) return;

    isLoading.value = true;
    const { user, error } = await sessionStore.signUp(
        values.email,
        values.password,
        {
            first_name: values.firstName.trim(),
            last_name: values.lastName.trim(),
            username: values.username.trim(),
        },
        { toast }
    );

    if (user && !error) {
        toast.add({
            severity: 'success',
            summary: '¡Bienvenid@!',
            detail: 'Tu cuenta ha sido creada exitosamente',
            life: 5000
        });
        router.push('/');
    }

    isLoading.value = false;
});
</script>

<template>
    <div>
        <!-- Formulario de Clave de Registro -->
        <div v-if="!showRegistrationForm">
            <form @submit.prevent="validateRegistrationKey">
                <label for="registrationKey"
                    class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                    Clave de Registro
                </label>
                <InputText id="registrationKey" v-model="registrationKey" placeholder="Ingresa tu clave de registro"
                    class="w-full mb-6" type="password" required />

                <Button type="submit" label="Validar Clave" :loading="isValidatingKey"
                    :disabled="!registrationKey.trim()" class="w-full mb-6" />
            </form>

            <!-- Login Link -->
            <div class="text-center">
                <span class="text-surface-600 dark:text-surface-400 text-sm">
                    ¿Ya tienes una cuenta?
                    <button @click="$emit('toggle-mode')" class="text-primary font-semibold ml-1 hover:underline"
                        type="button">
                        Inicia sesión aquí
                    </button>
                </span>
            </div>
        </div>

        <!-- Formulario de Registro Completo -->
        <div v-else>
            <form @submit.prevent="handleRegister">
                <!-- Name Fields -->
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                    <div>
                        <label for="firstName"
                            class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                            Nombre(s) <span class="text-red-500">*</span>
                        </label>
                        <InputText id="firstName" v-model="firstName" @keydown="preventInvalidNameChars"
                            @input="handleFirstNameInput" @blur="() => handleFieldBlur('firstName')"
                            placeholder="Tu nombre(s)" class="w-full" :class="{ 'p-invalid': errors.firstName }"
                            required />
                        <small v-if="errors.firstName" class="text-red-500 mt-1 block">
                            {{ errors.firstName }}
                        </small>
                    </div>
                    <div>
                        <label for="lastName"
                            class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                            Apellidos <span class="text-red-500">*</span>
                        </label>
                        <InputText id="lastName" v-model="lastName" @keydown="preventInvalidNameChars"
                            @input="handleLastNameInput" @blur="() => handleFieldBlur('lastName')"
                            placeholder="Tus apellidos" class="w-full" :class="{ 'p-invalid': errors.lastName }"
                            required />
                        <small v-if="errors.lastName" class="text-red-500 mt-1 block">
                            {{ errors.lastName }}
                        </small>
                    </div>
                </div>

                <!-- Username -->
                <div class="mb-6">
                    <label for="username" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                        Nombre de usuario <span class="text-red-500">*</span>
                    </label>
                    <InputText id="username" v-model="username" @keydown="preventInvalidUsernameChars"
                        @input="handleUsernameInput" @blur="() => handleFieldBlur('username')"
                        placeholder="Nombre visible para otros usuarios" class="w-full"
                        :class="{ 'p-invalid': errors.username }" required />
                    <small v-if="errors.username" class="text-red-500 mt-1 block">
                        {{ errors.username }}
                    </small>
                    <small class="text-surface-500 mt-1 block text-xs">
                        Este nombre será con el que otros usuarios te verán
                    </small>
                </div>

                <!-- Email -->
                <div class="mb-6">
                    <label for="email" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">
                        Correo electrónico <span class="text-red-500">*</span>
                    </label>
                    <InputText id="email" type="email" v-model="email" @keydown="preventInvalidEmailChars"
                        @input="handleEmailInput" @blur="() => handleFieldBlur('email')"
                        placeholder="correo@dominio.com" class="w-full" :class="{ 'p-invalid': errors.email }"
                        required />
                    <small v-if="errors.email" class="text-red-500 mt-1 block">
                        {{ errors.email }}
                    </small>
                    <small class="text-surface-500 mt-1 block text-xs">
                        Se recomienda usar un correo electrónico existente
                    </small>
                </div>

                <!-- Password -->
                <div class="mb-4">
                    <label for="password" class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">
                        Contraseña <span class="text-red-500">*</span>
                    </label>
                    <Password id="password" v-model="password" @blur="() => handleFieldBlur('password')"
                        placeholder="Crea una contraseña" :toggleMask="true" class="w-full"
                        :class="{ 'p-invalid': errors.password }" fluid :feedback="true" />
                    <small v-if="errors.password" class="text-red-500 mt-1 block">
                        {{ errors.password }}
                    </small>
                    <small class="text-surface-500 mt-1 block text-xs">
                        Mínimo 8 caracteres, debe contener letras y números
                    </small>
                </div>

                <!-- Confirm Password -->
                <div class="mb-6">
                    <label for="confirmPassword"
                        class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">
                        Confirmar Contraseña <span class="text-red-500">*</span>
                    </label>
                    <Password id="confirmPassword" v-model="confirmPassword"
                        @blur="() => handleFieldBlur('confirmPassword')" placeholder="Confirma tu contraseña"
                        :toggleMask="true" class="w-full" :class="{ 'p-invalid': errors.confirmPassword }" fluid
                        :feedback="false" />
                    <small v-if="errors.confirmPassword" class="text-red-500 mt-1 block">
                        {{ errors.confirmPassword }}
                    </small>
                </div>

                <!-- Terms -->
                <div class="mb-6">
                    <div class="flex items-start">
                        <Checkbox v-model="acceptTerms" inputId="terms" binary class="mr-2 mt-1"
                            :class="{ 'p-invalid': errors.acceptTerms }"
                            @change="() => handleFieldBlur('acceptTerms')" />
                        <label for="terms" class="text-sm text-surface-600 dark:text-surface-400 leading-relaxed">
                            Acepto los
                            <a href="#" class="text-primary font-semibold hover:underline">términos y condiciones</a>
                            y la
                            <a href="#" class="text-primary font-semibold hover:underline">política de privacidad</a>
                            <span class="text-red-500 ml-1">*</span>
                        </label>
                    </div>
                    <small v-if="errors.acceptTerms" class="text-red-500 mt-1 block ml-6">
                        {{ errors.acceptTerms }}
                    </small>
                </div>

                <!-- Submit Button -->
                <Button type="submit" label="Crear Cuenta" :loading="isLoading" :disabled="!isFormValid"
                    class="w-full mb-6" />
            </form>

            <!-- Login Link -->
            <div class="text-center">
                <span class="text-surface-600 dark:text-surface-400 text-sm">
                    ¿Ya tienes una cuenta?
                    <button @click="$emit('toggle-mode')" class="text-primary font-semibold ml-1 hover:underline"
                        type="button">
                        Inicia sesión aquí
                    </button>
                </span>
            </div>
        </div>
    </div>
</template>