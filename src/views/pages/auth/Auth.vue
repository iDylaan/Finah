<script setup>
import Signin from './components/Signin.vue';
import Signup from './components/Signup.vue';
import { ref, computed } from 'vue';
import { useUIStore } from '@/stores/ui.js';

const uiStore = useUIStore();
const isLoginMode = ref(true);

function toggleMode() {
    isLoginMode.value = !isLoginMode.value;
}

// Computed para detectar si es móvil
const isMobile = computed(() => uiStore.isMobile);

// Computed para detectar si se usa la paleta Ocean Breeze
const isOceanBreeze = computed(() => uiStore.layoutConfig.primary === 'ocean-breeze');

// Computed para las clases del texto Finah
const finahTextClass = computed(() => {
    if (isOceanBreeze.value) {
        return 'bg-gradient-to-r from-[#0077B6] via-[#00B4D8] to-[#00B4D8] bg-clip-text text-transparent dark:from-[#00B4D8] dark:via-[#48CAE4] dark:to-[#90E0EF]';
    }
    return 'text-surface-0 dark:text-surface-0';
});

// Función para cambiar el tema
const toggleTheme = () => {
    uiStore.executeDarkModeToggle();
};

</script>

<template>
    <!-- VERSION MOBILE -->
    <div v-if="isMobile" class="min-h-screen bg-surface-50 dark:bg-surface-950 flex flex-col">
        <!-- Header Mobile -->
        <div class="bg-surface-0 dark:bg-surface-900 border-b border-surface-200 dark:border-surface-700 px-4 py-4">
            <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                    <!-- Logo con gradiente para Ocean Breeze -->
                    <template v-if="isOceanBreeze">
                        <img v-if="!uiStore.darkMode" src="/imgs/logo-light.svg" alt="Finah Logo" class="h-12 w-12" />
                        <img v-else src="/imgs/logo-dark.svg" alt="Finah Logo" class="h-12 w-12" />
                    </template>
                    <!-- Logo con color primario dinámico para otros temas -->
                    <template v-else>
                        <svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg" class="h-12 w-12" :style="{ fill: 'var(--p-primary-color)' }">
                            <path d="M166.11,290.37s16.04-33,58.6-32.46c25,.31,128.89.26,210.35.16,57.1-.07,103.34-46.38,103.34-103.48h0s-254.83,0-254.83,0c-26.72,0-52.96,8.22-74.31,24.28-9.16,6.89-18.58,15.46-26.31,26.85-21.06,31.04-21.13,77.16-16.84,84.65Z"/>
                            <path d="M80.98,475.87s.99-2.35,3.04-6.26c22.97-43.69,68.49-70.82,117.85-70.82h59.68c57.36,0,103.85-46.5,103.85-103.85h0s-142.52,0-142.52,0c-27.47,0-54.53,7.75-77.28,23.13-10.07,6.81-20.2,15.6-29.3,26.91-36.4,45.25-43.18,99.85-35.33,130.9Z"/>
                        </svg>
                    </template>
                    <span class="text-2xl font-extrabold" :class="finahTextClass">Finah</span>
                </div>

                <!-- Botón de tema -->
                <Button :icon="uiStore.darkMode ? 'pi pi-sun' : 'pi pi-moon'" @click="toggleTheme" rounded text
                    severity="secondary" v-tooltip.left="uiStore.darkMode ? 'Modo claro' : 'Modo oscuro'" />
            </div>
        </div>

        <!-- Toggle Tabs Mobile -->
        <div class="bg-surface-0 dark:bg-surface-900 px-4 py-3 border-b border-surface-200 dark:border-surface-700">
            <div class="flex p-1 bg-surface-100/50 dark:bg-surface-800/50 rounded-xl">
                <button @click="isLoginMode = true" :class="[
                    'flex-1 py-2.5 px-4 text-sm font-semibold rounded-lg transition-all duration-200',
                    isLoginMode
                        ? 'bg-surface-0 dark:bg-surface-900 text-primary shadow-sm'
                        : 'text-surface-600 dark:text-surface-400'
                ]">
                    Iniciar Sesión
                </button>
                <button @click="isLoginMode = false" :class="[
                    'flex-1 py-2.5 px-4 text-sm font-semibold rounded-lg transition-all duration-200',
                    !isLoginMode
                        ? 'bg-surface-0 dark:bg-surface-900 text-primary shadow-sm'
                        : 'text-surface-600 dark:text-surface-400'
                ]">
                    Registrarse
                </button>
            </div>
        </div>

        <!-- Content Mobile -->
        <div class="flex-1 overflow-y-auto px-4 py-6">
            <div class="max-w-md mx-auto">
                <div class="mb-6 text-center">
                    <h1 class="text-2xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                        {{ isLoginMode ? '¡Bienvenido!' : '¡Únete!' }}
                    </h1>
                    <p class="text-sm text-surface-600 dark:text-surface-400">
                        {{ isLoginMode ? 'Inicia sesión para continuar' : 'Crea tu cuenta para comenzar' }}
                    </p>
                </div>

                <Transition name="fade" mode="out-in">
                    <Signin v-if="isLoginMode" @toggle-mode="toggleMode" />
                    <Signup v-else @toggle-mode="toggleMode" />
                </Transition>
            </div>
        </div>
    </div>

    <!-- VERSION DESKTOP -->
    <div v-else
        class="bg-surface-50 dark:bg-surface-950 flex items-center justify-center min-h-screen min-w-[100vw] overflow-hidden relative">

        <!-- Botón de tema (esquina superior derecha) -->
        <div class="absolute top-6 right-6 z-10">
            <Button :icon="uiStore.darkMode ? 'pi pi-sun' : 'pi pi-moon'" @click="toggleTheme" rounded text
                severity="secondary" size="large" v-tooltip.left="uiStore.darkMode ? 'Modo claro' : 'Modo oscuro'" />
        </div>

        <div class="flex items-center justify-center w-full max-w-[90rem] px-8">
            <div style="border-radius: 56px; padding: 0.3rem; background: linear-gradient(180deg, var(--p-primary-color) 10%, rgba(33, 150, 243, 0) 30%)"
                class="w-full shadow-2xl">
                <div class="w-full bg-surface-0 dark:bg-surface-900 py-12 px-12"
                    style="border-radius: 53px">
                    
                    <!-- Layout Horizontal -->
                    <div class="grid grid-cols-2 gap-16 items-center">
                        <!-- Columna Izquierda: Logo y Branding -->
                        <div class="flex flex-col items-center justify-center">
                            <div class="flex items-center justify-center mb-8">
                                <!-- Logo con gradiente para Ocean Breeze -->
                                <template v-if="isOceanBreeze">
                                    <img v-if="!uiStore.darkMode" src="/imgs/logo-light.svg" alt="Finah Logo" class="h-48 w-48" />
                                    <img v-else src="/imgs/logo-dark.svg" alt="Finah Logo" class="h-48 w-48" />
                                </template>
                                <!-- Logo con color primario dinámico para otros temas -->
                                <template v-else>
                                    <svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg" class="h-48 w-48" :style="{ fill: 'var(--p-primary-color)' }">
                                        <path d="M166.11,290.37s16.04-33,58.6-32.46c25,.31,128.89.26,210.35.16,57.1-.07,103.34-46.38,103.34-103.48h0s-254.83,0-254.83,0c-26.72,0-52.96,8.22-74.31,24.28-9.16,6.89-18.58,15.46-26.31,26.85-21.06,31.04-21.13,77.16-16.84,84.65Z"/>
                                        <path d="M80.98,475.87s.99-2.35,3.04-6.26c22.97-43.69,68.49-70.82,117.85-70.82h59.68c57.36,0,103.85-46.5,103.85-103.85h0s-142.52,0-142.52,0c-27.47,0-54.53,7.75-77.28,23.13-10.07,6.81-20.2,15.6-29.3,26.91-36.4,45.25-43.18,99.85-35.33,130.9Z"/>
                                    </svg>
                                </template>
                            </div>
                            <h1 class="text-6xl font-extrabold mb-3">
                                <span :class="finahTextClass">
                                    Finah
                                </span>
                            </h1>
                            <p class="text-surface-600 dark:text-surface-400 text-lg font-medium text-center">
                                Gestión Financiera Personal
                            </p>
                            <p class="text-surface-500 dark:text-surface-500 text-sm mt-4 text-center max-w-xs">
                                Controla tus finanzas de manera inteligente y alcanza tus metas económicas
                            </p>
                        </div>

                        <!-- Columna Derecha: Formularios -->
                        <div class="flex flex-col">
                            <div class="mb-8">
                                <h2 class="text-surface-900 dark:text-surface-0 text-3xl font-bold mb-2">
                                    {{ isLoginMode ? '¡Bienvenido de vuelta!' : '¡Únete a Finah!' }}
                                </h2>
                                <p class="text-surface-600 dark:text-surface-400 text-base">
                                    {{ isLoginMode ? 'Inicia sesión para continuar' : 'Crea tu cuenta para comenzar' }}
                                </p>
                            </div>

                            <!-- Tabs -->
                            <div class="flex mb-8 p-1 bg-surface-100/50 dark:bg-surface-800/50 rounded-xl">
                                <button @click="isLoginMode = true" :class="[
                                    'flex-1 py-3 px-6 text-sm font-semibold rounded-lg transition-all duration-200',
                                    isLoginMode
                                        ? 'bg-surface-0 dark:bg-surface-900 text-primary shadow-sm'
                                        : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-200'
                                ]">
                                    Iniciar Sesión
                                </button>
                                <button @click="isLoginMode = false" :class="[
                                    'flex-1 py-3 px-6 text-sm font-semibold rounded-lg transition-all duration-200',
                                    !isLoginMode
                                        ? 'bg-surface-0 dark:bg-surface-900 text-primary shadow-sm'
                                        : 'text-surface-600 dark:text-surface-400 hover:text-surface-900 dark:hover:text-surface-200'
                                ]">
                                    Registrarse
                                </button>
                            </div>

                            <!-- Forms -->
                            <div class="min-h-[450px]">
                                <Transition name="fade" mode="out-in">
                                    <Signin v-if="isLoginMode" @toggle-mode="toggleMode" />
                                    <Signup v-else @toggle-mode="toggleMode" />
                                </Transition>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.pi-eye {
    transform: scale(1.6);
    margin-right: 1rem;
}

.pi-eye-slash {
    transform: scale(1.6);
    margin-right: 1rem;
}

.fade-enter-active,
.fade-leave-active {
    transition: opacity 0.3s ease;
}

.fade-enter-from,
.fade-leave-to {
    opacity: 0;
}
</style>
