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
                                    :max="100" mode="decimal" :minFractionDigits="1" :maxFractionDigits="2"
                                    class="w-full" />
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
                                            suffix="%" placeholder="0.0%" class="w-full" />
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
        porcentaje_cat: 0,
        porcentaje_cashback: 0,
        anualidad: 0
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
            // Determinar si podemos cambiar el tipo
            canChangeType.value = !accountToEdit.tarjeta_credito;

            // Actualizar el formulario con los datos existentes
            accountForm.value = {
                nombre: accountToEdit.nombre,
                tipo: accountToEdit.tipo,
                banco_id: accountToEdit.banco_id,
                saldo: accountToEdit.saldo || 0,
                metadatos: {
                    ...defaultForm.metadatos,
                    ...accountToEdit.metadatos
                },
                tarjeta_credito: accountToEdit.tarjeta_credito ? {
                    limite_credito: accountToEdit.tarjeta_credito.limite_credito || 0,
                    credito_disponible: accountToEdit.tarjeta_credito.credito_disponible || 0,
                    dia_corte: accountToEdit.tarjeta_credito.dia_corte || 1,
                    dia_pago: accountToEdit.tarjeta_credito.dia_pago || 15,
                    porcentaje_cat: accountToEdit.tarjeta_credito.porcentaje_cat || 0,
                    porcentaje_cashback: accountToEdit.tarjeta_credito.porcentaje_cashback || 0,
                    anualidad: accountToEdit.tarjeta_credito.anualidad || 0
                } : { ...defaultForm.tarjeta_credito }
            };

            // Si tiene información de cashback, actualizar el flag
            if (accountToEdit.tarjeta_credito?.porcentaje_cashback > 0) {
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
    // Validar formulario
    const isValid = await v$.value.$validate();

    if (!isValid) {
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
            formData.tarjeta_credito = {
                limite_credito: parseFloat(accountForm.value.tarjeta_credito.limite_credito),
                credito_disponible: parseFloat(accountForm.value.tarjeta_credito.credito_disponible),
                dia_corte: accountForm.value.tarjeta_credito.dia_corte,
                dia_pago: accountForm.value.tarjeta_credito.dia_pago,
                porcentaje_cat: accountForm.value.tarjeta_credito.porcentaje_cat || 0,
                anualidad: parseFloat(accountForm.value.tarjeta_credito.anualidad) || 0
            };

            // Solo incluir porcentaje de cashback si está habilitado
            if (accountForm.value.metadatos.hasCashback) {
                formData.tarjeta_credito.porcentaje_cashback = accountForm.value.tarjeta_credito.porcentaje_cashback || 0;
            }
        }

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

// Watch para ajustar el crédito disponible si excede el límite de crédito
watch(() => accountForm.value.tarjeta_credito.limite_credito, (newLimit) => {
    if (accountForm.value.tipo === 'credit_card' &&
        accountForm.value.tarjeta_credito.credito_disponible > newLimit) {
        accountForm.value.tarjeta_credito.credito_disponible = newLimit;
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