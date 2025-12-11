<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from 'primevue/usetoast';
import { useUIStore } from '@/stores/ui';
import { useSessionStore } from '@/stores/session.js';
import AppConfigurator from './AppConfigurator.vue';

const uiStore = useUIStore();
const sessionStore = useSessionStore();
const router = useRouter();
const toast = useToast();

// Estado para el menú de perfil
const profileMenuVisible = ref(false);

// Función para alternar el menú de perfil
const toggleProfileMenu = (event) => {
    event.stopPropagation();
    profileMenuVisible.value = !profileMenuVisible.value;
};

// Función para cerrar el menú
const closeProfileMenu = () => {
    profileMenuVisible.value = false;
};

// Función para ir al perfil
const goToProfile = () => {
    closeProfileMenu();
    router.push('/profile');
};

// Función para cerrar sesión
const handleSignOut = async () => {
    closeProfileMenu();

    try {
        const { error } = await sessionStore.signOut();

        if (error) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se pudo cerrar la sesión correctamente',
                life: 4000
            });
            return;
        }

        toast.add({
            severity: 'success',
            summary: 'Sesión cerrada',
            detail: 'Has cerrado sesión exitosamente',
            life: 3000
        });

        // Redirigir al login
        router.push('/auth');

    } catch (error) {
        console.error('Error al cerrar sesión:', error);
        toast.add({
            severity: 'error',
            summary: 'Error inesperado',
            detail: 'Ocurrió un error al cerrar sesión',
            life: 4000
        });
    }
};

// Función para obtener las iniciales del usuario
const getUserInitials = () => {
    if (sessionStore.fullName) {
        return sessionStore.fullName
            .split(' ')
            .map(name => name.charAt(0))
            .join('')
            .substring(0, 2)
            .toUpperCase();
    }

    if (sessionStore.userEmail) {
        return sessionStore.userEmail.charAt(0).toUpperCase();
    }

    return 'U';
};

// **CORREGIDO:** URL de imagen como computed reactive
const userAvatar = computed(() => sessionStore.profile?.avatar_url);

// **AGREGADO:** Función para manejar clicks fuera del menú
const handleClickOutside = (event) => {
    const profileMenu = event.target.closest('.profile-menu-container');
    if (!profileMenu) {
        closeProfileMenu();
    }
};

// **AGREGADO:** Listener global para clicks
const setupClickOutside = () => {
    document.addEventListener('click', handleClickOutside);
};

const removeClickOutside = () => {
    document.removeEventListener('click', handleClickOutside);
};

// **AGREGADO:** Setup y cleanup de eventos

// Computed para detectar si se usa ocean-breeze
const isOceanBreeze = computed(() => uiStore.layoutConfig.primary === 'ocean-breeze');

onMounted(() => {
    setupClickOutside();
});

onUnmounted(() => {
    removeClickOutside();
});
</script>

<template>
    <div
        class="layout-topbar backdrop-blur-md bg-surface-0/70 dark:bg-surface-900/70 border-b border-surface-200/30 dark:border-surface-700/30 supports-[backdrop-filter]:bg-surface-0/60 supports-[backdrop-filter]:dark:bg-surface-900/60">
        <div class="layout-topbar-logo-container">
            <button class="layout-menu-button layout-topbar-action" @click="uiStore.toggleMenu">
                <i class="pi pi-bars"></i>
            </button>
            <router-link to="/" class="layout-topbar-logo">
                <!-- Logo con gradiente para Ocean Breeze -->
                <template v-if="isOceanBreeze">
                    <img v-if="!uiStore.darkMode" src="/imgs/logo-light.svg" alt="Finah" class="h-9 w-9 ml-[5px] mr-[6px]" />
                    <img v-else src="/imgs/logo-dark.svg" alt="Finah" class="h-9 w-9 ml-[5px] mr-[6px]" />
                </template>
                <!-- Logo con color primario dinámico para otros temas -->
                <template v-else>
                    <svg viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg" class="h-9 w-9" :style="{ fill: 'var(--p-primary-color)' }">
                        <path d="M166.11,290.37s16.04-33,58.6-32.46c25,.31,128.89.26,210.35.16,57.1-.07,103.34-46.38,103.34-103.48h0s-254.83,0-254.83,0c-26.72,0-52.96,8.22-74.31,24.28-9.16,6.89-18.58,15.46-26.31,26.85-21.06,31.04-21.13,77.16-16.84,84.65Z"/>
                        <path d="M80.98,475.87s.99-2.35,3.04-6.26c22.97-43.69,68.49-70.82,117.85-70.82h59.68c57.36,0,103.85-46.5,103.85-103.85h0s-142.52,0-142.52,0c-27.47,0-54.53,7.75-77.28,23.13-10.07,6.81-20.2,15.6-29.3,26.91-36.4,45.25-43.18,99.85-35.33,130.9Z"/>
                    </svg>
                </template>
                <span class="font-extrabold text-surface-900 dark:text-surface-0 hidden md:inline">Finah</span>
            </router-link>
        </div>

        <div class="layout-topbar-actions">
            <div class="layout-config-menu">
                <button type="button"
                    class="layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200"
                    @click="uiStore.executeDarkModeToggle">
                    <i :class="['pi', { 'pi-moon': uiStore.isDarkTheme, 'pi-sun': !uiStore.isDarkTheme }]"></i>
                </button>
                <div class="relative">
                    <button
                        v-styleclass="{ selector: '@next', enterFromClass: 'hidden', enterActiveClass: 'animate-scalein', leaveToClass: 'hidden', leaveActiveClass: 'animate-fadeout', hideOnOutsideClick: true }"
                        type="button"
                        class="layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200">
                        <i class="pi pi-palette"></i>
                    </button>
                    <AppConfigurator />
                </div>
            </div>

            <button
                class="layout-topbar-menu-button layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200"
                v-styleclass="{ selector: '@next', enterFromClass: 'hidden', enterActiveClass: 'animate-scalein', leaveToClass: 'hidden', leaveActiveClass: 'animate-fadeout', hideOnOutsideClick: true }">
                <i class="pi pi-ellipsis-v"></i>
            </button>

            <div class="layout-topbar-menu hidden lg:block">
                <div class="layout-topbar-menu-content">
                    <button type="button"
                        class="layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200">
                        <i class="pi pi-calendar"></i>
                        <span>Calendar</span>
                    </button>
                    <button type="button"
                        class="layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200">
                        <i class="pi pi-inbox"></i>
                        <span>Messages</span>
                    </button>

                    <div class="relative profile-menu-container">
                        <button type="button"
                            class="layout-topbar-action hover:bg-surface-100/50 dark:hover:bg-surface-700/50 transition-colors duration-200"
                            @click="toggleProfileMenu">
                            <!-- Avatar o iniciales del usuario -->
                            <div class="flex items-center gap-2">
                                <div class="profile-avatar">
                                    <img v-if="userAvatar" :src="userAvatar" :alt="sessionStore.fullName || 'Usuario'"
                                        class="w-8 h-8 rounded-full object-cover"
                                        @error="$event.target.style.display = 'none'" />
                                    <div v-else
                                        class="w-8 h-8 rounded-full bg-primary-500 flex items-center justify-center text-white text-sm font-semibold">
                                        {{ getUserInitials() }}
                                    </div>
                                </div>
                                <span class="hidden xl:inline">{{ sessionStore.fullName || sessionStore.username ||
                                    'Usuario' }}</span>
                            </div>
                        </button>

                        <Transition enter-active-class="transition-all duration-200 ease-out"
                            enter-from-class="opacity-0 scale-95 -translate-y-2"
                            enter-to-class="opacity-100 scale-100 translate-y-0"
                            leave-active-class="transition-all duration-150 ease-in"
                            leave-from-class="opacity-100 scale-100 translate-y-0"
                            leave-to-class="opacity-0 scale-95 -translate-y-2">
                            <div v-show="profileMenuVisible"
                                class="absolute right-0 top-full mt-2 w-64 bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700 rounded-lg shadow-lg z-50 origin-top-right">
                                <!-- Header del menú con info del usuario -->
                                <div class="p-4 border-b border-surface-200 dark:border-surface-700">
                                    <div class="flex items-center gap-2">
                                        <div class="profile-avatar">
                                            <img v-if="userAvatar" :src="userAvatar"
                                                :alt="sessionStore.fullName || 'Usuario'"
                                                class="w-12 h-12 rounded-full object-cover"
                                                @error="$event.target.style.display = 'none'" />
                                            <div v-else
                                                class="w-12 h-12 rounded-full bg-primary-500 flex items-center justify-center text-white text-lg font-semibold">
                                                {{ getUserInitials() }}
                                            </div>
                                        </div>
                                        <div class="flex-1 min-w-0">
                                            <span>
                                                <p
                                                    class="text-sm font-semibold text-surface-900 dark:text-surface-100 leading-tight mb-0">
                                                    {{ sessionStore.fullName || sessionStore.username || 'Usuario' }}
                                                </p>
                                                <p class="text-xs text-surface-600 dark:text-surface-400 leading-tight">
                                                    {{ sessionStore.userEmail }}
                                                </p>
                                            </span>
                                            <p v-if="sessionStore.username"
                                                class="text-xs text-surface-500 dark:text-surface-500 leading-tight mt-1">
                                                @{{ sessionStore.username }}
                                            </p>
                                        </div>
                                    </div>
                                </div>

                                <!-- Opciones del menú -->
                                <div class="p-2">
                                    <button @click="goToProfile"
                                        class="w-full flex items-center gap-3 px-3 py-2 text-sm text-surface-700 dark:text-surface-300 hover:bg-surface-100 dark:hover:bg-surface-700 rounded-md transition-colors duration-200">
                                        <i class="pi pi-user text-surface-500 dark:text-surface-400"></i>
                                        <span>Mi Perfil</span>
                                    </button>

                                    <button @click="handleSignOut"
                                        class="w-full flex items-center gap-3 px-3 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-md transition-colors duration-200">
                                        <i class="pi pi-sign-out text-red-500 dark:text-red-400"></i>
                                        <span>Cerrar Sesión</span>
                                    </button>
                                </div>
                            </div>
                        </Transition>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped>
.profile-avatar {
    position: relative;
    flex-shrink: 0;
}

.layout-topbar-action {
    position: relative;
}

.profile-menu-container {
    position: relative;
}

/* Responsive */
@media (max-width: 768px) {
    .layout-topbar-menu-content {
        flex-direction: column;
        gap: 0.5rem;
    }

    .layout-topbar-action span {
        display: none;
    }
}
</style>
