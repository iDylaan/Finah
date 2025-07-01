<template>
    <div class="space-y-6">
        <!-- Selector de banco (si es necesario) -->
        <div v-if="needsBankSelection">
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Banco <span class="text-red-500">*</span>
            </label>
            <Select v-model="accountForm.banco_id" 
                    :options="banks" 
                    option-label="nombre" 
                    option-value="id"
                    placeholder="Selecciona un banco" 
                    class="w-full" 
                    :loading="banksLoading"
                    :class="{ 'p-invalid': formErrors.banco_id }"
                    :disabled="disabled">
                <template #option="{ option }">
                    <div class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded flex items-center justify-center"
                            :style="{ backgroundColor: option.color || '#6366f1' }">
                            <i v-if="option.libreria_icono === 'primevue'" :class="option.nombre_icono"
                                class="text-white text-xs"></i>
                            <span v-else class="material-symbols-outlined text-white !text-[17px]">
                                {{ option.nombre_icono }}
                            </span>
                        </div>
                        <span>{{ option.nombre }}</span>
                    </div>
                </template>
                <template #value="{ value }">
                    <div v-if="value" class="flex items-center gap-2">
                        <div class="w-6 h-6 rounded flex items-center justify-center"
                            :style="{ backgroundColor: selectedBank?.color || '#6366f1' }">
                            <i v-if="selectedBank?.libreria_icono === 'primevue'" :class="selectedBank?.nombre_icono"
                                class="text-white text-xs"></i>
                            <span v-else class="material-symbols-outlined text-white !text-[17px]">
                                {{ selectedBank?.nombre_icono }}
                            </span>
                        </div>
                        <span>{{ selectedBank?.nombre }}</span>
                    </div>
                    <span v-else class="text-surface-500">Selecciona un banco</span>
                </template>
            </Select>
            <small v-if="formErrors.banco_id" class="p-error">{{ formErrors.banco_id }}</small>
        </div>

        <!-- Nombre de la cuenta -->
        <div>
            <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                Nombre de la Cuenta <span class="text-red-500">*</span>
            </label>
            <InputText v-model="accountForm.nombre" 
                       :placeholder="namePlaceholder" 
                       class="w-full"
                       :class="{ 'p-invalid': formErrors.nombre }" 
                       :disabled="disabled" />
            <small v-if="formErrors.nombre" class="p-error">{{ formErrors.nombre }}</small>
        </div>

        <!-- Grid para campos específicos -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <!-- Últimos 4 dígitos (para tarjetas de débito) -->
            <div v-if="accountForm.tipo === 'debit_card'">
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Últimos 4 dígitos
                </label>
                <InputText v-model="accountForm.last_four_digits" 
                           placeholder="1234" 
                           maxlength="4" 
                           class="w-full"
                           :disabled="disabled" />
            </div>

            <!-- Número de cuenta (para cuentas bancarias) -->
            <div v-if="accountForm.tipo === 'bank'">
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Número de Cuenta (opcional)
                </label>
                <InputText v-model="accountForm.account_number" 
                           placeholder="01234567890" 
                           class="w-full"
                           :disabled="disabled" />
            </div>

            <!-- Saldo inicial -->
            <div>
                <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    {{ isEditMode ? 'Saldo Actual' : 'Saldo Inicial' }}
                </label>
                <InputNumber v-model="accountForm.balance" 
                             mode="currency" 
                             currency="MXN" 
                             locale="es-MX"
                             class="w-full" 
                             :disabled="disabled" />
            </div>
        </div>

        <!-- Botones para formulario simple -->
        <div class="flex justify-end gap-2 pt-4">
            <Button label="Cancelar" 
                    severity="secondary" 
                    outlined 
                    @click="$emit('cancel')"
                    :disabled="disabled" />
            <Button :label="isEditMode ? 'Actualizar Cuenta' : 'Crear Cuenta'" 
                    severity="success" 
                    @click="$emit('submit')" 
                    :loading="isSubmitting" 
                    :disabled="!isFormValid"
                    :icon="isEditMode ? 'pi pi-check' : 'pi pi-plus'" />
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
    },
    isSubmitting: {
        type: Boolean,
        default: false
    },
    isFormValid: {
        type: Boolean,
        default: false
    },
    isEditMode: {
        type: Boolean,
        default: false
    },
    needsBankSelection: {
        type: Boolean,
        default: false
    },
    namePlaceholder: {
        type: String,
        default: 'Ej: Mi cuenta'
    }
});

// EMITS
defineEmits(['submit', 'cancel']);

// COMPUTED
const selectedBank = computed(() => {
    return props.banks.find(bank => bank.id === props.accountForm.banco_id);
});
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}
</style>
