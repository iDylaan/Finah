<script setup>
import GlobalCategoryGroupModal from '@/components/modals/GlobalCategoryGroupModal.vue';
import GlobalCategoryModal from '@/components/modals/GlobalCategoryModal.vue';
import RecurringTransactionModal from '@/components/modals/RecurringTransactionModal.vue';
import { useModalsStore } from '@/stores/ui-modals.js';
import { useAccountsStore } from '@/stores/accounts.js';

const modalsStore = useModalsStore();
const accountsStore = useAccountsStore();

const handleRecurringTransactionSuccess = async () => {
    console.log('🔄 Recargando cuentas después de actualizar transacción periódica');
    await accountsStore.fetchAccountsWithDetails({ force: true });
    console.log('✅ Cuentas actualizadas');
};
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
        @success="handleRecurringTransactionSuccess"
    />
    
    <router-view />
</template>

<style scoped></style>
