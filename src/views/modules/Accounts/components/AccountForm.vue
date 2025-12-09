<template>
    <div class="p-2 md:p-4">
        <div v-if="isLoading" class="flex justify-center py-6">
            <ProgressSpinner />
        </div>
        <div v-else>
            <form @submit.prevent="submitForm" class="space-y-4 md:space-y-6">
                <!-- Tipo de cuenta -->
                <div class="field">
                    <label class="block mb-2 md:mb-3 font-medium text-base md:text-lg">Tipo de Cuenta *</label>
                    <div class="flex justify-center">
                        <SelectButton v-model="accountForm.tipo" :options="accountTypes" optionLabel="label"
                            optionValue="value" :disabled="isEdit && !canChangeType" class="w-full">
                            <template #option="slotProps">
                                <div class="flex flex-col items-center gap-0.5 md:gap-1 p-0 min-w-0">
                                    <i :class="slotProps.option.icon" class="text-lg"></i>
                                    <span class="text-xs text-center leading-tight">{{ slotProps.option.label }}</span>
                                </div>
                            </template>
                        </SelectButton>
                    </div>
                </div>

                <!-- Nombre de la cuenta -->
                <div class="field">
                    <label for="accountName" class="block mb-2 font-medium">Nombre de la cuenta *</label>
                    <InputText id="accountName" v-model.trim="accountForm.nombre" class="w-full"
                        placeholder="Ej: Cuenta Nómina" :class="{ 'p-invalid': v$.nombre.$invalid && v$.nombre.$dirty }"
                        @blur="v$.nombre.$touch()" />
                    <small v-if="v$.nombre.$invalid && v$.nombre.$dirty" class="p-error block mt-1">
                        {{ v$.nombre.$errors[0].$message }}
                    </small>
                </div>

                <!-- Banco -->
                <div class="field">
                    <label for="accountBank" class="block mb-2 font-medium">Banco</label>
                    <Select id="accountBank" v-model="accountForm.banco_id" :options="bankOptions" optionLabel="label"
                        optionValue="value" class="w-full" placeholder="Seleccionar banco" :filter="true">
                        <template #value="slotProps">
                            <div v-if="slotProps.value" class="flex items-center">
                                <span v-if="getBankById(slotProps.value)?.color" class="w-3 h-3 rounded-full mr-2"
                                    :style="{ backgroundColor: getBankById(slotProps.value)?.color }"></span>
                                {{ getBankById(slotProps.value)?.name || slotProps.placeholder }}
                            </div>
                            <span v-else>{{ slotProps.placeholder }}</span>
                        </template>
                        <template #option="slotProps">
                            <div class="flex items-center">
                                <span v-if="getBankById(slotProps.option.value)?.color"
                                    class="w-3 h-3 rounded-full mr-2"
                                    :style="{ backgroundColor: getBankById(slotProps.option.value)?.color }"></span>
                                {{ slotProps.option.label }}
                            </div>
                        </template>
                    </Select>
                </div>

                <!-- Campos específicos según el tipo de cuenta -->
                <div class="space-y-6">
                    <!-- Tarjeta de Crédito -->
                    <div v-if="accountForm.tipo === 'credit_card'" class="space-y-3 md:space-y-4">
                        <!-- Últimos 4 dígitos -->
                        <div class="field">
                            <label for="lastFourDigits" class="block mb-2 font-medium">Últimos 4 dígitos</label>
                            <InputText id="lastFourDigits" v-model="accountForm.metadatos.last4" class="w-full"
                                placeholder="0000" maxlength="4" @input="formatLastFourDigits" />
                        </div>

                        <!-- Límite de crédito -->
                        <div class="field">
                            <label for="creditLimit" class="block mb-2 font-medium">Límite de crédito *</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.tarjeta_credito.limite_credito" :maxDigits="10"
                                    :showExpression="false" />
                            </div>
                            <small
                                v-if="v$.tarjeta_credito?.limite_credito?.$invalid && v$.tarjeta_credito?.limite_credito?.$dirty"
                                class="p-error block mt-1">
                                {{ v$.tarjeta_credito?.limite_credito?.$errors[0].$message }}
                            </small>
                        </div>

                        <!-- Crédito disponible -->
                        <div class="field">
                            <label for="availableCredit" class="block mb-2 font-medium">Crédito disponible *</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.tarjeta_credito.credito_disponible" :maxDigits="10"
                                    :showExpression="false" />
                            </div>
                            <small
                                v-if="v$.tarjeta_credito?.credito_disponible?.$invalid && v$.tarjeta_credito?.credito_disponible?.$dirty"
                                class="p-error block mt-1">
                                {{ v$.tarjeta_credito?.credito_disponible?.$errors[0].$message }}
                            </small>
                        </div>

                        <!-- Días de corte y pago -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">
                            <!-- Día de corte -->
                            <div class="field">
                                <label for="cutoffDay" class="block mb-2 font-medium">Día de corte *</label>
                                <InputNumber id="cutoffDay" v-model="accountForm.tarjeta_credito.dia_corte" :min="1"
                                    :max="31" class="w-full"
                                    :class="{ 'p-invalid': v$.tarjeta_credito?.dia_corte?.$invalid && v$.tarjeta_credito?.dia_corte?.$dirty }"
                                    @blur="v$.tarjeta_credito?.dia_corte?.$touch()" />
                                <small
                                    v-if="v$.tarjeta_credito?.dia_corte?.$invalid && v$.tarjeta_credito?.dia_corte?.$dirty"
                                    class="p-error block mt-1">
                                    {{ v$.tarjeta_credito?.dia_corte?.$errors[0].$message }}
                                </small>
                            </div>

                            <!-- Día de pago -->
                            <div class="field">
                                <label for="paymentDay" class="block mb-2 font-medium">Día de pago *</label>
                                <InputNumber id="paymentDay" v-model="accountForm.tarjeta_credito.dia_pago" :min="1"
                                    :max="31" class="w-full"
                                    :class="{ 'p-invalid': v$.tarjeta_credito?.dia_pago?.$invalid && v$.tarjeta_credito?.dia_pago?.$dirty }"
                                    @blur="v$.tarjeta_credito?.dia_pago?.$touch()" />
                                <small v-if="v$.tarjeta_credito?.dia_pago?.$invalid && v$.tarjeta_credito?.dia_pago?.$dirty"
                                    class="p-error block mt-1">
                                    {{ v$.tarjeta_credito?.dia_pago?.$errors[0].$message }}
                                </small>
                            </div>
                        </div>

                        <!-- CAT % y Anualidad -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">
                            <!-- CAT % -->
                            <div class="field">
                                <label for="catRate" class="block mb-2 font-medium">CAT %</label>
                                <InputNumber id="catRate" v-model="accountForm.tarjeta_credito.porcentaje_cat" :min="0"
                                    :max="500" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                    locale="en-US" suffix="%" placeholder="0.0%" class="w-full" />
                                <small class="text-xs text-surface-500">Costo Anual Total</small>
                            </div>

                            <!-- Anualidad -->
                            <div class="field">
                                <label for="annualFee" class="block mb-2 font-medium">Anualidad</label>
                                <div class="p-inputgroup">
                                    <BalanceInput v-model="accountForm.tarjeta_credito.anualidad" :maxDigits="10"
                                        :showExpression="false" />
                                </div>
                            </div>
                        </div>

                        <!-- Gasto para exención de anualidad -->
                        <div v-if="accountForm.tarjeta_credito.anualidad > 0" class="field">
                            <label for="annualFeeWaiver" class="block mb-2 font-medium">Gasto anual para exentar anualidad</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.tarjeta_credito.gasto_exencion_anualidad" :maxDigits="12"
                                    :showExpression="false" />
                            </div>
                            <small class="text-xs text-surface-500">Monto que debes gastar al año para no pagar anualidad</small>
                        </div>

                        <!-- Tasa de interés y Pago mínimo -->
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4">
                            <!-- Tasa de interés -->
                            <div class="field">
                                <label for="interestRate" class="block mb-2 font-medium">Tasa de interés anual</label>
                                <InputNumber id="interestRate" v-model="accountForm.tarjeta_credito.tasa_interes" :min="0"
                                    :max="99.99" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                    locale="en-US" suffix="%" placeholder="0.0%" class="w-full" />
                            </div>

                            <!-- Pago mínimo -->
                            <div class="field">
                                <label for="minPayment" class="block mb-2 font-medium">Pago mínimo %</label>
                                <InputNumber id="minPayment" v-model="accountForm.tarjeta_credito.porcentaje_pago_minimo" :min="0"
                                    :max="100" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                    locale="en-US" suffix="%" placeholder="5.0%" class="w-full" />
                                <small class="text-xs text-surface-500">Porcentaje del saldo a pagar mensualmente</small>
                            </div>
                        </div>

                        <!-- Días de gracia -->
                        <div class="field">
                            <label for="gracePeriod" class="block mb-2 font-medium">Días de gracia</label>
                            <InputNumber id="gracePeriod" v-model="accountForm.tarjeta_credito.dias_gracia" :min="0"
                                :max="60" class="w-full" />
                            <small class="text-xs text-surface-500">Días sin intereses después del corte si pagas el total</small>
                        </div>

                        <!-- Fechas calculadas automáticamente (solo lectura) -->
                        <div v-if="accountForm.tarjeta_credito.proxima_fecha_corte || accountForm.tarjeta_credito.proxima_fecha_pago" 
                            class="grid grid-cols-1 md:grid-cols-2 gap-3 md:gap-4 p-4 bg-surface-50 dark:bg-surface-800 rounded-lg border border-surface-200 dark:border-surface-700">
                            <!-- Próxima fecha de corte calculada -->
                            <div class="field mb-0">
                                <label class="block mb-2 font-medium text-sm">📅 Próxima fecha de corte</label>
                                <p class="text-base font-semibold text-primary">
                                    {{ accountForm.tarjeta_credito.proxima_fecha_corte ? 
                                        formatearFechaLocal(accountForm.tarjeta_credito.proxima_fecha_corte) : 'No calculada' }}
                                </p>
                            </div>

                            <!-- Próxima fecha de pago calculada -->
                            <div class="field mb-0">
                                <label class="block mb-2 font-medium text-sm">💳 Próxima fecha de pago</label>
                                <p class="text-base font-semibold text-primary">
                                    {{ accountForm.tarjeta_credito.proxima_fecha_pago ? 
                                        formatearFechaLocal(accountForm.tarjeta_credito.proxima_fecha_pago) : 'No calculada' }}
                                </p>
                            </div>
                        </div>

                        <!-- Puntos por peso -->
                        <div class="field">
                            <label for="rewardsPoints" class="block mb-2 font-medium">Puntos por peso gastado</label>
                            <InputNumber id="rewardsPoints" v-model="accountForm.tarjeta_credito.puntos_por_peso" :min="0"
                                :max="100" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                locale="en-US" placeholder="0.0" class="w-full" />
                            <small class="text-xs text-surface-500">Puntos de recompensa que acumulas por cada peso</small>
                        </div>

                        <!-- Notas adicionales -->
                        <div class="field">
                            <label for="notes" class="block mb-2 font-medium">Notas adicionales</label>
                            <Textarea id="notes" v-model="accountForm.tarjeta_credito.notas" rows="3"
                                placeholder="Promociones, beneficios especiales, MSI disponibles, etc." class="w-full" />
                            <small class="text-xs text-surface-500">Información sobre promociones, beneficios especiales, etc.</small>
                        </div>

                        <!-- Beneficios adicionales -->
                        <div class="field">
                            <label class="block mb-2 md:mb-3 font-medium">Beneficios adicionales</label>
                            <div class="grid grid-cols-1 md:grid-cols-2 gap-2 md:gap-3">
                                <div class="field-checkbox flex items-center">
                                    <Checkbox id="hasRewards" v-model="accountForm.metadatos.hasRewards"
                                        :binary="true" />
                                    <label for="hasRewards" class="ml-2">Programa de recompensas</label>
                                </div>
                                <div class="field-checkbox flex items-center">
                                    <Checkbox id="hasInsurance" v-model="accountForm.metadatos.hasInsurance"
                                        :binary="true" />
                                    <label for="hasInsurance" class="ml-2">Seguro incluido</label>
                                </div>
                                <div class="space-y-2">
                                    <div class="field-checkbox flex items-center">
                                        <Checkbox id="hasCashback" v-model="accountForm.metadatos.hasCashback"
                                            :binary="true" />
                                        <label for="hasCashback" class="ml-2">Cashback</label>
                                    </div>
                                    <div v-if="accountForm.metadatos.hasCashback" class="ml-6">
                                        <label for="cashbackPercentage"
                                            class="block mb-2 text-sm font-medium">Porcentaje de
                                            cashback</label>
                                        <InputNumber id="cashbackPercentage"
                                            v-model="accountForm.tarjeta_credito.porcentaje_cashback" :min="0"
                                            :max="100" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                            locale="en-US" suffix="%" placeholder="0.0%" class="w-full" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Tarjeta de débito -->
                    <div v-if="accountForm.tipo === 'debit_card'" class="space-y-3 md:space-y-4">
                        <!-- Últimos 4 dígitos -->
                        <div class="field">
                            <label for="lastFourDigits" class="block mb-2 font-medium">Últimos 4 dígitos</label>
                            <InputText id="lastFourDigits" v-model="accountForm.metadatos.last4" class="w-full"
                                placeholder="0000" maxlength="4" @input="formatLastFourDigits" />
                        </div>

                        <!-- Saldo actual -->
                        <div class="field">
                            <label for="balance" class="block mb-2 font-medium">Saldo actual *</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>

                    <!-- Cuenta bancaria -->
                    <div v-if="accountForm.tipo === 'bank'" class="space-y-3 md:space-y-4">
                        <!-- Número de cuenta (últimos 4 dígitos) -->
                        <div class="field">
                            <label for="accountNumber" class="block mb-2 font-medium">Últimos 4 dígitos</label>
                            <InputText id="accountNumber" v-model="accountForm.metadatos.last4" class="w-full"
                                placeholder="0000" maxlength="4" @input="formatLastFourDigits" />
                        </div>

                        <!-- Saldo actual -->
                        <div class="field">
                            <label for="balance" class="block mb-2 font-medium">Saldo actual *</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>

                    <!-- Efectivo -->
                    <div v-if="accountForm.tipo === 'cash'" class="space-y-3 md:space-y-4">
                        <!-- Ubicación -->
                        <div class="field">
                            <label for="location" class="block mb-2 font-medium">Ubicación</label>
                            <Select id="location" v-model="accountForm.metadatos.location"
                                :options="cashLocationOptions" optionLabel="label" optionValue="value" class="w-full"
                                placeholder="Seleccionar ubicación" />
                        </div>

                        <!-- Saldo actual -->
                        <div class="field">
                            <label for="balance" class="block mb-2 font-medium">Saldo actual *</label>
                            <div class="p-inputgroup">
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>
                </div>

                <!-- Botones de acción -->
                <div class="flex flex-col-reverse md:flex-row justify-end gap-2 md:gap-2 sticky md:static bottom-0 left-0 right-0 bg-surface-0 dark:bg-surface-900 p-3 md:p-0 -mx-2 md:mx-0 -mb-2 md:mb-0 border-t md:border-t-0 border-surface-200 dark:border-surface-700 md:border-none z-10">
                    <Button type="button" label="Cancelar" severity="secondary" outlined @click="cancelForm"
                        :disabled="isLoading || isSubmitting" class="w-full md:w-auto" />
                    <Button type="submit" :label="isEdit ? 'Actualizar' : 'Crear Cuenta'" :loading="isSubmitting"
                        :disabled="isLoading" class="w-full md:w-auto" />
                </div>
            </form>
        </div>
    </div>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minValue, helpers } from '@vuelidate/validators';
import { useToast } from 'primevue/usetoast';
import BalanceInput from '@/components/BalanceInput.vue';

// Props
const props = defineProps({
    isEdit: {
        type: Boolean,
        default: false
    },
    editAccountId: {
        type: String,
        default: null
    },
    accounts: {
        type: Array,
        default: () => []
    },
    banks: {
        type: Array,
        default: () => []
    },
    isLoading: {
        type: Boolean,
        default: false
    }
});

// Emits
const emit = defineEmits(['submit', 'cancel']);

// Composables
const toast = useToast();

// Estado del formulario
const isSubmitting = ref(false);
const canChangeType = ref(true);

// Opciones para selectores
const accountTypes = [
    { label: 'Efectivo', value: 'cash', icon: 'pi pi-dollar' },
    { label: 'Cuenta Bancaria', value: 'bank', icon: 'pi pi-building' },
    { label: 'Tarjeta de Débito', value: 'debit_card', icon: 'pi pi-credit-card' },
    { label: 'Tarjeta de Crédito', value: 'credit_card', icon: 'pi pi-credit-card' }
];

const cashLocationOptions = [
    { label: 'Cartera', value: 'wallet' },
    { label: 'Casa', value: 'home' },
    { label: 'Caja fuerte', value: 'safe' },
    { label: 'Otro', value: 'other' }
];

const bankOptions = computed(() => {
    return props.banks.map(bank => ({
        value: bank.id,
        label: bank.nombre,
        color: bank.color
    }));
});

// Valor por defecto del formulario
const defaultForm = {
    nombre: '',
    tipo: 'cash',
    banco_id: null,
    saldo: 0,
    metadatos: {
        last4: '',
        location: 'wallet',
        hasRewards: false,
        hasInsurance: false,
        hasCashback: false
    },
    tarjeta_credito: {
        limite_credito: 0,
        credito_disponible: 0,
        dia_corte: 1,
        dia_pago: 15,
        tasa_interes: null,
        porcentaje_pago_minimo: 5,
        proxima_fecha_pago: null,
        proxima_fecha_corte: null,
        porcentaje_cat: null,
        anualidad: 0,
        gasto_exencion_anualidad: null,
        porcentaje_cashback: null,
        puntos_por_peso: null,
        dias_gracia: null,
        notas: null
    }
};

const accountForm = ref({ ...defaultForm });

// Reglas de validación
const rules = computed(() => {
    const baseRules = {
        nombre: {
            required: helpers.withMessage('El nombre de la cuenta es obligatorio', required),
        },
        saldo: {
            required: helpers.withMessage('El saldo es obligatorio', required),
            minValue: helpers.withMessage('El saldo no puede ser negativo', minValue(0))
        }
    };

    // Reglas específicas para tarjetas de crédito
    if (accountForm.value.tipo === 'credit_card') {
        baseRules.tarjeta_credito = {
            limite_credito: {
                required: helpers.withMessage('El límite de crédito es obligatorio', required),
                minValue: helpers.withMessage('El límite de crédito debe ser mayor que cero', minValue(1))
            },
            credito_disponible: {
                required: helpers.withMessage('El crédito disponible es obligatorio', required),
                minValue: helpers.withMessage('El crédito disponible no puede ser negativo', minValue(0)),
            },
            dia_corte: {
                required: helpers.withMessage('El día de corte es obligatorio', required),
                minValue: helpers.withMessage('El día debe estar entre 1 y 31', minValue(1))
            },
            dia_pago: {
                required: helpers.withMessage('El día de pago es obligatorio', required),
                minValue: helpers.withMessage('El día debe estar entre 1 y 31', minValue(1))
            }
        };
    }

    return baseRules;
});

// Instancia de Vuelidate
const v$ = useVuelidate(rules, accountForm);

// Cargar datos si estamos en modo edición
const loadAccountData = async () => {
    if (props.isEdit && props.editAccountId) {
        const accountToEdit = props.accounts.find(acc => acc.id === props.editAccountId);

        if (accountToEdit) {
            console.log('📝 Cargando cuenta para editar:', accountToEdit);

            // Actualizar el formulario con los datos existentes
            accountForm.value = {
                nombre: accountToEdit.nombre,
                tipo: accountToEdit.tipo,
                banco_id: accountToEdit.banco_id,
                saldo: accountToEdit.saldo ?? 0,
                metadatos: {
                    ...defaultForm.metadatos,
                    ...accountToEdit.metadatos
                },
                tarjeta_credito: accountToEdit.tipo === 'credit_card' ? {
                    limite_credito: accountToEdit.limite_credito ?? 0,
                    credito_disponible: accountToEdit.credito_disponible ?? 0,
                    dia_corte: accountToEdit.dia_corte ?? 1,
                    dia_pago: accountToEdit.dia_pago ?? 15,
                    tasa_interes: accountToEdit.tasa_interes ?? null,
                    porcentaje_pago_minimo: accountToEdit.porcentaje_pago_minimo ?? 5,
                    proxima_fecha_pago: accountToEdit.proxima_fecha_pago ?? null,
                    proxima_fecha_corte: accountToEdit.proxima_fecha_corte ?? null,
                    porcentaje_cat: accountToEdit.porcentaje_cat ?? null,
                    anualidad: accountToEdit.anualidad ?? 0,
                    gasto_exencion_anualidad: accountToEdit.gasto_exencion_anualidad ?? null,
                    porcentaje_cashback: accountToEdit.porcentaje_cashback ?? null,
                    puntos_por_peso: accountToEdit.puntos_por_peso ?? null,
                    dias_gracia: accountToEdit.dias_gracia ?? null,
                    notas: accountToEdit.notas ?? null
                } : { ...defaultForm.tarjeta_credito }
            };

            console.log('📋 Datos cargados en formulario:', accountForm.value);

            // Si tiene información de cashback, actualizar el flag
            if (accountToEdit.porcentaje_cashback != null && accountToEdit.porcentaje_cashback > 0) {
                accountForm.value.metadatos.hasCashback = true;
            }
        }
    } else {
        // Resetear formulario para nueva cuenta
        accountForm.value = { ...defaultForm };
    }
};

// Método para manejar la validación y envío del formulario
const submitForm = async () => {
    // Limpiar validaciones anteriores
    v$.value.$reset();
    
    // Validar formulario
    const isValid = await v$.value.$validate();

    if (!isValid) {
        console.log('🚨 Errores de validación:', v$.value.$errors);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Por favor, corrige los errores del formulario',
            life: 3000
        });
        return;
    }

    try {
        isSubmitting.value = true;

        // Preparar los datos para envío
        const formData = {
            nombre: accountForm.value.nombre,
            tipo: accountForm.value.tipo,
            banco_id: accountForm.value.banco_id,
            saldo: parseFloat(accountForm.value.saldo),
            metadatos: { ...accountForm.value.metadatos }
        };

        // Si es tarjeta de crédito, incluir datos adicionales
        if (accountForm.value.tipo === 'credit_card') {
            // Convertir fechas a formato ISO (YYYY-MM-DD) para PostgreSQL usando fecha local
            const formatearFecha = (fecha) => {
                if (!fecha) return null;
                if (fecha instanceof Date) {
                    const year = fecha.getFullYear();
                    const month = String(fecha.getMonth() + 1).padStart(2, '0');
                    const day = String(fecha.getDate()).padStart(2, '0');
                    return `${year}-${month}-${day}`;
                }
                return fecha;
            };

            formData.tarjeta_credito = {
                limite_credito: parseFloat(accountForm.value.tarjeta_credito.limite_credito) || 0,
                credito_disponible: parseFloat(accountForm.value.tarjeta_credito.credito_disponible) || 0,
                dia_corte: parseInt(accountForm.value.tarjeta_credito.dia_corte) || 1,
                dia_pago: parseInt(accountForm.value.tarjeta_credito.dia_pago) || 15,
                tasa_interes: accountForm.value.tarjeta_credito.tasa_interes != null ? parseFloat(accountForm.value.tarjeta_credito.tasa_interes) : null,
                porcentaje_pago_minimo: accountForm.value.tarjeta_credito.porcentaje_pago_minimo != null ? parseFloat(accountForm.value.tarjeta_credito.porcentaje_pago_minimo) : null,
                proxima_fecha_pago: formatearFecha(accountForm.value.tarjeta_credito.proxima_fecha_pago),
                proxima_fecha_corte: formatearFecha(accountForm.value.tarjeta_credito.proxima_fecha_corte),
                porcentaje_cat: accountForm.value.tarjeta_credito.porcentaje_cat != null ? parseFloat(accountForm.value.tarjeta_credito.porcentaje_cat) : null,
                anualidad: parseFloat(accountForm.value.tarjeta_credito.anualidad) || 0,
                gasto_exencion_anualidad: accountForm.value.tarjeta_credito.gasto_exencion_anualidad != null ? parseFloat(accountForm.value.tarjeta_credito.gasto_exencion_anualidad) : null,
                porcentaje_cashback: accountForm.value.tarjeta_credito.porcentaje_cashback != null ? parseFloat(accountForm.value.tarjeta_credito.porcentaje_cashback) : null,
                puntos_por_peso: accountForm.value.tarjeta_credito.puntos_por_peso != null ? parseFloat(accountForm.value.tarjeta_credito.puntos_por_peso) : null,
                dias_gracia: accountForm.value.tarjeta_credito.dias_gracia != null ? parseInt(accountForm.value.tarjeta_credito.dias_gracia) : null,
                notas: accountForm.value.tarjeta_credito.notas?.trim() || null
            };

            console.log('📋 Datos de tarjeta de crédito a enviar:', formData.tarjeta_credito);
        }

        console.log('📤 Form data completo:', formData);

        // Enviar datos al componente padre
        emit('submit', {
            data: formData,
            isEdit: props.isEdit,
            accountId: props.editAccountId
        });

    } catch (error) {
        console.error('Error al enviar formulario:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: error.message || 'Error al procesar el formulario',
            life: 5000
        });
    } finally {
        isSubmitting.value = false;
    }
};

// Método para cancelar y cerrar el formulario
const cancelForm = () => {
    emit('cancel');
};

// Utilitarios
const getBankById = (id) => {
    const bank = props.banks.find(b => b.id === id);
    return bank ? { name: bank.nombre, color: bank.color } : null;
};

// Formatear los últimos 4 dígitos para que solo acepte números
const formatLastFourDigits = () => {
    if (accountForm.value.metadatos.last4) {
        // Eliminar caracteres no numéricos
        accountForm.value.metadatos.last4 = accountForm.value.metadatos.last4.replace(/\D/g, '');

        // Limitar a 4 dígitos
        if (accountForm.value.metadatos.last4.length > 4) {
            accountForm.value.metadatos.last4 = accountForm.value.metadatos.last4.slice(0, 4);
        }
    }
};

// Función para calcular la próxima fecha basada en un día del mes
const calcularProximaFecha = (diaDelMes) => {
    if (!diaDelMes || diaDelMes < 1 || diaDelMes > 31) return null;
    
    const hoy = new Date();
    const mesActual = hoy.getMonth();
    const añoActual = hoy.getFullYear();
    const diaActual = hoy.getDate();
    
    // Crear fecha con el día especificado en el mes actual a las 12:00 para evitar problemas de zona horaria
    let proximaFecha = new Date(añoActual, mesActual, diaDelMes, 12, 0, 0, 0);
    
    // Si la fecha ya pasó este mes, usar el siguiente mes
    if (proximaFecha <= hoy) {
        proximaFecha = new Date(añoActual, mesActual + 1, diaDelMes, 12, 0, 0, 0);
    }
    
    return proximaFecha;
};

// Función para calcular ambas fechas automáticamente considerando la relación corte-pago
const calcularFechasAutomaticas = () => {
    if (accountForm.value.tipo === 'credit_card') {
        const diaCorte = accountForm.value.tarjeta_credito.dia_corte;
        const diaPago = accountForm.value.tarjeta_credito.dia_pago;
        
        // Calcular próxima fecha de corte
        if (diaCorte) {
            accountForm.value.tarjeta_credito.proxima_fecha_corte = 
                calcularProximaFecha(diaCorte);
        }
        
        // Calcular próxima fecha de pago considerando la fecha de corte
        if (diaPago && diaCorte) {
            const fechaCorte = accountForm.value.tarjeta_credito.proxima_fecha_corte;
            
            if (fechaCorte) {
                const añoCorte = fechaCorte.getFullYear();
                const mesCorte = fechaCorte.getMonth();
                
                // Si el día de pago es menor que el día de corte, 
                // significa que el pago es en el mes siguiente al corte
                let fechaPago;
                if (diaPago < diaCorte) {
                    // Pago en el mes siguiente al corte
                    fechaPago = new Date(añoCorte, mesCorte + 1, diaPago, 12, 0, 0, 0);
                } else {
                    // Pago en el mismo mes que el corte
                    fechaPago = new Date(añoCorte, mesCorte, diaPago, 12, 0, 0, 0);
                }
                
                accountForm.value.tarjeta_credito.proxima_fecha_pago = fechaPago;
            }
        } else if (diaPago && !diaCorte) {
            // Si solo hay día de pago sin día de corte, usar el cálculo simple
            accountForm.value.tarjeta_credito.proxima_fecha_pago = 
                calcularProximaFecha(diaPago);
        }
    }
};

// Función para formatear fecha local para visualización
const formatearFechaLocal = (fecha) => {
    if (!fecha) return '';
    
    let dateObj;
    if (fecha instanceof Date) {
        dateObj = fecha;
    } else if (typeof fecha === 'string') {
        // Si es un string YYYY-MM-DD, parsearlo correctamente en zona local
        const [year, month, day] = fecha.split('-').map(Number);
        dateObj = new Date(year, month - 1, day);
    } else {
        return '';
    }
    
    return dateObj.toLocaleDateString('es-MX', { 
        day: '2-digit', 
        month: 'long', 
        year: 'numeric',
        timeZone: 'America/Mexico_City'
    });
};

// Watch para ajustar el crédito disponible si excede el límite de crédito
watch(() => accountForm.value.tarjeta_credito.limite_credito, (newLimit) => {
    if (accountForm.value.tipo === 'credit_card' &&
        accountForm.value.tarjeta_credito.credito_disponible > newLimit) {
        accountForm.value.tarjeta_credito.credito_disponible = newLimit;
    }
});

// Watch para recalcular fechas cuando cambia el día de corte
watch(() => accountForm.value.tarjeta_credito.dia_corte, (nuevoDia) => {
    if (accountForm.value.tipo === 'credit_card' && nuevoDia) {
        calcularFechasAutomaticas();
    }
});

// Watch para recalcular fechas cuando cambia el día de pago
watch(() => accountForm.value.tarjeta_credito.dia_pago, (nuevoDia) => {
    if (accountForm.value.tipo === 'credit_card' && nuevoDia) {
        calcularFechasAutomaticas();
    }
});

// Watch para resetear validaciones cuando cambia el tipo de cuenta
watch(() => accountForm.value.tipo, (newType, oldType) => {
    if (newType !== oldType) {
        // Resetear las validaciones
        v$.value.$reset();
        
        // Si cambia de credit_card a otro tipo, resetear datos de tarjeta
        if (oldType === 'credit_card' && newType !== 'credit_card') {
            accountForm.value.tarjeta_credito = { ...defaultForm.tarjeta_credito };
        }
    }
});

// Watch para resetear el formulario cuando cambian las props
watch(() => [props.isEdit, props.editAccountId], () => {
    loadAccountData();
}, { immediate: true });

// Ciclo de vida
onMounted(() => {
    loadAccountData();
});
</script>

<style scoped>
/* Estilos para el SelectButton personalizado */
:deep(.p-selectbutton) {
    width: 100%;
    display: grid;
    grid-template-columns: repeat(4, 1fr);
}

:deep(.p-selectbutton .p-button) {
    flex: 1;
    min-width: 0;
    padding: 0.75rem 0.5rem;
}

:deep(.p-selectbutton .p-button.p-highlight) {
    background: var(--primary-color);
    border-color: var(--primary-color);
    color: var(--primary-color-text);
}

:deep(.p-selectbutton .p-button:not(.p-highlight)) {
    background: var(--surface-100);
    border-color: var(--surface-300);
    color: var(--text-color-secondary);
}

:deep(.p-selectbutton .p-button:not(.p-highlight):hover) {
    background: var(--surface-200);
    border-color: var(--surface-400);
}

/* Responsive para dispositivos móviles */
@media (max-width: 767px) {
    :deep(.p-selectbutton) {
        grid-template-columns: repeat(2, 1fr);
        gap: 0.5rem;
    }

    :deep(.p-selectbutton .p-button) {
        padding: 0.625rem 0.5rem;
        font-size: 0.8125rem;
        border-radius: 0.5rem;
    }

    :deep(.p-selectbutton .p-button .p-button-icon) {
        font-size: 1.25rem;
    }

    /* Ajustar spacing del formulario en móvil */
    .field {
        margin-bottom: 0;
    }

    /* Labels más compactos */
    label {
        font-size: 0.875rem;
    }

    /* InputGroups más compactos */
    :deep(.p-inputgroup) {
        font-size: 0.875rem;
    }

    /* Badges más pequeños */
    :deep(.p-badge) {
        font-size: 0.6875rem;
        padding: 0.125rem 0.375rem;
    }
}
</style>