<template>
    <div class="account-form">
        <div v-if="isLoading" class="flex justify-center py-6">
            <ProgressSpinner />
        </div>
        <div v-else class="account-form-content">
            <form @submit.prevent="submitForm">
                <!-- Tipo de cuenta -->
                <div class="field mb-4">
                    <span class="block mb-2 font-medium">Tipo de Cuenta</span>
                    <div class="flex flex-wrap gap-3">
                        <div v-for="type in accountTypes" :key="type.value" class="account-type-selector">
                            <RadioButton v-model="accountForm.tipo" :inputId="`type_${type.value}`" name="accountType"
                                :value="type.value" :disabled="isEdit && !canChangeType" />
                            <label :for="`type_${type.value}`" class="account-type-label ml-2">
                                <i :class="type.icon" class="mr-2"></i>
                                {{ type.label }}
                            </label>
                        </div>
                    </div>
                </div>

                <!-- Información básica -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                    <!-- Nombre -->
                    <div class="field">
                        <label for="accountName" class="block mb-2 font-medium">Nombre de la cuenta *</label>
                        <InputText id="accountName" v-model.trim="accountForm.nombre" class="w-full"
                            placeholder="Ej: Cuenta Nómina"
                            :class="{ 'p-invalid': v$.nombre.$invalid && v$.nombre.$dirty }"
                            @blur="v$.nombre.$touch()" />
                        <small v-if="v$.nombre.$invalid && v$.nombre.$dirty" class="p-error block mt-1">
                            {{ v$.nombre.$errors[0].$message }}
                        </small>
                    </div>

                    <!-- Banco -->
                    <div class="field">
                        <label for="accountBank" class="block mb-2 font-medium">Banco</label>
                        <Dropdown id="accountBank" v-model="accountForm.banco_id" :options="bankOptions"
                            optionLabel="label" optionValue="value" class="w-full" placeholder="Seleccionar banco"
                            :filter="true">
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
                                    <span v-if="slotProps.option.color" class="w-3 h-3 rounded-full mr-2"
                                        :style="{ backgroundColor: slotProps.option.color }"></span>
                                    {{ slotProps.option.label }}
                                </div>
                            </template>
                        </Dropdown>
                    </div>
                </div>

                <!-- Campos específicos según el tipo de cuenta -->
                <div class="mb-4">
                    <!-- Tarjeta de Crédito -->
                    <div v-if="accountForm.tipo === 'credit_card'" class="space-y-4">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
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
                                    <span class="p-inputgroup-addon">$</span>
                                    <BalanceInput v-model="accountForm.tarjeta_credito.limite_credito" :maxDigits="10"
                                        :showExpression="false" />
                                </div>
                                <small
                                    v-if="v$.tarjeta_credito?.limite_credito?.$invalid && v$.tarjeta_credito?.limite_credito?.$dirty"
                                    class="p-error block mt-1">
                                    El límite de crédito es obligatorio y debe ser mayor a cero
                                </small>
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                            <!-- Día de corte -->
                            <div class="field">
                                <label for="cutoffDay" class="block mb-2 font-medium">Día de corte *</label>
                                <InputNumber id="cutoffDay" v-model="accountForm.tarjeta_credito.dia_corte"
                                    class="w-full" :min="1" :max="31" showButtons
                                    :class="{ 'p-invalid': v$.tarjeta_credito?.dia_corte?.$invalid && v$.tarjeta_credito?.dia_corte?.$dirty }"
                                    @blur="v$.tarjeta_credito?.dia_corte?.$touch()" />
                                <small
                                    v-if="v$.tarjeta_credito?.dia_corte?.$invalid && v$.tarjeta_credito?.dia_corte?.$dirty"
                                    class="p-error block mt-1">
                                    Debe ser un día del mes válido (1-31)
                                </small>
                            </div>

                            <!-- Día de pago -->
                            <div class="field">
                                <label for="paymentDay" class="block mb-2 font-medium">Día de pago *</label>
                                <InputNumber id="paymentDay" v-model="accountForm.tarjeta_credito.dia_pago"
                                    class="w-full" :min="1" :max="31" showButtons
                                    :class="{ 'p-invalid': v$.tarjeta_credito?.dia_pago?.$invalid && v$.tarjeta_credito?.dia_pago?.$dirty }"
                                    @blur="v$.tarjeta_credito?.dia_pago?.$touch()" />
                                <small
                                    v-if="v$.tarjeta_credito?.dia_pago?.$invalid && v$.tarjeta_credito?.dia_pago?.$dirty"
                                    class="p-error block mt-1">
                                    Debe ser un día del mes válido (1-31)
                                </small>
                            </div>

                            <!-- CAT % -->
                            <div class="field">
                                <label for="catRate" class="block mb-2 font-medium">CAT %</label>
                                <InputNumber id="catRate" v-model="accountForm.tarjeta_credito.porcentaje_cat"
                                    class="w-full" :min="0" :max="200" suffix="%" :minFractionDigits="2" />
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                            <!-- Crédito disponible -->
                            <div class="field">
                                <label for="availableCredit" class="block mb-2 font-medium">Crédito disponible *</label>
                                <div class="p-inputgroup">
                                    <span class="p-inputgroup-addon">$</span>
                                    <BalanceInput v-model="accountForm.tarjeta_credito.credito_disponible"
                                        :maxDigits="10" :showExpression="false" />
                                </div>
                                <small
                                    v-if="v$.tarjeta_credito?.credito_disponible?.$invalid && v$.tarjeta_credito?.credito_disponible?.$dirty"
                                    class="p-error block mt-1">
                                    El crédito disponible es obligatorio y debe ser mayor o igual a cero
                                </small>
                            </div>

                            <!-- Anualidad -->
                            <div class="field">
                                <label for="annualFee" class="block mb-2 font-medium">Anualidad</label>
                                <div class="p-inputgroup">
                                    <span class="p-inputgroup-addon">$</span>
                                    <BalanceInput v-model="accountForm.tarjeta_credito.anualidad" :maxDigits="8"
                                        :showExpression="false" />
                                </div>
                            </div>
                        </div>

                        <!-- Beneficios adicionales -->
                        <div class="field">
                            <label class="block mb-2 font-medium">Beneficios adicionales</label>
                            <div class="flex flex-wrap gap-4">
                                <div class="field-checkbox">
                                    <Checkbox v-model="accountForm.metadatos.hasInsurance" :binary="true"
                                        inputId="hasInsurance" />
                                    <label for="hasInsurance" class="ml-2">Seguro de compras</label>
                                </div>
                                <div class="field-checkbox">
                                    <Checkbox v-model="accountForm.metadatos.hasRewards" :binary="true"
                                        inputId="hasRewards" />
                                    <label for="hasRewards" class="ml-2">Programa de puntos</label>
                                </div>
                                <div class="flex items-center gap-2">
                                    <Checkbox v-model="accountForm.metadatos.hasCashback" :binary="true"
                                        inputId="hasCashback" />
                                    <label for="hasCashback" class="mr-2">Cashback</label>
                                    <InputNumber v-if="accountForm.metadatos.hasCashback"
                                        v-model="accountForm.tarjeta_credito.porcentaje_cashback" class="w-24" :min="0"
                                        :max="100" suffix="%" :minFractionDigits="2" />
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Tarjeta de débito -->
                    <div v-if="accountForm.tipo === 'debit_card'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                                <span class="p-inputgroup-addon">$</span>
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>

                    <!-- Cuenta bancaria -->
                    <div v-if="accountForm.tipo === 'bank'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
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
                                <span class="p-inputgroup-addon">$</span>
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>

                    <!-- Efectivo -->
                    <div v-if="accountForm.tipo === 'cash'" class="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <!-- Ubicación -->
                        <div class="field">
                            <label for="location" class="block mb-2 font-medium">Ubicación</label>
                            <Dropdown id="location" v-model="accountForm.metadatos.location"
                                :options="cashLocationOptions" optionLabel="label" optionValue="value" class="w-full"
                                placeholder="Seleccionar ubicación" />
                        </div>

                        <!-- Saldo actual -->
                        <div class="field">
                            <label for="balance" class="block mb-2 font-medium">Saldo actual *</label>
                            <div class="p-inputgroup">
                                <span class="p-inputgroup-addon">$</span>
                                <BalanceInput v-model="accountForm.saldo" :maxDigits="10" :showExpression="false" />
                            </div>
                            <small v-if="v$.saldo.$invalid && v$.saldo.$dirty" class="p-error block mt-1">
                                {{ v$.saldo.$errors[0].$message }}
                            </small>
                        </div>
                    </div>
                </div>

                <!-- Botones de acción -->
                <div class="flex justify-end gap-2 pt-4 border-t border-surface-200 dark:border-surface-700">
                    <Button type="button" label="Cancelar" class="p-button-secondary p-button-outlined"
                        @click="cancelForm" :disabled="isLoading" />
                    <Button type="submit" :label="isEdit ? 'Actualizar' : 'Guardar'" :loading="isSubmitting"
                        :disabled="isLoading" />
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
import ProgressSpinner from 'primevue/progressspinner';
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
import InputNumber from 'primevue/inputnumber';
import Dropdown from 'primevue/dropdown';
import RadioButton from 'primevue/radiobutton';
import Checkbox from 'primevue/checkbox';

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
            canChangeType.value = !accountToEdit.tarjeta_credito; // No permitir cambiar si es tarjeta de crédito

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

// Ciclo de vida
onMounted(() => {
    loadAccountData();
});
</script>

<style scoped>
.account-type-selector {
    display: flex;
    align-items: center;
}

.account-type-label {
    display: flex;
    align-items: center;
    cursor: pointer;
}
</style>