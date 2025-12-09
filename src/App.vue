<script setup>
import GlobalCategoryGroupModal from '@/components/modals/GlobalCategoryGroupModal.vue';
import GlobalCategoryModal from '@/components/modals/GlobalCategoryModal.vue';
</script>

<template>
    <Toast />
    <ConfirmDialog />
    
    <!-- Modales globales -->
    <GlobalCategoryGroupModal />
    <GlobalCategoryModal />
    
    <router-view />
</template>

<style scoped></style>
