<template>
    <SpeedDial :model="items" direction="up" :transitionDelay="80" mask
        :style="{ position: 'fixed', right: '2rem', bottom: '2rem', zIndex: 100 }"
        :tooltipOptions="{ position: 'left' }" @show="onShow" @hide="onHide" :pt="{
            root: {
                style: 'align-items: flex-end'
            },
            list: {
                style: 'align-items: self-end;'
            }
        }">
        <template #button="{ toggleCallback }">
            <Button severity="primary" class="mt-1" aria-label="Bookmark" @click="toggleCallback" size="large">
                <template #icon>
                    <span class="material-symbols-outlined speed-dial-icon" :class="{ 'rotate': isOpen }">add</span>
                </template>
            </Button>
        </template>
        <template #item="{ item, toggleCallback, index }">
            <div class="speed-dial-item-wrapper">
                <div class="
                    flex 
                    flex-col 
                    items-center 
                    justify-center 
                    w-[3rem] h-[3rem]
                    gap-4
                    p-1 
                    border 
                    rounded-lg
                    cursor-pointer 
                    border-surface-200 dark:border-surface-700/60
                    bg-surface-0/80 dark:bg-surface-800/70
                    hover:bg-surface-50 dark:hover:bg-surface-700 
                    transition-colors 
                    shadow-md" @click="toggleCallback">
                    <div class="flex flex-col justify-center items-center">
                        <span class="material-symbols-outlined">{{ item.icon }}</span>
                    </div>
                </div>
                <Transition enter-active-class="animate__animated animate__fadeInLeft animate__faster"
                    leave-active-class="animate__animated animate__fadeOutDown"
                    :style="{ '--animate-delay': `${index * 0.05}s` }">
                    <div v-if="isOpen" class="speed-dial-tooltip">
                        <span class="
                            bg-surface-0/60 dark:bg-surface-700/40 
                            text-surface-800 dark:text-surface-0/70
                            px-3
                            py-2 
                            rounded-md
                            shadow-md">{{ item.label }}</span>
                        <div class="speed-dial-arrow"></div>
                    </div>
                </Transition>
            </div>
        </template>
    </SpeedDial>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'

const router = useRouter()
const toast = useToast()
const isOpen = ref(false)

const onShow = () => {
    isOpen.value = true
    const mask = document.querySelector('.p-speeddial-mask')
    if (mask) {
        mask.style.zIndex = '99'
        mask.style.pointerEvents = 'auto'
        mask.style.position = 'fixed'
        mask.style.top = '0'
        mask.style.left = '0'
        mask.style.width = '100vw'
        mask.style.height = '100vh'
    }
}

const onHide = () => {
    isOpen.value = false
    const mask = document.querySelector('.p-speeddial-mask')
    if (mask) {
        mask.style.zIndex = '-1'
        mask.style.pointerEvents = 'none'
    }
}

const items = ref([
    {
        label: 'Ingreso',
        icon: 'paid',
        command: () => {
            // TODO: Abrir modal o navegar a registro de ingreso
            toast.add({
                severity: 'success',
                summary: 'Nuevo Ingreso',
                detail: 'Función próximamente',
                life: 3000
            })
        }
    },
    {
        label: 'Gasto',
        icon: 'receipt_long',
        command: () => {
            // TODO: Abrir modal o navegar a registro de gasto
            toast.add({
                severity: 'danger',
                summary: 'Nuevo Gasto',
                detail: 'Función próximamente',
                life: 3000
            })
        }
    },
    {
        label: 'Transferir',
        icon: 'send_money',
        command: () => {
            // TODO: Abrir modal o navegar a registro de transferencia
            toast.add({
                severity: 'info',
                summary: 'Nueva Transferencia',
                detail: 'Función próximamente',
                life: 3000
            })
        }
    }
].map((item, index) => ({ ...item, index })))
</script>

<style>
.p-speeddial-mask {
    z-index: -1;
    transition: z-index 0s;
    pointer-events: none;
    position: fixed !important;
    inset: 0 !important;
}

.p-speeddial {
    z-index: 100;
}

.speed-dial-icon {
    transition: transform 0.3s ease;
}

.speed-dial-icon.rotate {
    transform: rotate(45deg);
}

.speed-dial-item-wrapper {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex-direction: row-reverse;
}

.speed-dial-tooltip {
    display: flex;
    align-items: center;
    gap: 0;
    position: relative;
}

.speed-dial-arrow {
    width: 0;
    height: 0;
    border-top: 6px solid transparent;
    border-bottom: 6px solid transparent;
    border-left: 8px solid rgb(var(--p-surface-0-rgb) / 0.6);
}

.app-dark .speed-dial-arrow {
    border-left-color: rgb(var(--p-surface-700-rgb) / 0.4);
}

.speed-dial-label {
    background: var(--p-surface-900);
    color: var(--p-surface-0);
    padding: 0.5rem 0.75rem;
    border-radius: 0.375rem;
    font-size: 0.875rem;
    white-space: nowrap;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* Animación de salida con delay secuencial */
.animate__fadeOutDown {
    animation-delay: var(--animate-delay, 0s);
}

@media (prefers-color-scheme: dark) {
    .speed-dial-label {
        background: var(--p-surface-700);
        color: var(--p-surface-0);
    }
}
</style>