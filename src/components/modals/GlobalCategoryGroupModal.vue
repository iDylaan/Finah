<template>
    <CategoryGroupForm 
        v-model:visible="isVisible" 
        :is-edit="isEditMode"
        :edit-group-id="modalsStore.categoryGroupEditId" 
        :category-groups="categoriesStore.categoryGroups"
        :is-loading="categoriesStore.loading"
        @submit="handleSubmit" 
        @close="handleClose" 
    />
</template>

<script setup>
import { computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useModalsStore } from '@/stores/ui-modals';
import { useCategoriesStore } from '@/stores/categories';
import CategoryGroupForm from '@/views/modules/Categories/components/CategoryGroupForm.vue';

const toast = useToast();
const modalsStore = useModalsStore();
const categoriesStore = useCategoriesStore();

const isVisible = computed({
    get: () => modalsStore.categoryGroupModalVisible,
    set: (value) => {
        if (!value) {
            modalsStore.closeCategoryGroupModal();
        }
    }
});

const isEditMode = computed(() => modalsStore.categoryGroupModalMode === 'edit');

const handleSubmit = async ({ data, isEdit, groupId, onSuccess, onError }) => {
    try {
        let result;

        if (isEdit && groupId) {
            // Actualizar grupo existente
            result = await categoriesStore.updateCategoryGroup(groupId, data, { toast });
        } else {
            // Crear nuevo grupo
            result = await categoriesStore.createCategoryGroup(data, { toast });
        }

        if (result) {
            // Recargar datos para mostrar cambios
            // Recargar solo si se creó un nuevo grupo
            await categoriesStore.fetchCategoryGroupsWithCategories({ toast, force: true });

            // Ejecutar callback de éxito
            onSuccess();
            
            // Cerrar modal
            modalsStore.closeCategoryGroupModal();
        }

    } catch (error) {
        console.error('💥 Error en handleSubmit:', error);
        // Ejecutar callback de error
        onError(error);
    }
};

const handleClose = () => {
    modalsStore.closeCategoryGroupModal();
};
</script>
