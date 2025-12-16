<template>
    <div class="flex flex-col gap-2">
        <label :for="inputId" class="font-semibold text-sm">
            {{ label }}
            <span v-if="required" class="text-red-500">*</span>
        </label>
        <Select 
            :id="inputId"
            :modelValue="modelValue" 
            @update:modelValue="handleChange"
            :options="filteredAccounts" 
            optionLabel="nombre"
            optionValue="id"
            :placeholder="placeholder"
            :class="{ 'p-invalid': error }"
            :disabled="disabled"
            class="w-full"
            :filter="enableFilter"
            filterPlaceholder="Buscar cuenta..."
        >
            <template #value="slotProps">
                <div v-if="slotProps.value" class="flex items-center gap-3">
                    <!-- Icono de la cuenta/banco -->
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center text-white text-sm shadow-sm"
                        :style="{ backgroundColor: getAccountColor(getAccountById(slotProps.value)) }">
                        <i v-if="getAccountById(slotProps.value)?.banco?.libreria_icono === 'primevue'"
                            :class="getAccountById(slotProps.value)?.banco?.nombre_icono"
                            class="text-lg"></i>
                        <span v-else-if="getAccountById(slotProps.value)?.banco?.libreria_icono === 'material'"
                            class="material-symbols-rounded text-lg">
                            {{ getAccountById(slotProps.value)?.banco?.nombre_icono }}
                        </span>
                        <i v-else :class="getAccountIcon(getAccountById(slotProps.value))" class="text-lg"></i>
                    </div>
                    
                    <!-- Información de la cuenta -->
                    <div class="flex-1 min-w-0">
                        <div class="font-medium truncate">{{ getAccountById(slotProps.value)?.nombre }}</div>
                        <div class="text-xs text-surface-500 flex items-center gap-1.5">
                            <span v-if="getAccountById(slotProps.value)?.banco">
                                {{ getAccountById(slotProps.value)?.banco?.nombre }}
                            </span>
                            <span v-if="getAccountById(slotProps.value)?.banco" class="text-surface-400">•</span>
                            <span>{{ getAccountTypeLabel(getAccountById(slotProps.value)?.tipo) }}</span>
                        </div>
                    </div>
                    
                    <!-- Saldo (opcional) -->
                    <div v-if="showBalance && getAccountById(slotProps.value)" class="text-right">
                        <div class="text-sm font-semibold" :class="getBalanceClass(getAccountById(slotProps.value))">
                            {{ formatCurrency(getAccountBalance(getAccountById(slotProps.value))) }}
                        </div>
                        <div v-if="getAccountById(slotProps.value)?.tipo === 'credit_card'" class="text-xs text-surface-500">
                            Disponible
                        </div>
                    </div>
                </div>
                <span v-else>{{ placeholder }}</span>
            </template>
            
            <template #option="slotProps">
                <div class="flex items-center gap-3 py-1">
                    <!-- Icono de la cuenta/banco -->
                    <div class="w-9 h-9 rounded-lg flex items-center justify-center text-white text-sm shadow-sm"
                        :style="{ backgroundColor: getAccountColor(slotProps.option) }">
                        <i v-if="slotProps.option.banco?.libreria_icono === 'primevue'"
                            :class="slotProps.option.banco.nombre_icono"
                            class="text-lg"></i>
                        <span v-else-if="slotProps.option.banco?.libreria_icono === 'material'"
                            class="material-symbols-rounded text-lg">
                            {{ slotProps.option.banco.nombre_icono }}
                        </span>
                        <i v-else :class="getAccountIcon(slotProps.option)" class="text-lg"></i>
                    </div>
                    
                    <!-- Información de la cuenta -->
                    <div class="flex-1 min-w-0">
                        <div class="font-medium truncate">{{ slotProps.option.nombre }}</div>
                        <div class="text-xs text-surface-500 flex items-center gap-1.5">
                            <span v-if="slotProps.option.banco">
                                {{ slotProps.option.banco.nombre }}
                            </span>
                            <span v-if="slotProps.option.banco" class="text-surface-400">•</span>
                            <span>{{ getAccountTypeLabel(slotProps.option.tipo) }}</span>
                            <template v-if="slotProps.option.metadatos?.ultimos_digitos">
                                <span class="text-surface-400">•</span>
                                <span>****{{ slotProps.option.metadatos.ultimos_digitos }}</span>
                            </template>
                        </div>
                    </div>
                    
                    <!-- Saldo (opcional) -->
                    <div v-if="showBalance" class="text-right">
                        <div class="text-sm font-semibold" :class="getBalanceClass(slotProps.option)">
                            {{ formatCurrency(getAccountBalance(slotProps.option)) }}
                        </div>
                        <div v-if="slotProps.option.tipo === 'credit_card'" class="text-xs text-surface-500">
                            Disponible
                        </div>
                    </div>
                </div>
            </template>
            
            <template #empty>
                <div class="text-center py-4 text-surface-500">
                    No hay cuentas disponibles
                </div>
            </template>
        </Select>
        
        <!-- Mensaje de error -->
        <small v-if="error" class="text-red-500">{{ error }}</small>
        
        <!-- Información adicional de la cuenta seleccionada (tarjetas de crédito) -->
        <div v-if="showCreditCardInfo && selectedAccount && selectedAccount.tipo === 'credit_card'" 
            class="p-3 bg-surface-50 dark:bg-surface-800 rounded-lg border border-surface-200 dark:border-surface-700">
            <div class="flex items-start gap-3">
                <i class="pi pi-info-circle text-primary mt-0.5"></i>
                <div class="flex-1 text-sm space-y-1">
                    <div class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Crédito disponible:</span>
                        <span class="font-semibold">{{ formatCurrency(selectedAccount.credito_disponible) }}</span>
                    </div>
                    <div class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Límite de crédito:</span>
                        <span class="font-semibold">{{ formatCurrency(selectedAccount.limite_credito) }}</span>
                    </div>
                    <div v-if="selectedAccount.saldo_periodo_actual > 0" class="flex justify-between">
                        <span class="text-surface-600 dark:text-surface-400">Saldo del periodo:</span>
                        <span class="font-semibold text-orange-600 dark:text-orange-400">
                            {{ formatCurrency(selectedAccount.saldo_periodo_actual) }}
                        </span>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Advertencia de saldo insuficiente -->
        <div v-if="showInsufficientBalanceWarning && selectedAccount && requiredAmount" 
            class="p-3 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800 flex items-start gap-2">
            <i class="pi pi-exclamation-triangle text-red-600 dark:text-red-400 mt-0.5"></i>
            <div class="flex-1 text-sm text-red-700 dark:text-red-300">
                <span class="font-semibold">Saldo insuficiente.</span>
                <span v-if="selectedAccount.tipo === 'credit_card'">
                    Crédito disponible: {{ formatCurrency(selectedAccount.credito_disponible) }}
                </span>
                <span v-else>
                    Saldo disponible: {{ formatCurrency(selectedAccount.saldo) }}
                </span>
            </div>
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';

const props = defineProps({
    modelValue: {
        type: String,
        default: null
    },
    label: {
        type: String,
        default: 'Cuenta'
    },
    placeholder: {
        type: String,
        default: 'Selecciona una cuenta'
    },
    inputId: {
        type: String,
        default: 'account-picker'
    },
    required: {
        type: Boolean,
        default: false
    },
    error: {
        type: String,
        default: null
    },
    disabled: {
        type: Boolean,
        default: false
    },
    accounts: {
        type: Array,
        required: true
    },
    // Filtros de tipo de cuenta
    excludeTypes: {
        type: Array,
        default: () => []
    },
    includeTypes: {
        type: Array,
        default: () => []
    },
    // Opciones de visualización
    showBalance: {
        type: Boolean,
        default: false
    },
    showCreditCardInfo: {
        type: Boolean,
        default: false
    },
    enableFilter: {
        type: Boolean,
        default: false
    },
    // Validación de saldo
    requiredAmount: {
        type: Number,
        default: null
    }
});

const emit = defineEmits(['update:modelValue', 'change']);

// Cuentas filtradas según los tipos incluidos/excluidos
const filteredAccounts = computed(() => {
    let accounts = props.accounts;
    
    // Filtrar por tipos incluidos
    if (props.includeTypes.length > 0) {
        accounts = accounts.filter(acc => props.includeTypes.includes(acc.tipo));
    }
    
    // Filtrar por tipos excluidos
    if (props.excludeTypes.length > 0) {
        accounts = accounts.filter(acc => !props.excludeTypes.includes(acc.tipo));
    }
    
    return accounts;
});

// Cuenta seleccionada
const selectedAccount = computed(() => {
    return props.accounts.find(acc => acc.id === props.modelValue);
});

// Advertencia de saldo insuficiente
const showInsufficientBalanceWarning = computed(() => {
    if (!selectedAccount.value || !props.requiredAmount) return false;
    
    const availableBalance = selectedAccount.value.tipo === 'credit_card' 
        ? selectedAccount.value.credito_disponible 
        : selectedAccount.value.saldo;
    
    return props.requiredAmount > availableBalance;
});

// Métodos
const handleChange = (value) => {
    emit('update:modelValue', value);
    emit('change', getAccountById(value));
};

const getAccountById = (id) => {
    return props.accounts.find(acc => acc.id === id);
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
    
    const icons = {
        'cash': 'pi pi-dollar',
        'bank': 'pi pi-building',
        'debit_card': 'pi pi-credit-card',
        'credit_card': 'pi pi-credit-card'
    };
    return icons[account.tipo] || 'pi pi-wallet';
};

const getAccountTypeLabel = (type) => {
    const types = {
        'cash': 'Efectivo',
        'bank': 'Cuenta Bancaria',
        'debit_card': 'Tarjeta de Débito',
        'credit_card': 'Tarjeta de Crédito'
    };
    return types[type] || type;
};

const getAccountBalance = (account) => {
    if (!account) return 0;
    return account.tipo === 'credit_card' ? account.credito_disponible : account.saldo;
};

const getBalanceClass = (account) => {
    if (!account) return '';
    
    if (account.tipo === 'credit_card') {
        const usagePercent = ((account.limite_credito - account.credito_disponible) / account.limite_credito) * 100;
        if (usagePercent >= 90) return 'text-red-600 dark:text-red-400';
        if (usagePercent >= 70) return 'text-orange-600 dark:text-orange-400';
        return 'text-green-600 dark:text-green-400';
    }
    
    return account.saldo < 0 ? 'text-red-600 dark:text-red-400' : 'text-green-600 dark:text-green-400';
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(value || 0);
};
</script>

<style scoped>
/* Estilos personalizados si son necesarios */
</style>
