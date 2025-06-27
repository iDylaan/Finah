<template>
    <Dialog v-model:visible="isVisible" modal :header="dialogTitle" :style="{ width: '500px', maxWidth: '95vw' }">
        <div v-if="isLoadingData" class="flex justify-center py-8">
            <ProgressSpinner />
        </div>
        <div v-else class="space-y-4">
            <div>
                <label class="block text-sm font-medium mb-2">Nombre del nivel</label>
                <InputText v-model.trim="levelForm.name" class="w-full" :disabled="isReadOnlyMode || isSubmitting"
                    :class="{ 'p-invalid': formErrors.name }" />
                <small v-if="formErrors.name" class="p-error block mt-1">{{ formErrors.name }}</small>
            </div>

            <div v-if="!isReadOnlyMode">
                <label class="block text-sm font-medium mb-2">Color</label>
                <div class="grid grid-cols-4 sm:grid-cols-6 gap-2">
                    <button v-for="(colorValue, colorKey) in LEVEL_COLORS" :key="`${colorKey}-${isDarkMode}`"
                        type="button" class="color-option-btn p-2 rounded-lg border-2 transition-all"
                        :class="levelForm.colorKey === colorKey ? 'border-primary-500 shadow-md' : 'border-transparent'"
                        :title="colorKey" :style="getColorButtonStyle(colorKey)" @click="selectColor(colorKey)">
                        <i class="pi pi-check text-white"
                            :class="levelForm.colorKey === colorKey ? 'visible' : 'invisible'"></i>
                    </button>
                </div>

                <div class="mt-4">
                    <label class="block text-sm font-medium mb-2">Vista previa</label>
                    <div class="flex flex-col gap-2">
                        <Tag class="py-2 px-3 w-full" rounded :style="tagPreviewStyle">
                            <span class="block w-full text-center">
                                {{ levelForm.name.trim() || 'Nivel' }}
                            </span>
                        </Tag>
                    </div>
                </div>
            </div>
            
            <!-- Vista de solo lectura -->
            <div v-if="isReadOnlyMode" class="mt-4">
                <label class="block text-sm font-medium mb-2">Vista previa</label>
                <div class="flex flex-col gap-2">
                    <Tag class="py-2 px-3 w-full" rounded :style="tagPreviewStyle">
                        <span class="block w-full text-center">
                            {{ levelForm.name.trim() || 'Nivel' }}
                        </span>
                    </Tag>
                </div>
                
                <div v-if="isPublicLevel" class="mt-4 p-3 bg-blue-50 dark:bg-blue-900 rounded-lg">
                    <div class="flex items-start gap-2">
                        <i class="pi pi-info-circle text-blue-500 dark:text-blue-300 mt-0.5"></i>
                        <div>
                            <p class="text-sm text-blue-800 dark:text-blue-200">
                                Este es un nivel público del sistema y no puede ser modificado.
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <template #footer>
            <div class="flex justify-end gap-2">
                <Button label="Cerrar" severity="secondary" outlined @click="handleClose"
                    :disabled="isSubmitting || isLoadingData" />

                <Button v-if="!isReadOnlyMode" :label="isEditMode ? 'Actualizar' : 'Crear'" severity="primary"
                    @click="submitLevel" :loading="isSubmitting" :disabled="!isFormValid || isSubmitting" />
            </div>
        </template>
    </Dialog>
</template>

<script setup>
// IMPORTS
import { ref, computed, watch, nextTick } from 'vue';
import { useLevelStore } from '@/stores/levels.js';
import { useSessionStore } from '@/stores/session.js';
import { useToast } from 'primevue/usetoast';
import { useUIStore } from '@/stores/ui';
import { LEVEL_COLORS, getLevelTagStyle as getTagStyleFromUtils } from '@/assets/constants/levels-colors.js';

// STORES
const levelStore = useLevelStore();
const UI = useUIStore();
const toast = useToast();
const sessionStore = useSessionStore();

// Referencia reactiva al modo oscuro desde la UI Store
const isDarkMode = computed(() => UI.isDarkTheme);

// PROPS
const props = defineProps({
    visible: Boolean,
    isNew: Boolean,
    levelId: [String, Number],
    level: Object,
    isLoading: Boolean,
});

// EMITS
const emit = defineEmits(['update:visible', 'close', 'success']);

// STATE
const isVisible = computed({
    get: () => props.visible,
    set: (value) => emit('update:visible', value)
});

// Formulario controlado por el componente
const levelForm = ref({
    name: '',
    colorKey: 'blue'
});

const formErrors = ref({});
const isSubmitting = ref(false);
const isLoadingData = ref(false);
const loadedLevelData = ref(null);

// COMPUTED
const dialogTitle = computed(() => {
    if (isReadOnlyMode.value) return 'Ver Nivel';
    return isNewLevel.value ? 'Crear Nivel' : 'Editar Nivel';
});

const isNewLevel = computed(() => props.isNew);
const isEditMode = computed(() => !isNewLevel.value);

const isPublicLevel = computed(() => {
    // Asegurarnos de que is_public se interprete correctamente como booleano
    return Boolean(loadedLevelData.value?.is_public);
});

const isReadOnlyMode = computed(() => {
    // Es un nivel público o no es nivel propio (del usuario actual)
    const readOnly = isPublicLevel.value || (
        !isNewLevel.value &&
        loadedLevelData.value &&
        loadedLevelData.value.user_id !== sessionStore.userId
    );
    
    return readOnly;
});

const isFormValid = computed(() => {
    return levelForm.value.name?.trim() &&
        levelForm.value.name.trim().length >= 2 &&
        Object.keys(formErrors.value).length === 0;
});

// Función para obtener estilos para los botones de selección de color
const getColorButtonStyle = (colorKey) => {
    return {
        backgroundColor: `var(--p-${LEVEL_COLORS[colorKey]}-500)`,
        color: '#fff'
    };
};

// Computar estilos para la vista previa del tag - Ahora es reactivo al cambio de color
const tagPreviewStyle = computed(() => {
    return getTagStyleFromUtils(levelForm.value.colorKey, isDarkMode.value);
});

// WATCHERS
// Observar cuando el modal se hace visible para inicializar correctamente
watch(() => props.visible, (newValue) => {
    if (newValue) {
        // NO inicializamos el formulario aquí para evitar limpiar datos ya cargados
        // La inicialización ahora se maneja en los watches específicos
    } else {
        // Limpiar después de cerrar
        resetFormState();
    }
});

// Watch para detectar cambios en los props que determinan qué nivel mostrar
watch([() => props.isNew, () => props.levelId, () => props.level, () => props.visible],
    async ([newIsNew, newLevelId, newLevel, newVisible]) => {
        if (newVisible) {
            // Prioridad: prop level > levelId > isNew
            if (newIsNew) {
                // Caso 1: Nuevo nivel
                setupNewLevel();
            } else if (newLevel) {
                // Caso 2: Nivel pasado como prop
                loadLevelFromProp(newLevel);
            } else if (newLevelId) {
                // Caso 3: ID de nivel para cargar
                await loadLevelData(newLevelId);
            } else {
                // Caso fallback: no deberíamos llegar aquí
                console.warn('⚠️ Modal abierto sin condiciones claras. Configurando como nuevo nivel.');
                setupNewLevel();
            }
        }
    }, { immediate: true });

// METHODS
const resetFormState = () => {
    formErrors.value = {};
    isSubmitting.value = false;
    isLoadingData.value = false;
};

const initializeForm = (data = {}) => {
    // Inicializar con valores por defecto y luego sobreescribir con los datos proporcionados
    levelForm.value = {
        name: '',
        colorKey: 'blue',
        ...data
    };
    
    resetFormState();
};

const setupNewLevel = () => {
    console.log('🆕 Configurando nuevo nivel');
    loadedLevelData.value = null;
    initializeForm(); // Formulario vacío para nuevo nivel
};

const loadLevelFromProp = (level) => {
    console.log('📥 Cargando nivel desde props:', level);

    if (!level) {
        console.warn('⚠️ No se proporcionó datos de nivel');
        setupNewLevel();
        return;
    }

    // Guardar nivel completo para acceder a propiedades como is_public
    loadedLevelData.value = { ...level };

    // Inicializar formulario con datos del nivel - aplicando trim al color
    initializeForm({
        name: level.name || '',
        colorKey: (level.color || 'blue').trim() // Aplicar trim al color
    });
    
    console.log('📋 Formulario cargado:', levelForm.value);
};

const loadLevelData = async (levelId) => {
    console.log('🔍 Cargando datos del nivel:', levelId);
    
    if (!levelId) {
        console.warn('⚠️ No se proporcionó ID de nivel');
        setupNewLevel();
        return;
    }
    
    isLoadingData.value = true;
    
    try {
        // Buscar nivel en los datos cargados
        const foundLevel = levelStore.levels.find(l => l.id === levelId);
        
        if (!foundLevel) {
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: 'No se encontró el nivel solicitado',
                life: 3000
            });
            handleClose();
            return;
        }
        
        console.log('✅ Nivel encontrado:', foundLevel);
        
        // Guardar nivel completo
        loadedLevelData.value = { ...foundLevel };
        
        // Inicializar formulario con datos del nivel - aplicando trim al color
        initializeForm({
            name: foundLevel.name || '',
            colorKey: (foundLevel.color || 'blue').trim() // Aplicar trim al color
        });
        
        console.log('📋 Formulario cargado:', levelForm.value);
        
    } catch (error) {
        console.error('❌ Error al cargar nivel:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'Ocurrió un error al cargar el nivel',
            life: 3000
        });
        handleClose();
    } finally {
        isLoadingData.value = false;
    }
};

// Función para seleccionar un color
const selectColor = (colorKey) => {
    console.log('Color seleccionado:', colorKey, LEVEL_COLORS[colorKey]);
    levelForm.value.colorKey = colorKey;
};

const validateForm = () => {
    const errors = {};
    
    // Validar nombre - asegurarnos de aplicar trim
    if (!levelForm.value.name?.trim()) {
        errors.name = 'El nombre es obligatorio';
    } else if (levelForm.value.name.trim().length < 2) {
        errors.name = 'El nombre debe tener al menos 2 caracteres';
    }
    
    formErrors.value = errors;
    return Object.keys(errors).length === 0;
};

const submitLevel = async () => {
    console.log('📝 Enviando formulario:', levelForm.value);
    
    // Verificación adicional para evitar modificar niveles públicos
    if (isPublicLevel.value) {
        toast.add({
            severity: 'error',
            summary: 'Operación no permitida',
            detail: 'No puedes modificar un nivel público del sistema',
            life: 3000
        });
        return;
    }
    
    if (!validateForm()) {
        console.warn('⚠️ Formulario inválido');
        return;
    }
    
    isSubmitting.value = true;
    
    try {
        // Preparar datos para enviar - aplicar trim al nombre y al color
        const levelData = {
            name: levelForm.value.name.trim(),
            colorKey: levelForm.value.colorKey.trim() // Aplicar trim al color
        };
        
        console.log('Datos a enviar:', levelData);
        
        let result;
        
        if (isNewLevel.value) {
            // Crear nuevo nivel
            result = await levelStore.createLevel(levelData, { toast });
        } else {
            // Actualizar nivel existente
            result = await levelStore.updateLevel(props.levelId, levelData, { toast });
        }
        
        if (result) {
            toast.add({
                severity: 'success',
                summary: 'Éxito',
                detail: isNewLevel.value ? 'Nivel creado correctamente' : 'Nivel actualizado correctamente',
                life: 3000
            });
            
            emit('success', result);
        }
    } catch (error) {
        console.error('❌ Error al enviar nivel:', error);
        
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: `Error al ${isNewLevel.value ? 'crear' : 'actualizar'} el nivel`,
            life: 3000
        });
    } finally {
        isSubmitting.value = false;
    }
};

const handleClose = () => {
    emit('close');
};
</script>

<style scoped>
.color-option-btn {
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
}

.color-option-btn:hover {
    transform: scale(1.05);
}
</style>