<template>
    <div class="space-y-6 min-h-[400px]">
        <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-surface-800 dark:text-surface-200">
                Información Financiera Avanzada
            </h3>
            <p class="text-sm text-surface-600 dark:text-surface-400 mt-1">
                Estos campos son opcionales pero te ayudarán a tener un mejor control
            </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- CAT -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    CAT (Costo Anual Total) %
                </label>
                <InputNumber v-model="accountForm.cat_percentage" 
                             :min="0" 
                             :max="500"
                             :maxFractionDigits="2" 
                             suffix="%" 
                             class="w-full" 
                             :disabled="disabled" />
                <small class="text-xs text-surface-500">Incluye todos los costos</small>
            </div>

            <!-- Anualidad -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Anualidad
                </label>
                <InputNumber v-model="accountForm.annual_fee" 
                             mode="currency" 
                             currency="MXN"
                             locale="es-MX" 
                             class="w-full" 
                             :disabled="disabled" />
                <small class="text-xs text-surface-500">0 = sin anualidad</small>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Gasto para exentar anualidad -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Gasto para Exentar Anualidad
                </label>
                <InputNumber v-model="accountForm.annual_fee_waiver_spending" 
                             mode="currency"
                             currency="MXN" 
                             locale="es-MX" 
                             class="w-full" 
                             :disabled="disabled" />
            </div>

            <!-- Días de gracia -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Días de Gracia
                </label>
                <InputNumber v-model="accountForm.grace_period_days" 
                             :min="0" 
                             :max="60" 
                             class="w-full"
                             :disabled="disabled" />
                <small class="text-xs text-surface-500">Típicamente 20-25 días</small>
            </div>
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
    disabled: {
        type: Boolean,
        default: false
    }
});
</script>
