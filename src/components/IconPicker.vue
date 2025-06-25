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
                    <i v-if="currentLibrary === 'primeicons'" :class="finalIcon" class="text-white text-xl !text-white"
                        style="color: white !important; font-size: 40px"></i>
                    <span v-else-if="currentLibrary === 'material'"
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
                            :severity="currentLibrary === 'primeicons' ? 'primary' : 'secondary'"
                            :outlined="currentLibrary !== 'primeicons'" size="small"
                            @click="changeLibrary('primeicons')" />
                        <Button :label="`Material (${materialIcons.length})`"
                            :severity="currentLibrary === 'material' ? 'primary' : 'secondary'"
                            :outlined="currentLibrary !== 'material'" size="small"
                            @click="changeLibrary('material')" />
                    </div>
                </div>

                <!-- Buscador -->
                <div class="mb-4">
                    <InputText v-model="searchQuery" placeholder="Buscar icono..." class="w-full" />
                </div>

                <!-- Grid de iconos -->
                <div class="icon-grid max-h-80 overflow-y-auto p-1">
                    <div class="grid grid-cols-8 gap-2 p-1">
                        <!-- PrimeIcons -->
                        <template v-if="currentLibrary === 'primeicons'">
                            <div v-for="icon in filteredPrimeIcons" :key="icon"
                                class="icon-item w-10 h-10 rounded-md cursor-pointer border-2 border-transparent hover:border-primary-400 transition-all duration-150 flex items-center justify-center bg-surface-100 dark:bg-surface-700 hover:bg-surface-200 dark:hover:bg-surface-600"
                                :class="{ 'ring-2 ring-primary-500 bg-primary-50 dark:bg-primary-900': selectedPrimeIcon === icon }"
                                @click="selectIcon(icon)" :title="icon">
                                <i :class="icon" class="text-surface-700 dark:text-surface-300 text-sm"></i>
                            </div>
                        </template>

                        <!-- Material Symbols -->
                        <template v-else-if="currentLibrary === 'material'">
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
                            <code class="text-xs bg-surface-200 dark:bg-surface-600 px-2 py-1 rounded">{{ finalIcon }}</code>
                        </div>
                    </div>
                </div>
            </div>
        </Popover>
    </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue';

// Props
const props = defineProps({
    modelValue: {
        type: String,
        default: 'pi pi-folder'
    },
    iconType: {
        type: String,
        default: 'primeicons',
        validator: (value) => ['primeicons', 'material'].includes(value)
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
const currentLibrary = ref('primeicons');
const searchQuery = ref('');

// Iconos seleccionados independientes con valores por defecto de folder
const selectedPrimeIcon = ref('pi pi-folder');
const selectedMaterialIcon = ref('folder');

// Función para abrir el picker
const openPicker = (event) => {
    op.value.show(event);
}

// Función para cerrar el picker (solo desde el botón X)
const closePicker = () => {
    op.value.hide();
}

// Computed para color seguro (solo para el display)
const safePreviewColor = computed(() => {
    const color = props.color || '#6366f1';
    console.log('🎨 IconPicker safePreviewColor:', color);
    return color;
});

// Computed para estilos del botón que se actualizan reactivamente
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

// Iconos PrimeIcons
const primeIcons = [
    'pi pi-home', 'pi pi-user', 'pi pi-cog', 'pi pi-heart', 'pi pi-star',
    'pi pi-search', 'pi pi-plus', 'pi pi-minus', 'pi pi-times', 'pi pi-check',
    'pi pi-arrow-left', 'pi pi-arrow-right', 'pi pi-arrow-up', 'pi pi-arrow-down',
    'pi pi-chevron-left', 'pi pi-chevron-right', 'pi pi-chevron-up', 'pi pi-chevron-down',
    'pi pi-calendar', 'pi pi-clock', 'pi pi-envelope', 'pi pi-phone', 'pi pi-map-marker',
    'pi pi-shopping-cart', 'pi pi-credit-card', 'pi pi-money-bill', 'pi pi-wallet',
    'pi pi-file', 'pi pi-folder', 'pi pi-image', 'pi pi-video', 'pi pi-music',
    'pi pi-camera', 'pi pi-microphone', 'pi pi-volume-up', 'pi pi-volume-down',
    'pi pi-wifi', 'pi pi-bluetooth', 'pi pi-signal', 'pi pi-battery',
    'pi pi-lock', 'pi pi-unlock', 'pi pi-key', 'pi pi-shield',
    'pi pi-eye', 'pi pi-eye-slash', 'pi pi-bookmark', 'pi pi-tag',
    'pi pi-thumbs-up', 'pi pi-thumbs-down', 'pi pi-share', 'pi pi-download',
    'pi pi-upload', 'pi pi-cloud', 'pi pi-server', 'pi pi-database',
    'pi pi-chart-bar', 'pi pi-chart-pie', 'pi pi-chart-line', 'pi pi-percentage',
    'pi pi-globe', 'pi pi-flag', 'pi pi-building', 'pi pi-car',
    'pi pi-plane', 'pi pi-train', 'pi pi-bus', 'pi pi-bicycle',
    'pi pi-coffee', 'pi pi-pizza-slice', 'pi pi-apple', 'pi pi-gift',
    'pi pi-sun', 'pi pi-moon', 'pi pi-cloud-rain', 'pi pi-snowflake',
    'pi pi-fire', 'pi pi-bolt', 'pi pi-leaf', 'pi pi-tree',
    'pi pi-desktop', 'pi pi-mobile', 'pi pi-tablet', 'pi pi-gamepad',
    'pi pi-print', 'pi pi-save', 'pi pi-copy', 'pi pi-paste',
    'pi pi-cut', 'pi pi-undo', 'pi pi-redo', 'pi pi-refresh',
    'pi pi-sync', 'pi pi-spin', 'pi pi-pause', 'pi pi-play',
    'pi pi-stop', 'pi pi-forward', 'pi pi-backward', 'pi pi-step-forward',
    'pi pi-step-backward', 'pi pi-eject', 'pi pi-random', 'pi pi-replay'
];

// Iconos Material Symbols
const materialIcons = [
    'home', 'person', 'settings', 'favorite', 'star',
    'search', 'add', 'remove', 'close', 'check',
    'arrow_back', 'arrow_forward', 'arrow_upward', 'arrow_downward',
    'chevron_left', 'chevron_right', 'expand_less', 'expand_more',
    'calendar_today', 'schedule', 'mail', 'phone', 'place',
    'shopping_cart', 'credit_card', 'payments', 'account_balance_wallet',
    'description', 'folder', 'image', 'videocam', 'music_note',
    'photo_camera', 'mic', 'volume_up', 'volume_down',
    'wifi', 'bluetooth', 'signal_cellular_alt', 'battery_full',
    'lock', 'lock_open', 'vpn_key', 'security',
    'visibility', 'visibility_off', 'bookmark', 'label',
    'thumb_up', 'thumb_down', 'share', 'download',
    'upload', 'cloud', 'dns', 'storage',
    'bar_chart', 'pie_chart', 'show_chart', 'percent',
    'language', 'flag', 'business', 'directions_car',
    'flight', 'train', 'directions_bus', 'pedal_bike',
    'local_cafe', 'local_pizza', 'apple', 'card_giftcard',
    'wb_sunny', 'brightness_3', 'cloud_rain', 'ac_unit',
    'local_fire_department', 'flash_on', 'eco', 'park',
    'computer', 'smartphone', 'tablet', 'sports_esports',
    'print', 'save', 'content_copy', 'content_paste',
    'content_cut', 'undo', 'redo', 'refresh',
    'sync', 'autorenew', 'pause', 'play_arrow',
    'stop', 'skip_next', 'skip_previous', 'fast_forward',
    'fast_rewind', 'eject', 'shuffle', 'repeat'
];

// Computed
const finalIcon = computed(() => {
    return currentLibrary.value === 'material' ? selectedMaterialIcon.value : selectedPrimeIcon.value;
});

const filteredPrimeIcons = computed(() => {
    if (!searchQuery.value) return primeIcons;
    return primeIcons.filter(icon =>
        icon.toLowerCase().includes(searchQuery.value.toLowerCase())
    );
});

const filteredMaterialIcons = computed(() => {
    if (!searchQuery.value) return materialIcons;
    return materialIcons.filter(icon =>
        icon.toLowerCase().includes(searchQuery.value.toLowerCase())
    );
});

const filteredIcons = computed(() => {
    return currentLibrary.value === 'primeicons' ? filteredPrimeIcons.value : filteredMaterialIcons.value;
});

// Watchers
watch(() => props.modelValue, (newValue) => {
    if (newValue && newValue !== finalIcon.value) {
        detectLibrary(newValue);
    }
}, { immediate: true });

watch(() => props.iconType, (newType) => {
    if (newType && newType !== currentLibrary.value) {
        console.log('🎯 IconType prop changed:', newType);
        currentLibrary.value = newType;
    }
}, { immediate: true });

watch(finalIcon, (newIcon) => {
    if (newIcon !== props.modelValue) {
        emit('update:modelValue', newIcon);
    }
});

// NUEVO: Watcher para currentLibrary que emite el tipo de icono
watch(currentLibrary, (newLibrary) => {
    console.log('🎯 currentLibrary changed:', newLibrary);
    if (newLibrary !== props.iconType) {
        emit('update:iconType', newLibrary);
    }
});

// Watcher para detectar cambios en el color y forzar reactividad
watch(() => props.color, (newColor) => {
    console.log('🎨 IconPicker detectó cambio de color:', newColor);
}, { immediate: true });

// Funciones
function getMaterialIconName(fullIcon) {
    return fullIcon;
}

function detectLibrary(icon) {
    if (icon?.startsWith('pi ')) {
        console.log('🎯 Detectando PrimeIcons para:', icon);
        currentLibrary.value = 'primeicons';
        selectedPrimeIcon.value = icon;
    } else if (icon) {
        console.log('🎯 Detectando Material para:', icon);
        currentLibrary.value = 'material';
        selectedMaterialIcon.value = icon;
    }
}

function selectIcon(icon) {
    console.log('🎯 Seleccionando icono:', icon, 'en librería:', currentLibrary.value);
    
    if (currentLibrary.value === 'primeicons') {
        selectedPrimeIcon.value = icon;
    } else {
        selectedMaterialIcon.value = icon;
    }
    searchQuery.value = '';
    // No llamar toggle() aquí
}

// NUEVA: Función para cambiar librería
function changeLibrary(newLibrary) {
    console.log('🎯 Cambiando librería a:', newLibrary);
    currentLibrary.value = newLibrary;
    // El watcher se encargará de emitir el cambio
}

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