<template>
    <!-- Modal para Nueva Categoría -->
    <Dialog v-model:visible="localVisible" modal :header="isEditMode ? 'Editar Grupo' : 'Nuevo Grupo'"
        :style="{ width: '500px' }" class="" :draggable="false" :closable="!isSubmitting" @hide="handleClose">
        <template #header>
            <div class="flex items-center gap-2">
                <i class="pi pi-plus-circle text-xl text-primary-500"></i>
                <span class="font-semibold">{{ isEditMode ? 'Editar Grupo' : 'Nuevo Grupo' }}</span>
            </div>
        </template>

        <form @submit.prevent="submitCategory" class="space-y-4">
            <!-- Nombre -->
            <div>
                <label for="category_name"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Nombre *
                </label>
                <InputText id="category_name" v-model="categoryForm.name"
                    placeholder="Ej: Alimentación, Transporte, etc." class="w-full"
                    :class="{ 'p-invalid': formErrors.name }" :disabled="isSubmitting" maxlength="100" />
                <small v-if="formErrors.name" class="p-error">{{ formErrors.name }}</small>
            </div>

            <!-- Descripción -->
            <div>
                <label for="category_description"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Descripción
                </label>
                <Textarea id="category_description" v-model="categoryForm.description"
                    placeholder="Descripción opcional de la categoría" class="w-full"
                    :class="{ 'p-invalid': formErrors.description }" :disabled="isSubmitting" rows="3"
                    maxlength="500" />
                <small v-if="formErrors.description" class="p-error">{{ formErrors.description }}</small>
                <small class="text-surface-500">{{ categoryForm.description?.length || 0 }}/500 caracteres</small>
            </div>

            <!-- Grupo de Categoría -->
            <div>
                <label for="category_group"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Grupo de Categoría *
                </label>
                <Dropdown id="category_group" v-model="categoryForm.group_id" :options="availableGroups"
                    optionLabel="name" optionValue="id" placeholder="Selecciona un grupo" class="w-full"
                    :class="{ 'p-invalid': formErrors.group_id }" :disabled="isSubmitting" :loading="isLoading">
                    <template #option="{ option }">
                        <div class="flex items-center gap-2">
                            <div class="w-6 h-6 rounded-md flex items-center justify-center"
                                :style="{ backgroundColor: option.color || '#6366f1' }">
                                <i :class="option.icon_name || 'pi pi-folder'" class="text-white text-xs"></i>
                            </div>
                            <span>{{ option.name }}</span>
                            <Badge v-if="option.is_public" value="Público" severity="info" size="small" />
                        </div>
                    </template>
                    <template #value="{ value }">
                        <div v-if="value && selectedGroup" class="flex items-center gap-2">
                            <div class="w-6 h-6 rounded-md flex items-center justify-center"
                                :style="{ backgroundColor: selectedGroup.color || '#6366f1' }">
                                <i :class="selectedGroup.icon_name || 'pi pi-folder'" class="text-white text-xs"></i>
                            </div>
                            <span>{{ selectedGroup.name }}</span>
                        </div>
                        <span v-else class="text-surface-500">Selecciona un grupo</span>
                    </template>
                </Dropdown>
                <small v-if="formErrors.group_id" class="p-error">{{ formErrors.group_id }}</small>
            </div>

            <!-- Icono -->
            <div>
                <label for="category_icon"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Icono
                </label>
                <div class="flex gap-3">
                    <InputText id="category_icon" v-model="categoryForm.icon_name" placeholder="pi pi-tag"
                        class="flex-1" :disabled="isSubmitting" />
                    <div
                        class="w-12 h-12 bg-surface-100 dark:bg-surface-700 rounded-lg flex items-center justify-center">
                        <i :class="categoryForm.icon_name || 'pi pi-tag'"
                            class="text-lg text-surface-600 dark:text-surface-400"></i>
                    </div>
                </div>
                <small class="text-surface-500">Usa clases de PrimeIcons (ej: pi pi-tag)</small>
            </div>

            <!-- Color -->
            <div>
                <label for="category_color"
                    class="block text-sm font-medium text-surface-700 dark:text-surface-300 mb-2">
                    Color
                </label>
                <div class="flex gap-3">
                    <InputText id="category_color" v-model="categoryForm.color" placeholder="#6366f1" class="flex-1"
                        :disabled="isSubmitting" />
                    <div class="w-12 h-12 rounded-lg border-2 border-surface-200 dark:border-surface-600"
                        :style="{ backgroundColor: categoryForm.color || '#6366f1' }"></div>
                </div>
                <small class="text-surface-500">Color en formato hexadecimal</small>
            </div>

            <!-- Público/Privado -->
            <div>
                <div class="flex items-center gap-3">
                    <Checkbox id="category_public" v-model="categoryForm.is_public" :binary="true"
                        :disabled="isSubmitting" />
                    <label for="category_public" class="text-sm font-medium text-surface-700 dark:text-surface-300">
                        Hacer esta categoría pública
                    </label>
                </div>
                <small class="text-surface-500 block mt-1">
                    Las categorías públicas serán visibles para todos los usuarios
                </small>
            </div>
        </form>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cancelar" severity="secondary" outlined @click="handleClose" :disabled="isSubmitting" />
                <Button :label="isEditMode ? 'Actualizar' : 'Crear Categoría'" severity="success"
                    @click="submitCategory" :loading="isSubmitting" :disabled="!isFormValid" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

// Props
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

// Emits
const emit = defineEmits(['update:visible', 'submit', 'close']);

// Local variables
const isSubmitting = ref(false);
const isEditMode = computed(() => !!props.editCategory);

// Form data
const categoryForm = ref({
    name: '',
    description: '',
    group_id: null,
    icon_name: 'pi pi-tag',
    color: '#6366f1',
    is_public: false
});

// Form validation
const formErrors = ref({});

// Computed values
const localVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const availableGroups = computed(() => {
    return props.categoryGroups.filter(group => !group.is_public || group.user_id);
});

const selectedGroup = computed(() => {
    return availableGroups.value.find(group => group.id === categoryForm.value.group_id);
});

const isFormValid = computed(() => {
    return categoryForm.value.name?.trim() &&
        categoryForm.value.group_id &&
        Object.keys(formErrors.value).length === 0;
});

// Validación del formulario
const validateForm = () => {
    const errors = {};

    // Validar nombre
    if (!categoryForm.value.name?.trim()) {
        errors.name = 'El nombre es requerido';
    } else if (categoryForm.value.name.trim().length < 2) {
        errors.name = 'El nombre debe tener al menos 2 caracteres';
    } else if (categoryForm.value.name.trim().length > 100) {
        errors.name = 'El nombre no puede exceder 100 caracteres';
    }

    // Validar grupo
    if (!categoryForm.value.group_id) {
        errors.group_id = 'Debes seleccionar un grupo';
    }

    // Validar descripción
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

watch(() => categoryForm.value.group_id, () => {
    if (formErrors.value.group_id) {
        validateForm();
    }
});

// Watcher para inicializar formulario cuando se abre el modal
watch(() => props.visible, (newValue) => {
    if (newValue) {
        initializeForm();
    }
});

// Watcher para cargar datos de edición
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

// Función para cargar categoría para editar
const loadCategoryForEdit = (category) => {
    categoryForm.value = {
        id: category.id,
        name: category.name || '',
        description: category.description || '',
        group_id: category.group_id || null,
        icon_name: category.icon_name || 'pi pi-tag',
        color: category.color || '#6366f1',
        is_public: category.is_public || false
    };
};

// Función para resetear formulario
const resetForm = () => {
    categoryForm.value = {
        name: '',
        description: '',
        group_id: null,
        icon_name: 'pi pi-tag',
        color: '#6366f1',
        is_public: false
    };
};

// Función para cerrar modal
const handleClose = () => {
    emit('close');
    resetForm();
    formErrors.value = {};
};

// Función para enviar formulario
const submitCategory = async () => {
    if (!validateForm()) {
        return;
    }

    isSubmitting.value = true;

    try {
        // Preparar datos para enviar
        const categoryData = {
            ...(isEditMode.value && { id: categoryForm.value.id }),
            name: categoryForm.value.name.trim(),
            description: categoryForm.value.description?.trim() || null,
            group_id: categoryForm.value.group_id,
            icon_name: categoryForm.value.icon_name || 'pi pi-tag',
            color: categoryForm.value.color || '#6366f1',
            is_public: categoryForm.value.is_public || false
        };

        // Emitir evento con los datos
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