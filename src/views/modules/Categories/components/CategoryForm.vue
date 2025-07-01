<template>
    <!-- Modal para Ver/Crear/Editar Categoría -->
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" 
        class="w-full max-w-md" :draggable="false" :closable="!isSubmitting && !isLoadingData" 
        @hide="handleClose">
        
        <template #header>
            <div class="flex items-center gap-2">
                <span class="font-semibold text-xl">{{ dialogTitle }}</span>
            </div>
        </template>

        <!-- Loading state -->
        <div v-if="isLoadingData" class="flex justify-center items-center py-8">
            <ProgressSpinner size="small" />
            <span class="ml-3 text-surface-600">Cargando datos de la categoría...</span>
        </div>

        <!-- Formulario o Vista de detalles -->
        <div v-else class="space-y-4">
            <form v-if="!isReadOnlyMode" @submit.prevent="submitCategory" class="space-y-4">
                <!-- Icono (usando el color del grupo) -->
                <div class="flex gap-4 w-full justify-center">
                    <IconPicker 
                        v-model="categoryForm.icon_name" 
                        v-model:iconType="categoryForm.icon_type"
                        :color="selectedGroup?.color || '#6366f1'" 
                        :disabled="isSubmitting || isReadOnlyMode" />
                </div>

                <!-- Nombre -->
                <div>
                    <label for="categoryName" class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-0">
                        Nombre <span class="text-red-500">*</span>
                    </label>
                    <InputText 
                        id="categoryName" 
                        v-model="categoryForm.name"
                        placeholder="Nombre para la categoría" 
                        class="w-full"
                        :class="{ 'p-invalid': formErrors.name }" 
                        required 
                        :disabled="isSubmitting || isReadOnlyMode" />
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
                        placeholder="Breve descripción para la categoría" 
                        rows="3" 
                        class="w-full" 
                        :disabled="isSubmitting || isReadOnlyMode" />
                    <small v-if="formErrors.description" class="p-error">{{ formErrors.description }}</small>
                </div>
            </form>

            <!-- Vista de solo lectura -->
            <div v-else class="space-y-4">
                <!-- Icono -->
                <div class="flex justify-center my-4">
                    <div class="w-16 h-16 rounded-lg flex items-center justify-center"
                        :style="{ backgroundColor: selectedGroup?.color || '#6366f1' }">
                        <span v-if="categoryForm.icon_type === 'material'" 
                            class="material-symbols-outlined text-white" style="font-size: 32px">
                            {{ categoryForm.icon_name }}
                        </span>
                        <i v-else :class="categoryForm.icon_name || 'pi pi-tag'" 
                            class="text-white" style="font-size: 32px"></i>
                    </div>
                </div>

                <!-- Detalles -->
                <div class="space-y-3">
                    <!-- Nombre -->
                    <div>
                        <h4 class="text-sm font-medium text-surface-600 dark:text-surface-400 mb-0">Nombre</h4>
                        <p class="text-lg font-semibold text-surface-900 dark:text-surface-100">{{ categoryForm.name }}</p>
                    </div>

                    <!-- Descripción -->
                    <div v-if="categoryForm.description">
                        <h4 class="text-sm font-medium text-surface-600 dark:text-surface-400">Descripción</h4>
                        <p class="text-base text-surface-800 dark:text-surface-200">{{ categoryForm.description }}</p>
                    </div>

                    <!-- Badge público -->
                    <div v-if="isPublicCategory" class="mt-3">
                        <p class="text-xs text-surface-500 mt-1">Las categorías preestablecidas no pueden ser modificadas</p>
                    </div>
                </div>
            </div>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button 
                    label="Cerrar" 
                    severity="secondary" 
                    outlined 
                    @click="handleClose" 
                    :disabled="isSubmitting || isLoadingData" />
                
                <Button v-if="!isReadOnlyMode"
                    :label="isEditMode ? 'Actualizar' : 'Crear'" 
                    severity="success" 
                    @click="submitCategory"
                    :loading="isSubmitting" 
                    :disabled="!isFormValid || isLoadingData" 
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
import { useSessionStore } from '@/stores/session.js';
import { useToast } from 'primevue/usetoast';

// COMPONENTS
import IconPicker from '@/components/IconPicker.vue';

// STORES & COMPOSABLES
const categoriesStore = useCategoriesStore();
const sessionStore = useSessionStore();
const toast = useToast();

// PROPS
const props = defineProps({
    visible: {
        type: Boolean,
        default: false
    },
    isNew: {
        type: Boolean,
        default: false
    },
    categoryId: {
        type: String,
        default: null
    },
    groupId: {
        type: String,
        default: null
    },
    category: {
        type: Object,
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
const emit = defineEmits(['update:visible', 'submit', 'close', 'success']);

// VARIABLES
const isSubmitting = ref(false);
const isLoadingData = ref(false);
const loadedCategoryData = ref(null);
const categoryForm = ref({
    name: '',
    description: '',
    icon_name: 'pi pi-tag',
    icon_type: ICONS.PRIMEVUE,
    is_public: false,
    group_id: null
});
const formErrors = ref({});

// COMPUTED PROPERTIES
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const isNewCategory = computed(() => props.isNew);

const isEditMode = computed(() => !props.isNew && !isReadOnlyMode.value);

const dialogTitle = computed(() => {
    if (isNewCategory.value) return 'Nueva Categoría';
    if (isEditMode.value) return 'Editar Categoría';
    return 'Detalles de Categoría';
});

const isPublicCategory = computed(() => {
    return loadedCategoryData.value?.es_publico || false;
});

const isReadOnlyMode = computed(() => {
    // Modo solo lectura si:
    // - Es una categoría pública
    // - O no es categoría propia (del usuario actual)
    return isPublicCategory.value || (
        !isNewCategory.value && 
        loadedCategoryData.value && 
        loadedCategoryData.value.usuario_id !== sessionStore.userId
    );
});

const selectedGroup = computed(() => {
    const groupId = props.groupId || categoryForm.value.group_id;
    if (!groupId) return null;
    
    return props.categoryGroups.find(group => group.id === groupId) || null;
});

const isFormValid = computed(() => {
    return categoryForm.value.name?.trim() && 
           categoryForm.value.name.trim().length >= 2 &&
           Object.keys(formErrors.value).length === 0 &&
           !!categoryForm.value.group_id;
});

// WATCHERS
watch(() => props.visible, (newValue) => {
    if (newValue) {
        initializeForm();
    }
});

watch([() => props.isNew, () => props.categoryId, () => props.category], 
    ([newIsNew, newCategoryId, newCategory]) => {
        if (props.visible) {
            if (newIsNew) {
                setupNewCategory();
            } else if (newCategory) {
                loadCategoryFromProp(newCategory);
            } else if (newCategoryId) {
                loadCategoryData(newCategoryId);
            }
        }
    }, { immediate: true });

// FUNCTIONS
const initializeForm = () => {
    formErrors.value = {};
    loadedCategoryData.value = null;
    
    if (props.isNew) {
        setupNewCategory();
    } else if (props.category) {
        loadCategoryFromProp(props.category);
    } else if (props.categoryId) {
        loadCategoryData(props.categoryId);
    } else {
        resetForm();
    }
};

const setupNewCategory = () => {
    resetForm();
    
    // Si tenemos groupId, usarlo para la nueva categoría
    if (props.groupId) {
        categoryForm.value.group_id = props.groupId;
    }
};

const loadCategoryFromProp = (category) => {
    if (!category) {
        console.warn('⚠️ No se proporcionó datos de categoría');
        resetForm();
        return;
    }
    
    loadedCategoryData.value = { ...category };
    
    categoryForm.value = {
        name: category.nombre || '',
        description: category.descripcion || '',
        icon_name: category.nombre_icono || 'pi pi-tag',
        icon_type: category.icon_type || category.biblioteca_iconos || ICONS.PRIMEVUE,
        is_public: category.es_publico || false,
        group_id: category.grupo_id || category.category_group_id || null
    };
};

const loadCategoryData = async (categoryId) => {
    if (!categoryId) {
        console.warn('⚠️ No se proporcionó ID de categoría para cargar');
        return;
    }
    
    isLoadingData.value = true;
    
    try {
        // Buscar primero en los grupos cargados
        let foundCategory = null;
        
        props.categoryGroups.forEach(group => {
            const found = group.categories?.find(cat => cat.id === categoryId);
            if (found) {
                foundCategory = found;
                foundCategory.group_id = group.id; // Asegurar que tengamos el group_id
            }
        });
        
        if (!foundCategory) {
            // Si no encontramos la categoría en los datos locales, podríamos
            // implementar aquí una llamada a la API para obtenerla
            console.warn('⚠️ Categoría no encontrada localmente');
            formErrors.value = { general: 'No se pudo encontrar la categoría' };
            return;
        }
        
        loadedCategoryData.value = { ...foundCategory };
        
        categoryForm.value = {
            name: foundCategory.nombre || '',
            description: foundCategory.descripcion || '',
            icon_name: foundCategory.nombre_icono || 'pi pi-tag',
            icon_type: foundCategory.icon_type || foundCategory.biblioteca_iconos || ICONS.PRIMEVUE,
            is_public: foundCategory.es_publico || false,
            group_id: foundCategory.grupo_id || foundCategory.category_group_id || null
        };
        
    } catch (error) {
        console.error('💥 Error cargando categoría:', error);
        formErrors.value = { general: 'Error cargando los datos de la categoría' };
    } finally {
        isLoadingData.value = false;
    }
};

const resetForm = () => {
    categoryForm.value = {
        name: '',
        description: '',
        icon_name: 'pi pi-tag',
        icon_type: ICONS.PRIMEVUE,
        is_public: false,
        group_id: props.groupId || null
    };
    
    formErrors.value = {};
    loadedCategoryData.value = null;
};

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
    
    if (!categoryForm.value.group_id) {
        errors.group_id = 'Se requiere un grupo para la categoría';
    }

    formErrors.value = errors;
    return Object.keys(errors).length === 0;
};

const handleClose = () => {
    emit('close');
    resetForm();
};

const submitCategory = async () => {
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
            icon_name: categoryForm.value.icon_name || 'pi pi-tag',
            icon_type: categoryForm.value.icon_type || ICONS.PRIMEVUE,
            is_public: false, // Las categorías creadas por usuarios son privadas por defecto
            group_id: categoryForm.value.group_id
        };
        
        // Agregar ID si es edición
        if (!isNewCategory.value && props.categoryId) {
            categoryData.id = props.categoryId;
        }
        
        let result;
        
        // Usar el store directamente para guardar en lugar de emitir un evento
        if (isNewCategory.value) {
            // Crear nueva categoría
            result = await categoriesStore.createCategory(categoryData, { toast });
        } else {
            // Actualizar categoría existente
            result = await categoriesStore.updateCategory(props.categoryId, categoryData, { toast });
        }
        
        if (result) {
            // Emitir evento de éxito con la categoría creada/actualizada
            emit('success', result);
            
            // Cerrar modal
            handleClose();
        }

    } catch (error) {
        console.error('💥 Error guardando categoría:', error);
        
        // Mostrar mensaje de error adicional (si es necesario)
        if (!error.message?.includes('Error')) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se pudo guardar la categoría',
                life: 5000
            });
        }
    } finally {
        isSubmitting.value = false;
    }
};

// HOOKS
watch(() => categoryForm.value.name, () => {
    if (formErrors.value.name) validateForm();
});

watch(() => categoryForm.value.description, () => {
    if (formErrors.value.description) validateForm();
});

// EXPOSE
defineExpose({
    resetForm,
    initializeForm,
    loadCategoryData
});
</script>

<style lang="scss" scoped>
.p-error {
    color: #e24c4c;
}

.material-symbols-outlined {
    font-variation-settings:
        'FILL' 0,
        'wght' 400,
        'GRAD' 0,
        'opsz' 24;
}
</style>