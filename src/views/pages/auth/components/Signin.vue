<script setup>
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const router = useRouter();
const emit = defineEmits(['toggle-mode']);

const email = ref('');
const password = ref('');
const checked = ref(false);
const isLoading = ref(false);

async function handleLogin() {
    if (!email.value || !password.value) {
        return;
    }

    isLoading.value = true;

    try {
        // Simular llamada API
        await new Promise(resolve => setTimeout(resolve, 1500));

        // Redirigir al dashboard
        router.push('/');
    } catch (error) {
        console.error('Error al iniciar sesión:', error);
    } finally {
        isLoading.value = false;
    }
}
</script>

<template>
    <div>
        <form @submit.prevent="handleLogin">
            <label for="email1" class="block text-surface-900 dark:text-surface-0 text-xl font-medium mb-2">Nombre de
                usuario</label>
            <InputText id="email1" type="text" placeholder="Nombre de usuario" class="w-full md:w-[30rem] mb-8"
                v-model="email" />

            <label for="password1"
                class="block text-surface-900 dark:text-surface-0 font-medium text-xl mb-2">Contraseña</label>
            <Password id="password1" v-model="password" placeholder="Contraseña" :toggleMask="true" class="mb-4" fluid
                :feedback="false"></Password>

            <div class="flex items-center justify-end mt-2 mb-8 gap-8">
                <span class="font-medium no-underline ml-2 text-right cursor-pointer text-primary">¿Olvidaste la
                    contraseña?</span>
            </div>
            <Button type="submit" label="Iniciar Sesión" :loading="isLoading" class="w-full mb-6" />
        </form>

        <!-- Divider -->
        <div class="my-6 flex items-center">
            <div class="flex-1 border-t border-surface-200 dark:border-surface-700"></div>
            <span class="px-4 text-sm text-surface-500 dark:text-surface-400">o continúa con</span>
            <div class="flex-1 border-t border-surface-200 dark:border-surface-700"></div>
        </div>

        <!-- Social Login -->
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

        <!-- Register Link -->
        <div class="text-center">
            <span class="text-surface-600 dark:text-surface-400 text-sm">
                ¿No tienes una cuenta?
                <button @click="$emit('toggle-mode')" class="text-primary font-semibold ml-1 hover:underline"
                    type="button">
                    Regístrate aquí
                </button>
            </span>
        </div>
    </div>
</template>