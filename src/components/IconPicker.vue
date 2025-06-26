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

        <!-- Selector de iconos solamente -->
        <Popover ref="op" class="w-96" :autoHide="false">
            <div class="rounded-lg">
                <div class="flex justify-between items-center mb-4">
                    <span class="text-sm font-medium text-surface-700 dark:text-surface-300">Seleccionar Icono</span>
                    <Button icon="pi pi-times" size="small" text rounded @click="closePicker" />
                </div>

                <!-- Selector de librería -->
                <div class="mb-4">
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

                <!-- Buscador -->
                <div class="mb-4">
                    <InputText v-model="searchQuery" placeholder="Buscar icono..." class="w-full" />
                </div>

                <!-- Grid de iconos -->
                <div class="icon-grid max-h-80 w-full overflow-y-auto p-1">
                    <div class="grid grid-cols-7 gap-2 p-1">
                        <!-- PrimeIcons -->
                        <template v-if="currentLibrary === ICONS.PRIMEVUE">
                            <div v-for="icon in filteredPrimeIcons" :key="icon"
                                class="icon-item w-10 h-10 rounded-md cursor-pointer border-2 border-transparent hover:border-primary-400 transition-all duration-150 flex items-center justify-center bg-surface-100 dark:bg-surface-700 hover:bg-surface-200 dark:hover:bg-surface-600"
                                :class="{ 'ring-2 ring-primary-500 bg-primary-50 dark:bg-primary-900': selectedPrimeIcon === icon }"
                                @click="selectIcon(icon)" :title="icon">
                                <i :class="icon" class="text-surface-700 dark:text-surface-300 text-sm"></i>
                            </div>
                        </template>

                        <!-- Material Symbols -->
                        <template v-else-if="currentLibrary === ICONS.MATERIAL">
                            <div v-for="icon in filteredMaterialIcons" :key="icon"
                                class="icon-item w-10 h-10 rounded-md cursor-pointer border-2 border-transparent hover:border-primary-400 transition-all duration-150 flex items-center justify-center bg-surface-100 dark:bg-surface-700 hover:bg-surface-200 dark:hover:bg-surface-600"
                                :class="{ 'ring-2 ring-primary-500 bg-primary-50 dark:bg-primary-900': selectedMaterialIcon === icon }"
                                @click="selectIcon(icon)" :title="icon">
                                <span
                                    class="material-symbols-rounded text-surface-700 dark:text-surface-300 icon-grid-item">
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

                <!-- Info del icono seleccionado -->
                <div v-if="finalIcon" class="mt-3 p-3 bg-surface-100 dark:bg-surface-700 rounded text-sm">
                    <div class="space-y-2">
                        <div class="flex justify-between items-center">
                            <span class="font-medium">Icono:</span>
                            <code
                                class="text-xs bg-surface-200 dark:bg-surface-600 px-2 py-1 rounded">{{ finalIcon }}</code>
                        </div>
                    </div>
                </div>
            </div>
        </Popover>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import materialSymbolsData from '@/assets/constants/material-symbols.json';
import primevueIconsData from '@/assets/constants/primevue-icons.json';
import ICONS from '@/assets/constants/icon-providers.js'

// Props (mantener igual...)
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
const op = ref();
const currentLibrary = ref(ICONS.PRIMEVUE);
const searchQuery = ref('');
const debouncedSearchQuery = ref(''); // NUEVA: Query con debounce
const searchTimeout = ref(null); // NUEVA: Timeout para debounce

// Iconos seleccionados independientes
const selectedPrimeIcon = ref('pi pi-folder');
const selectedMaterialIcon = ref('folder');

// NUEVA: Función de debounce
function debounceSearch(query) {
    // Limpiar timeout anterior
    if (searchTimeout.value) {
        clearTimeout(searchTimeout.value);
    }

    // Crear nuevo timeout
    searchTimeout.value = setTimeout(() => {
        console.log('🔍 Aplicando filtro con delay:', query);
        debouncedSearchQuery.value = query;
    }, 300); // 300ms de delay
}

// NUEVA: Watcher para searchQuery que aplica debounce
watch(searchQuery, (newQuery) => {
    console.log('⌨️ Usuario escribió:', newQuery);
    debounceSearch(newQuery);
});

// Función para abrir el picker
const openPicker = (event) => {
    op.value.show(event);
}

// Función para cerrar el picker
const closePicker = () => {
    op.value.hide();
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

// Computed
const finalIcon = computed(() => {
    return currentLibrary.value === ICONS.MATERIAL ? selectedMaterialIcon.value : selectedPrimeIcon.value;
});

// ACTUALIZADO: Filtros usando debouncedSearchQuery
const filteredPrimeIcons = computed(() => {
    const query = debouncedSearchQuery.value.toLowerCase();
    if (!query) return primeIcons;

    console.log('🔍 Filtrando PrimeIcons con:', query);
    return primeIcons.filter(icon =>
        icon.toLowerCase().includes(query)
    );
});

const filteredMaterialIcons = computed(() => {
    const query = debouncedSearchQuery.value.toLowerCase();
    if (!query) return materialIcons;

    console.log('🔍 Filtrando Material Icons con:', query);
    return materialIcons.filter(icon =>
        icon.toLowerCase().includes(query)
    );
});

const filteredIcons = computed(() => {
    return currentLibrary.value === ICONS.PRIMEVUE ? filteredPrimeIcons.value : filteredMaterialIcons.value;
});

// Watchers (mantener igual...)
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

// Funciones (mantener igual...)
function getMaterialIconName(fullIcon) {
    return fullIcon;
}

function detectLibrary(icon) {
    if (icon?.startsWith('pi ')) {
        currentLibrary.value = ICONS.PRIMEVUE;
        selectedPrimeIcon.value = icon;
    } else if (icon) {
        currentLibrary.value = ICONS.MATERIAL;
        selectedMaterialIcon.value = icon;
    }
}

function selectIcon(icon) {
    if (currentLibrary.value === ICONS.PRIMEVUE) {
        selectedPrimeIcon.value = icon;
    } else {
        selectedMaterialIcon.value = icon;
    }
    searchQuery.value = '';
    debouncedSearchQuery.value = ''; // NUEVA: Limpiar también el debounced
}

function changeLibrary(newLibrary) {
    currentLibrary.value = newLibrary;
}

// NUEVA: Limpiar timeout al desmontar componente
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
/* ESTILOS ACTUALIZADOS para mejor reactividad */
.icon-grid {
    scrollbar-width: thin;
    scrollbar-color: #cbd5e1 transparent;
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

.icon-item {
    aspect-ratio: 1;
}

.icon-item:hover {
    transform: scale(1.05);
}

.icon-grid-item {
    font-size: 18px;
}
</style>