<template>
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" class="w-full max-w-4xl" :draggable="false"
        :closable="!isSubmitting && !isLoadingAccountData" @hide="handleClose">

        <!-- Loading state mientras carga datos para editar -->
        <div v-if="isLoadingAccountData" class="flex justify-center items-center py-8">
            <ProgressSpinner size="small" />
            <span class="ml-3 text-surface-600">Cargando datos de la cuenta...</span>
        </div>

        <!-- Formulario -->
        <form v-else @submit.prevent="submitAccount" class="space-y-6">

            <!-- ✅ MODO CREACIÓN CON STEPPER PARA TARJETAS DE CRÉDITO -->
            <CreditCardStepperForm v-if="!isEditMode && accountForm.type === 'credit_card'" :account-form="accountForm"
                :form-errors="formErrors" :banks="banks" :banks-loading="banksLoading" :is-submitting="isSubmitting"
                :is-form-valid="isFormValid" :current-step-value="currentStepValue"
                :validate-and-proceed-to-step="stepperValidateAndProceed" :go-to-previous-step="stepperGoToPrevious"
                @submit="submitAccount" />

            <!-- ✅ MODO EDICIÓN CON TABS PARA TARJETAS DE CRÉDITO -->
            <CreditCardEditTabs v-else-if="isEditMode && accountForm.type === 'credit_card'" 
                :account-form="accountForm"
                :form-errors="formErrors" 
                :banks="banks" 
                :banks-loading="banksLoading"
                :disabled="isSubmitting"
                :is-submitting="isSubmitting" 
                :is-form-valid="isFormValid"
                :current-tab="currentEditTab"
                :name-placeholder="getNamePlaceholder()"
                @update:current-tab="setCurrentTab"
                @submit="submitAccount" 
                @cancel="handleClose" 
            />

            <!-- ✅ FORMULARIO INICIAL Y OTROS TIPOS DE CUENTA -->
            <div v-else class="space-y-6">
                <!-- Selector de tipo de cuenta -->
                <AccountTypeSelector v-model="accountForm.type" :disabled="isSubmitting"
                    @update:model-value="selectAccountType" />

                <!-- Formulario básico para otros tipos -->
                <BasicAccountForm v-if="accountForm.type !== 'credit_card' || isEditMode" :account-form="accountForm"
                    :form-errors="formErrors" :banks="banks" :banks-loading="banksLoading" :disabled="isSubmitting"
                    :is-submitting="isSubmitting" :is-form-valid="isFormValid" :is-edit-mode="isEditMode"
                    :needs-bank-selection="needsBankSelection" :name-placeholder="getNamePlaceholder()"
                    @submit="submitAccount" @cancel="handleClose" />
            </div>
        </form>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch, onMounted } from 'vue';
import { accountTypes, ACCOUNT_TYPES } from '@/assets/constants/account-types';

// COMPONENTES
import AccountTypeSelector from './shared/AccountTypeSelector.vue';
import BasicAccountForm from './forms/BasicAccountForm.vue';
import CreditCardStepperForm from './forms/CreditCardStepperForm.vue';
import CreditCardEditTabs from './tabs/CreditCardEditTabs.vue';

// COMPOSABLES
import { useAccountForm } from './composables/useAccountForm.js';
import { useFormValidation } from './composables/useFormValidation.js';
import { useCreditCardSteps } from './composables/useCreditCardSteps.js';

// PROPS
const props = defineProps({
    visible: {
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
    banksLoading: {
        type: Boolean,
        default: false
    }
});

// EMITS
const emit = defineEmits(['update:visible', 'submit', 'close']);

// USAR COMPOSABLES
const {
    accountForm,
    formErrors,
    isSubmitting,
    isLoadingAccountData,
    loadedAccountData,
    needsBankSelection,
    showCardFields,
    isCreditCard,
    resetForm,
    selectAccountType,
    getNamePlaceholder,
    loadAccountForEdit,
    prepareDataForSubmit
} = useAccountForm();

const {
    isFormValid,
    validateForm,
    canProceedFromStep1,
    canProceedFromStep2,
    validateStep
} = useFormValidation(accountForm, formErrors, needsBankSelection);

const {
    currentStepValue,
    currentEditTab,
    editTabs,
    validateAndProceedToStep,
    goToPreviousStep,
    resetSteps,
    setCurrentStep,
    setCurrentTab
} = useCreditCardSteps();

// COMPUTED LOCALES
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const isEditMode = computed(() => !!props.editAccountId);

const dialogTitle = computed(() => {
    if (isEditMode.value) {
        const account = loadedAccountData.value;
        return account ? `Editar ${account.name}` : 'Editar Cuenta';
    }

    if (accountForm.value.type === 'credit_card') {
        return 'Crear Tarjeta de Crédito';
    }

    return 'Crear Cuenta';
});

const selectedBank = computed(() => {
    return props.banks.find(bank => bank.id === accountForm.value.bank_id);
});

// FUNCIONES LOCALES
const initializeForm = () => {
    console.log('🔄 Inicializando formulario', {
        isEditMode: isEditMode.value,
        editAccountId: props.editAccountId
    });

    if (isEditMode.value && props.editAccountId) {
        // Modo edición - cargar datos de la cuenta
        const account = props.accounts.find(a => a.id === props.editAccountId);
        if (account) {
            loadAccountForEdit(account);

            // Si es tarjeta de crédito en modo edición, ir al primer tab
            if (account.type === 'credit_card') {
                setCurrentTab('general');
            }
        }
    } else {
        // Modo creación - resetear formulario
        resetForm();
        resetSteps();
    }
};

const submitAccount = async () => {
    console.log('📤 Enviando formulario...', {
        isEdit: isEditMode.value,
        accountId: props.editAccountId,
        formData: accountForm.value
    });

    if (!validateForm()) {
        console.warn('⚠️ Formulario no válido:', formErrors.value);
        return;
    }

    isSubmitting.value = true;

    try {
        const accountData = prepareDataForSubmit(isEditMode.value, props.editAccountId);

        console.log('📋 Datos finales a enviar:', {
            accountData,
            originalForm: accountForm.value,
            isEdit: isEditMode.value,
            accountId: props.editAccountId
        });

        // Emitir evento al componente padre
        emit('submit', {
            data: accountData,
            isEdit: isEditMode.value,
            accountId: isEditMode.value ? props.editAccountId : null,
            onSuccess: () => {
                console.log('✅ Operación exitosa');
                handleClose();
            },
            onError: (error) => {
                console.error('💥 Error en operación:', error);
            }
        });

    } catch (error) {
        console.error('💥 Error inesperado en submitAccount:', error);
    } finally {
        isSubmitting.value = false;
    }
};

const handleClose = () => {
    console.log('🚪 Cerrando formulario');
    resetForm();
    resetSteps();
    emit('close');
    emit('update:visible', false);
};

// FUNCIONES PARA STEPS (envueltas para pasar validaciones)
const validateAndProceedWithValidation = (targetStep, activateCallback) => {
    validateAndProceedToStep(targetStep, activateCallback, validateStep);
};

const goToPreviousStepWithReset = (targetStep, activateCallback) => {
    goToPreviousStep(targetStep, activateCallback, () => {
        formErrors.value = {};
    });
};

// WATCHERS
watch(() => props.visible, (newVisible) => {
    if (newVisible) {
        initializeForm();
    }
});

watch(() => props.editAccountId, () => {
    if (props.visible) {
        initializeForm();
    }
});

// Auto-llenar available_credit cuando cambie credit_limit
watch(() => accountForm.value.credit_limit, (newLimit) => {
    if (accountForm.value.type === 'credit_card' && !accountForm.value.available_credit) {
        accountForm.value.available_credit = newLimit;
    }
});

// LIFECYCLE
onMounted(() => {
    if (props.visible) {
        initializeForm();
    }
});

// EXPONER FUNCIONES ACTUALIZADAS PARA EL STEPPER
// Estas funciones se pasan a los componentes step para mantener las validaciones
const stepperValidateAndProceed = validateAndProceedWithValidation;
const stepperGoToPrevious = goToPreviousStepWithReset;
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}

:deep(.p-button.h-16) {
    height: 4rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

// Estilos específicos para el stepper
.credit-card-stepper {
    :deep(.p-stepper) {
        .p-stepper-header {
            padding: 1rem 0;
        }

        .p-stepper-content {
            padding: 1rem 0;
        }
    }
}

// Estilos para los tabs
.credit-card-edit {
    .tab-button {
        transition: all 0.2s ease;
    }
}
</style>
