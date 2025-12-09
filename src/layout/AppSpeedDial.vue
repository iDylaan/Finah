<template>
    <SpeedDial :model="items" direction="up" :transitionDelay="80" mask
        :style="{ position: 'fixed', right: '2.5rem', bottom: '2rem', zIndex: 100 }"
        :tooltipOptions="{ position: 'left' }" @show="onShow" @hide="onHide" :pt="{
            root: {
                style: `align-items: flex-end;`
            },
            list: {
                style: `align-items: self-end;`,
                class: hideList ? 'no-height' : ''
            }
        }">
        <template #button="{ toggleCallback }">
            <Button severity="primary" :pt="{
                root: {
                    style: `
                        width: 4.5rem;
                        height: 4.5rem;
                        border-radius: 0.75rem;
                        box-shadow: var(--p-shadow-6);
                    `
                }
            }" aria-label="Bookmark" @click="toggleCallback" size="large">
                <template #icon>
                    <span class="material-symbols-outlined speed-dial-icon" style="font-size: 2.5rem;" :class="{ 'rotate': isOpen }">add</span>
                </template>
            </Button>
        </template>
        <template #item="{ item, toggleCallback }">
            <div class="
                flex 
                flex-col 
                items-center 
                justify-center 
                w-[4.5rem] 
                gap-1
                p-2 
                border 
                rounded-lg
                hover:bg-surface-50 dark:hover:bg-surface-700 
                cursor-pointer 
                border-surface-200 dark:border-surface-700/60
                bg-surface-0
                dark:bg-surface-800
                transition-colors 
                shadow-md" @click="toggleCallback">
                <span class="material-symbols-outlined text-2xl">{{ item.icon }}</span>
                <span class="text-xs text-center text-surface-700 dark:text-surface-300 leading-tight">{{ item.label }}</span>
            </div>
        </template>
    </SpeedDial>
</template>

<script setup>
import { ref } from 'vue'
import { useModalsStore } from '@/stores/ui-modals.js'

const modalsStore = useModalsStore()
const isOpen = ref(false)
const hideList = ref(true)

const onShow = () => {
    isOpen.value = true
    hideList.value = false
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
    
    // Delay para quitar la clase no-height después de la animación
    setTimeout(() => {
        hideList.value = true
    }, 300) // 300ms coincide con la duración de la animación
    
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
            modalsStore.openIngresoModal()
        }
    },
    {
        label: 'Gasto',
        icon: 'receipt_long',
        command: () => {
            // TODO: Implementar modal de gasto
            modalsStore.openGastoModal()
        }
    },
    {
        label: 'Transferir',
        icon: 'send_money',
        command: () => {
            // TODO: Implementar modal de transferencia
            modalsStore.openTransferenciaModal()
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

.no-height {
    height: 0 !important;
    overflow: hidden !important;
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
</style>