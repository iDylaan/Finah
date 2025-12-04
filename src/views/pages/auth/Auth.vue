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
                <div class="flex items-center">
                    <svg id="Capa_2" data-name="Capa 2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 549.85 494.46" class="w-10 h-10">
                        <g id="Capa_4" data-name="Capa 4">
                            <polygon fill="var(--p-primary-color)" points="399.96 90.35 267.57 222.72 267.57 0 399.96 0 399.96 90.35" />
                            <polygon fill="var(--p-primary-color)" points="0 453.61 132.4 321.21 132.4 494.46 0 494.46 0 453.61" />
                            <polygon fill="var(--p-primary-color)" points="267.57 355.95 399.96 223.57 399.96 494.46 267.57 494.46 267.57 355.95" />
                            <polygon fill="var(--p-primary-color)" points="549.85 0 549.85 108.04 515.37 73.54 265.32 323.6 182.58 240.86 0 423.44 0 359.01 185.65 173.52 266.31 254.19 483.17 37.33 445.83 0 549.85 0" />
                            <polygon fill="var(--p-primary-color)" points="132.4 187.97 0 320.37 0 0 132.4 0 132.4 187.97" />
                        </g>
                    </svg>
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

        <div class="flex flex-col items-center justify-center w-full max-w-[48em] px-4">
            <div style="border-radius: 56px; padding: 0.3rem; background: linear-gradient(180deg, var(--p-primary-color) 10%, rgba(33, 150, 243, 0) 30%)"
                class="w-full shadow-2xl">
                <div class="w-full bg-surface-0 dark:bg-surface-900 py-12 px-8 sm:py-16 sm:px-24"
                    style="border-radius: 53px">
                    <!-- Logo y Título Desktop -->
                    <div class="text-center mb-10">
                        <div class="flex items-center justify-center mx-auto mb-6 gap-1">
                            <span class="text-[6rem] font-bold text-surface-900 dark:text-surface-0">Fina</span>
                            <svg id="Capa_2" data-name="Capa 2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 549.85 494.46" class="w-auto h-20">
                                <g id="Capa_4" data-name="Capa 4">
                                    <polygon fill="var(--p-primary-color)" points="399.96 90.35 267.57 222.72 267.57 0 399.96 0 399.96 90.35" />
                                    <polygon fill="var(--p-primary-color)" points="0 453.61 132.4 321.21 132.4 494.46 0 494.46 0 453.61" />
                                    <polygon fill="var(--p-primary-color)" points="267.57 355.95 399.96 223.57 399.96 494.46 267.57 494.46 267.57 355.95" />
                                    <polygon fill="var(--p-primary-color)" points="549.85 0 549.85 108.04 515.37 73.54 265.32 323.6 182.58 240.86 0 423.44 0 359.01 185.65 173.52 266.31 254.19 483.17 37.33 445.83 0 549.85 0" />
                                    <polygon fill="var(--p-primary-color)" points="132.4 187.97 0 320.37 0 0 132.4 0 132.4 187.97" />
                                </g>
                            </svg>
                        </div>

                        <div class="text-surface-900 dark:text-surface-0 text-4xl font-bold mb-3">
                            {{ isLoginMode ? 'Bienvenido' : 'Únete' }}
                        </div>
                        <span class="text-muted-color font-medium text-lg">
                            {{ isLoginMode ? 'Inicia sesión para continuar' : 'Crea tu cuenta para comenzar' }}
                        </span>
                    </div>

                    <!-- Tabs Desktop -->
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

                    <!-- Forms Desktop -->
                    <div class="min-h-[500px]">
                        <Transition name="fade" mode="out-in">
                            <Signin v-if="isLoginMode" @toggle-mode="toggleMode" />
                            <Signup v-else @toggle-mode="toggleMode" />
                        </Transition>
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
