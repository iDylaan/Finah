<template>
    <div class="levels-page">
        <div class="mb-4 flex justify-between items-center">
            <h1 class="text-2xl font-bold">Niveles de Gasto</h1>

            <Button label="Nuevo Nivel" icon="pi pi-plus" @click="handleNewLevel" class="p-button-sm" />
        </div>

        <!-- Loading Skeleton -->
        <div v-if="isInitialLoad || levelStore.loading" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
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
        <div v-else class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            <div v-for="level in levelStore.levels" :key="`${level.id}-${isDarkMode}`"
                class="cursor-pointer border border-surface-200 dark:border-surface-700 rounded-lg p-4 bg-surface-0 dark:bg-surface-800 relative hover:shadow-md transition-shadow duration-200"
                @click="handleLevelClick(level)">
                <!-- Menú de acciones (solo para niveles privados) -->
                <Menu v-if="!level.es_publico" :model="getLevelMenuItems(level)" :popup="true"
                    :pt="{ root: { class: 'surface-0 dark:surface-800' } }"
                    :ref="el => setLevelMenuRef(el, level.id)" />

                <button v-if="!level.es_publico"
                    class="absolute right-2 top-2 p-2 rounded-full"
                    @click.stop="toggleLevelMenu($event, level.id)">
                    <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400"></i>
                </button>

                <!-- Contenido principal con tag de color predefinido -->
                <div class="flex items-center mb-3 mt-2">
                    <Tag class="" rounded :style="getLevelTagStyle(level)">
                        <span class="block w-full text-center">
                            {{ level.nombre }}
                        </span>
                    </Tag>
                </div>
            </div>
        </div>

        <!-- Modal de Nivel -->
        <LevelForm v-model:visible="showLevelModal" :is-new="newLevelMode" :level-id="editingLevelId"
            :level="selectedLevel" :is-loading="levelStore.loading" @close="handleLevelModalClose"
            @success="handleLevelSuccess" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed, inject, watch } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import LevelForm from './components/LevelForm.vue';
import { findLevelColor, getLevelTagStyle as getTagStyleFromUtils } from '@/assets/constants/levels-colors.js';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
import { useLevelStore } from '@/stores/levels.js';
const levelStore = useLevelStore();
import { useUIStore } from '@/stores/ui';
const UI = useUIStore();

// Referencia reactiva al modo oscuro desde la UI Store
const isDarkMode = computed(() => UI.isDarkTheme);

// VARIABLES
const isInitialLoad = ref(true);
const levelMenuRefs = ref({}); // Cambiado: ahora tenemos un objeto para guardar todas las referencias

// Modal state
const showLevelModal = ref(false);
const newLevelMode = ref(false);
const editingLevelId = ref(null);
const selectedLevel = ref(null);

// FUNCTIONS - Menú de nivel
const getLevelMenuItems = (level) => {
    return [
        {
            label: 'Editar',
            icon: 'pi pi-pencil',
            command: () => handleEditLevel(level)
        },
        {
            separator: true
        },
        {
            label: 'Eliminar',
            icon: 'pi pi-trash',
            class: 'text-red-600 dark:text-red-400',
            command: () => handleDeleteLevel(level)
        }
    ];
};

// Función para obtener estilos del tag según el nivel
const getLevelTagStyle = (level) => {
    // Convertir cualquier formato antiguo a una clave de color válida
    const colorKey = findLevelColor(level.color);
    
    // Usar la función importada para obtener los estilos según el modo actual
    return getTagStyleFromUtils(colorKey, isDarkMode.value);
};

// Forzar actualización de componentes cuando cambia el modo oscuro
watch(() => isDarkMode.value, () => {
    // Este watch forzará la re-evaluación de las propiedades de estilo
    // cuando cambie el modo oscuro/claro
    if (levelStore.levels.length > 0) {
        // Podemos forzar la actualización de la referencia a levels
        // para que Vue re-renderice los componentes
        levelStore.levels = [...levelStore.levels];
    }
});

// FUNCTIONS - Referencias de menú
const setLevelMenuRef = (el, levelId) => {
    if (el) {
        levelMenuRefs.value[levelId] = el;
    }
};

const toggleLevelMenu = (event, levelId) => {
    // Verificar que el menú exista para este levelId
    if (levelMenuRefs.value[levelId]) {
        levelMenuRefs.value[levelId].toggle(event);
    } else {
        console.warn(`Menú no encontrado para el nivel ID: ${levelId}`);
    }
    event.stopPropagation(); // Evitar que se propague al clic del nivel
};

// Modal handlers
const handleNewLevel = () => {
    console.log('🆕 Nuevo nivel');

    // Resetear estado para creación
    newLevelMode.value = true;
    editingLevelId.value = null;
    selectedLevel.value = null;

    // Mostrar el modal
    showLevelModal.value = true;
};

const handleEditLevel = (level) => {
    console.log('✏️ Editar nivel:', level);

    // Configurar estado para edición
    newLevelMode.value = false;
    editingLevelId.value = level.id;
    selectedLevel.value = level;

    // Mostrar el modal
    showLevelModal.value = true;
};

const handleLevelClick = (level) => {
    // Configurar estado para ver/editar
    newLevelMode.value = false;
    editingLevelId.value = level.id;
    selectedLevel.value = level;

    // Mostrar el modal
    showLevelModal.value = true;
};

const handleLevelModalClose = () => {
    // Resetear estado del modal
    showLevelModal.value = false;
    newLevelMode.value = false;
    editingLevelId.value = null;
    selectedLevel.value = null;
};

// Función para manejar el éxito de crear/editar nivel
const handleLevelSuccess = async (level) => {
    console.log('✅ Nivel guardado exitosamente:', level);

    // Recargar datos para asegurar que los cambios sean visibles
    await loadData();

    // Cerrar modal
    handleLevelModalClose();
};

// Función para eliminar nivel
const handleDeleteLevel = async (level) => {
    console.log('🗑️ Eliminar nivel:', level);

    try {
        // Usar el servicio de confirmación
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
                // Mostrar indicador de carga
                toast.add({
                    severity: 'info',
                    summary: 'Procesando',
                    detail: 'Eliminando nivel...',
                    life: 2000
                });

                // Eliminar nivel usando el store
                await levelStore.deleteLevel(level.id, { toast });

                // Recargar datos para reflejar los cambios
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
        console.log('🔄 Cargando datos...');
        await levelStore.fetchLevels({ toast });
        isInitialLoad.value = false;
        console.log('✅ Datos cargados exitosamente');
    } catch (error) {
        console.error('💥 Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al cargar',
            detail: 'No se pudieron cargar los niveles',
            life: 5000
        });
    }
};

// Añadir función refreshData
const refreshData = async () => {
    try {
        console.log('🔄 Actualizando datos...');
        // Usamos refreshLevels que fuerza la reconsulta
        await levelStore.refreshLevels({ toast });
        toast.add({
            severity: 'success',
            summary: 'Actualizado',
            detail: 'Lista de niveles actualizada',
            life: 3000
        });
    } catch (error) {
        console.error('💥 Error actualizando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al actualizar',
            detail: 'No se pudieron actualizar los niveles',
            life: 5000
        });
    }
};

// HOOKS
onMounted(() => {
    loadData();
});
</script>

<style lang="scss" scoped>
.levels-page {
    padding: 1rem;
}

// Estilos para los tags de niveles
:deep(.p-tag) {
    &.tag-level {
        font-weight: 500;
    }
}
</style>