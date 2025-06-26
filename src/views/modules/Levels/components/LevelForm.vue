<template>
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" 
        :style="{ width: '500px', maxWidth: '95vw' }"
        :closeOnEscape="false"
        :dismissableMask="false"
        :closable="!isSubmitting">
        
        <div v-if="formErrors.general" class="p-4 bg-red-50 dark:bg-red-900 rounded-lg mb-4">
            <p class="text-red-600 dark:text-red-200">{{ formErrors.general }}</p>
        </div>

        <!-- Loading Skeleton -->
        <div v-if="isLoadingData || levelStore.loading" class="p-4">
            <Skeleton height="2rem" class="mb-3" />
            <Skeleton height="2rem" class="mb-3" />
            <Skeleton height="2rem" class="mb-3" />
        </div>

        <!-- Modo Solo Lectura (para niveles públicos o no propios) -->
        <div v-else-if="isReadOnlyMode" class="space-y-4">
            <div class="flex items-center justify-center my-4">
                <div class="w-16 h-16 rounded-lg flex items-center justify-center"
                    :style="{ backgroundColor: loadedLevelData?.color || '#6366f1' }">
                </div>
            </div>

            <!-- Detalles -->
            <div class="space-y-3">
                <!-- Nombre -->
                <div>
                    <h4 class="text-sm font-medium text-surface-600 dark:text-surface-400 mb-0">Nombre</h4>
                    <p class="text-lg font-semibold text-surface-900 dark:text-surface-100">{{ levelForm.name }}</p>
                </div>

                <!-- Badge público -->
                <div v-if="isPublicLevel" class="mt-3">
                    <p class="text-xs text-surface-500 mt-1">Los niveles preestablecidos no pueden ser modificados</p>
                </div>
            </div>
        </div>

        <!-- Formulario de Edición/Creación -->
        <div v-else class="space-y-4">
            <!-- Nombre -->
            <div>
                <label for="name" class="block text-sm font-medium mb-1">
                    Nombre <span class="text-red-500">*</span>
                </label>
                <InputText id="name" v-model="levelForm.name" 
                    :class="{ 'p-invalid': formErrors.name }"
                    placeholder="Ej: Necesidades básicas" 
                    class="w-full" 
                    :disabled="isSubmitting" />
                <small v-if="formErrors.name" class="p-error block mt-1">{{ formErrors.name }}</small>
            </div>

            <!-- Color Picker -->
            <div>
                <label for="color" class="block text-sm font-medium mb-1">Color</label>
                <CustomColorPicker v-model="levelForm.color" 
                    :disabled="isSubmitting || isReadOnlyMode" />
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
                    severity="primary" 
                    @click="submitLevel" 
                    :loading="isSubmitting" 
                    :disabled="!isFormValid || isSubmitting" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch } from 'vue';
import { useLevelStore } from '@/stores/levels.js';
import { useSessionStore } from '@/stores/session.js';
import { useToast } from 'primevue/usetoast';

// COMPONENTS
import CustomColorPicker from '@/components/CustomColorPicker.vue';

// STORES & COMPOSABLES
const levelStore = useLevelStore();
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
    levelId: {
        type: String,
        default: null
    },
    level: {
        type: Object,
        default: null
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
const loadedLevelData = ref(null);
const levelForm = ref({
    name: '',
    color: '#6366f1'
});
const formErrors = ref({});

// COMPUTED PROPERTIES
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

const isNewLevel = computed(() => props.isNew);

const isEditMode = computed(() => !props.isNew && !isReadOnlyMode.value);

const dialogTitle = computed(() => {
    if (isNewLevel.value) return 'Nuevo Nivel';
    if (isEditMode.value) return 'Editar Nivel';
    return 'Detalles de Nivel';
});

const isPublicLevel = computed(() => {
    return loadedLevelData.value?.is_public || false;
});

const isReadOnlyMode = computed(() => {
    // Modo solo lectura si:
    // - Es un nivel público
    // - O no es nivel propio (del usuario actual)
    return isPublicLevel.value || (
        !isNewLevel.value && 
        loadedLevelData.value && 
        loadedLevelData.value.user_id !== sessionStore.userId
    );
});

const isFormValid = computed(() => {
    return levelForm.value.name?.trim() && 
           levelForm.value.name.trim().length >= 2 &&
           Object.keys(formErrors.value).length === 0;
});

// WATCHERS
watch(() => props.visible, (newValue) => {
    if (newValue) {
        initializeForm();
    }
});

watch([() => props.isNew, () => props.levelId, () => props.level], 
    ([newIsNew, newLevelId, newLevel]) => {
        if (props.visible) {
            if (newIsNew) {
                setupNewLevel();
            } else if (newLevel) {
                loadLevelFromProp(newLevel);
            } else if (newLevelId) {
                loadLevelData(newLevelId);
            }
        }
    }, { immediate: true });

// FUNCTIONS
const initializeForm = () => {
    console.log('🔄 Inicializando formulario...', { 
        isNew: props.isNew, 
        levelId: props.levelId
    });
    
    formErrors.value = {};
    loadedLevelData.value = null;
    
    if (props.isNew) {
        setupNewLevel();
    } else if (props.level) {
        loadLevelFromProp(props.level);
    } else if (props.levelId) {
        loadLevelData(props.levelId);
    } else {
        resetForm();
    }
};

const setupNewLevel = () => {
    console.log('🆕 Configurando nuevo nivel');
    
    resetForm();
};

const loadLevelFromProp = (level) => {
    console.log('📥 Cargando nivel desde props:', level);
    
    if (!level) {
        console.warn('⚠️ No se proporcionó datos de nivel');
        resetForm();
        return;
    }
    
    loadedLevelData.value = { ...level };
    
    levelForm.value = {
        name: level.name || '',
        color: level.color || '#6366f1'
    };
};

const loadLevelData = async (levelId) => {
    if (!levelId) {
        console.warn('⚠️ No se proporcionó ID de nivel para cargar');
        return;
    }
    
    isLoadingData.value = true;
    
    try {
        console.log('📥 Cargando nivel:', levelId);
        
        // Buscar primero en los niveles cargados
        let foundLevel = levelStore.levels.find(l => l.id === levelId);
        
        if (!foundLevel) {
            // Si no encontramos el nivel en los datos locales, intentar obtenerlo de la API
            const { data, error } = await supabase
                .from('levels')
                .select('*')
                .eq('id', levelId)
                .single();
                
            if (error) {
                throw error;
            }
            
            foundLevel = data;
        }
        
        if (!foundLevel) {
            console.warn('⚠️ Nivel no encontrado');
            formErrors.value = { general: 'No se pudo encontrar el nivel' };
            return;
        }
        
        console.log('✅ Nivel encontrado:', foundLevel);
        loadedLevelData.value = { ...foundLevel };
        
        levelForm.value = {
            name: foundLevel.name || '',
            color: foundLevel.color || '#6366f1'
        };
        
    } catch (error) {
        console.error('💥 Error cargando nivel:', error);
        formErrors.value = { general: 'Error cargando los datos del nivel' };
    } finally {
        isLoadingData.value = false;
    }
};

const resetForm = () => {
    levelForm.value = {
        name: '',
        color: '#6366f1'
    };
    
    formErrors.value = {};
    loadedLevelData.value = null;
};

const validateForm = () => {
    const errors = {};

    if (!levelForm.value.name?.trim()) {
        errors.name = 'El nombre es requerido';
    } else if (levelForm.value.name.trim().length < 2) {
        errors.name = 'El nombre debe tener al menos 2 caracteres';
    } else if (levelForm.value.name.trim().length > 100) {
        errors.name = 'El nombre no puede exceder 100 caracteres';
    }

    formErrors.value = errors;
    return Object.keys(errors).length === 0;
};

const handleClose = () => {
    console.log('❌ Cerrando modal de nivel');
    
    emit('close');
    resetForm();
};

const submitLevel = async () => {
    console.log('📤 Enviando formulario de nivel...', { 
        isNew: isNewLevel.value,
        levelId: props.levelId 
    });
    
    if (!validateForm()) {
        console.warn('⚠️ Formulario no válido');
        return;
    }

    isSubmitting.value = true;

    try {
        // Preparar datos para enviar
        const levelData = {
            name: levelForm.value.name.trim(),
            color: levelForm.value.color || '#6366f1'
        };
        
        // Agregar ID si es edición
        if (!isNewLevel.value && props.levelId) {
            levelData.id = props.levelId;
        }
        
        console.log('📋 Datos a enviar:', levelData);

        let result;
        
        // Usar el store directamente para guardar
        if (isNewLevel.value) {
            // Crear nuevo nivel
            result = await levelStore.createLevel(levelData, { toast });
        } else {
            // Actualizar nivel existente
            result = await levelStore.updateLevel(props.levelId, levelData, { toast });
        }
        
        if (result) {
            // Emitir evento de éxito con el nivel creado/actualizado
            emit('success', result);
            
            // Cerrar modal
            handleClose();
        }

    } catch (error) {
        console.error('💥 Error guardando nivel:', error);
        
        // Mostrar mensaje de error adicional (si es necesario)
        if (!error.message?.includes('Error')) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se pudo guardar el nivel',
                life: 5000
            });
        }
    } finally {
        isSubmitting.value = false;
    }
};

// HOOKS
watch(() => levelForm.value.name, () => {
    if (formErrors.value.name) validateForm();
});

// EXPOSE
defineExpose({
    resetForm,
    initializeForm,
    loadLevelData
});
</script>