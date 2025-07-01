<template>
    <div class="space-y-6 min-h-[400px]">
        <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-surface-800 dark:text-surface-200">
                Beneficios y Recompensas
            </h3>
            <p class="text-sm text-surface-600 dark:text-surface-400 mt-1">
                Configura los beneficios que ofrece tu tarjeta
            </p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Cashback -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Cashback %
                </label>
                <InputNumber v-model="accountForm.cashback_percentage" 
                             :min="0" 
                             :max="20"
                             :maxFractionDigits="2" 
                             suffix="%" 
                             class="w-full" 
                             :disabled="disabled" />
            </div>

            <!-- Puntos por peso -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Puntos por Peso
                </label>
                <InputNumber v-model="accountForm.rewards_points_ratio" 
                             :min="0" 
                             :max="100"
                             :maxFractionDigits="2" 
                             class="w-full" 
                             :disabled="disabled" />
            </div>
        </div>

        <!-- Notas y beneficios adicionales -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Notas y Beneficios Adicionales
            </label>
            <Textarea v-model="accountForm.notes"
                      placeholder="Ej: Promociones especiales, seguros incluidos, acceso a salas VIP, etc."
                      rows="4" 
                      class="w-full" 
                      :disabled="disabled" />
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
