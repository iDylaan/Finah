<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const emit = defineEmits(['toggle-mode']);

// Estados del flujo de registro
const registrationKey = ref('');
const showRegistrationForm = ref(false);
const isValidatingKey = ref(false);

// Datos del formulario de registro
const firstName = ref('');
const lastName = ref('');
const username = ref('');
const password = ref('');
const confirmPassword = ref('');
const acceptTerms = ref(false);
const isLoading = ref(false);

const passwordsMatch = computed(() => {
    return password.value === confirmPassword.value;
});

const isFormValid = computed(() => {
    return firstName.value &&
        lastName.value &&
        username.value &&
        password.value &&
        confirmPassword.value &&
        passwordsMatch.value &&
        acceptTerms.value;
});

// Función para validar la clave de registro
async function validateRegistrationKey() {
    if (!registrationKey.value.trim()) {
        return;
    }

    isValidatingKey.value = true;

    try {
        // Simular validación de clave de registro
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Por ahora acepta cualquier valor no vacío
        showRegistrationForm.value = true;
        
    } catch (error) {
        console.error('Error al validar clave de registro:', error);
    } finally {
        isValidatingKey.value = false;
    }
}

// Función para volver al formulario de clave
function goBackToKeyForm() {
    showRegistrationForm.value = false;
    registrationKey.value = '';
}

async function handleRegister() {
    if (!isFormValid.value) {
        return;
    }

    isLoading.value = true;

    try {
        // Simular llamada API
        await new Promise(resolve => setTimeout(resolve, 2000));

        // Redirigir al dashboard
        router.push('/');
    } catch (error) {
        console.error('Error al registrarse:', error);
    } finally {
        isLoading.value = false;
    }
}
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
                <InputText 
                    id="registrationKey" 
                    v-model="registrationKey" 
                    placeholder="Ingresa tu clave de registro" 
                    class="w-full md:w-[30rem] mb-6"
                    required 
                />

                <Button 
                    type="submit" 
                    label="Validar Clave" 
                    :loading="isValidatingKey"
                    :disabled="!registrationKey.trim()"
                    class="w-full mb-6" 
                />
            </form>

            <!-- Login Link -->
            <div class="text-center">
                <span class="text-surface-600 dark:text-surface-400 text-sm">
                    ¿Ya tienes una cuenta?
                    <button @click="$emit('toggle-mode')" 
                        class="text-primary font-semibold ml-1 hover:underline"
                        type="button">
                        Inicia sesión aquí
                    </button>
                </span>
            </div>
        </div>

        <!-- Formulario de Registro Completo -->
        <div v-else>
            <!-- Botón para volver -->
            <div class="mb-6">
                <Button 
                    @click="goBackToKeyForm"
                    severity="secondary"
                    outlined
                    size="small"
                    class="mb-4"
                >
                    <template #icon>
                        <i class="pi pi-arrow-left mr-2"></i>
                    </template>
                    Cambiar clave de registro
                </Button>
            </div>

            <form @submit.prevent="handleRegister">
                <!-- Name Fields -->
                <div class="grid grid-cols-2 gap-4 mb-6">
                    <div>
                        <label for="firstName"
                            class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Nombre</label>
                        <InputText id="firstName" v-model="firstName" placeholder="Tu nombre" class="w-full" required />
                    </div>
                    <div>
                        <label for="lastName"
                            class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Apellidos</label>
                        <InputText id="lastName" v-model="lastName" placeholder="Tu apellido" class="w-full" required />
                    </div>
                </div>

                <!-- Username -->
                <label for="username" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Nombre de usuario</label>
                <InputText id="username" type="username" placeholder="Nombre de usuario" class="w-full md:w-[30rem] mb-6"
                    v-model="username" />

                <!-- Password -->
                <label for="password"
                    class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">Contraseña</label>
                <Password id="password" v-model="password" placeholder="Crea una contraseña" :toggleMask="true" class="mb-4"
                    fluid :feedback="true"></Password>

                <!-- Confirm Password -->
                <label for="confirmPassword"
                    class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">Confirmar Contraseña</label>
                <Password id="confirmPassword" v-model="confirmPassword" placeholder="Confirma tu contraseña"
                    :toggleMask="true" class="mb-2" fluid :feedback="false"
                    :class="{ 'p-invalid': confirmPassword && !passwordsMatch }" />
                <small v-if="confirmPassword && !passwordsMatch" class="text-red-500 mb-4 block">
                    Las contraseñas no coinciden
                </small>

                <!-- Terms -->
                <div class="flex items-start mb-6 mt-4">
                    <Checkbox v-model="acceptTerms" inputId="terms" binary class="mr-2 mt-1" />
                    <label for="terms" class="text-sm text-surface-600 dark:text-surface-400 leading-relaxed">
                        Acepto los
                        <a href="#" class="text-primary font-semibold hover:underline">términos y condiciones</a>
                        y la
                        <a href="#" class="text-primary font-semibold hover:underline">política de privacidad</a>
                    </label>
                </div>

                <!-- Submit Button -->
                <Button type="submit" label="Crear Cuenta" :loading="isLoading" :disabled="!isFormValid"
                    class="w-full mb-6" />
            </form>

            <!-- Divider -->
            <div class="my-6 flex items-center">
                <div class="flex-1 border-t border-surface-200 dark:border-surface-700"></div>
                <span class="px-4 text-sm text-surface-500 dark:text-surface-400">o regístrate con</span>
                <div class="flex-1 border-t border-surface-200 dark:border-surface-700"></div>
            </div>

            <!-- Social Register -->
            <div class="space-y-3 mb-6">
                <Button severity="secondary" outlined class="w-full" size="large">
                    <template #icon>
                        <svg class="w-5 h-5 mr-2" viewBox="0 0 24 24">
                            <path fill="currentColor"
                                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                            <path fill="currentColor"
                                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                            <path fill="currentColor"
                                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                            <path fill="currentColor"
                                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                        </svg>
                    </template>
                    Continuar con Google
                </Button>

                <Button severity="secondary" outlined class="w-full" size="large">
                    <template #icon>
                        <i class="pi pi-github mr-2"></i>
                    </template>
                    Continuar con GitHub
                </Button>
            </div>

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