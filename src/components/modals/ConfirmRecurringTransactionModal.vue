<template>
    <Dialog v-model:visible="show" modal header="Confirmar Transacción Periódica" :closable="true" :draggable="false"
        :breakpoints="{ '768px': '100vw' }" :style="{ width: '32rem' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }" class="mobile-fullscreen-dialog">
        
        <div v-if="execution" class="flex flex-col gap-6">
            <!-- Información de la transacción -->
            <div class="p-4 bg-surface-50 dark:bg-surface-800 rounded-lg border border-surface-200 dark:border-surface-700">
                <div class="flex items-center gap-3 mb-4">
                    <div class="flex items-center justify-center w-12 h-12 rounded-lg"
                        :class="getTypeBgClass(execution.transaccion_periodica.tipo)">
                        <span class="material-symbols-outlined text-2xl" :class="getTypeColor(execution.transaccion_periodica.tipo)">
                            {{ getTypeIcon(execution.transaccion_periodica.tipo) }}
                        </span>
                    </div>
                    <div class="flex-1">
                        <h3 class="font-semibold text-lg">{{ execution.transaccion_periodica.nombre }}</h3>
                        <p class="text-sm text-surface-600 dark:text-surface-400">
                            {{ getFrequencyLabel(execution.transaccion_periodica.frecuencia) }}
                        </p>
                    </div>
                </div>

                <!-- Detalles -->
                <div class="flex flex-col gap-2 text-sm">
                    <div class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Cuenta:</span>
                        <span class="font-medium">{{ execution.transaccion_periodica.cuenta.nombre }}</span>
                    </div>
                    
                    <div v-if="execution.transaccion_periodica.categoria" class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Categoría:</span>
                        <div class="flex items-center gap-1.5">
                            <span class="material-symbols-outlined text-base"
                                :style="{ color: execution.transaccion_periodica.categoria.grupo?.color }">
                                {{ execution.transaccion_periodica.categoria.nombre_icono || 'category' }}
                            </span>
                            <span class="font-medium">{{ execution.transaccion_periodica.categoria.nombre }}</span>
                        </div>
                    </div>

                    <div class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Fecha programada:</span>
                        <span class="font-medium">{{ formatDate(execution.fecha_programada) }}</span>
                    </div>

                    <div class="flex justify-between items-center pt-2 border-t border-surface-300 dark:border-surface-600">
                        <span class="text-surface-600 dark:text-surface-400">Monto original:</span>
                        <span class="font-bold text-lg" :class="getTypeColor(execution.transaccion_periodica.tipo)">
                            {{ formatCurrency(execution.monto_programado) }}
                        </span>
                    </div>
                </div>
            </div>

            <!-- Formulario de edición -->
            <div class="flex flex-col gap-4">
                <Message severity="info" :closable="false">
                    <span class="text-sm">
                        La transacción se registrará con la fecha de hoy ({{ formatDate(new Date()) }}).
                        Puedes modificar el monto y/o la descripción antes de confirmar.
                    </span>
                </Message>

                <!-- Monto editable -->
                <div class="flex flex-col gap-2">
                    <label for="monto" class="text-sm font-semibold">
                        Monto a Registrar
                        <span class="text-red-500">*</span>
                    </label>
                    <InputNumber v-model="form.monto" mode="currency" currency="MXN" locale="es-MX"
                        placeholder="$0.00" :invalid="errors.monto" :min="0.01" inputId="monto" />
                    <small v-if="errors.monto" class="text-red-500">{{ errors.monto }}</small>
                </div>

                <!-- Descripción editable -->
                <div class="flex flex-col gap-2">
                    <label for="descripcion" class="text-sm font-semibold">Descripción (Opcional)</label>
                    <Textarea v-model="form.descripcion" rows="2" 
                        placeholder="Agregar información adicional..." 
                        autoResize inputId="descripcion" />
                </div>
            </div>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cancelar" severity="secondary" @click="show = false" />
                <Button label="Confirmar y Registrar" icon="pi pi-check" @click="handleConfirm" :loading="loading" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions.js'
import { useTransactionsStore } from '@/stores/transactions.js'

const toast = useToast()
const recurringStore = useRecurringTransactionsStore()
const transactionsStore = useTransactionsStore()

// Props
const props = defineProps({
    visible: Boolean,
    execution: Object
})

// Emits
const emit = defineEmits(['update:visible', 'success'])

// State
const show = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
})

const loading = ref(false)

const form = ref({
    monto: null,
    descripcion: ''
})

const errors = ref({})

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
        month: 'long',
        year: 'numeric'
    })
}

const validateForm = () => {
    errors.value = {}
    
    if (!form.value.monto || form.value.monto <= 0) {
        errors.value.monto = 'Ingresa un monto válido'
    }
    
    return Object.keys(errors.value).length === 0
}

const handleConfirm = async () => {
    if (!validateForm()) return
    
    loading.value = true
    
    try {
        await recurringStore.confirmAndExecuteTransaction(
            props.execution.id,
            {
                monto: form.value.monto,
                descripcion: form.value.descripcion?.trim() || null,
                toast
            }
        )
        
        // Recargar transacciones si hay un store disponible
        if (transactionsStore.fetchTransactions) {
            await transactionsStore.fetchTransactions({ toast: null })
        }
        
        show.value = false
        emit('success')
    } catch (error) {
        console.error('Error al confirmar transacción:', error)
    } finally {
        loading.value = false
    }
}

const resetForm = () => {
    form.value = {
        monto: null,
        descripcion: ''
    }
    errors.value = {}
}

// Watchers
watch(() => props.visible, (newValue) => {
    if (newValue && props.execution) {
        form.value.monto = props.execution.monto_programado
        form.value.descripcion = props.execution.transaccion_periodica.descripcion || ''
    } else {
        resetForm()
    }
})
</script>
