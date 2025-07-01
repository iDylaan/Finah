<template>
    <div class="credit-card-stepper">
        <Stepper :value="currentStepValue" class="basis-full">
            <StepList>
                <Step value="1">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-info-circle"></i>
                        <span>Información Básica</span>
                    </div>
                </Step>
                <Step value="2">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-credit-card"></i>
                        <span>Configuración Crédito</span>
                    </div>
                </Step>
                <Step value="3">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-dollar"></i>
                        <span>Costos y Tarifas</span>
                    </div>
                </Step>
                <Step value="4">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-star"></i>
                        <span>Beneficios</span>
                    </div>
                </Step>
            </StepList>

            <StepPanels>
                <!-- STEP 1: Información Básica -->
                <StepPanel v-slot="{ activateCallback }" value="1">
                    <Step1BasicInfo 
                        :account-form="accountForm"
                        :form-errors="formErrors"
                        :banks="banks"
                        :banks-loading="banksLoading"
                        :disabled="isSubmitting" />

                    <div class="flex pt-6 justify-end">
                        <Button label="Siguiente" 
                                icon="pi pi-arrow-right" 
                                iconPos="right" 
                                @click="validateAndProceedToStep('2', activateCallback)" 
                                :disabled="isSubmitting" />
                    </div>
                </StepPanel>

                <!-- STEP 2: Configuración de Crédito -->
                <StepPanel v-slot="{ activateCallback }" value="2">
                    <Step2CreditConfig 
                        :account-form="accountForm"
                        :form-errors="formErrors"
                        :disabled="isSubmitting" />

                    <div class="flex pt-6 justify-between">
                        <Button label="Anterior" 
                                severity="secondary" 
                                icon="pi pi-arrow-left" 
                                @click="goToPreviousStep('1', activateCallback)"
                                :disabled="isSubmitting" />
                        <Button label="Siguiente" 
                                icon="pi pi-arrow-right" 
                                iconPos="right" 
                                @click="validateAndProceedToStep('3', activateCallback)"
                                :disabled="isSubmitting" />
                    </div>
                </StepPanel>

                <!-- STEP 3: Costos y Tarifas (Opcional) -->
                <StepPanel v-slot="{ activateCallback }" value="3">
                    <Step3CostsAndFees 
                        :account-form="accountForm"
                        :disabled="isSubmitting" />

                    <div class="flex pt-6 justify-between">
                        <Button label="Anterior" 
                                severity="secondary" 
                                icon="pi pi-arrow-left" 
                                @click="goToPreviousStep('2', activateCallback)"
                                :disabled="isSubmitting" />
                        <Button label="Siguiente" 
                                icon="pi pi-arrow-right" 
                                iconPos="right" 
                                @click="activateCallback('4')"
                                :disabled="isSubmitting" />
                    </div>
                </StepPanel>

                <!-- STEP 4: Beneficios y Recompensas (Opcional) -->
                <StepPanel v-slot="{ activateCallback }" value="4">
                    <Step4Benefits 
                        :account-form="accountForm"
                        :disabled="isSubmitting" />

                    <div class="flex pt-6 justify-between">
                        <Button label="Anterior" 
                                severity="secondary" 
                                icon="pi pi-arrow-left" 
                                @click="goToPreviousStep('3', activateCallback)"
                                :disabled="isSubmitting" />
                        <Button label="Crear Cuenta" 
                                severity="success" 
                                icon="pi pi-plus" 
                                @click="$emit('submit')" 
                                :loading="isSubmitting"
                                :disabled="!isFormValid" />
                    </div>
                </StepPanel>
            </StepPanels>
        </Stepper>
    </div>
</template>

<script setup>
// IMPORTS
import Step1BasicInfo from '../steps/Step1BasicInfo.vue';
import Step2CreditConfig from '../steps/Step2CreditConfig.vue';
import Step3CostsAndFees from '../steps/Step3CostsAndFees.vue';
import Step4Benefits from '../steps/Step4Benefits.vue';

// PROPS
defineProps({
    accountForm: {
        type: Object,
        required: true
    },
    formErrors: {
        type: Object,
        default: () => ({})
    },
    banks: {
        type: Array,
        default: () => []
    },
    banksLoading: {
        type: Boolean,
        default: false
    },
    isSubmitting: {
        type: Boolean,
        default: false
    },
    isFormValid: {
        type: Boolean,
        default: false
    },
    currentStepValue: {
        type: String,
        required: true
    },
    validateAndProceedToStep: {
        type: Function,
        required: true
    },
    goToPreviousStep: {
        type: Function,
        required: true
    }
});

// EMITS
defineEmits(['submit']);
</script>

<style lang="scss" scoped>
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
</style>
