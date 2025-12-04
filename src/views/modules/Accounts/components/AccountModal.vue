<template>
    <Dialog v-model:visible="isVisible" :header="isEdit ? 'Editar Cuenta' : 'Nueva Cuenta'" modal :closable="true"
        :draggable="false" :resizable="false" 
        :style="{ width: '95vw', maxWidth: '50rem' }" 
        :breakpoints="{ '768px': '100vw' }"
        :contentStyle="{ maxHeight: 'calc(100vh - 120px)', overflowY: 'auto' }"
        class="mobile-fullscreen-dialog"
        @hide="handleClose">
        <div class="p-0">
            <AccountForm :is-edit="isEdit" :edit-account-id="editAccountId" :accounts="accounts" :banks="banks"
                :is-loading="isLoading" @submit="handleSubmit" @cancel="handleCancel" />
        </div>
    </Dialog>
</template>

<script setup>
import { computed, ref, onMounted, onUnmounted } from 'vue';
import AccountForm from './AccountForm.vue';

// Detección de móvil
const isMobile = ref(window.innerWidth < 768);

const handleResize = () => {
    isMobile.value = window.innerWidth < 768;
};

onMounted(() => {
    window.addEventListener('resize', handleResize);
});

onUnmounted(() => {
    window.removeEventListener('resize', handleResize);
});

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
/* Escritorio */
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

/* Móvil */
:deep(.account-modal-mobile.p-dialog) {
    width: 100vw !important;
    max-width: 100vw !important;
    height: 100vh !important;
    max-height: 100vh !important;
    margin: 0 !important;
    border-radius: 0 !important;
    left: 0 !important;
    top: 0 !important;
}

:deep(.account-modal-mobile .p-dialog-content) {
    max-height: calc(100vh - 4rem);
    padding-bottom: 1rem;
}

:deep(.account-modal-mobile .p-dialog-header) {
    padding: 1rem;
    position: sticky;
    top: 0;
    background: var(--surface-0);
    z-index: 1;
    border-bottom: 1px solid var(--surface-border);
}
</style>