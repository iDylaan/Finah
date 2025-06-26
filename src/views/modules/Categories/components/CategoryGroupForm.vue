<template>
    <!-- Modal para Nueva/Editar Categoría -->
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" 
        class="w-full max-w-md" :draggable="false" :closable="!isSubmitting && !isLoadingGroupData" 
        @hide="handleClose">
        
        <template #header>
            <div class="flex items-center gap-2">
                <span class="font-semibold text-xl">{{ dialogTitle }}</span>
            </div>
        </template>

        <!-- Loading state mientras carga datos para editar -->
        <div v-if="isLoadingGroupData" class="flex justify-center items-center py-8">
            <ProgressSpinner size="small" />
            <span class="ml-3 text-surface-600">Cargando datos del grupo...</span>
        </div>

        <!-- Formulario -->
        <form v-else @submit.prevent="submitCategory" class="space-y-4">
            <!-- Icono y Color -->
            <div class="flex gap-4 w-full">
                <IconPicker 
                    v-model="categoryForm.icon_name" 
                    v-model:iconType="categoryForm.icon_type"
                    :color="categoryForm.color" 
                    :disabled="isSubmitting" />
                <CustomColorPicker 
                    v-model="categoryForm.color" 
                    label="Color" 
                    :disabled="isSubmitting" />
            </div>

            <!-- Nombre -->
            <div>
                <label for="categoryName" class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Nombre <span class="text-red-500">*</span>
                </label>
                <InputText 
                    id="categoryName" 
                    v-model="categoryForm.name"
                    placeholder="Nombre para el grupo de categorías" 
                    class="w-full"
                    :class="{ 'p-invalid': formErrors.name }" 
                    required 
                    :disabled="isSubmitting" />
                <small v-if="formErrors.name" class="p-error">{{ formErrors.name }}</small>
            </div>

            <!-- Descripción -->
            <div>
                <label for="categoryDescription" class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Descripción (opcional)
                </label>
                <Textarea 
                    id="categoryDescription" 
                    v-model="categoryForm.description"
                    placeholder="Descripción general para el grupo de categorías" 
                    rows="3" 
                    class="w-full" 
                    :disabled="isSubmitting" />
                <small v-if="formErrors.description" class="p-error">{{ formErrors.description }}</small>
            </div>
        </form>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button 
                    label="Cancelar" 
                    severity="secondary" 
                    outlined 
                    @click="handleClose" 
                    :disabled="isSubmitting || isLoadingGroupData" />
                <Button 
                    :label="isEditMode ? 'Actualizar Grupo' : 'Crear Grupo'" 
                    severity="success" 
                    @click="submitCategory"
                    :loading="isSubmitting" 
                    :disabled="!isFormValid || isLoadingGroupData" 
                    :icon="isEditMode ? 'pi pi-check' : 'pi pi-plus'" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch } from 'vue';
import ICONS from '@/assets/constants/icon-providers.js';
import { useCategoriesStore } from '@/stores/categories.js';

// COMPONENTS
import IconPicker from '@/components/IconPicker.vue';
import CustomColorPicker from '@/components/CustomColorPicker.vue';

// PROPS - ACTUALIZADOS
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
    isEdit: {
        type: Boolean,
        default: false
    },
    editGroupId: {
        type: String,
        default: null
    },
    categoryGroups: {
        type: Array,
        default: () => []
    },
    isLoading: {
        type: Boolean,
        default: false
    }
});

// EMITS
const emit = defineEmits(['update:visible', 'submit', 'close']);

// STORE
const categoriesStore = useCategoriesStore();

// VARIABLES
const isSubmitting = ref(false);
const isLoadingGroupData = ref(false);
const loadedGroupData = ref(null);

// COMPUTED
const isEditMode = computed(() => props.isEdit && !!props.editGroupId);

const dialogTitle = computed(() => {
    return isEditMode.value ? 'Editar Grupo' : 'Nuevo Grupo';
});

const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const isFormValid = computed(() => {
    return categoryForm.value.name?.trim() && 
           categoryForm.value.name.trim().length >= 2 &&
           Object.keys(formErrors.value).length === 0;
});

// FORM DATA
const categoryForm = ref({
    name: '',
    description: '',
    icon_name: 'pi pi-folder',
    icon_type: ICONS.PRIMEVUE,
    color: '#6366f1',
    is_public: false
});

// FORM VALIDATION
const formErrors = ref({});

// FUNCIONES DE VALIDACIÓN
const validateForm = () => {
    const errors = {};

    if (!categoryForm.value.name?.trim()) {
        errors.name = 'El nombre es requerido';
    } else if (categoryForm.value.name.trim().length < 2) {
        errors.name = 'El nombre debe tener al menos 2 caracteres';
    } else if (categoryForm.value.name.trim().length > 100) {
        errors.name = 'El nombre no puede exceder 100 caracteres';
    }

    if (categoryForm.value.description && categoryForm.value.description.length > 500) {
        errors.description = 'La descripción no puede exceder 500 caracteres';
    }

    formErrors.value = errors;
    return Object.keys(errors).length === 0;
};

// WATCHERS
watch(() => categoryForm.value.name, () => {
    if (formErrors.value.name) {
        validateForm();
    }
});

watch(() => categoryForm.value.description, () => {
    if (formErrors.value.description) {
        validateForm();
    }
});

// Watcher principal para el modal
watch(() => props.visible, (newValue) => {
    if (newValue) {
        initializeForm();
    }
});

// Watcher para cambios en modo edición
watch([() => props.isEdit, () => props.editGroupId], ([newIsEdit, newEditGroupId]) => {
    if (props.visible && newIsEdit && newEditGroupId) {
        loadGroupForEdit(newEditGroupId);
    }
}, { immediate: true });

// FUNCIONES
const initializeForm = async () => {
    console.log('🔄 Inicializando formulario...', { 
        isEdit: props.isEdit, 
        editGroupId: props.editGroupId 
    });
    
    formErrors.value = {};
    loadedGroupData.value = null;
    
    if (isEditMode.value) {
        await loadGroupForEdit(props.editGroupId);
    } else {
        resetForm();
    }
};

const loadGroupForEdit = async (groupId) => {
    if (!groupId) {
        console.warn('⚠️ No se proporcionó ID de grupo para editar');
        return;
    }
    
    isLoadingGroupData.value = true;
    
    try {
        console.log('📥 Cargando grupo para editar:', groupId);
        
        // Buscar en los grupos ya cargados primero
        let group = categoriesStore.categoryGroups.find(g => g.id === groupId);
        
        // Si no se encuentra, intentar buscar en props
        if (!group) {
            console.log('🔍 Grupo no encontrado en store, buscando en props...');
            group = props.categoryGroups.find(g => g.id === groupId);
        }
        
        if (!group) {
            throw new Error(`No se encontró el grupo con ID: ${groupId}`);
        }
        
        console.log('✅ Grupo encontrado:', group);
        loadedGroupData.value = group;
        
        // Cargar datos en el formulario
        categoryForm.value = {
            name: group.name || '',
            description: group.description || '',
            icon_name: group.icon_name || 'pi pi-folder',
            icon_type: group.icon_type || group.icon_library || ICONS.PRIMEVUE, // Manejo de ambos nombres
            color: group.color || '#6366f1',
            is_public: group.is_public || false
        };
        
        console.log('📝 Formulario cargado con datos:', categoryForm.value);
        
    } catch (error) {
        console.error('💥 Error cargando grupo para editar:', error);
        
        // Reset form y mostrar error
        resetForm();
        formErrors.value = {
            general: 'Error cargando los datos del grupo'
        };
        
    } finally {
        isLoadingGroupData.value = false;
    }
};

const resetForm = () => {
    console.log('🔄 Reseteando formulario');
    
    categoryForm.value = {
        name: '',
        description: '',
        icon_name: 'pi pi-folder',
        icon_type: ICONS.PRIMEVUE,
        color: '#6366f1',
        is_public: false
    };
    
    formErrors.value = {};
    loadedGroupData.value = null;
};

const handleClose = () => {
    console.log('❌ Cerrando modal');
    
    emit('close');
    resetForm();
    isLoadingGroupData.value = false;
};

const submitCategory = async () => {
    console.log('📤 Enviando formulario...', { 
        isEdit: isEditMode.value, 
        groupId: props.editGroupId 
    });
    
    if (!validateForm()) {
        console.warn('⚠️ Formulario no válido');
        return;
    }

    isSubmitting.value = true;

    try {
        // Preparar datos para enviar
        const categoryData = {
            name: categoryForm.value.name.trim(),
            description: categoryForm.value.description?.trim() || null,
            icon_name: categoryForm.value.icon_name || 'pi pi-folder',
            icon_type: categoryForm.value.icon_type || ICONS.PRIMEVUE,
            color: categoryForm.value.color || '#6366f1',
            is_public: categoryForm.value.is_public || false
        };
        
        // Agregar ID si es edición
        if (isEditMode.value) {
            categoryData.id = props.editGroupId;
        }
        
        console.log('📋 Datos a enviar:', categoryData);

        // Emitir evento al componente padre
        emit('submit', {
            data: categoryData,
            isEdit: isEditMode.value,
            groupId: isEditMode.value ? props.editGroupId : null,
            onSuccess: () => {
                console.log('✅ Operación exitosa');
                handleClose();
            },
            onError: (error) => {
                console.error('💥 Error en operación:', error);
                // El error se maneja en el padre
            }
        });

    } catch (error) {
        console.error('💥 Error inesperado:', error);
    } finally {
        isSubmitting.value = false;
    }
};

// EXPOSE
defineExpose({
    resetForm,
    initializeForm,
    loadGroupForEdit
});
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}
</style>