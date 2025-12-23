<template>
    <Card v-if="hasPendingTransactions" class="shadow-md">
        <template #title>
            <div class="flex items-center gap-2">
                <span class="material-symbols-outlined text-primary">schedule</span>
                <span>Transacciones Pendientes de Confirmar</span>
            </div>
        </template>
        
        <template #content>
            <div class="flex flex-col gap-4">
                <TransitionGroup name="list">
                    <div v-for="execution in pendingExecutions" :key="execution.id"
                        class="p-4 border border-surface-200 dark:border-surface-700 rounded-lg hover:bg-surface-50 dark:hover:bg-surface-800 transition-colors">
                        
                        <div class="flex flex-col gap-3">
                            <!-- Header con nombre y tipo -->
                            <div class="flex items-start justify-between gap-2">
                                <div class="flex items-center gap-2 flex-1">
                                    <span class="material-symbols-outlined text-2xl" :class="getTypeColor(execution.transaccion_periodica.tipo)">
                                        {{ getTypeIcon(execution.transaccion_periodica.tipo) }}
                                    </span>
                                    <div class="flex flex-col">
                                        <span class="font-semibold">{{ execution.transaccion_periodica.nombre }}</span>
                                        <span class="text-sm text-surface-600 dark:text-surface-400">
                                            {{ getFrequencyLabel(execution.transaccion_periodica.frecuencia) }}
                                        </span>
                                    </div>
                                </div>
                                <div class="flex flex-col items-end">
                                    <span class="font-bold text-lg" :class="getTypeColor(execution.transaccion_periodica.tipo)">
                                        {{ formatCurrency(execution.monto_programado) }}
                                    </span>
                                    <span class="text-xs text-surface-500">
                                        {{ formatDate(execution.fecha_programada) }}
                                    </span>
                                </div>
                            </div>

                            <!-- Cuenta y categoría -->
                            <div class="flex flex-wrap gap-3 text-sm">
                                <div class="flex items-center gap-1.5">
                                    <span class="material-symbols-outlined text-base text-surface-600">
                                        account_balance_wallet
                                    </span>
                                    <span>{{ execution.transaccion_periodica.cuenta.nombre }}</span>
                                </div>
                                
                                <div v-if="execution.transaccion_periodica.categoria" class="flex items-center gap-1.5">
                                    <span class="material-symbols-outlined text-base" 
                                        :style="{ color: execution.transaccion_periodica.categoria.grupo?.color }">
                                        {{ execution.transaccion_periodica.categoria.nombre_icono || 'category' }}
                                    </span>
                                    <span>{{ execution.transaccion_periodica.categoria.nombre }}</span>
                                </div>
                            </div>

                            <!-- Descripción (si existe) -->
                            <p v-if="execution.transaccion_periodica.descripcion" 
                                class="text-sm text-surface-600 dark:text-surface-400">
                                {{ execution.transaccion_periodica.descripcion }}
                            </p>

                            <!-- Acciones -->
                            <div class="flex gap-2 pt-2">
                                <Button label="Confirmar" icon="pi pi-check" severity="success" 
                                    @click="openConfirmModal(execution)" class="flex-1" />
                                <Button label="Rechazar" icon="pi pi-times" severity="danger" 
                                    outlined @click="handleReject(execution)" class="flex-1" />
                            </div>
                        </div>
                    </div>
                </TransitionGroup>

                <!-- Mensaje cuando no hay pendientes -->
                <div v-if="pendingExecutions.length === 0" class="text-center py-8 text-surface-500">
                    <span class="material-symbols-outlined text-5xl mb-2">check_circle</span>
                    <p>No hay transacciones pendientes de confirmar</p>
                </div>
            </div>
        </template>
    </Card>

    <!-- Modal de Confirmación -->
    <ConfirmRecurringTransactionModal 
        v-model:visible="showConfirmModal" 
        :execution="selectedExecution"
        @success="handleSuccess" />
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions.js'
import ConfirmRecurringTransactionModal from '@/components/modals/ConfirmRecurringTransactionModal.vue'

const toast = useToast()
const confirm = useConfirm()
const recurringStore = useRecurringTransactionsStore()

// State
const showConfirmModal = ref(false)
const selectedExecution = ref(null)

// Computed
const pendingExecutions = computed(() => recurringStore.pendingExecutions || [])
const hasPendingTransactions = computed(() => pendingExecutions.value.length > 0)

// Methods
const getTypeIcon = (type) => {
    const icons = {
        'ingreso': 'paid',
        'gasto': 'receipt_long',
        'transferencia': 'swap_horiz'
    }
    return icons[type] || 'receipt'
}

const getTypeColor = (type) => {
    const colors = {
        'ingreso': 'text-green-600 dark:text-green-400',
        'gasto': 'text-red-500 dark:text-red-400',
        'transferencia': 'text-blue-500 dark:text-blue-400'
    }
    return colors[type] || 'text-surface-600'
}

const getFrequencyLabel = (frequency) => {
    const labels = {
        'diaria': 'Diaria',
        'semanal': 'Semanal',
        'quincenal': 'Quincenal',
        'mensual': 'Mensual',
        'bimestral': 'Bimestral',
        'trimestral': 'Trimestral',
        'semestral': 'Semestral',
        'anual': 'Anual'
    }
    return labels[frequency] || frequency
}

const formatCurrency = (value) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(value)
}

const formatDate = (date) => {
    return new Date(date).toLocaleDateString('es-MX', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
    })
}

const openConfirmModal = (execution) => {
    selectedExecution.value = execution
    showConfirmModal.value = true
}

const handleReject = (execution) => {
    confirm.require({
        message: `¿Estás seguro de rechazar la transacción "${execution.transaccion_periodica.nombre}"? Se pasará al siguiente periodo.`,
        header: 'Rechazar Transacción',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Sí, Rechazar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await recurringStore.rejectExecution(execution.id, { toast })
            } catch (error) {
                console.error('Error al rechazar transacción:', error)
            }
        }
    })
}

const handleSuccess = async () => {
    await loadPendingExecutions()
}

const loadPendingExecutions = async () => {
    await recurringStore.fetchPendingExecutions({ toast })
}

// Lifecycle
onMounted(() => {
    loadPendingExecutions()
})
</script>

<style scoped>
.list-enter-active,
.list-leave-active {
    transition: all 0.3s ease;
}

.list-enter-from {
    opacity: 0;
    transform: translateY(-10px);
}

.list-leave-to {
    opacity: 0;
    transform: translateX(30px);
}

.list-move {
    transition: transform 0.3s ease;
}
</style>
