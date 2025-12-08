<template>
    <div class="flex flex-col min-h-full gap-6">
        <!-- Page Header -->
        <div ref="headerRef" class="
                sticky 
                z-10 
                backdrop-blur-md 
                supports-[backdrop-filter]:bg-surface-0/60 supports-[backdrop-filter]:dark:bg-surface-900/60 
                bg-surface-0/70 dark:bg-surface-900/70 
                border-b border-surface-200/30 dark:border-surface-700/30
                md:px-8
                rounded-xl
                w-[100%]
                mx-auto
                transition-all duration-300
            " :class="[
                isSticky ? 'py-2 md:py-3 -top-4 md:-top-6' : 'py-4 md:py-4 top-0'
            ]">
            <div class="
                    flex 
                    gap-4 
                    items-center md:items-start
                    w-full
                    px-4
                " :class="isSticky ? 'flex-nowrap' : 'flex-wrap md:flex-row'">
                <!-- Texto del header (título y descripción) -->
                <div class="min-w-0 overflow-hidden" :class="isSticky ? 'flex-1' : 'w-full md:flex-1'">
                    <slot name="header">
                        <!-- Slot para contenido personalizado del header -->
                        <div>
                            <h1 v-if="title"
                                class="font-bold text-surface-900 dark:text-surface-0 leading-tight transition-all duration-300 truncate"
                                :class="isSticky ? 'text-xl md:text-2xl mb-0' : 'text-2xl md:text-3xl mb-1 md:mb-2'">
                                {{ title }}
                            </h1>
                            <Transition name="description">
                                <p v-if="description && !isSticky"
                                    class="text-sm md:text-base text-surface-600 dark:text-surface-400 m-0 leading-normal">
                                    {{ description }}
                                </p>
                            </Transition>
                        </div>
                    </slot>
                </div>

                <!-- Acciones del header (botones) -->
                <div v-if="$slots.actions" class="flex gap-2 items-center shrink-0 page-header-actions"
                    :class="isSticky ? 'ml-auto' : 'w-full md:w-auto justify-end'">
                    <slot name="actions"></slot>
                </div>
            </div>
        </div>

        <!-- Page Content -->
        <div class="flex-1 max-w-screen-2xl w-full mx-auto p-0">
            <slot></slot>
        </div>
    </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

// Props opcionales para uso simple
const props = defineProps({
    title: {
        type: String,
        default: ''
    },
    description: {
        type: String,
        default: ''
    }
});

// Estado para detectar si está sticky
const isSticky = ref(false);
const headerRef = ref(null);
const scrollContainer = ref(null);
const activationThreshold = ref(200); // Píxeles para activar sticky (contraer)
const deactivationThreshold = ref(100); // Píxeles para desactivar sticky (expandir)

// Función para detectar scroll con umbrales fijos
const handleScroll = () => {
    if (headerRef.value && scrollContainer.value) {
        const scrollY = scrollContainer.value.scrollTop;

        // Si no está sticky y pasamos el umbral de activación -> contraer
        if (!isSticky.value && scrollY > activationThreshold.value) {
            isSticky.value = true;
        }
        // Si está sticky y bajamos del umbral de desactivación -> expandir
        else if (isSticky.value && scrollY < deactivationThreshold.value) {
            isSticky.value = false;
        }
        // Entre 100px y 200px: mantener el estado actual (zona muerta)
    }
};

// Lifecycle hooks
onMounted(() => {
    // Reset del estado al montar
    isSticky.value = false;

    // Buscar el contenedor de scroll (.layout-main-container)
    scrollContainer.value = document.querySelector('.layout-main-container');

    if (scrollContainer.value) {
        scrollContainer.value.addEventListener('scroll', handleScroll, { passive: true });
        handleScroll(); // Check inicial
    }
});

onUnmounted(() => {
    if (scrollContainer.value) {
        scrollContainer.value.removeEventListener('scroll', handleScroll);
    }
});
</script>

<style scoped>
/* Animación para la descripción */
.description-enter-active,
.description-leave-active {
    transition: all 0.3s ease;
}

.description-enter-from,
.description-leave-to {
    opacity: 0;
    transform: translateY(-10px);
    max-height: 0;
}

.description-enter-to,
.description-leave-from {
    opacity: 1;
    transform: translateY(0);
    max-height: 100px;
}
</style>
