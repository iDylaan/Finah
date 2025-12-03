<template>
    <SpeedDial :model="items" direction="up" :transitionDelay="80" mask
        :style="{ position: 'fixed', right: '1.5rem', bottom: '1.5rem', zIndex: 999 }"
        :tooltipOptions="{ position: 'left' }" pt:menuitem="m-2">
        <template #button="{ toggleCallback }">
            <Button severity="primary" rounded aria-label="Bookmark" @click="toggleCallback" size="large">
                <template #icon>
                    <span class="material-symbols-outlined">add</span>
                </template> 
            </Button>
        </template>
        <template #item="{ item, toggleCallback }">
            <div class="flex flex-col items-center justify-center gap-2 p-3 border rounded-lg border-surface-200 dark:border-surface-700 w-20 h-20 cursor-pointer bg-surface-0 dark:bg-surface-800 hover:bg-surface-50 dark:hover:bg-surface-700 transition-colors shadow-md"
                @click="toggleCallback">
                <i :class="item.icon" class="text-2xl"></i>
                <span class="text-xs font-medium">{{ item.label }}</span>
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

const items = ref([
    {
        label: 'Ingreso',
        icon: 'pi pi-arrow-down',
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
        icon: 'pi pi-arrow-up',
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
        icon: 'pi pi-arrow-right-arrow-left',
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
])
</script>

<style scoped></style>