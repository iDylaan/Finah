<template>
    <div class="flex flex-col gap-4">
        <!-- Cuenta -->
        <AccountPicker
            v-model="formData.cuenta_id"
            :accounts="cuentas"
            label="Cuenta"
            placeholder="Selecciona una cuenta"
            inputId="cuenta-gasto"
            :required="true"
            :error="errors.cuenta_id"
            :showBalance="true"
            :showCreditCardInfo="true"
            :requiredAmount="formData.monto"
            enableFilter
        />

        <!-- Categoría -->
        <CategoryPicker 
            v-model="formData.categoria_id"
            :categoryGroups="categoryGroups"
            tipo="gasto"
            label="Categoría"
            :required="true"
            :error="errors.categoria_id"
            inputId="categoria-gasto"
        />

        <!-- Nivel (Obligatorio para gastos) -->
        <div class="flex flex-col gap-2">
            <label for="nivel" class="font-semibold text-sm">Nivel de Prioridad *</label>
            <Select 
                id="nivel"
                v-model="formData.nivel_id" 
                :options="niveles" 
                optionLabel="nombre"
                optionValue="id"
                placeholder="Selecciona un nivel"
                :class="{ 'p-invalid': errors.nivel_id }"
                class="w-full"
            >
                <template #value="slotProps">
                    <div v-if="slotProps.value" class="flex items-center gap-2">
                        <div class="w-4 h-4 rounded-full" 
                            :style="{ backgroundColor: getNivelById(slotProps.value)?.color }"></div>
                        <span>{{ getNivelById(slotProps.value)?.nombre }}</span>
                    </div>
                    <span v-else>{{ slotProps.placeholder }}</span>
                </template>
                <template #option="slotProps">
                    <div class="flex items-center gap-2">
                        <div class="w-4 h-4 rounded-full" 
                            :style="{ backgroundColor: slotProps.option.color }"></div>
                        <span>{{ slotProps.option.nombre }}</span>
                    </div>
                </template>
            </Select>
            <small v-if="errors.nivel_id" class="text-red-500">{{ errors.nivel_id }}</small>
        </div>

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

        <!-- Opción de Meses Sin Intereses (solo para tarjetas de crédito) -->
        <div v-if="selectedCuenta && selectedCuenta.tipo === 'credit_card'" class="flex flex-col gap-3 p-3 border border-primary-200 dark:border-primary-800 rounded-lg bg-primary-50 dark:bg-primary-900/20">
            <div class="flex items-center justify-between">
                <label class="font-semibold text-sm flex items-center gap-2">
                    <i class="pi pi-calendar text-primary"></i>
                    Diferir Pago a Meses
                </label>
                <InputSwitch v-model="formData.diferirMSI" />
            </div>

            <!-- Configuración de MSI -->
            <div v-if="formData.diferirMSI" class="flex flex-col gap-3 pl-6 border-l-2 border-primary-300 dark:border-primary-700">
                <div class="flex flex-col gap-2">
                    <label for="meses" class="font-semibold text-sm">Número de meses *</label>
                    <Select
                        id="meses"
                        v-model="formData.numeroMeses"
                        :options="mesesOptions"
                        optionLabel="label"
                        optionValue="value"
                        placeholder="Selecciona los meses"
                        :class="{ 'p-invalid': errors.numeroMeses }"
                        class="w-full"
                    />
                    <small v-if="errors.numeroMeses" class="text-red-500">{{ errors.numeroMeses }}</small>
                </div>

                <!-- Input para meses personalizados -->
                <div v-if="formData.numeroMeses === 'personalizado'" class="flex flex-col gap-2">
                    <label for="meses-personalizados" class="font-semibold text-sm">Especifica el número de meses *</label>
                    <InputNumber
                        id="meses-personalizados"
                        v-model="formData.mesesPersonalizados"
                        :min="1"
                        :max="60"
                        placeholder="Ej: 15"
                        :class="{ 'p-invalid': errors.mesesPersonalizados }"
                        showButtons
                        buttonLayout="horizontal"
                    >
                        <template #incrementbuttonicon>
                            <span class="pi pi-plus" />
                        </template>
                        <template #decrementbuttonicon>
                            <span class="pi pi-minus" />
                        </template>
                    </InputNumber>
                    <small v-if="errors.mesesPersonalizados" class="text-red-500">{{ errors.mesesPersonalizados }}</small>
                </div>

                <!-- Tipo de monto -->
                <div class="flex flex-col gap-2">
                    <label class="font-semibold text-sm">Monto por cuota</label>
                    <div class="flex flex-col gap-2">
                        <div class="flex items-center gap-2">
                            <RadioButton 
                                v-model="formData.tipoMonto" 
                                inputId="automatico" 
                                value="automatico" 
                            />
                            <label for="automatico" class="cursor-pointer">
                                Automático: {{ formatCurrency((formData.monto || 0) / (formData.numeroMeses || 1)) }}
                            </label>
                        </div>
                        
                        <div class="flex items-center gap-2">
                            <RadioButton 
                                v-model="formData.tipoMonto" 
                                inputId="redondeado" 
                                value="redondeado" 
                            />
                            <label for="redondeado" class="cursor-pointer">
                                Redondeado: {{ formatCurrency(montoPorMesRedondeado) }}
                            </label>
                        </div>
                        
                        <div class="flex items-center gap-2">
                            <RadioButton 
                                v-model="formData.tipoMonto" 
                                inputId="manual" 
                                value="manual" 
                            />
                            <label for="manual" class="cursor-pointer">Manual</label>
                        </div>
                        
                        <!-- Campo de monto manual -->
                        <div v-if="formData.tipoMonto === 'manual'" class="pl-6">
                            <InputNumber
                                v-model="formData.montoPorMes"
                                mode="currency"
                                currency="MXN"
                                locale="es-MX"
                                :min="0"
                                :max="formData.monto"
                                placeholder="Ingresa el monto por mes"
                                class="w-full"
                                :class="{ 'p-invalid': errors.montoPorMes }"
                            />
                            <small v-if="errors.montoPorMes" class="text-red-500">{{ errors.montoPorMes }}</small>
                            <small v-else class="text-surface-600 dark:text-surface-400">
                                Total: {{ formatCurrency((formData.montoPorMes || 0) * (formData.numeroMeses || 1)) }}
                            </small>
                        </div>
                    </div>
                </div>

                <div class="flex flex-col gap-2">
                    <label for="mesesPagados" class="font-semibold text-sm">Meses ya pagados</label>
                    <InputNumber
                        id="mesesPagados"
                        v-model="formData.mesesYaPagados"
                        :min="0"
                        :max="formData.numeroMeses ? formData.numeroMeses - 1 : 0"
                        :disabled="!formData.numeroMeses"
                        showButtons
                        buttonLayout="horizontal"
                        :step="1"
                        incrementButtonIcon="pi pi-plus"
                        decrementButtonIcon="pi pi-minus"
                    >
                        <template #incrementbuttonicon>
                            <span class="pi pi-plus" />
                        </template>
                        <template #decrementbuttonicon>
                            <span class="pi pi-minus" />
                        </template>
                    </InputNumber>
                    <small class="text-surface-600 dark:text-surface-400">
                        Si ya pagaste algunos meses, indícalo aquí
                    </small>
                </div>

                <!-- Opción para iniciar en el siguiente periodo -->
                <div class="flex items-center justify-between p-3 bg-surface-50 dark:bg-surface-800 rounded-lg">
                    <div class="flex flex-col gap-1">
                        <label for="iniciarSiguientePeriodo" class="font-semibold text-sm">Iniciar en el siguiente periodo</label>
                        <small class="text-surface-600 dark:text-surface-400">
                            Si está activado, el primer pago será después de la próxima fecha de corte
                        </small>
                    </div>
                    <InputSwitch 
                        id="iniciarSiguientePeriodo"
                        v-model="formData.iniciarSiguientePeriodo" 
                    />
                </div>

                <div class="flex flex-col gap-2">
                    <label for="nombreMSI" class="font-semibold text-sm">Nombre del pago diferido</label>
                    <InputText
                        id="nombreMSI"
                        v-model="formData.nombreMSI"
                        placeholder="Ej: Laptop Dell, TV Samsung, etc."
                        class="w-full"
                    />
                    <small class="text-surface-600 dark:text-surface-400">
                        Opcional: identifica fácilmente este pago diferido
                    </small>
                </div>
            </div>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import CategoryPicker from '@/components/CategoryPicker.vue';
import AccountPicker from '@/components/AccountPicker.vue';

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
    niveles: {
        type: Array,
        required: true
    }
});

// Emits
const emit = defineEmits(['update:modelValue', 'validate']);

// Form data
const formData = ref({
    cuenta_id: null,
    categoria_id: null,
    nivel_id: null,
    monto: null,
    fecha_ocurrencia: new Date(),
    descripcion: '',
    // Campos de MSI
    diferirMSI: false,
    numeroMeses: null,
    mesesPersonalizados: null,
    mesesYaPagados: 0,
    nombreMSI: '',
    tipoMonto: 'automatico', // 'automatico', 'redondeado', 'manual'
    montoPorMes: null,
    iniciarSiguientePeriodo: false // Si true, primera cuota es en el siguiente periodo
});

// Errors
const errors = ref({});

// Computed - Monto redondeado por mes
const montoPorMesRedondeado = computed(() => {
    const mesesFinal = formData.value.numeroMeses === 'personalizado' 
        ? formData.value.mesesPersonalizados 
        : formData.value.numeroMeses;
    
    if (!formData.value.monto || !mesesFinal) return 0;
    const montoAutomatico = formData.value.monto / mesesFinal;
    return Math.ceil(montoAutomatico);
});

// Computed
const selectedCuenta = computed(() => getCuentaById(formData.value.cuenta_id));

// Opciones de meses comunes
const mesesOptions = [
    { label: '3 meses', value: 3 },
    { label: '4 meses', value: 4 },
    { label: '6 meses', value: 6 },
    { label: '9 meses', value: 9 },
    { label: '10 meses', value: 10 },
    { label: '12 meses', value: 12 },
    { label: '15 meses', value: 15 },
    { label: '18 meses', value: 18 },
    { label: '24 meses', value: 24 },
    { label: '36 meses', value: 36 },
    { label: 'Personalizado', value: 'personalizado' }
];

// Helpers para obtener datos por ID
const getCuentaById = (id) => props.cuentas.find(c => c.id === id);
const getNivelById = (id) => props.niveles.find(n => n.id === id);

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

// Formato de moneda
const formatCurrency = (amount) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(amount || 0);
};

// Validación
const validate = () => {
    errors.value = {};

    if (!formData.value.cuenta_id) {
        errors.value.cuenta_id = 'La cuenta es obligatoria';
    }
    if (!formData.value.categoria_id) {
        errors.value.categoria_id = 'La categoría es obligatoria';
    }
    if (!formData.value.nivel_id) {
        errors.value.nivel_id = 'El nivel de prioridad es obligatorio';
    }
    if (!formData.value.monto || formData.value.monto <= 0) {
        errors.value.monto = 'El monto debe ser mayor a 0';
    }
    if (!formData.value.fecha_ocurrencia) {
        errors.value.fecha_ocurrencia = 'La fecha es obligatoria';
    }
    
    // Validaciones de MSI
    if (formData.value.diferirMSI) {
        if (!formData.value.numeroMeses) {
            errors.value.numeroMeses = 'Selecciona el número de meses';
        }
        if (formData.value.numeroMeses === 'personalizado') {
            if (!formData.value.mesesPersonalizados || formData.value.mesesPersonalizados < 1) {
                errors.value.mesesPersonalizados = 'Ingresa un número de meses válido';
            }
        }
    }

    return Object.keys(errors.value).length === 0;
};

// Watch para resetear MSI si se cambia de cuenta
watch(() => formData.value.cuenta_id, (newCuentaId) => {
    const cuenta = getCuentaById(newCuentaId);
    if (cuenta && cuenta.tipo !== 'credit_card') {
        // Si no es tarjeta de crédito, resetear opciones de MSI
        formData.value.diferirMSI = false;
        formData.value.numeroMeses = null;
        formData.value.mesesYaPagados = 0;
        formData.value.nombreMSI = '';
    }
});

// Exponer datos y validación
defineExpose({
    formData,
    validate,
    reset: () => {
        formData.value = {
            cuenta_id: null,
            categoria_id: null,
            nivel_id: null,
            monto: null,
            fecha_ocurrencia: new Date(),
            descripcion: '',
            diferirMSI: false,
            numeroMeses: null,
            mesesPersonalizados: null,
            mesesYaPagados: 0,
            nombreMSI: '',
            tipoMonto: 'automatico',
            montoPorMes: null,
            iniciarSiguientePeriodo: false
        };
        errors.value = {};
    }
});

// Watch para emitir cambios
watch(formData, (newVal) => {
    emit('update:modelValue', newVal);
}, { deep: true });
</script>
