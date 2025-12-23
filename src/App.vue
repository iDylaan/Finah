<script setup>
import GlobalCategoryGroupModal from '@/components/modals/GlobalCategoryGroupModal.vue';
import GlobalCategoryModal from '@/components/modals/GlobalCategoryModal.vue';
import RecurringTransactionModal from '@/components/modals/RecurringTransactionModal.vue';
import { useModalsStore } from '@/stores/ui-modals.js';

const modalsStore = useModalsStore();
</script>

<template>
    <Toast />
    <ConfirmDialog />
    
    <!-- Modales globales -->
    <GlobalCategoryGroupModal />
    <GlobalCategoryModal />
    <RecurringTransactionModal 
        v-model:visible="modalsStore.recurringTransactionModalVisible" 
        :edit-data="modalsStore.recurringTransactionEditData" 
    />
    
    <router-view />
</template>

<style scoped></style>
