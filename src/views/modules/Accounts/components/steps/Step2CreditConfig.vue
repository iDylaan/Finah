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
                <InputNumber v-model="accountForm.credit_limit" 
                             mode="currency" 
                             currency="MXN" 
                             locale="es-MX"
                             class="w-full" 
                             :class="{ 'p-invalid': formErrors.credit_limit }" 
                             :disabled="disabled" />
                <small v-if="formErrors.credit_limit" class="p-error">{{ formErrors.credit_limit }}</small>
            </div>

            <!-- Crédito disponible -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Crédito Disponible
                </label>
                <InputNumber v-model="accountForm.available_credit" 
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
                <InputNumber v-model="accountForm.payment_day" 
                             :min="1" 
                             :max="31" 
                             class="w-full"
                             :class="{ 'p-invalid': formErrors.payment_day }" 
                             :disabled="disabled" />
                <small v-if="formErrors.payment_day" class="p-error">{{ formErrors.payment_day }}</small>
            </div>

            <!-- Día de corte -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Día de Corte <span class="text-red-500">*</span>
                </label>
                <InputNumber v-model="accountForm.cutoff_day" 
                             :min="1" 
                             :max="31" 
                             class="w-full"
                             :class="{ 'p-invalid': formErrors.cutoff_day }" 
                             :disabled="disabled" />
                <small v-if="formErrors.cutoff_day" class="p-error">{{ formErrors.cutoff_day }}</small>
            </div>
        </div>

        <!-- Tasa de interés -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Tasa de Interés % (anual)
            </label>
            <InputNumber v-model="accountForm.interest_rate" 
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
