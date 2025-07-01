<template>
    <div class="space-y-6 min-h-[400px]">
        <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-surface-800 dark:text-surface-200">
                Configuración de Crédito
            </h3>
            <p class="text-sm text-surface-600 dark:text-surface-400 mt-1">
                Define los límites y fechas importantes de tu tarjeta
            </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Límite de crédito -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Límite de Crédito <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="accountForm.limite_credito" 
                             mode="currency" 
                             currency="MXN" 
                             locale="es-MX"
                             class="w-full" 
                             :class="{ 'p-invalid': formErrors.limite_credito }" 
                             :disabled="disabled" />
                <small v-if="formErrors.limite_credito" class="p-error">{{ formErrors.limite_credito }}</small>
            </div>

            <!-- Crédito disponible -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Crédito Disponible
                </label>
                <InputNumber v-model="accountForm.credito_disponible" 
                             mode="currency" 
                             currency="MXN"
                             locale="es-MX" 
                             class="w-full" 
                             :disabled="disabled" />
                <small class="text-xs text-surface-500">Si no se especifica, se usará el límite completo</small>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Día de pago -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Día de Pago <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="accountForm.dia_pago" 
                             :min="1" 
                             :max="31" 
                             class="w-full"
                             :class="{ 'p-invalid': formErrors.dia_pago }" 
                             :disabled="disabled" />
                <small v-if="formErrors.dia_pago" class="p-error">{{ formErrors.dia_pago }}</small>
            </div>

            <!-- Día de corte -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Día de Corte <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="accountForm.dia_corte" 
                             :min="1" 
                             :max="31" 
                             class="w-full"
                             :class="{ 'p-invalid': formErrors.dia_corte }" 
                             :disabled="disabled" />
                <small v-if="formErrors.dia_corte" class="p-error">{{ formErrors.dia_corte }}</small>
            </div>
        </div>

        <!-- Tasa de interés -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Tasa de Interés % (anual)
            </label>
            <InputNumber v-model="accountForm.tasa_interes" 
                         :min="0" 
                         :max="100" 
                         :maxFractionDigits="2"
                         suffix="%" 
                         class="w-full" 
                         :disabled="disabled" />
            <small class="text-xs text-surface-500">Para calcular intereses moratorios</small>
        </div>
    </div>
</template>

<script setup>
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
    disabled: {
        type: Boolean,
        default: false
    }
});
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}
</style>
