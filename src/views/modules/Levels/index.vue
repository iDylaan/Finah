<template>
    <div class="levels-page">
        <div class="mb-4 flex justify-between items-center">
            <h1 class="text-2xl font-bold">Niveles de Gasto</h1>

            <div class="flex gap-2">
                <Button 
                    v-if="hasUserLevels && !isReorderMode" 
                    label="Restaurar Original" 
                    icon="pi pi-refresh" 
                    @click="restoreHierarchy"
                    class="p-button-sm p-button-text" 
                    severity="secondary"
                />
                <Button 
                    v-if="hasUserLevels && !isReorderMode" 
                    label="Reordenar" 
                    icon="pi pi-sort" 
                    @click="toggleReorderMode" 
                    class="p-button-sm p-button-secondary" 
                />
                <Button 
                    v-if="isReorderMode" 
                    label="Guardar Orden" 
                    icon="pi pi-check" 
                    @click="saveOrder" 
                    class="p-button-sm p-button-success" 
                />
                <Button 
                    v-if="isReorderMode" 
                    label="Cancelar" 
                    icon="pi pi-times" 
                    @click="cancelReorder" 
                    class="p-button-sm p-button-secondary" 
                />
                <Button 
                    label="Nuevo Nivel" 
                    icon="pi pi-plus" 
                    @click="handleNewLevel" 
                    class="p-button-sm" 
                />
            </div>
        </div>

        <!-- Loading Skeleton -->
        <div v-if="isInitialLoad || levelStore.loading" class="space-y-3">
            <div v-for="i in 6" :key="i"
                class="border border-surface-200 dark:border-surface-700 rounded-lg p-4 bg-surface-0 dark:bg-surface-800">
                <Skeleton height="3rem" class="mb-2" />
                <Skeleton height="1.5rem" class="mb-2" width="70%" />
                <Skeleton height="1.5rem" width="40%" />
            </div>
        </div>

        <!-- Sin resultados -->
        <div v-else-if="!levelStore.levels.length" class="text-center py-8">
            <i class="pi pi-exclamation-circle text-4xl text-surface-400 mb-4"></i>
            <h3 class="text-xl font-medium mb-2">No hay niveles disponibles</h3>
            <p class="text-surface-600 dark:text-surface-400 mb-4">
                Los niveles te permiten clasificar gastos e ingresos según su importancia.
            </p>
            <Button label="Crear Nivel" icon="pi pi-plus" @click="handleNewLevel" />
        </div>

        <!-- Lista de Niveles -->
        <div v-else>
            <!-- Modo de reordenamiento -->
            <div v-if="isReorderMode" class="mb-4 p-4 bg-blue-50 dark:bg-blue-900 rounded-lg">
                <div class="flex items-center gap-2 mb-2">
                    <i class="pi pi-info-circle text-blue-500"></i>
                    <span class="text-sm text-blue-800 dark:text-blue-200">
                        Arrastra y suelta los niveles para cambiar su orden de prioridad
                    </span>
                </div>
                <small class="text-blue-600 dark:text-blue-300">
                    Solo puedes reordenar tus niveles privados. Los niveles públicos del sistema no se pueden mover.
                </small>
            </div>

            <!-- Lista de niveles en columna única -->
            <div 
                ref="sortableContainer"
                class="sortable-list"
                :class="{ 'reorder-mode': isReorderMode }"
            >
                <div 
                    v-for="level in displayLevels" 
                    :key="level.id"
                    :data-id="level.id"
                    class="sortable-item level-card"
                    :class="{
                        'cursor-pointer hover:shadow-md': !isReorderMode,
                        'cursor-grab hover:shadow-lg': isReorderMode && !level.es_publico,
                        'opacity-50 cursor-not-allowed': isReorderMode && level.es_publico,
                        'non-draggable': level.es_publico,
                        'draggable': !level.es_publico
                    }"
                    @click="!isReorderMode && handleLevelClick(level)"
                >
                    <!-- Indicador de drag -->
                    <div v-if="isReorderMode && !level.es_publico" 
                         class="drag-handle">
                        <i class="pi pi-bars text-lg text-surface-400"></i>
                    </div>

                    <!-- Menú de acciones -->
                    <Menu v-if="!level.es_publico && !isReorderMode" 
                          :model="getLevelMenuItems(level)" 
                          :popup="true"
                          :ref="el => setLevelMenuRef(el, level.id)" />

                    <button v-if="!level.es_publico && !isReorderMode"
                            class="action-menu-btn"
                            @click.stop="toggleLevelMenu($event, level.id)">
                        <i class="pi pi-ellipsis-v"></i>
                    </button>

                    <!-- Contenido principal -->
                    <div class="level-content">
                        <div class="flex items-center gap-3">
                            <!-- Icono de nivel público -->
                            <div v-if="level.es_publico" class="flex-shrink-0">
                                <i class="pi pi-globe text-surface-400 text-sm"></i>
                            </div>
                            
                            <!-- Tag del nivel -->
                            <Tag class="level-tag flex-grow" 
                                 rounded 
                                 :style="getLevelTagStyle(level)">
                                <span class="level-name">{{ level.nombre }}</span>
                            </Tag>
                        </div>
                        
                        <!-- Información adicional en modo reordenamiento -->
                        <div v-if="isReorderMode" class="reorder-info mt-2">
                            <span v-if="level.es_publico" class="status-text">
                                <i class="pi pi-lock text-xs mr-1"></i>
                                Nivel público (no se puede mover)
                            </span>
                            <span v-else class="status-text">
                                <i class="pi pi-sort text-xs mr-1"></i>
                                Nivel privado (se puede reordenar)
                            </span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Modal de Nivel -->
        <LevelForm v-model:visible="showLevelModal" 
                   :is-new="newLevelMode" 
                   :level-id="editingLevelId"
                   :level="selectedLevel" 
                   :is-loading="levelStore.loading" 
                   @close="handleLevelModalClose"
                   @success="handleLevelSuccess" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed, watch, nextTick, onUnmounted } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import Sortable from 'sortablejs';
import LevelForm from './components/LevelForm.vue';
import { findLevelColor, getLevelTagStyle as getTagStyleFromUtils } from '@/assets/constants/levels-colors.js';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
import { useLevelStore } from '@/stores/levels.js';
const levelStore = useLevelStore();
import { useUIStore } from '@/stores/ui';
const UI = useUIStore();

// Referencia reactiva al modo oscuro
const isDarkMode = computed(() => UI.isDarkTheme);

// VARIABLES
const isInitialLoad = ref(true);
const levelMenuRefs = ref({});

// Modal state
const showLevelModal = ref(false);
const newLevelMode = ref(false);
const editingLevelId = ref(null);
const selectedLevel = ref(null);

// Reorder state
const isReorderMode = ref(false);
const displayLevels = ref([]);
const originalOrder = ref([]);

// Sortable container ref
const sortableContainer = ref(null);
let sortableInstance = null;

// COMPUTED
const hasUserLevels = computed(() => {
    return levelStore.levels.some(level => !level.es_publico);
});

// FUNCTIONS - Sortable Management
const initializeSortable = () => {
    if (!sortableContainer.value) return;

    sortableInstance = Sortable.create(sortableContainer.value, {
        animation: 200,
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        handle: '.drag-handle',
        disabled: !isReorderMode.value,
        filter: '.non-draggable',
        preventOnFilter: true,
        
        onStart: (event) => {
            console.log('🟢 Drag started:', event);
            document.body.classList.add('is-dragging');
        },
        
        onEnd: (event) => {
            console.log('🔴 Drag ended:', event);
            document.body.classList.remove('is-dragging');
        },
        
        onUpdate: (event) => {
            console.log('🔄 Order updated:', event);
            const { oldIndex, newIndex } = event;
            
            if (oldIndex !== newIndex) {
                // Actualizar el orden local
                const movedItem = displayLevels.value.splice(oldIndex, 1)[0];
                displayLevels.value.splice(newIndex, 0, movedItem);
                
                // Recalcular jerarquías
                updateHierarchies();
            }
        }
    });
};

const destroySortable = () => {
    if (sortableInstance) {
        sortableInstance.destroy();
        sortableInstance = null;
    }
};

const updateHierarchies = () => {
    // Ya no necesitamos recalcular jerarquías manualmente
    // El sistema de base de datos se encarga de esto
    console.log('Jerarquías actualizadas por drag and drop');
};

// FUNCTIONS - Drag and Drop
const toggleReorderMode = async () => {
    isReorderMode.value = true;
    originalOrder.value = [...displayLevels.value];
    
    await nextTick();
    
    if (sortableInstance) {
        sortableInstance.option('disabled', false);
    }
};

const cancelReorder = async () => {
    isReorderMode.value = false;
    displayLevels.value = [...originalOrder.value];
    originalOrder.value = [];
    
    await nextTick();
    
    if (sortableInstance) {
        sortableInstance.option('disabled', true);
    }
};

const saveOrder = async () => {
    try {
        toast.add({
            severity: 'info',
            summary: 'Guardando...',
            detail: 'Actualizando orden de niveles',
            life: 2000
        });

        await levelStore.reorderLevels(displayLevels.value, { toast });
        
        isReorderMode.value = false;
        originalOrder.value = [];
        
        await nextTick();
        
        if (sortableInstance) {
            sortableInstance.option('disabled', true);
        }
        
        // Recargar datos para asegurar consistencia
        await loadData();
        
    } catch (error) {
        console.error('Error guardando orden:', error);
        await cancelReorder();
    }
};

// FUNCTIONS - Menú de nivel
// Función para obtener ítems del menú sin opciones de favoritos y visibilidad
const getLevelMenuItems = (level) => {
    const items = [
        {
            label: 'Editar',
            icon: 'pi pi-pencil',
            command: () => handleEditLevel(level)
        }
    ];

    // Solo mostrar opción de eliminar para niveles privados del usuario
    if (!level.es_publico) {
        items.push({
            separator: true
        });
        
        items.push({
            label: 'Eliminar',
            icon: 'pi pi-trash',
            class: 'text-red-600 dark:text-red-400',
            command: () => handleDeleteLevel(level)
        });
    }

    return items;
};

// Función para obtener estilos del tag
const getLevelTagStyle = (level) => {
    const colorKey = findLevelColor(level.color);
    return getTagStyleFromUtils(colorKey, isDarkMode.value);
};

// FUNCTIONS - Referencias de menú
const setLevelMenuRef = (el, levelId) => {
    if (el) {
        levelMenuRefs.value[levelId] = el;
    }
};

const toggleLevelMenu = (event, levelId) => {
    if (levelMenuRefs.value[levelId]) {
        levelMenuRefs.value[levelId].toggle(event);
    }
    event.stopPropagation();
};

// Modal handlers
const handleNewLevel = () => {
    newLevelMode.value = true;
    editingLevelId.value = null;
    selectedLevel.value = null;
    showLevelModal.value = true;
};

const handleEditLevel = (level) => {
    newLevelMode.value = false;
    editingLevelId.value = level.id;
    selectedLevel.value = level;
    showLevelModal.value = true;
};

const handleLevelClick = (level) => {
    newLevelMode.value = false;
    editingLevelId.value = level.id;
    selectedLevel.value = level;
    showLevelModal.value = true;
};

const handleLevelModalClose = () => {
    showLevelModal.value = false;
    newLevelMode.value = false;
    editingLevelId.value = null;
    selectedLevel.value = null;
};

const handleLevelSuccess = async (level) => {
    await loadData();
    handleLevelModalClose();
};

const handleDeleteLevel = async (level) => {
    try {
        confirm.require({
            message: `¿Estás seguro de eliminar el nivel "${level.nombre}"?`,
            header: 'Confirmar eliminación',
            icon: 'pi pi-exclamation-triangle',
            acceptLabel: 'Eliminar',
            acceptClass: 'p-button-danger',
            rejectLabel: 'Cancelar',
            rejectClass: 'p-button-secondary',
            acceptIcon: 'pi pi-trash',
            rejectIcon: 'pi pi-times',
            accept: async () => {
                await levelStore.deleteLevel(level.id, { toast });
                await loadData();
            }
        });
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudo eliminar el nivel',
            life: 5000
        });
    }
};

// Función para cargar datos
const loadData = async () => {
    try {
        await levelStore.fetchLevels({ toast });
        displayLevels.value = [...levelStore.levels];
        isInitialLoad.value = false;
    } catch (error) {
        console.error('Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al cargar',
            detail: 'No se pudieron cargar los niveles',
            life: 5000
        });
    }
};

// Función para restaurar jerarquía original
const restoreHierarchy = async () => {
    try {
        confirm.require({
            message: '¿Deseas restaurar la jerarquía original de los niveles?',
            header: 'Restaurar Jerarquía',
            icon: 'pi pi-exclamation-triangle',
            acceptLabel: 'Restaurar',
            acceptClass: 'p-button-primary',
            rejectLabel: 'Cancelar',
            rejectClass: 'p-button-secondary',
            accept: async () => {
                await levelStore.restoreOriginalHierarchy({ toast });
                await loadData();
            }
        });
    } catch (error) {
        console.error('Error restoring hierarchy:', error);
    }
};

// WATCHERS
watch(() => levelStore.levels, (newLevels) => {
    if (!isReorderMode.value) {
        displayLevels.value = [...newLevels];
    }
}, { deep: true });

watch(() => isReorderMode.value, async (newValue) => {
    await nextTick();
    if (sortableInstance) {
        sortableInstance.option('disabled', !newValue);
    }
});

// HOOKS
onMounted(async () => {
    await loadData();
    await nextTick();
    initializeSortable();
});

onUnmounted(() => {
    destroySortable();
});
</script>

<style lang="scss" scoped>
.levels-page {
    padding: 1rem;
    max-width: 800px; // Reducir ancho máximo para una sola columna
    margin: 0 auto;
}

.sortable-list {
    display: flex;
    flex-direction: column;
    gap: 0.75rem; // Espacio entre elementos
    
    &.reorder-mode {
        .level-card {
            transition: all 0.2s ease;
        }
    }
}

.level-card {
    position: relative;
    padding: 1rem;
    border: 1px solid var(--surface-border);
    border-radius: 8px;
    background: var(--surface-card);
    transition: all 0.2s ease;
    
    &:hover:not(.cursor-not-allowed) {
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
        transform: translateY(-2px);
    }
    
    &.draggable {
        cursor: grab;
        
        &:active {
            cursor: grabbing;
        }
    }
    
    &.non-draggable {
        position: relative;
        
        &::after {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0, 0, 0, 0.05);
            border-radius: 8px;
            pointer-events: none;
        }
    }
}

.drag-handle {
    position: absolute;
    left: 0.5rem;
    top: 50%;
    transform: translateY(-50%);
    padding: 0.25rem;
    cursor: grab;
    color: var(--text-color-secondary);
    z-index: 10;
    
    &:hover {
        color: var(--primary-color);
    }
    
    &:active {
        cursor: grabbing;
    }
}

.action-menu-btn {
    position: absolute;
    right: 0.5rem;
    top: 50%;
    transform: translateY(-50%);
    padding: 0.5rem;
    border: none;
    background: transparent;
    color: var(--text-color-secondary);
    border-radius: 4px;
    cursor: pointer;
    
    &:hover {
        background: var(--surface-hover);
        color: var(--primary-color);
    }
}

.level-content {
    margin-left: 2rem; // Espacio para el drag handle
    margin-right: 2rem; // Espacio para el menú
    
    .level-tag {
        .level-name {
            display: block;
            text-align: center;
            font-weight: 500;
        }
    }
    
    .reorder-info {
        text-align: center;
        
        .status-text {
            font-size: 0.75rem;
            color: var(--text-color-secondary);
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 0.25rem;
        }
    }
}

// Estilos para el drag and drop
.sortable-ghost {
    opacity: 0.5;
    background: var(--primary-50);
    border: 2px dashed var(--primary-200);
    transform: scale(0.98);
}

.sortable-chosen {
    transform: scale(1.02);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
    z-index: 1000;
}

.sortable-drag {
    opacity: 0.8;
    transform: rotate(1deg);
}

// Estado global cuando se está arrastrando
:global(.is-dragging) {
    cursor: grabbing !important;
    user-select: none;
}

// Responsive
@media (max-width: 768px) {
    .levels-page {
        padding: 0.75rem;
    }
    
    .level-card {
        padding: 0.75rem;
    }
    
    .level-content {
        margin-left: 1.5rem;
        margin-right: 1.5rem;
    }
    
    .drag-handle {
        left: 0.25rem;
    }
    
    .action-menu-btn {
        right: 0.25rem;
    }
}
</style>