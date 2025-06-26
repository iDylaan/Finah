<template>
    <div class="levels-page">
        <div class="mb-4 flex justify-between items-center">
            <h1 class="text-2xl font-bold">Niveles de Gasto</h1>
            
            <Button 
                label="Nuevo Nivel" 
                icon="pi pi-plus" 
                @click="handleNewLevel" 
                class="p-button-sm" />
        </div>
        
        <!-- Loading Skeleton -->
        <div v-if="isInitialLoad || levelStore.loading" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            <div v-for="i in 6" :key="i" class="border border-surface-200 dark:border-surface-700 rounded-lg p-4 bg-surface-0 dark:bg-surface-800">
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
            <div v-for="level in levelStore.levels" :key="level.id"
                class="border border-surface-200 dark:border-surface-700 rounded-lg p-4 bg-surface-0 dark:bg-surface-800 relative hover:shadow-md transition-shadow duration-200"
                @click="handleLevelClick(level)">
                
                <!-- Menú de acciones (solo para niveles privados) -->
                <Menu v-if="!level.is_public" 
                    :model="getLevelMenuItems(level)" 
                    :popup="true" 
                    :pt="{root: {class: 'surface-0 dark:surface-800'}}"
                    :ref="el => setLevelMenuRef(el, level.id)" />
                
                <button v-if="!level.is_public"
                    class="absolute right-2 top-2 p-2 rounded-full hover:bg-surface-200 dark:hover:bg-surface-700 transition-colors"
                    @click.stop="toggleLevelMenu($event, level.id)">
                    <i class="pi pi-ellipsis-v text-surface-600 dark:text-surface-400"></i>
                </button>
                
                <!-- Contenido principal -->
                <div class="flex items-center mb-3 mt-2">
                    <div class="w-8 h-8 rounded-md mr-3" :style="{ backgroundColor: level.color || '#6366f1' }"></div>
                    <h3 class="text-lg font-semibold truncate">{{ level.name }}</h3>
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
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import LevelForm from './components/LevelForm.vue';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
import { useLevelStore } from '@/stores/levels.js';
const levelStore = useLevelStore();

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
    console.log('👆 Click en nivel:', level);
    
    // Configurar estado para ver/editar
    newLevelMode.value = false;
    editingLevelId.value = level.id;
    selectedLevel.value = level;
    
    // Mostrar el modal
    showLevelModal.value = true;
};

const handleLevelModalClose = () => {
    console.log('❌ Cerrar modal de nivel');
    
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
            message: `¿Estás seguro de eliminar el nivel "${level.name}"?`,
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
// HOOKS
onMounted(() => {
    loadData();
});
</script>

<style lang="scss" scoped>
.levels-page {
    padding: 1rem;
}
</style>