<template>
    <Dialog v-model:visible="isVisible" :header="isEdit ? 'Editar Cuenta' : 'Nueva Cuenta'" modal :closable="true"
        :draggable="false" :resizable="false" class="w-auto max-w-2xl mx-4" @hide="handleClose">
        <div class="p-0">
            <AccountForm :is-edit="isEdit" :edit-account-id="editAccountId" :accounts="accounts" :banks="banks"
                :is-loading="isLoading" @submit="handleSubmit" @cancel="handleCancel" />
        </div>
    </Dialog>
</template>

<script setup>
import { computed } from 'vue';
import AccountForm from './AccountForm.vue';

// Props
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
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
const emit = defineEmits(['update:visible', 'submit', 'cancel', 'close']);

// Computed
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

// Methods
const handleSubmit = (data) => {
    emit('submit', data);
};

const handleCancel = () => {
    emit('cancel');
    isVisible.value = false;
};

const handleClose = () => {
    emit('close');
    emit('cancel');
};
</script>

<style scoped>
:deep(.p-dialog) {
    max-height: 90vh;
}

:deep(.p-dialog-content) {
    padding: 0;
    overflow-y: auto;
    max-height: calc(90vh - 8rem);
}

:deep(.p-dialog-header) {
    padding: 1.5rem 1.5rem 1rem 1.5rem;
    border-bottom: 1px solid var(--surface-border);
}
</style>