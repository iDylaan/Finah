<template>
    <!-- Modal para Nueva Categoría -->
    <Dialog v-model:visible="isVisible" modal :header="isEditMode ? 'Editar Grupo' : 'Nuevo Grupo'"
        class="w-full max-w-md" :draggable="false" :closable="!isSubmitting" @hide="handleClose">
        <template #header>
            <div class="flex items-center gap-2">
                <span class="font-semibold text-xl">{{ isEditMode ? 'Editar Grupo' : 'Nuevo Grupo' }}</span>
            </div>
        </template>

        <form @submit.prevent="submitCategory" class="space-y-4">

            <!-- Icono -->
            <div class="flex gap-4 w-full">
                <IconPicker v-model="categoryForm.icon_name" v-model:iconType="categoryForm.icon_type"
                    :color="categoryForm.color" :disabled="isSubmitting" />
                <CustomColorPicker v-model="categoryForm.color" label="Color" :disabled="isSubmitting" />
            </div>

            <div>
                <label for="categoryName" class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Nombre
                </label>
                <InputText id="categoryName" v-model="categoryForm.name"
                    placeholder="Nombre para el nuevo grupo de categorías" class="w-full"
                    :class="{ 'p-invalid': formErrors.name }" required />
                <small v-if="formErrors.name" class="p-error">{{ formErrors.name }}</small>
            </div>

            <!-- Descripción -->
            <div>
                <label for="categoryDescription"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-1">
                    Descripción (opcional)
                </label>
                <Textarea id="categoryDescription" v-model="categoryForm.description"
                    placeholder="Decripción general para el grupo de categorías" rows="3" class="w-full" />
            </div>

            <!-- Debug info ACTUALIZADO -->
            <!-- <div class="p-3 bg-surface-50 dark:bg-surface-800 rounded text-xs space-y-1">
                <p><strong>Debug:</strong></p>
                <p>Icono: <code>{{ categoryForm.icon_name }}</code></p>
                <p>Tipo: <code>{{ categoryForm.icon_type }}</code></p>
                <p>Color: <code>{{ categoryForm.color }}</code></p>
                <div class="flex items-center gap-2 mt-2">
                    <span>Preview:</span>
                    <div class="w-8 h-8 rounded flex items-center justify-center" 
                         :style="{ backgroundColor: categoryForm.color }">
                        <i v-if="categoryForm.icon_type === 'primeicons'" 
                           :class="categoryForm.icon_name" 
                           class="text-white text-sm"></i>
                        <span v-else 
                              class="material-symbols-rounded text-white text-sm">
                            {{ categoryForm.icon_name }}
                        </span>
                    </div>
                    <span class="text-xs px-2 py-1 rounded"
                          :class="categoryForm.icon_type === 'primeicons' 
                            ? 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200' 
                            : 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200'">
                        {{ categoryForm.icon_type === 'primeicons' ? 'PrimeIcons' : 'Material' }}
                    </span>
                </div>
                <p class="text-green-600">✅ Actualización en tiempo real</p>
            </div> -->
        </form>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cancelar" severity="secondary" outlined @click="handleClose" :disabled="isSubmitting" />
                <Button :label="isEditMode ? 'Actualizar' : 'Crear Grupo'" severity="success" @click="submitCategory"
                    :loading="isSubmitting" :disabled="!isFormValid" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch } from 'vue';

// COMPONENTS
import IconPicker from '@/components/IconPicker.vue';
import CustomColorPicker from '@/components/CustomColorPicker.vue';

// PROPS (mismos de antes...)
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
    categoryGroups: {
        type: Array,
        default: () => []
    },
    isLoading: {
        type: Boolean,
        default: false
    },
    editCategory: {
        type: Object,
        default: null
    }
});

// EMITS
const emit = defineEmits(['update:visible', 'submit', 'close']);

// VARIABLES
const isSubmitting = ref(false);
const isEditMode = computed(() => !!props.editCategory);

// Form data - ACTUALIZADO con icon_type
const categoryForm = ref({
    name: '',
    description: '',
    icon_name: 'pi pi-folder',
    icon_type: 'primeicons', // NUEVO CAMPO
    color: '#6366f1',
    is_public: false
});

// Form validation
const formErrors = ref({});

// Computed values (mismos de antes...)
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const isFormValid = computed(() => {
    return categoryForm.value.name?.trim() &&
        Object.keys(formErrors.value).length === 0;
});

// Validación del formulario (misma de antes...)
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

// Watchers para validación en tiempo real
watch(() => categoryForm.value.name, () => {
    if (formErrors.value.name) {
        validateForm();
    }
});

// Watcher para debug de cambios de color en tiempo real
watch(() => categoryForm.value.color, (newColor) => {
    console.log('🎨 NewCategoryGroup detectó cambio de color:', newColor);
});

// NUEVO: Watcher para debug de cambios de tipo de icono
watch(() => categoryForm.value.icon_type, (newType) => {
    console.log('🎯 NewCategoryGroup detectó cambio de tipo de icono:', newType);
});

// NUEVO: Watcher para debug de cambios de icono
watch(() => categoryForm.value.icon_name, (newIcon) => {
    console.log('🎯 NewCategoryGroup detectó cambio de icono:', newIcon);
});

// Watchers para modal (mismos de antes...)
watch(() => props.visible, (newValue) => {
    if (newValue) {
        initializeForm();
    }
});

watch(() => props.editCategory, (newCategory) => {
    if (newCategory) {
        loadCategoryForEdit(newCategory);
    }
}, { immediate: true });

// Función para inicializar formulario
const initializeForm = () => {
    if (props.editCategory) {
        loadCategoryForEdit(props.editCategory);
    } else {
        resetForm();
    }
    formErrors.value = {};
};

// Función para cargar categoría para editar - ACTUALIZADA
const loadCategoryForEdit = (category) => {
    categoryForm.value = {
        id: category.id,
        name: category.name || '',
        description: category.description || '',
        icon_name: category.icon_name || 'pi pi-folder',
        icon_type: category.icon_type || 'primeicons', // NUEVO CAMPO
        color: category.color || '#6366f1',
        is_public: category.is_public || false
    };
};

// Función para resetear formulario - ACTUALIZADA
const resetForm = () => {
    categoryForm.value = {
        name: '',
        description: '',
        icon_name: 'pi pi-folder',
        icon_type: 'primeicons', // NUEVO CAMPO
        color: '#6366f1',
        is_public: false
    };
};

// Función para cerrar modal (misma de antes...)
const handleClose = () => {
    emit('close');
    resetForm();
    formErrors.value = {};
};

// Función para enviar formulario - ACTUALIZADA
const submitCategory = async () => {
    if (!validateForm()) {
        return;
    }

    isSubmitting.value = true;

    try {
        // Preparar datos para enviar - ACTUALIZADO con icon_type
        const categoryData = {
            ...(isEditMode.value && { id: categoryForm.value.id }),
            name: categoryForm.value.name.trim(),
            description: categoryForm.value.description?.trim() || null,
            icon_name: categoryForm.value.icon_name || 'pi pi-folder',
            icon_type: categoryForm.value.icon_type || 'primeicons', // NUEVO CAMPO
            color: categoryForm.value.color || '#6366f1',
            is_public: categoryForm.value.is_public || false
        };

        console.log('📤 Enviando datos del grupo (con tipo de icono):', categoryData);

        emit('submit', {
            data: categoryData,
            isEdit: isEditMode.value,
            onSuccess: () => {
                handleClose();
            },
            onError: () => {
                // El padre manejará el error
            }
        });

    } catch (error) {
        console.error('💥 Error inesperado:', error);
    } finally {
        isSubmitting.value = false;
    }
};

// Exponer funciones públicas
defineExpose({
    resetForm,
    initializeForm
});
</script>

<style lang="scss" scoped></style>