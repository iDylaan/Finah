<template>
    <Dialog
        :visible="visible"
        @update:visible="$emit('update:visible', $event)"
        :header="modalTitle"
        :modal="true"
        :closable="!isLoading"
        :closeOnEscape="!isLoading"
        :dismissableMask="!isLoading"
        :draggable="false"
        :style="{ width: '95vw', maxWidth: '42rem' }"
        :breakpoints="{ '768px': '100vw' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
        class="mobile-fullscreen-dialog"
        @hide="handleClose"
    >
        <template #header>
            <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-lg flex items-center justify-center bg-green-500">
                    <span class="material-symbols-rounded text-white text-xl">credit_card</span>
                </div>
                <div>
                    <h3 class="text-lg font-semibold m-0">{{ modalTitle }}</h3>
                    <p class="text-sm text-surface-500 m-0">Registra el pago de tu tarjeta de crédito</p>
                </div>
            </div>
        </template>

        <!-- Loading State -->
        <div v-if="isLoadingData" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Form Content -->
        <div v-else class="flex flex-col gap-4">
            <!-- Información de la tarjeta -->
            <div class="p-3 bg-surface-50 dark:bg-surface-800 rounded-lg">
                <div class="flex items-center gap-3 mb-2">
                    <div class="w-10 h-10 rounded-lg flex items-center justify-center text-white"
                        :style="{ backgroundColor: getAccountColor(creditCard) }">
                        <i v-if="creditCard?.banco?.libreria_icono === 'primevue'"
                            :class="creditCard.banco.nombre_icono"></i>
                        <span v-else-if="creditCard?.banco?.libreria_icono === 'material'"
                            class="material-symbols-rounded text-lg">
                            {{ creditCard?.banco?.nombre_icono }}
                        </span>
                        <i v-else class="pi pi-credit-card"></i>
                    </div>
                    <div class="flex-1">
                        <div class="font-semibold text-surface-900 dark:text-surface-0">
                            {{ creditCard?.nombre }}
                        </div>
                        <div class="text-xs text-surface-500">
                            Saldo pendiente: {{ formatCurrency(saldoPendiente) }}
                        </div>
                    </div>
                </div>
                <div class="text-xs text-surface-600 dark:text-surface-400">
                    Límite: {{ formatCurrency(creditCard?.limite_credito || 0) }} • 
                    Disponible: {{ formatCurrency(creditCard?.credito_disponible || 0) }}
                </div>
            </div>

            <!-- Tipo de pago -->
            <div class="flex flex-col gap-2">
                <label class="font-semibold text-sm">Tipo de Pago *</label>
                <div class="flex gap-3">
                    <div 
                        class="flex-1 p-3 border-2 rounded-lg cursor-pointer transition-all"
                        :class="paymentType === 'manual' 
                            ? 'border-primary bg-primary/10' 
                            : 'border-surface-300 dark:border-surface-600 hover:border-primary/50'"
                        @click="paymentType = 'manual'"
                    >
                        <div class="flex items-center gap-2">
                            <RadioButton 
                                inputId="manual" 
                                name="paymentType" 
                                value="manual" 
                                v-model="paymentType" 
                            />
                            <label for="manual" class="cursor-pointer flex-1">
                                <div class="font-semibold text-sm">Pago Manual</div>
                                <div class="text-xs text-surface-500">Registro directo del monto pagado</div>
                            </label>
                        </div>
                    </div>
                    
                    <div 
                        class="flex-1 p-3 border-2 rounded-lg cursor-pointer transition-all"
                        :class="paymentType === 'transfer' 
                            ? 'border-primary bg-primary/10' 
                            : 'border-surface-300 dark:border-surface-600 hover:border-primary/50'"
                        @click="paymentType = 'transfer'"
                    >
                        <div class="flex items-center gap-2">
                            <RadioButton 
                                inputId="transfer" 
                                name="paymentType" 
                                value="transfer" 
                                v-model="paymentType" 
                            />
                            <label for="transfer" class="cursor-pointer flex-1">
                                <div class="font-semibold text-sm">Desde Cuenta</div>
                                <div class="text-xs text-surface-500">Transferencia desde otra cuenta</div>
                            </label>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Cuenta de origen (solo si es transferencia) -->
            <div v-if="paymentType === 'transfer'" class="flex flex-col gap-2">
                <label for="cuenta_origen" class="font-semibold text-sm">Cuenta de Origen *</label>
                <Dropdown 
                    id="cuenta_origen"
                    v-model="formData.cuenta_origen_id" 
                    :options="availableAccounts" 
                    optionLabel="nombre"
                    optionValue="id"
                    placeholder="Selecciona la cuenta para pagar"
                    :class="{ 'p-invalid': errors.cuenta_origen_id }"
                    class="w-full"
                >
                    <template #value="slotProps">
                        <div v-if="slotProps.value" class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded flex items-center justify-center text-white text-sm"
                                :style="{ backgroundColor: getAccountColor(getAccountById(slotProps.value)) }">
                                <i v-if="getAccountById(slotProps.value)?.banco?.libreria_icono === 'primevue'"
                                    :class="getAccountById(slotProps.value)?.banco?.nombre_icono"></i>
                                <span v-else-if="getAccountById(slotProps.value)?.banco?.libreria_icono === 'material'"
                                    class="material-symbols-rounded text-base">
                                    {{ getAccountById(slotProps.value)?.banco?.nombre_icono }}
                                </span>
                                <i v-else :class="getAccountIcon(getAccountById(slotProps.value))"></i>
                            </div>
                            <div class="flex-1">
                                <div>{{ getAccountById(slotProps.value)?.nombre }}</div>
                                <div class="text-xs text-surface-500">
                                    Disponible: {{ formatCurrency(getAccountById(slotProps.value)?.saldo || 0) }}
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
                                    {{ getAccountTypeLabel(slotProps.option.tipo) }} · 
                                    {{ formatCurrency(slotProps.option.saldo || 0) }}
                                </div>
                            </div>
                        </div>
                    </template>
                </Dropdown>
                <small v-if="errors.cuenta_origen_id" class="text-red-500">{{ errors.cuenta_origen_id }}</small>
            </div>

            <!-- Opciones de monto rápido -->
            <div class="flex flex-col gap-2">
                <label class="font-semibold text-sm">Monto del Pago *</label>
                <div class="grid grid-cols-3 gap-2">
                    <Button 
                        label="Pago Mínimo"
                        severity="secondary"
                        outlined
                        size="small"
                        @click="setMontoMinimo"
                        :disabled="!pagoMinimo"
                    >
                        <template #default>
                            <div class="flex flex-col items-center gap-0.5">
                                <span class="text-xs">Pago Mínimo</span>
                                <span class="text-xs font-semibold">{{ formatCurrency(pagoMinimo) }}</span>
                            </div>
                        </template>
                    </Button>
                    <Button 
                        label="Pago Total"
                        severity="secondary"
                        outlined
                        size="small"
                        @click="setMontoTotal"
                    >
                        <template #default>
                            <div class="flex flex-col items-center gap-0.5">
                                <span class="text-xs">Pago Total</span>
                                <span class="text-xs font-semibold">{{ formatCurrency(saldoPendiente) }}</span>
                            </div>
                        </template>
                    </Button>
                    <Button 
                        label="Personalizado"
                        severity="secondary"
                        outlined
                        size="small"
                        @click="formData.monto = null"
                    >
                        <template #default>
                            <div class="flex flex-col items-center gap-0.5">
                                <span class="text-xs">Personalizado</span>
                                <span class="text-xs font-semibold">Otro monto</span>
                            </div>
                        </template>
                    </Button>
                </div>
            </div>

            <!-- Monto -->
            <div class="flex flex-col gap-2">
                <label for="monto" class="font-semibold text-sm">Monto a Pagar *</label>
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
                <small v-else class="text-surface-500">
                    Máximo a pagar: {{ formatCurrency(saldoPendiente) }}
                </small>
            </div>

            <!-- Categoría -->
            <CategoryPicker 
                v-model="formData.categoria_id"
                :categoryGroups="categoryGroups"
                label="Categoría"
                :required="true"
                :error="errors.categoria_id"
                inputId="categoria-pago"
            />

            <!-- Fecha -->
            <div class="flex flex-col gap-2">
                <label for="fecha" class="font-semibold text-sm">Fecha del Pago *</label>
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
                    rows="2"
                    :placeholder="`Pago de ${paymentType === 'transfer' ? 'transferencia' : 'tarjeta de crédito'}...`"
                    class="w-full"
                />
            </div>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button 
                    label="Cancelar" 
                    severity="secondary" 
                    outlined 
                    @click="handleClose"
                    :disabled="isLoading"
                />
                <Button 
                    :label="isLoading ? 'Procesando...' : 'Registrar Pago'"
                    :loading="isLoading"
                    @click="handleSubmit"
                    :disabled="isLoading"
                    icon="pi pi-check"
                />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useAccountsStore } from '@/stores/accounts.js';
import { useCategoriesStore } from '@/stores/categories.js';
import { useTransactionsStore } from '@/stores/transactions.js';
import CategoryPicker from '@/components/CategoryPicker.vue';

const props = defineProps({
    visible: {
        type: Boolean,
        required: true
    },
    creditCardId: {
        type: String,
        default: null
    }
});

const emit = defineEmits(['update:visible', 'payment-registered']);

// Composables
const toast = useToast();

// Stores
const accountsStore = useAccountsStore();
const categoriesStore = useCategoriesStore();
const transactionsStore = useTransactionsStore();

// State
const isLoading = ref(false);
const isLoadingData = ref(false);
const paymentType = ref('manual'); // 'manual' o 'transfer'

// Form data
const formData = ref({
    cuenta_origen_id: null,
    monto: null,
    categoria_id: null,
    fecha_ocurrencia: new Date(),
    descripcion: ''
});

const errors = ref({});

// Datos
const creditCard = computed(() => {
    return accountsStore.accounts.find(acc => acc.id === props.creditCardId);
});

const saldoPendiente = computed(() => {
    if (!creditCard.value) return 0;
    return (creditCard.value.limite_credito || 0) - (creditCard.value.credito_disponible || 0);
});

const pagoMinimo = computed(() => {
    if (!creditCard.value || !saldoPendiente.value) return 0;
    const porcentaje = creditCard.value.porcentaje_pago_minimo || 5;
    return saldoPendiente.value * (porcentaje / 100);
});

// Cuentas disponibles (excluir tarjetas de crédito)
const availableAccounts = computed(() => {
    return accountsStore.accounts.filter(acc => 
        acc.tipo !== 'credit_card' && acc.id !== props.creditCardId
    );
});

const categoryGroups = computed(() => {
    return categoriesStore.categoryGroups;
});

// Computed
const modalTitle = computed(() => {
    return creditCard.value ? `Pagar ${creditCard.value.nombre}` : 'Pagar Tarjeta';
});

// Helpers
const getAccountById = (id) => {
    return accountsStore.accounts.find(acc => acc.id === id);
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

const getAccountTypeLabel = (type) => {
    const types = {
        'cash': 'Efectivo',
        'bank': 'Cuenta Bancaria',
        'debit_card': 'Tarjeta de Débito',
        'credit_card': 'Tarjeta de Crédito'
    };
    return types[type] || type;
};

const formatCurrency = (value) => {
    return new Intl.NumberFormat('es-MX', {
        style: 'currency',
        currency: 'MXN'
    }).format(value || 0);
};

// Acciones rápidas de monto
const setMontoMinimo = () => {
    formData.value.monto = pagoMinimo.value;
};

const setMontoTotal = () => {
    formData.value.monto = saldoPendiente.value;
};

// Validación
const validate = () => {
    errors.value = {};
    
    if (paymentType.value === 'transfer' && !formData.value.cuenta_origen_id) {
        errors.value.cuenta_origen_id = 'Selecciona una cuenta de origen';
    }
    
    if (!formData.value.monto || formData.value.monto <= 0) {
        errors.value.monto = 'El monto debe ser mayor a 0';
    }
    
    if (formData.value.monto > saldoPendiente.value) {
        errors.value.monto = 'El monto no puede ser mayor al saldo pendiente';
    }
    
    if (paymentType.value === 'transfer' && formData.value.cuenta_origen_id) {
        const cuentaOrigen = getAccountById(formData.value.cuenta_origen_id);
        if (cuentaOrigen && formData.value.monto > (cuentaOrigen.saldo || 0)) {
            errors.value.monto = 'Saldo insuficiente en la cuenta de origen';
        }
    }
    
    if (!formData.value.categoria_id) {
        errors.value.categoria_id = 'Selecciona una categoría';
    }
    
    if (!formData.value.fecha_ocurrencia) {
        errors.value.fecha_ocurrencia = 'Selecciona una fecha';
    }
    
    return Object.keys(errors.value).length === 0;
};

// Handlers
const handleClose = () => {
    if (isLoading.value) return;
    
    emit('update:visible', false);
    resetForm();
};

const handleSubmit = async () => {
    if (!validate()) {
        toast.add({
            severity: 'warn',
            summary: 'Validación',
            detail: 'Por favor completa todos los campos requeridos',
            life: 3000
        });
        return;
    }
    
    isLoading.value = true;
    
    try {
        const paymentData = {
            monto: formData.value.monto,
            categoria_id: formData.value.categoria_id,
            fecha_ocurrencia: formData.value.fecha_ocurrencia instanceof Date 
                ? formData.value.fecha_ocurrencia.toISOString().split('T')[0]
                : formData.value.fecha_ocurrencia,
            descripcion: formData.value.descripcion || `Pago de tarjeta ${creditCard.value?.nombre}`,
            metadatos: {
                tipo_pago: paymentType.value
            }
        };
        
        if (paymentType.value === 'transfer') {
            // Crear como transferencia desde cuenta origen a tarjeta de crédito
            const transferData = {
                cuenta_origen_id: formData.value.cuenta_origen_id,
                cuenta_destino_id: props.creditCardId,
                ...paymentData
            };
            
            await transactionsStore.createTransferencia(transferData, { toast });
        } else {
            // Crear como ingreso directo a la tarjeta de crédito
            const ingresoData = {
                cuenta_id: props.creditCardId,
                nivel_id: null, // Los pagos de tarjeta no necesitan nivel
                ...paymentData
            };
            
            await transactionsStore.createIngreso(ingresoData, { toast });
        }
        
        // Refrescar cuentas
        await accountsStore.fetchAccountsWithDetails({ toast, force: true });
        
        emit('payment-registered');
        handleClose();
        
    } catch (error) {
        console.error('Error registrando pago:', error);
    } finally {
        isLoading.value = false;
    }
};

const resetForm = () => {
    formData.value = {
        cuenta_origen_id: null,
        monto: null,
        categoria_id: null,
        fecha_ocurrencia: new Date(),
        descripcion: ''
    };
    errors.value = {};
    paymentType.value = 'manual';
};

// Cargar datos cuando se abre el modal
watch(() => props.visible, async (newValue) => {
    if (newValue) {
        isLoadingData.value = true;
        try {
            await Promise.all([
                accountsStore.fetchAccountsWithDetails({ toast }),
                categoriesStore.fetchCategoryGroupsWithCategories({ toast })
            ]);
        } catch (error) {
            console.error('Error cargando datos:', error);
        } finally {
            isLoadingData.value = false;
        }
    }
});

// Limpiar cuenta origen al cambiar tipo de pago
watch(paymentType, () => {
    formData.value.cuenta_origen_id = null;
});
</script>

<style scoped>
/* Estilos adicionales si son necesarios */
</style>
