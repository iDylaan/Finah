<template>
    <div>
        <!-- DEBUG (temporal para verificar) -->
        <div class="text-xs text-surface-500 mb-1" v-if="false">
            Color prop: {{ color }}, IconType: {{ iconType }}
        </div>

        <!-- Botón del icono con color dinámico -->
        <div class="relative mt-1 w-[70px]">
            <Button :style="buttonStyles" @click="openPicker" :disabled="disabled" severity="secondary" outlined
                size="large">
                <template #icon>
                    <i v-if="currentLibrary === ICONS.PRIMEVUE" :class="finalIcon"
                        class="text-white text-xl !text-white" style="color: white !important; font-size: 40px"></i>
                    <span v-else-if="currentLibrary === ICONS.MATERIAL"
                        class="material-symbols-rounded text-white text-xl !text-white"
                        style="color: white !important; font-size: 50px">
                        {{ getMaterialIconName(finalIcon) }}
                    </span>
                </template>
            </Button>

            <!-- Badge de editar en esquina superior derecha -->
            <div class="absolute -top-1 -right-1 w-6 h-6 bg-surface-100 dark:bg-surface-700 border-2 border-surface-200 dark:border-surface-600 rounded-full flex items-center justify-center cursor-pointer transition-all duration-200 z-10"
                @click="openPicker" :class="{ 'opacity-50 cursor-not-allowed': disabled }">
                <i class="pi pi-pencil text-surface-600 dark:text-surface-300 text-xs"></i>
            </div>
        </div>

        <!-- Selector de iconos usando Dialog en lugar de Popover -->
        <Dialog v-model:visible="isPickerVisible" modal header="Seleccionar Icono"
            :style="{ width: '95vw', maxWidth: '56rem' }" :breakpoints="{ '768px': '100vw' }"
            class="mobile-fullscreen-dialog icon-picker-dialog"
            :pt="{
                root: { class: 'z-[9999]' },
                mask: { class: 'z-[9998]' },
                content: { class: 'icon-picker-content flex flex-col p-0' }
            }"
            :dismissableMask="true">
            <div class="flex flex-col h-full md:h-auto">
                <!-- Selector de librería (fijo) -->
                <div class="flex-shrink-0 px-6 pt-6 pb-4">
                    <div class="flex gap-2">
                        <Button :label="`PrimeIcons (${primeIcons.length})`"
                            :severity="currentLibrary === ICONS.PRIMEVUE ? 'primary' : 'secondary'"
                            :outlined="currentLibrary !== ICONS.PRIMEVUE" size="small"
                            @click="changeLibrary(ICONS.PRIMEVUE)" />
                        <Button :label="`Material (${materialIcons.length})`"
                            :severity="currentLibrary === ICONS.MATERIAL ? 'primary' : 'secondary'"
                            :outlined="currentLibrary !== ICONS.MATERIAL" size="small"
                            @click="changeLibrary(ICONS.MATERIAL)" />
                    </div>
                </div>

                <!-- Buscador (fijo) -->
                <div class="flex-shrink-0 px-6 pb-4">
                    <InputText v-model="searchQuery" placeholder="Buscar icono..." class="w-full" />
                </div>

                <!-- Grid de iconos (scrolleable) -->
                <div class="icon-grid-container relative flex-1 md:flex-none overflow-hidden">
                    <div class="icon-grid w-full h-full md:h-auto md:max-h-[40vh] overflow-y-auto pb-20">
                        <div class="grid grid-cols-5 pt-2 px-6 md:grid-cols-7 gap-2 md:gap-2">
                            <!-- PrimeIcons -->
                            <template v-if="currentLibrary === ICONS.PRIMEVUE">
                                <div v-for="icon in filteredPrimeIcons" :key="icon"
                                    class="icon-item w-full aspect-square rounded-md cursor-pointer border-2 border-transparent hover:border-primary-400 transition-all duration-150 flex items-center justify-center bg-surface-100 dark:bg-surface-700 hover:bg-surface-200 dark:hover:bg-surface-600"
                                    :class="{ 'ring-2 ring-primary-500 bg-primary-50 dark:bg-primary-900': tempSelectedPrimeIcon === icon }"
                                    @click="selectIcon(icon)" :title="icon">
                                    <i :class="icon" class="text-surface-700 dark:text-surface-300 prime-icon-size"></i>
                                </div>
                            </template>

                            <!-- Material Symbols -->
                            <template v-else-if="currentLibrary === ICONS.MATERIAL">
                                <div v-for="icon in filteredMaterialIcons" :key="icon"
                                    class="icon-item w-full aspect-square rounded-md cursor-pointer border-2 border-transparent hover:border-primary-400 transition-all duration-150 flex items-center justify-center bg-surface-100 dark:bg-surface-700 hover:bg-surface-200 dark:hover:bg-surface-600"
                                    :class="{ 'ring-2 ring-primary-500 bg-primary-50 dark:bg-primary-900': tempSelectedMaterialIcon === icon }"
                                    @click="selectIcon(icon)" :title="icon">
                                    <span
                                        class="material-symbols-rounded text-surface-700 dark:text-surface-300 material-icon-size">
                                        {{ icon }}
                                    </span>
                                </div>
                            </template>
                        </div>
                        <!-- No results -->
                        <div v-if="filteredIcons.length === 0" class="text-center py-8 text-surface-500">
                            <i class="pi pi-search text-2xl mb-2 block"></i>
                            <p>No se encontraron iconos</p>
                            <small>Intenta con otro término de búsqueda</small>
                        </div>
                    </div>
                    <!-- Efecto de difuminado inferior -->
                    <div class="icon-grid-fade absolute bottom-0 left-0 right-0 h-16 pointer-events-none"></div>
                </div>

                <!-- Info del icono seleccionado (fijo) -->
                <div v-if="tempFinalIcon" class="flex-shrink-0 px-6 pb-6 pt-3">
                    <div class="p-3 bg-surface-100 dark:bg-surface-700 rounded text-sm">
                        <div class="space-y-2">
                            <div class="flex justify-between items-center">
                                <span class="font-medium">Icono:</span>
                                <code class="text-xs bg-surface-200 dark:bg-surface-600 px-2 py-1 rounded">{{ tempFinalIcon }}</code>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <template #footer>
                <div class="flex justify-end gap-2">
                    <Button label="Cancelar" severity="secondary" outlined @click="closePicker" />
                    <Button label="Seleccionar" severity="primary" @click="applyAndClose" />
                </div>
            </template>
        </Dialog>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import materialSymbolsData from '@/assets/constants/material-symbols.json';
import primevueIconsData from '@/assets/constants/primevue-icons.json';
import ICONS from '@/assets/constants/icon-providers.js';
import { materialIconKeywords, primeIconKeywords } from '@/assets/constants/icon-keywords.js';

// Props
const props = defineProps({
    modelValue: {
        type: String,
        default: 'pi pi-folder'
    },
    iconType: {
        type: String,
        default: ICONS.PRIMEVUE,
        validator: (value) => [ICONS.PRIMEVUE, ICONS.MATERIAL].includes(value)
    },
    color: {
        type: String,
        default: '#6366f1'
    },
    disabled: {
        type: Boolean,
        default: false
    }
});

// Emits
const emit = defineEmits(['update:modelValue', 'update:iconType']);

// Variables reactivas
const isPickerVisible = ref(false);
const currentLibrary = ref(ICONS.PRIMEVUE);
const searchQuery = ref('');
const debouncedSearchQuery = ref('');
const searchTimeout = ref(null);

// Variables para mantener el estado temporal (antes de confirmar)
const tempSelectedPrimeIcon = ref('pi pi-folder');
const tempSelectedMaterialIcon = ref('folder');

// Variables para el valor final (confirmado)
const selectedPrimeIcon = ref('pi pi-folder');
const selectedMaterialIcon = ref('folder');

// NUEVA: Función de debounce
function debounceSearch(query) {
    if (searchTimeout.value) {
        clearTimeout(searchTimeout.value);
    }

    searchTimeout.value = setTimeout(() => {
        debouncedSearchQuery.value = query;
    }, 300);
}

// Watcher para searchQuery
watch(searchQuery, (newQuery) => {
    debounceSearch(newQuery);
});

// Función para abrir el picker
const openPicker = () => {
    if (props.disabled) return;

    // Al abrir, inicializamos los valores temporales con los actuales
    tempSelectedPrimeIcon.value = selectedPrimeIcon.value;
    tempSelectedMaterialIcon.value = selectedMaterialIcon.value;

    isPickerVisible.value = true;
}

// Función para cerrar el picker sin aplicar cambios
const closePicker = () => {
    isPickerVisible.value = false;
    searchQuery.value = '';
    debouncedSearchQuery.value = '';
}

// Nueva función para aplicar cambios y cerrar
const applyAndClose = () => {
    // Aplicar los cambios temporales
    selectedPrimeIcon.value = tempSelectedPrimeIcon.value;
    selectedMaterialIcon.value = tempSelectedMaterialIcon.value;

    // Cerrar el picker
    closePicker();
}

// Computed para color seguro
const safePreviewColor = computed(() => {
    return props.color || '#6366f1';
});

// Computed para estilos del botón
const buttonStyles = computed(() => {
    const color = safePreviewColor.value;
    return {
        backgroundColor: `${color} !important`,
        borderColor: `${color}40 !important`,
        '--icon-button-color': color,
        height: '70px',
        width: '70px'
    };
});

// Iconos
const primeIcons = primevueIconsData;
const materialIcons = materialSymbolsData;

// Computed para icono final
const finalIcon = computed(() => {
    return currentLibrary.value === ICONS.MATERIAL ? selectedMaterialIcon.value : selectedPrimeIcon.value;
});

// Computed para icono temporal (en el modal)
const tempFinalIcon = computed(() => {
    return currentLibrary.value === ICONS.MATERIAL ? tempSelectedMaterialIcon.value : tempSelectedPrimeIcon.value;
});

// Filtros usando debouncedSearchQuery con búsqueda mejorada
const filteredPrimeIcons = computed(() => {
    const query = debouncedSearchQuery.value.toLowerCase().trim();
    if (!query) return primeIcons;
    
    return primeIcons.filter(icon => {
        // Buscar en el nombre del icono
        if (icon.toLowerCase().includes(query)) return true;
        
        // Buscar en las palabras clave en español
        const keywords = primeIconKeywords[icon] || [];
        return keywords.some(keyword => keyword.toLowerCase().includes(query));
    });
});

const filteredMaterialIcons = computed(() => {
    const query = debouncedSearchQuery.value.toLowerCase().trim();
    if (!query) return materialIcons;
    
    return materialIcons.filter(icon => {
        // Buscar en el nombre del icono
        if (icon.toLowerCase().includes(query)) return true;
        
        // Buscar en las palabras clave en español
        const keywords = materialIconKeywords[icon] || [];
        return keywords.some(keyword => keyword.toLowerCase().includes(query));
    });
});

const filteredIcons = computed(() => {
    return currentLibrary.value === ICONS.PRIMEVUE ? filteredPrimeIcons.value : filteredMaterialIcons.value;
});

// Watchers
watch(() => props.modelValue, (newValue) => {
    if (newValue && newValue !== finalIcon.value) {
        detectLibrary(newValue);
    }
}, { immediate: true });

watch(() => props.iconType, (newType) => {
    if (newType && newType !== currentLibrary.value) {
        currentLibrary.value = newType;
    }
}, { immediate: true });

watch(finalIcon, (newIcon) => {
    if (newIcon !== props.modelValue) {
        emit('update:modelValue', newIcon);
    }
});

watch(currentLibrary, (newLibrary) => {
    if (newLibrary !== props.iconType) {
        emit('update:iconType', newLibrary);
    }
});

// Funciones
function getMaterialIconName(fullIcon) {
    return fullIcon;
}

function detectLibrary(icon) {
    if (icon?.startsWith('pi ')) {
        currentLibrary.value = ICONS.PRIMEVUE;
        selectedPrimeIcon.value = icon;
        tempSelectedPrimeIcon.value = icon;
    } else if (icon) {
        currentLibrary.value = ICONS.MATERIAL;
        selectedMaterialIcon.value = icon;
        tempSelectedMaterialIcon.value = icon;
    }
}

function selectIcon(icon) {
    // Actualizamos solo los valores temporales
    if (currentLibrary.value === ICONS.PRIMEVUE) {
        tempSelectedPrimeIcon.value = icon;
    } else {
        tempSelectedMaterialIcon.value = icon;
    }
}

function changeLibrary(newLibrary) {
    currentLibrary.value = newLibrary;
}

// Limpiar timeout al desmontar componente
import { onUnmounted } from 'vue';
onUnmounted(() => {
    if (searchTimeout.value) {
        clearTimeout(searchTimeout.value);
    }
});

// Inicializar
detectLibrary(props.modelValue);
</script>

<style scoped>
/* Estilos para la cuadrícula de iconos */
.icon-grid-container {
    min-height: 0;
}

.icon-grid {
    scrollbar-width: thin;
    scrollbar-color: #cbd5e1 transparent;
    overscroll-behavior: contain;
    overflow-y: auto;
}

.icon-grid::-webkit-scrollbar {
    width: 6px;
}

.icon-grid::-webkit-scrollbar-track {
    background: transparent;
}

.icon-grid::-webkit-scrollbar-thumb {
    background-color: #cbd5e1;
    border-radius: 3px;
}

.icon-grid::-webkit-scrollbar-thumb:hover {
    background-color: #94a3b8;
}

.icon-item:hover {
    transform: scale(1.05);
}

/* Tamaños de iconos responsive */
.prime-icon-size {
    font-size: 1.5rem;
}

.material-icon-size {
    font-size: 2rem;
}

@media (min-width: 768px) {
    .prime-icon-size {
        font-size: 2.4rem;
    }
    
    .material-icon-size {
        font-size: 3rem;
    }
}

/* Efecto de difuminado inferior */
.icon-grid-fade {
    background: linear-gradient(to top, 
        var(--p-content-background) 0%, 
        var(--p-content-background) 20%,
        transparent 100%);
}

/* Asegurarse que el modal se superponga a otros modales */
:deep(.p-dialog.z-\[9999\]) {
    z-index: 9999 !important;
}

:deep(.p-dialog-mask.z-\[9998\]) {
    z-index: 9998 !important;
}

/* Modal de altura completa en mobile */
@media (max-width: 768px) {
    :deep(.icon-picker-dialog .p-dialog) {
        height: 100vh;
        max-height: 100vh;
        margin: 0;
        border-radius: 0;
    }

    :deep(.icon-picker-dialog .p-dialog-content) {
        overflow: hidden !important;
        padding: 0 !important;
    }
}

/* Asegurar que el contenido del dialog use flexbox */
:deep(.icon-picker-dialog .p-dialog-content) {
    overflow: hidden;
}
</style>