<template>
    <CategoryForm 
        v-model:visible="isVisible" 
        :is-new="isNewMode" 
        :category-id="modalsStore.categoryEditId"
        :group-id="modalsStore.categoryGroupId" 
        :category="modalsStore.categoryData" 
        :category-groups="categoriesStore.categoryGroups"
        :is-loading="categoriesStore.loading" 
        @close="handleClose" 
        @success="handleSuccess" 
    />
</template>

<script setup>
import { computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useModalsStore } from '@/stores/ui-modals';
import { useCategoriesStore } from '@/stores/categories';
import CategoryForm from '@/views/modules/Categories/components/CategoryForm.vue';

const toast = useToast();
const modalsStore = useModalsStore();
const categoriesStore = useCategoriesStore();

const isVisible = computed({
    get: () => modalsStore.categoryModalVisible,
    set: (value) => {
        if (!value) {
            modalsStore.closeCategoryModal();
        }
    }
});

const isNewMode = computed(() => modalsStore.categoryModalMode === 'create');

const handleSuccess = async (category) => {
    // Recargar datos para asegurar que los cambios sean visibles
    await categoriesStore.fetchCategoryGroupsWithCategories({ toast });

    // Cerrar modal
    modalsStore.closeCategoryModal();
};

const handleClose = () => {
    modalsStore.closeCategoryModal();
};
</script>
