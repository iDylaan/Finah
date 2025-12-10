<template>
    <div class="flex flex-col gap-4">
        <!-- Cuenta Origen -->
        <div class="flex flex-col gap-2">
            <label for="cuenta_origen" class="font-semibold text-sm">Cuenta Origen *</label>
            <Select 
                id="cuenta_origen"
                v-model="formData.cuenta_origen_id" 
                :options="cuentas" 
                optionLabel="nombre"
                optionValue="id"
                placeholder="Selecciona la cuenta de origen"
                :class="{ 'p-invalid': errors.cuenta_origen_id }"
                class="w-full"
                @change="onCuentaOrigenChange"
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(getCuentaById(slotProps.value)) }">
                            <i v-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'primevue'"
                                :class="getCuentaById(slotProps.value)?.banco?.nombre_icono"></i>
                            <span v-else-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ getCuentaById(slotProps.value)?.banco?.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(getCuentaById(slotProps.value))"></i>
                        </div>
                        <div class="flex-1">
                            <div>{{ getCuentaById(slotProps.value)?.nombre }}</div>
                            <div class="text-xs text-surface-500">
                                {{ formatSaldoDisponible(getCuentaById(slotProps.value)) }}
                            </div>
                        </div>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(slotProps.option) }">
                            <i v-if="slotProps.option.banco?.libreria_icono === 'primevue'"
                                :class="slotProps.option.banco.nombre_icono"></i>
                            <span v-else-if="slotProps.option.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ slotProps.option.banco.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(slotProps.option)"></i>
                        </div>
                        <div class="flex-1">
                            <div class="font-medium">{{ slotProps.option.nombre }}</div>
                            <div class="text-xs text-surface-500">
                                {{ getAccountTypeLabel(slotProps.option.tipo) }} · {{ formatSaldoDisponible(slotProps.option) }}
                            </div>
                        </div>
                    </div>
                </template>
            </Select>
            <small v-if="errors.cuenta_origen_id" class="text-red-500">{{ errors.cuenta_origen_id }}</small>
        </div>

        <!-- Cuenta Destino -->
        <div class="flex flex-col gap-2">
            <label for="cuenta_destino" class="font-semibold text-sm">Cuenta Destino *</label>
            <Select 
                id="cuenta_destino"
                v-model="formData.cuenta_destino_id" 
                :options="cuentasDestino" 
                optionLabel="nombre"
                optionValue="id"
                placeholder="Selecciona la cuenta de destino"
                :class="{ 'p-invalid': errors.cuenta_destino_id }"
                class="w-full"
                :disabled="!formData.cuenta_origen_id"
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(getCuentaById(slotProps.value)) }">
                            <i v-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'primevue'"
                                :class="getCuentaById(slotProps.value)?.banco?.nombre_icono"></i>
                            <span v-else-if="getCuentaById(slotProps.value)?.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ getCuentaById(slotProps.value)?.banco?.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(getCuentaById(slotProps.value))"></i>
                        </div>
                        <span>{{ getCuentaById(slotProps.value)?.nombre }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                            :style="{ backgroundColor: getAccountColor(slotProps.option) }">
                            <i v-if="slotProps.option.banco?.libreria_icono === 'primevue'"
                                :class="slotProps.option.banco.nombre_icono"></i>
                            <span v-else-if="slotProps.option.banco?.libreria_icono === 'material'"
                                class="material-symbols-rounded text-base">
                                {{ slotProps.option.banco.nombre_icono }}
                            </span>
                            <i v-else :class="getAccountIcon(slotProps.option)"></i>
                        </div>
                        <div class="flex-1">
                            <div class="font-medium">{{ slotProps.option.nombre }}</div>
                            <div class="text-xs text-surface-500">
                                {{ getAccountTypeLabel(slotProps.option.tipo) }}
                            </div>
                        </div>
                    </div>
                </template>
            </Select>
            <small v-if="errors.cuenta_destino_id" class="text-red-500">{{ errors.cuenta_destino_id }}</small>
        </div>

        <!-- Categoría -->
        <CategoryPicker 
            v-model="formData.categoria_id"
            :categoryGroups="categoryGroups"
            label="Categoría"
            :required="true"
            :error="errors.categoria_id"
            inputId="categoria-transferencia"
        />

        <!-- Monto -->
        <div class="flex flex-col gap-2">
            <label for="monto" class="font-semibold text-sm">Monto *</label>
            <InputNumber
                id="monto"
                v-model="formData.monto"
                mode="currency"
                currency="MXN"
                locale="es-MX"
                :minFractionDigits="2"
                :maxFractionDigits="2"
                :class="{ 'p-invalid': errors.monto }"
                placeholder="$0.00"
                class="w-full"
            />
            <small v-if="errors.monto" class="text-red-500">{{ errors.monto }}</small>
            <small v-if="montoDisponible !== null" class="text-surface-500">
                Disponible: {{ formatCurrency(montoDisponible) }}
            </small>
        </div>

        <!-- Fecha -->
        <div class="flex flex-col gap-2">
            <label for="fecha" class="font-semibold text-sm">Fecha *</label>
            <DatePicker
                id="fecha"
                v-model="formData.fecha_ocurrencia"
                dateFormat="dd/mm/yy"
                :maxDate="new Date()"
                :class="{ 'p-invalid': errors.fecha_ocurrencia }"
                placeholder="Selecciona la fecha"
                class="w-full"
                showIcon
                iconDisplay="input"
            />
            <small v-if="errors.fecha_ocurrencia" class="text-red-500">{{ errors.fecha_ocurrencia }}</small>
        </div>

        <!-- Descripción -->
        <div class="flex flex-col gap-2">
            <label for="descripcion" class="font-semibold text-sm">Descripción</label>
            <Textarea
                id="descripcion"
                v-model="formData.descripcion"
                rows="3"
                placeholder="Agrega una descripción opcional..."
                class="w-full"
            />
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import CategoryPicker from '@/components/CategoryPicker.vue';

// Props
const props = defineProps({
    cuentas: {
        type: Array,
        required: true
    },
    categoryGroups: {
        type: Array,
        required: true
    },
    preselectedAccountId: {
        type: Number,
        default: null
    }
});

// Emits
const emit = defineEmits(['update:modelValue', 'validate']);

// Form data
const formData = ref({
    cuenta_origen_id: props.preselectedAccountId || null,
    cuenta_destino_id: null,
    categoria_id: null,
    monto: null,
    fecha_ocurrencia: new Date(),
    descripcion: ''
});

// Errors
const errors = ref({});

// Cuentas destino (excluir la cuenta origen)
const cuentasDestino = computed(() => {
    if (!formData.value.cuenta_origen_id) return [];
    return props.cuentas.filter(c => c.id !== formData.value.cuenta_origen_id);
});

// Monto disponible en cuenta origen
const montoDisponible = computed(() => {
    if (!formData.value.cuenta_origen_id) return null;
    const cuenta = getCuentaById(formData.value.cuenta_origen_id);
    if (!cuenta) return null;
    
    if (cuenta.tipo === 'credit_card') {
        return parseFloat(cuenta.credito_disponible || 0);
    }
    return parseFloat(cuenta.saldo || 0);
});

// Handlers
const onCuentaOrigenChange = () => {
    // Si la cuenta destino es la misma que la origen, resetearla
    if (formData.value.cuenta_destino_id === formData.value.cuenta_origen_id) {
        formData.value.cuenta_destino_id = null;
    }
};

// Helpers para obtener datos por ID
const getCuentaById = (id) => props.cuentas.find(c => c.id === id);

// Helpers de cuentas
const getAccountTypeLabel = (type) => {
    const types = {
        'cash': 'Efectivo',
        'bank': 'Cuenta Bancaria',
        'debit_card': 'Tarjeta de Débito',
        'credit_card': 'Tarjeta de Crédito'
    };
    return types[type] || type;
};

const getAccountColor = (account) => {
    if (!account) return '#6366f1';
    if (account.banco?.color) return account.banco.color;

    const colors = {
        'cash': '#10b981',
        'bank': '#3b82f6',
        'debit_card': '#8b5cf6',
        'credit_card': '#f59e0b'
    };
    return colors[account.tipo] || '#6366f1';
};

const getAccountIcon = (account) => {
    if (!account) return 'pi pi-wallet';
    if (account.banco?.nombre_icono && account.banco?.libreria_icono === 'primevue') {
        return account.banco.nombre_icono;
    }

    const icons = {
        'cash': 'pi pi-dollar',
        'bank': 'pi pi-building',
        'debit_card': 'pi pi-credit-card',
        'credit_card': 'pi pi-credit-card'
    };
    return icons[account.tipo] || 'pi pi-wallet';
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(value);
};

const formatSaldoDisponible = (account) => {
    if (!account) return '';
    if (account.tipo === 'credit_card') {
        return formatCurrency(account.credito_disponible || 0);
    }
    return formatCurrency(account.saldo || 0);
};

// Validación
const validate = () => {
    errors.value = {};

    if (!formData.value.cuenta_origen_id) {
        errors.value.cuenta_origen_id = 'La cuenta origen es obligatoria';
    }
    if (!formData.value.cuenta_destino_id) {
        errors.value.cuenta_destino_id = 'La cuenta destino es obligatoria';
    }
    if (formData.value.cuenta_origen_id === formData.value.cuenta_destino_id) {
        errors.value.cuenta_destino_id = 'Las cuentas deben ser diferentes';
    }
    if (!formData.value.categoria_id) {
        errors.value.categoria_id = 'La categoría es obligatoria';
    }
    if (!formData.value.monto || formData.value.monto <= 0) {
        errors.value.monto = 'El monto debe ser mayor a 0';
    }
    if (montoDisponible.value !== null && formData.value.monto > montoDisponible.value) {
        errors.value.monto = 'El monto excede el disponible';
    }
    if (!formData.value.fecha_ocurrencia) {
        errors.value.fecha_ocurrencia = 'La fecha es obligatoria';
    }

    return Object.keys(errors.value).length === 0;
};

// Exponer datos y validación
defineExpose({
    formData,
    validate,
    reset: () => {
        formData.value = {
            cuenta_origen_id: props.preselectedAccountId || null,
            cuenta_destino_id: null,
            categoria_id: null,
            monto: null,
            fecha_ocurrencia: new Date(),
            descripcion: ''
        };
        errors.value = {};
    }
});

// Watch para emitir cambios
watch(formData, (newVal) => {
    emit('update:modelValue', newVal);
}, { deep: true });
</script>
