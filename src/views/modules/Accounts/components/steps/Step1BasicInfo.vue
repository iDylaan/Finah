<template>
    <div class="space-y-6 min-h-[400px]">
        <div class="text-center mb-6">
            <h3 class="text-lg font-semibold text-surface-800 dark:text-surface-200">
                Información Básica de la Cuenta
            </h3>
            <p class="text-sm text-surface-600 dark:text-surface-400 mt-1">
                Configuremos los datos generales de tu tarjeta de crédito
            </p>
        </div>

        <!-- Banco (requerido) -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Banco <span class="text-red-500">*</span>
            </label>
            <Select v-model="accountForm.bank_id" 
                    :options="banks" 
                    option-label="name" 
                    option-value="id"
                    placeholder="Selecciona un banco" 
                    class="w-full" 
                    :loading="banksLoading"
                    :class="{ 'p-invalid': formErrors.bank_id }"
                    :disabled="disabled">
                <template #option="{ option }">
                    <div class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded flex items-center justify-center"
                            :style="{ backgroundColor: option.color || '#6366f1' }">
                            <i v-if="option.icon_library === 'primevue'" :class="option.icon_name"
                                class="text-white text-xs"></i>
                            <span v-else class="material-symbols-outlined text-white !text-[17px]">
                                {{ option.icon_name }}
                            </span>
                        </div>
                        <span>{{ option.name }}</span>
                    </div>
                </template>
                <template #value="{ value }">
                    <div v-if="value" class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded flex items-center justify-center"
                            :style="{ backgroundColor: selectedBank?.color || '#6366f1' }">
                            <i v-if="selectedBank?.icon_library === 'primevue'" :class="selectedBank?.icon_name"
                                class="text-white text-xs"></i>
                            <span v-else class="material-symbols-outlined text-white !text-[17px]">
                                {{ selectedBank?.icon_name }}
                            </span>
                        </div>
                        <span>{{ selectedBank?.name }}</span>
                    </div>
                    <span v-else class="text-surface-500">Selecciona un banco</span>
                </template>
            </Select>
            <small v-if="formErrors.bank_id" class="p-error">{{ formErrors.bank_id }}</small>
        </div>

        <!-- Nombre de la cuenta -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Nombre de la Cuenta <span class="text-red-500">*</span>
            </label>
            <InputText v-model="accountForm.name" 
                       placeholder="Ej: Tarjeta BBVA Oro" 
                       class="w-full"
                       :class="{ 'p-invalid': formErrors.name }" 
                       :disabled="disabled" />
            <small v-if="formErrors.name" class="p-error">{{ formErrors.name }}</small>
        </div>

        <!-- Nombre de la tarjeta -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Nombre de la Tarjeta
            </label>
            <InputText v-model="accountForm.card_name" 
                       placeholder="BBVA Oro, Santander Free, etc."
                       class="w-full" 
                       :disabled="disabled" />
            <small class="text-xs text-surface-500">Si no se especifica, usará el nombre de la cuenta</small>
        </div>

        <!-- Últimos 4 dígitos -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Últimos 4 dígitos
            </label>
            <InputText v-model="accountForm.last_four_digits" 
                       placeholder="1234" 
                       maxlength="4" 
                       class="w-full"
                       :disabled="disabled" />
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';

// PROPS
const props = defineProps({
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
    disabled: {
        type: Boolean,
        default: false
    }
});

// COMPUTED
const selectedBank = computed(() => {
    return props.banks.find(bank => bank.id === props.accountForm.bank_id);
});
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}
</style>
