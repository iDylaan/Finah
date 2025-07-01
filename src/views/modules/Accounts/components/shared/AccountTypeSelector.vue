<template>
    <div>
        <label class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-3">
            Tipo de Cuenta <span class="text-red-500">*</span>
        </label>
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
            <Button v-for="type in accountTypes" :key="type.value" 
                    :label="type.label" 
                    :icon="type.icon"
                    :severity="modelValue === type.value ? 'primary' : 'secondary'"
                    :outlined="modelValue !== type.value" 
                    size="small" 
                    class="h-16 flex flex-col gap-1"
                    @click="$emit('update:modelValue', type.value)" 
                    type="button"
                    :disabled="disabled">
                <template #default>
                    <i :class="type.icon" class="text-lg mb-1"></i>
                    <span class="text-xs">{{ type.label }}</span>
                </template>
            </Button>
        </div>
    </div>
</template>

<script setup>
import { accountTypes } from '@/assets/constants/account-types';

// PROPS
defineProps({
    modelValue: {
        type: String,
        default: 'cash'
    },
    disabled: {
        type: Boolean,
        default: false
    }
});

// EMITS
defineEmits(['update:modelValue']);
</script>

<style lang="scss" scoped>
:deep(.p-button.h-16) {
    height: 4rem;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}
</style>
