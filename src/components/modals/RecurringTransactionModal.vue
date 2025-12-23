<template>
    <Dialog v-model:visible="show" modal :header="isEditMode ? 'Editar Transacción Periódica' : 'Nueva Transacción Periódica'"
        :closable="true" :draggable="false" :breakpoints="{ '768px': '100vw' }" :style="{ width: '42rem' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }" class="mobile-fullscreen-dialog"
        @hide="resetForm">
        
        <div class="flex flex-col gap-6">
            <!-- Tipo de transacción -->
            <div class="flex flex-col gap-2">
                <label class="text-sm font-semibold">Tipo de Transacción</label>
                <SelectButton v-model="form.tipo" :options="tipoOptions" optionLabel="label" optionValue="value"
                    :disabled="isEditMode" />
            </div>

            <!-- Cuenta origen -->
            <div class="flex flex-col gap-2">
                <label for="cuenta" class="text-sm font-semibold">
                    {{ form.tipo === 'transferencia' ? 'Cuenta Origen' : 'Cuenta' }}
                    <span class="text-red-500">*</span>
                </label>
                <Select v-model="form.cuenta_id" :options="availableAccounts" optionLabel="nombre" optionValue="id"
                    placeholder="Selecciona una cuenta" showClear :invalid="errors.cuenta_id">
                    <template #value="slotProps">
                        <div v-if="slotProps.value" class="flex items-center gap-2">
                            <span class="material-symbols-outlined text-xl" :style="{ color: getAccountColor(slotProps.value) }">
                                {{ getAccountIcon(slotProps.value) }}
                            </span>
                            <span>{{ getAccountName(slotProps.value) }}</span>
                        </div>
                        <span v-else>{{ slotProps.placeholder }}</span>
                    </template>
                    <template #option="slotProps">
                        <div class="flex items-center gap-2">
                            <span class="material-symbols-outlined text-xl" :style="{ color: slotProps.option.color }">
                                {{ slotProps.option.icon }}
                            </span>
                            <span>{{ slotProps.option.nombre }}</span>
                        </div>
                    </template>
                </Select>
                <small v-if="errors.cuenta_id" class="text-red-500">{{ errors.cuenta_id }}</small>
            </div>

            <!-- Cuenta destino (solo para transferencias) -->
            <div v-if="form.tipo === 'transferencia'" class="flex flex-col gap-2">
                <label for="cuenta_destino" class="text-sm font-semibold">
                    Cuenta Destino
                    <span class="text-red-500">*</span>
                </label>
                <Select v-model="form.cuenta_destino_id" :options="destinationAccounts" optionLabel="nombre"
                    optionValue="id" placeholder="Selecciona cuenta destino" showClear :invalid="errors.cuenta_destino_id">
                    <template #value="slotProps">
                        <div v-if="slotProps.value" class="flex items-center gap-2">
                            <span class="material-symbols-outlined text-xl" :style="{ color: getAccountColor(slotProps.value) }">
                                {{ getAccountIcon(slotProps.value) }}
                            </span>
                            <span>{{ getAccountName(slotProps.value) }}</span>
                        </div>
                        <span v-else>{{ slotProps.placeholder }}</span>
                    </template>
                    <template #option="slotProps">
                        <div class="flex items-center gap-2">
                            <span class="material-symbols-outlined text-xl" :style="{ color: slotProps.option.color }">
                                {{ slotProps.option.icon }}
                            </span>
                            <span>{{ slotProps.option.nombre }}</span>
                        </div>
                    </template>
                </Select>
                <small v-if="errors.cuenta_destino_id" class="text-red-500">{{ errors.cuenta_destino_id }}</small>
            </div>

            <!-- Categoría (no para transferencias) -->
            <div v-if="form.tipo !== 'transferencia'" class="flex flex-col gap-2">
                <CategoryPicker 
                    v-model="form.categoria_id" 
                    :category-groups="categoriesStore.categoryGroups"
                    :tipo="form.tipo"
                    label="Categoría" 
                    placeholder="Selecciona una categoría" 
                    required 
                    :error="errors.categoria_id" 
                />
            </div>

            <!-- Nombre -->
            <div class="flex flex-col gap-2">
                <label for="nombre" class="text-sm font-semibold">
                    Nombre
                    <span class="text-red-500">*</span>
                </label>
                <InputText v-model="form.nombre" placeholder="Ej: Salario mensual, Netflix, Renta" :invalid="errors.nombre" />
                <small v-if="errors.nombre" class="text-red-500">{{ errors.nombre }}</small>
            </div>

            <!-- Descripción -->
            <div class="flex flex-col gap-2">
                <label for="descripcion" class="text-sm font-semibold">Descripción (Opcional)</label>
                <Textarea v-model="form.descripcion" rows="2" placeholder="Información adicional..." autoResize />
            </div>

            <!-- Monto -->
            <div class="flex flex-col gap-2">
                <label for="monto" class="text-sm font-semibold">
                    Monto
                    <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="form.monto" mode="currency" currency="MXN" locale="es-MX"
                    placeholder="$0.00" :invalid="errors.monto" :min="0.01" />
                <small v-if="errors.monto" class="text-red-500">{{ errors.monto }}</small>
            </div>

            <!-- Frecuencia -->
            <div class="flex flex-col gap-2">
                <label class="text-sm font-semibold">
                    Frecuencia
                    <span class="text-red-500">*</span>
                </label>
                <Select v-model="form.frecuencia" :options="frecuenciaOptions" optionLabel="label" optionValue="value"
                    placeholder="Selecciona frecuencia" :invalid="errors.frecuencia" />
                <small v-if="errors.frecuencia" class="text-red-500">{{ errors.frecuencia }}</small>
            </div>

            <!-- Día específico (según frecuencia) -->
            <div v-if="needsDaySelection" class="flex flex-col gap-2">
                <label class="text-sm font-semibold">
                    {{ daySelectionLabel }}
                    <span class="text-red-500">*</span>
                </label>
                <Select v-if="form.frecuencia === 'semanal'" v-model="form.dia_especifico" :options="diasSemanaOptions"
                    optionLabel="label" optionValue="value" placeholder="Selecciona día" />
                <InputNumber v-else v-model="form.dia_especifico" placeholder="Día del mes" :min="1" :max="31"
                    :invalid="errors.dia_especifico" />
                <small v-if="errors.dia_especifico" class="text-red-500">{{ errors.dia_especifico }}</small>
            </div>

            <!-- Fecha de inicio -->
            <div class="flex flex-col gap-2">
                <label class="text-sm font-semibold">
                    Fecha de Inicio
                    <span class="text-red-500">*</span>
                </label>
                <DatePicker v-model="form.fecha_inicio" dateFormat="dd/mm/yy" placeholder="Selecciona fecha"
                    :invalid="errors.fecha_inicio" showIcon iconDisplay="input" />
                <small v-if="errors.fecha_inicio" class="text-red-500">{{ errors.fecha_inicio }}</small>
            </div>

            <!-- Criterio de finalización -->
            <div class="flex flex-col gap-2">
                <label class="text-sm font-semibold">¿Cuándo termina?</label>
                <Select v-model="form.criterio_fin" :options="criterioFinalizacionOptions" optionLabel="label"
                    optionValue="value" />
            </div>

            <!-- Fecha fin (si es por fecha) -->
            <div v-if="form.criterio_fin === 'fecha_fin'" class="flex flex-col gap-2">
                <label class="text-sm font-semibold">
                    Fecha de Finalización
                    <span class="text-red-500">*</span>
                </label>
                <DatePicker v-model="form.fecha_fin" dateFormat="dd/mm/yy" placeholder="Selecciona fecha"
                    :invalid="errors.fecha_fin" showIcon iconDisplay="input" :minDate="form.fecha_inicio" />
                <small v-if="errors.fecha_fin" class="text-red-500">{{ errors.fecha_fin }}</small>
            </div>

            <!-- Número de repeticiones (si es por número) -->
            <div v-if="form.criterio_fin === 'numero_repeticiones'" class="flex flex-col gap-2">
                <label class="text-sm font-semibold">
                    Número de Repeticiones
                    <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="form.numero_repeticiones" placeholder="Ej: 12" :min="1"
                    :invalid="errors.numero_repeticiones" />
                <small v-if="errors.numero_repeticiones" class="text-red-500">{{ errors.numero_repeticiones }}</small>
            </div>

            <!-- Requiere confirmación -->
            <div class="flex items-center gap-2">
                <Checkbox v-model="form.requiere_confirmacion" :binary="true" inputId="confirmacion" />
                <label for="confirmacion" class="text-sm">Requiere confirmación antes de registrarse</label>
            </div>

            <!-- Información adicional -->
            <Message severity="info" :closable="false">
                <span class="text-sm">
                    {{ form.requiere_confirmacion ? 
                        'Recibirás una notificación 5 días antes de cada periodo para confirmar o rechazar la transacción.' :
                        'La transacción se registrará automáticamente en cada periodo.'
                    }}
                </span>
            </Message>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cancelar" severity="secondary" @click="show = false" />
                <Button :label="isEditMode ? 'Actualizar' : 'Crear'" @click="handleSubmit" :loading="loading" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useToast } from 'primevue/usetoast'
import { useAccountsStore } from '@/stores/accounts.js'
import { useCategoriesStore } from '@/stores/categories.js'
import { useRecurringTransactionsStore } from '@/stores/recurring-transactions.js'
import CategoryPicker from '@/components/CategoryPicker.vue'

const toast = useToast()
const accountsStore = useAccountsStore()
const categoriesStore = useCategoriesStore()
const recurringStore = useRecurringTransactionsStore()

// Props
const props = defineProps({
    visible: Boolean,
    editData: Object
})

// Emits
const emit = defineEmits(['update:visible', 'success'])

// State
const show = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
})

const loading = ref(false)
const isEditMode = computed(() => !!props.editData)

const form = ref({
    tipo: 'gasto',
    cuenta_id: null,
    cuenta_destino_id: null,
    categoria_id: null,
    nombre: '',
    descripcion: '',
    monto: null,
    frecuencia: 'mensual',
    dia_especifico: null,
    fecha_inicio: new Date(),
    criterio_fin: 'sin_fin',
    fecha_fin: null,
    numero_repeticiones: null,
    requiere_confirmacion: true,
    activa: true
})

const errors = ref({})

// Options
const tipoOptions = [
    { label: 'Ingreso', value: 'ingreso' },
    { label: 'Gasto', value: 'gasto' },
    { label: 'Transferencia', value: 'transferencia' }
]

const frecuenciaOptions = [
    { label: 'Diaria', value: 'diaria' },
    { label: 'Semanal', value: 'semanal' },
    { label: 'Quincenal', value: 'quincenal' },
    { label: 'Mensual', value: 'mensual' },
    { label: 'Bimestral', value: 'bimestral' },
    { label: 'Trimestral', value: 'trimestral' },
    { label: 'Semestral', value: 'semestral' },
    { label: 'Anual', value: 'anual' }
]

const diasSemanaOptions = [
    { label: 'Lunes', value: 'lunes' },
    { label: 'Martes', value: 'martes' },
    { label: 'Miércoles', value: 'miercoles' },
    { label: 'Jueves', value: 'jueves' },
    { label: 'Viernes', value: 'viernes' },
    { label: 'Sábado', value: 'sabado' },
    { label: 'Domingo', value: 'domingo' }
]

const criterioFinalizacionOptions = [
    { label: 'Sin fin (indefinida)', value: 'sin_fin' },
    { label: 'Hasta una fecha', value: 'fecha_fin' },
    { label: 'Número de repeticiones', value: 'numero_repeticiones' }
]

// Computed
const availableAccounts = computed(() => {
    return accountsStore.accounts.map(account => ({
        ...account,
        icon: getAccountIconMaterial(account),
        color: getAccountColor(account.id)
    }))
})

const destinationAccounts = computed(() => {
    return availableAccounts.value.filter(acc => acc.id !== form.value.cuenta_id)
})

const needsDaySelection = computed(() => {
    return ['semanal', 'mensual', 'bimestral', 'trimestral', 'semestral', 'anual'].includes(form.value.frecuencia)
})

const daySelectionLabel = computed(() => {
    if (form.value.frecuencia === 'semanal') return 'Día de la Semana'
    return 'Día del Mes'
})

// Methods
const getAccountIconMaterial = (account) => {
    if (account.banco?.nombre_icono && account.banco?.biblioteca_iconos === 'material') {
        return account.banco.nombre_icono
    }
    const icons = {
        'cash': 'payments',
        'bank': 'account_balance',
        'debit_card': 'credit_card',
        'credit_card': 'credit_card'
    }
    return icons[account.tipo] || 'account_balance_wallet'
}

const getAccountColor = (accountId) => {
    const account = accountsStore.accounts.find(a => a.id === accountId)
    if (!account) return '#6366f1'
    if (account.banco?.color) return account.banco.color
    const colors = {
        'cash': '#10b981',
        'bank': '#3b82f6',
        'debit_card': '#8b5cf6',
        'credit_card': '#f59e0b'
    }
    return colors[account.tipo] || '#6366f1'
}

const getAccountName = (accountId) => {
    const account = accountsStore.accounts.find(a => a.id === accountId)
    return account?.nombre || ''
}

const getAccountIcon = (accountId) => {
    const account = accountsStore.accounts.find(a => a.id === accountId)
    return account ? getAccountIconMaterial(account) : 'account_balance_wallet'
}

const validateForm = () => {
    errors.value = {}
    
    if (!form.value.cuenta_id) errors.value.cuenta_id = 'Selecciona una cuenta'
    if (form.value.tipo === 'transferencia' && !form.value.cuenta_destino_id) {
        errors.value.cuenta_destino_id = 'Selecciona cuenta destino'
    }
    if (form.value.tipo !== 'transferencia' && !form.value.categoria_id) {
        errors.value.categoria_id = 'Selecciona una categoría'
    }
    if (!form.value.nombre?.trim()) errors.value.nombre = 'Ingresa un nombre'
    if (!form.value.monto || form.value.monto <= 0) errors.value.monto = 'Ingresa un monto válido'
    if (!form.value.frecuencia) errors.value.frecuencia = 'Selecciona una frecuencia'
    if (needsDaySelection.value && !form.value.dia_especifico) {
        errors.value.dia_especifico = 'Selecciona un día'
    }
    if (!form.value.fecha_inicio) errors.value.fecha_inicio = 'Selecciona fecha de inicio'
    if (form.value.criterio_fin === 'fecha_fin' && !form.value.fecha_fin) {
        errors.value.fecha_fin = 'Selecciona fecha de finalización'
    }
    if (form.value.criterio_fin === 'numero_repeticiones' && !form.value.numero_repeticiones) {
        errors.value.numero_repeticiones = 'Ingresa número de repeticiones'
    }
    
    return Object.keys(errors.value).length === 0
}

const handleSubmit = async () => {
    if (!validateForm()) return
    
    loading.value = true
    
    try {
        const data = {
            tipo: form.value.tipo,
            cuenta_id: form.value.cuenta_id,
            cuenta_destino_id: form.value.cuenta_destino_id,
            categoria_id: form.value.categoria_id,
            nombre: form.value.nombre.trim(),
            descripcion: form.value.descripcion?.trim() || null,
            monto: form.value.monto,
            frecuencia: form.value.frecuencia,
            fecha_inicio: form.value.fecha_inicio.toISOString(),
            criterio_fin: form.value.criterio_fin,
            fecha_fin: form.value.fecha_fin ? form.value.fecha_fin.toISOString() : null,
            numero_total_repeticiones: form.value.numero_repeticiones,
            requiere_confirmacion: form.value.requiere_confirmacion,
            activa: true
        }
        
        // Mapear dia_especifico al campo correcto según frecuencia
        if (form.value.frecuencia === 'mensual' && form.value.dia_especifico) {
            data.dia_del_mes = form.value.dia_especifico
        } else if (form.value.frecuencia === 'semanal' && form.value.dia_especifico) {
            data.dias_semana = [form.value.dia_especifico]
        }
        
        if (isEditMode.value) {
            await recurringStore.updateRecurringTransaction(props.editData.id, data, { toast })
        } else {
            await recurringStore.createRecurringTransaction(data, { toast })
        }
        
        show.value = false
        emit('success')
    } catch (error) {
        console.error('Error al guardar transacción periódica:', error)
    } finally {
        loading.value = false
    }
}

const resetForm = () => {
    form.value = {
        tipo: 'gasto',
        cuenta_id: null,
        cuenta_destino_id: null,
        categoria_id: null,
        nombre: '',
        descripcion: '',
        monto: null,
        frecuencia: 'mensual',
        dia_especifico: null,
        fecha_inicio: new Date(),
        criterio_fin: 'sin_fin',
        fecha_fin: null,
        numero_repeticiones: null,
        requiere_confirmacion: true,
        activa: true
    }
    errors.value = {}
}

// Watchers
watch(() => props.visible, (newValue) => {
    if (newValue && props.editData) {
        form.value = {
            ...props.editData,
            fecha_inicio: props.editData.fecha_inicio ? new Date(props.editData.fecha_inicio) : new Date(),
            fecha_fin: props.editData.fecha_fin ? new Date(props.editData.fecha_fin) : null
        }
    }
})

watch(() => form.value.tipo, () => {
    form.value.categoria_id = null
    form.value.cuenta_destino_id = null
})

watch(() => form.value.criterio_fin, (newValue) => {
    if (newValue !== 'fecha_fin') form.value.fecha_fin = null
    if (newValue !== 'numero_repeticiones') form.value.numero_repeticiones = null
})
</script>
