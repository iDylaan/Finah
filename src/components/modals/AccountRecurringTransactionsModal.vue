<template>
    <Dialog v-model:visible="show" modal :header="dialogTitle" :closable="true" :draggable="false"
        :breakpoints="{ '768px': '100vw' }" :style="{ width: '50rem' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }" class="mobile-fullscreen-dialog">
        
        <div class="flex flex-col gap-4">
            <!-- Botón para crear nueva -->
            <div class="flex justify-end">
                <Button label="Nueva Transacción Periódica" icon="pi pi-plus" @click="openCreateModal" />
            </div>

            <!-- Lista de transacciones periódicas -->
            <div v-if="accountRecurringTransactions.length > 0" class="flex flex-col gap-3">
                <div v-for="transaction in accountRecurringTransactions" :key="transaction.id"
                    class="p-4 border border-surface-200 dark:border-surface-700 rounded-lg hover:shadow-md transition-all">
                    
                    <div class="flex flex-col gap-3">
                        <!-- Header -->
                        <div class="flex items-start justify-between gap-3">
                            <div class="flex items-center gap-3 flex-1">
                                <div class="flex items-center justify-center w-12 h-12 rounded-lg"
                                    :class="getTypeBgClass(transaction.tipo)">
                                    <span class="material-symbols-outlined text-2xl" :class="getTypeColor(transaction.tipo)">
                                        {{ getTypeIcon(transaction.tipo) }}
                                    </span>
                                </div>
                                <div class="flex-1">
                                    <h4 class="font-semibold text-lg">{{ transaction.nombre }}</h4>
                                    <div class="flex flex-wrap gap-2 text-sm text-surface-600 dark:text-surface-400">
                                        <span>{{ getFrequencyLabel(transaction.frecuencia) }}</span>
                                        <span>•</span>
                                        <span class="font-medium" :class="getTypeColor(transaction.tipo)">
                                            {{ formatCurrency(transaction.monto) }}
                                        </span>
                                    </div>
                                </div>
                            </div>

                            <!-- Estado y menú -->
                            <div class="flex items-center gap-2">
                                <Chip :label="transaction.activa ? 'Activa' : 'Pausada'" 
                                    :severity="transaction.activa ? 'success' : 'secondary'" 
                                    class="h-6" />
                                <Button icon="pi pi-ellipsis-v" text rounded @click="toggleMenu($event, transaction)" />
                            </div>
                        </div>

                        <!-- Detalles -->
                        <div class="flex flex-wrap gap-x-4 gap-y-2 text-sm">
                            <div v-if="transaction.categoria" class="flex items-center gap-1.5">
                                <span class="material-symbols-outlined text-base"
                                    :style="{ color: transaction.categoria.grupo?.color }">
                                    {{ transaction.categoria.nombre_icono || 'category' }}
                                </span>
                                <span>{{ transaction.categoria.nombre }}</span>
                            </div>

                            <div class="flex items-center gap-1.5">
                                <span class="material-symbols-outlined text-base text-surface-600">
                                    calendar_today
                                </span>
                                <span>Inicia: {{ formatDate(transaction.fecha_inicio) }}</span>
                            </div>

                            <div v-if="transaction.criterio_finalizacion !== 'sin_fin'" class="flex items-center gap-1.5">
                                <span class="material-symbols-outlined text-base text-surface-600">
                                    event_available
                                </span>
                                <span v-if="transaction.criterio_finalizacion === 'fecha_fin'">
                                    Hasta: {{ formatDate(transaction.fecha_fin) }}
                                </span>
                                <span v-else-if="transaction.criterio_finalizacion === 'numero_repeticiones'">
                                    {{ transaction.repeticiones_completadas || 0 }} de {{ transaction.numero_repeticiones }} veces
                                </span>
                            </div>
                        </div>

                        <!-- Descripción -->
                        <p v-if="transaction.descripcion" class="text-sm text-surface-600 dark:text-surface-400">
                            {{ transaction.descripcion }}
                        </p>

                        <!-- Badges informativos -->
                        <div class="flex flex-wrap gap-2">
                            <Chip v-if="transaction.requiere_confirmacion" 
                                label="Requiere Confirmación" 
                                icon="pi pi-check-circle"
                                severity="info" 
                                class="h-6 text-xs" />
                            <Chip v-if="transaction.es_msi" 
                                label="MSI" 
                                icon="pi pi-credit-card"
                                severity="warning" 
                                class="h-6 text-xs" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Empty state -->
            <div v-else class="flex flex-col items-center justify-center py-12 text-surface-500">
                <span class="material-symbols-outlined text-6xl mb-4">event_repeat</span>
                <p class="text-lg font-medium mb-2">No hay transacciones periódicas</p>
                <p class="text-sm">Crea una para automatizar tus pagos recurrentes</p>
                <Button label="Crear Primera Transacción" icon="pi pi-plus" 
                    class="mt-4" @click="openCreateModal" />
            </div>
        </div>

        <!-- Menú contextual -->
        <Menu ref="menu" :model="menuItems" :popup="true" />
    </Dialog>

    <!-- Modal de crear/editar -->
    <RecurringTransactionModal 
        v-model:visible="showRecurringModal" 
        :edit-data="selectedTransaction"
        @success="handleSuccess" />
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useAccountsStore } from '@/stores/accounts.js'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions.js'
import RecurringTransactionModal from '@/components/modals/RecurringTransactionModal.vue'

const toast = useToast()
const confirm = useConfirm()
const accountsStore = useAccountsStore()
const recurringStore = useRecurringTransactionsStore()

// Props
const props = defineProps({
    visible: Boolean,
    accountId: String
})

// Emits
const emit = defineEmits(['update:visible'])

// State
const show = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
})

const menu = ref()
const selectedTransaction = ref(null)
const showRecurringModal = ref(false)

// Computed
const account = computed(() => {
    return accountsStore.accounts.find(a => a.id === props.accountId)
})

const dialogTitle = computed(() => {
    return account.value 
        ? `Transacciones Periódicas - ${account.value.nombre}` 
        : 'Transacciones Periódicas'
})

const accountRecurringTransactions = computed(() => {
    return recurringStore.recurringTransactions.filter(t => 
        t.cuenta_id === props.accountId && !t.es_msi
    )
})

const menuItems = computed(() => [
    {
        label: 'Editar',
        icon: 'pi pi-pencil',
        command: () => openEditModal()
    },
    {
        label: selectedTransaction.value?.activa ? 'Pausar' : 'Reanudar',
        icon: selectedTransaction.value?.activa ? 'pi pi-pause' : 'pi pi-play',
        command: () => toggleActive()
    },
    {
        separator: true
    },
    {
        label: 'Eliminar',
        icon: 'pi pi-trash',
        class: 'text-red-500',
        command: () => handleDelete()
    }
])

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

const getTypeBgClass = (type) => {
    const colors = {
        'ingreso': 'bg-green-100 dark:bg-green-500/10',
        'gasto': 'bg-red-100 dark:bg-red-500/10',
        'transferencia': 'bg-blue-100 dark:bg-blue-500/10'
    }
    return colors[type] || 'bg-surface-100'
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

const toggleMenu = (event, transaction) => {
    selectedTransaction.value = transaction
    menu.value.toggle(event)
}

const openCreateModal = () => {
    selectedTransaction.value = null
    showRecurringModal.value = true
}

const openEditModal = () => {
    showRecurringModal.value = true
}

const toggleActive = async () => {
    try {
        await recurringStore.toggleRecurringTransaction(selectedTransaction.value.id, { toast })
        await loadData()
    } catch (error) {
        console.error('Error al cambiar estado:', error)
    }
}

const handleDelete = () => {
    confirm.require({
        message: `¿Estás seguro de eliminar la transacción periódica "${selectedTransaction.value.nombre}"?`,
        header: 'Confirmar Eliminación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Sí, Eliminar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await recurringStore.deleteRecurringTransaction(selectedTransaction.value.id, { toast })
                await loadData()
            } catch (error) {
                console.error('Error al eliminar:', error)
            }
        }
    })
}

const handleSuccess = async () => {
    await loadData()
}

const loadData = async () => {
    await recurringStore.fetchRecurringTransactions({ toast })
}

// Watchers
watch(() => props.visible, (newValue) => {
    if (newValue) {
        loadData()
    }
})
</script>
