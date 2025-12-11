<template>
    <PageLayout 
        title="Categorías" 
        description="Gestiona la clasificación de tus ingresos, egresos y gastos"
    >
        <!-- Acciones del header -->
        <template #actions>
            <Button 
                icon="pi pi-refresh" 
                @click="refreshData" 
                :loading="categoriesStore.loading"
                severity="secondary" 
                outlined 
                size="small" 
            />
            <Button 
                icon="pi pi-plus" 
                @click="handleNewCategoryGroup" 
                :disabled="categoriesStore.loading"
                size="small" 
                label="Nuevo Grupo" 
                class="mobile-icon-only"
            />
        </template>

        <!-- Contenido principal -->
        <div v-if="categoriesStore.loading" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Content -->
        <div v-else-if="categoryGroups.length > 0" class="flex flex-col gap-4">
            <div v-for="(group, index) in categoryGroups" :key="group.id" 
                class="bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700 rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow duration-200 animate__animated animate__fadeInUp animate__faster"
                :style="{ animationDelay: `${index * 0.05}s` }">
                <!-- Header del Grupo -->
                <div class="flex items-center justify-between p-4 md:py-5 md:px-6 cursor-pointer gap-3 transition-colors duration-200" 
                    @click="toggleGroup(group.id)">
                    <div class="flex items-center gap-3 flex-1 min-w-0">
                        <!-- Icono del grupo -->
                        <div class="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0 shadow-md" 
                            :style="{ backgroundColor: hexToRgba(group.color || '#6366f1', 0.65) }">
                            <span v-if="group.biblioteca_iconos === 'material'"
                                class="material-symbols-outlined text-white text-2xl">{{ group.nombre_icono }}</span>
                            <i v-else :class="group.nombre_icono || 'pi pi-folder'" class="text-white text-2xl"></i>
                        </div>

                        <!-- Nombre y descripción -->
                        <div class="flex-1 min-w-0">
                            <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0 m-0 mb-1 truncate">{{ group.nombre }}</h3>
                            <p v-if="group.descripcion" class="text-sm text-surface-600 dark:text-surface-400 m-0 mt-[-8px] mb-0 truncate">{{ group.descripcion }}</p>
                            <span class="text-xs text-surface-500 font-medium">{{ group.categories.length }} {{ group.categories.length === 1 ? 'categoría' : 'categorías' }}</span>
                        </div>
                    </div>

                    <!-- Acciones del grupo -->
                    <div class="flex gap-1 flex-shrink-0">
                        <Button icon="pi pi-plus" severity="success" rounded text size="small"
                            @click.stop="handleNewCategory(group.id)" class="!w-9 !h-9" />

                        <Button icon="pi pi-ellipsis-v" severity="secondary" rounded text size="small"
                            @click.stop="(event) => toggleGroupMenu(event, group.id)" class="!w-9 !h-9" />

                        <!-- Menú popup para cada grupo -->
                        <Menu :ref="(el) => setGroupMenuRef(el, group.id)" :id="`group_menu_${group.id}`"
                            :model="getGroupMenuItems(group)" popup />
                    </div>
                </div>

                <!-- Contenido del Grupo (Categorías) -->
                <Transition name="expand">
                    <div v-show="!collapsedGroups[group.id]" class="p-0 px-4 pb-4 md:px-6 md:pb-6">
                        <!-- Mensaje si no hay categorías -->
                        <div v-if="group.categories.length === 0" class="flex flex-col items-center justify-center py-8 px-4 gap-3 rounded-lg border border-dashed border-surface-300 dark:border-surface-600 bg-surface-50 dark:bg-surface-900">
                            <i class="pi pi-inbox text-4xl text-surface-400 dark:text-surface-500"></i>
                            <span class="text-sm text-surface-600 dark:text-surface-400">No hay categorías en este grupo</span>
                            <Button label="Agregar categoría" icon="pi pi-plus" size="small" text
                                @click="handleNewCategory(group.id)" />
                        </div>

                        <!-- Lista de categorías en grid mobile -->
                        <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                            <div v-for="(category, catIndex) in group.categories" :key="category.id" 
                                class="flex items-center gap-3 py-3.5 px-3.5 border border-solid rounded-lg cursor-pointer transition-all duration-200 min-h-[64px] hover:-translate-y-0.5 hover:shadow-md active:scale-[0.98] animate__animated animate__fadeIn animate__faster"
                                :style="{ 
                                    animationDelay: `${catIndex * 0.03}s`,
                                    backgroundColor: hexToRgba(group.color || '#6366f1', 0.08),
                                    borderColor: hexToRgba(group.color || '#6366f1', 0.2)
                                }"
                                @click="() => handleCategoryClick(category, group)">
                                <!-- Icono de la categoría -->
                                <div class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0 shadow-md" :style="{ backgroundColor: hexToRgba(group.color || '#6366f1', 0.65) }">
                                    <span v-if="category.biblioteca_iconos === 'material'"
                                        class="material-symbols-outlined text-white text-xl">{{ category.nombre_icono }}</span>
                                    <i v-else :class="category.nombre_icono || 'pi pi-tag'" class="text-white text-xl"></i>
                                </div>

                                <!-- Info de la categoría -->
                                <div class="flex-1 min-w-0">
                                    <h4 class="text-sm font-semibold text-surface-900 dark:text-surface-100 m-0 mb-0.5 truncate">{{ category.nombre }}</h4>
                                    <p v-if="category.descripcion" class="text-xs text-surface-600 dark:text-surface-400 m-0 truncate">
                                        {{ category.descripcion }}
                                    </p>
                                </div>

                                <!-- Badge y menú -->
                                <div class="flex items-center gap-2 flex-shrink-0">
                                    <Badge v-if="!category.es_publico" value="Personal" severity="success" size="small" />

                                    <!-- Menú de opciones solo para categorías privadas -->
                                    <Button v-if="!category.es_publico" icon="pi pi-ellipsis-v" severity="secondary"
                                        rounded text size="small"
                                        @click.stop="(event) => toggleCategoryMenu(event, category.id)"
                                        class="!w-9 !h-9" />

                                    <!-- Menú popup para cada categoría -->
                                    <Menu v-if="!category.es_publico" :ref="(el) => setCategoryMenuRef(el, category.id)"
                                        :id="`category_menu_${category.id}`" :model="getCategoryMenuItems(category)"
                                        popup />
                                </div>
                            </div>
                        </div>
                    </div>
                </Transition>
            </div>
        </div>

        <!-- Empty State -->
        <div v-else class="flex items-center justify-center min-h-[400px] py-8 px-4">
            <div class="text-center max-w-md">
                <i class="pi pi-folder-open text-6xl text-surface-300 dark:text-surface-600 mb-6"></i>
                
                <h3 class="text-xl font-semibold text-surface-700 dark:text-surface-300 m-0 mb-2">No hay grupos de categorías</h3>
                
                <p class="text-sm text-surface-500 dark:text-surface-400 m-0 mb-6">
                    No se encontraron grupos de categorías disponibles
                </p>
                
                <Button label="Recargar datos" icon="pi pi-refresh" @click="loadData" outlined />
            </div>
        </div>
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageLayout from '@/components/PageLayout.vue';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
import { useCategoriesStore } from '@/stores/categories.js';
const categoriesStore = useCategoriesStore();
import { useUIStore } from '@/stores/ui';
const uiStore = useUIStore();
import { useModalsStore } from '@/stores/ui-modals';
const modalsStore = useModalsStore();

// VARIABLES
const isInitialLoad = ref(true);
const categoryGroups = computed(() => categoriesStore.categoryGroups);
const groupMenuRefs = ref({});
const categoryMenuRefs = ref({});
const collapsedGroups = ref({});

// FUNCTIONS - Helper para convertir hex a rgba con opacidad
const hexToRgba = (hex, opacity = 1) => {
    // Remover el # si existe
    hex = hex.replace('#', '');
    
    // Convertir hex de 3 dígitos a 6 dígitos
    if (hex.length === 3) {
        hex = hex.split('').map(char => char + char).join('');
    }
    
    // Extraer RGB
    const r = parseInt(hex.substring(0, 2), 16);
    const g = parseInt(hex.substring(2, 4), 16);
    const b = parseInt(hex.substring(4, 6), 16);
    
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
};

// FUNCTIONS - Toggle group collapse
const toggleGroup = (groupId) => {
    collapsedGroups.value[groupId] = !collapsedGroups.value[groupId];
};

// FUNCTIONS - Grupos
const getGroupMenuItems = (group) => {
    const items = [
        {
            label: 'Nueva categoría',
            icon: 'pi pi-plus',
            command: () => {
                handleNewCategory(group.id);
            }
        }
    ];

    if (!group.es_publico) {
        items.push(
            {
                separator: true // Separador visual
            },
            {
                label: 'Editar grupo',
                icon: 'pi pi-pencil',
                command: () => handleEditGroup(group)
            },
            {
                label: 'Eliminar grupo',
                icon: 'pi pi-trash',
                command: () => handleDeleteGroup(group),
                class: 'text-red-500'
            }
        )
    }

    return items;
};

const setGroupMenuRef = (el, groupId) => {
    if (el) {
        groupMenuRefs.value[groupId] = el;
    }
};

const toggleGroupMenu = (event, groupId) => {
    const menu = groupMenuRefs.value[groupId];
    if (menu) {
        menu.toggle(event);
    }
};

// FUNCTIONS - Categorías
const getCategoryMenuItems = (category) => {
    return [
        {
            label: 'Editar',
            icon: 'pi pi-pencil',
            command: () => {
                handleEditCategory(category);
            }
        },
        {
            label: 'Eliminar',
            icon: 'pi pi-trash',
            command: () => {
                handleDeleteCategory(category);
            },
            class: 'text-red-500'
        }
    ];
};

const setCategoryMenuRef = (el, categoryId) => {
    if (el) {
        categoryMenuRefs.value[categoryId] = el;
    }
};

const toggleCategoryMenu = (event, categoryId) => {
    event.stopPropagation();
    const menu = categoryMenuRefs.value[categoryId];
    if (menu) {
        menu.toggle(event);
    }
};

// Modal handlers - Grupo
const handleNewCategoryGroup = async () => {
    modalsStore.openCategoryGroupModal();
};

const handleEditGroup = async (group) => {
    modalsStore.openCategoryGroupModal(group.id);
};

const handleModalClose = () => {
    modalsStore.closeCategoryGroupModal();
};

const handleCategoryGroupSubmit = async ({ data, isEdit, groupId, onSuccess, onError }) => {
    try {
        let result;

        if (isEdit && groupId) {
            // Actualizar grupo existente
            result = await categoriesStore.updateCategoryGroup(groupId, data, { toast });
        } else {
            // Crear nuevo grupo
            result = await categoriesStore.createCategoryGroup(data, { toast });
        }

        if (result) {
            // Recargar datos para mostrar cambios
            await loadData();

            // Ejecutar callback de éxito
            onSuccess();
        }

    } catch (error) {
        console.error('💥 Error en handleCategoryGroupSubmit:', error);
        // Ejecutar callback de error
        onError(error);
    }
};

// Modal handlers - Categoría
const handleNewCategory = async (groupID) => {
    modalsStore.openNewCategoryModal(groupID);
};

const handleEditCategory = async (category) => {
    // Encontrar el grupo de la categoría
    const group = categoryGroups.value.find(g =>
        g.categories?.some(c => c.id === category.id)
    );

    modalsStore.openEditCategoryModal(category.id, {
        ...category,
        group_id: group?.id
    });
};

const handleCategoryClick = async (category, group) => {
    modalsStore.openViewCategoryModal(category.id, {
        ...category,
        group_id: group.id
    });
};

const handleCategoryModalClose = () => {
    modalsStore.closeCategoryModal();
};

// Función para manejar el éxito de crear/editar categoría
const handleCategorySuccess = async (category) => {
    // Recargar datos para asegurar que los cambios sean visibles
    await loadData();

    // Cerrar modal
    handleCategoryModalClose();
};

// Función para eliminar categoría
const handleDeleteCategory = async (category) => {
    try {
        // Usar el servicio de confirmación a través de la instancia confirm
        confirm.require({
            message: `¿Estás seguro de eliminar la categoría "${category.nombre}"?`,
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
                    detail: 'Eliminando categoría...',
                    life: 2000
                });

                // Eliminar categoría usando el store
                await categoriesStore.deleteCategory(category.id, { toast });

                // Recargar datos para reflejar los cambios
                await loadData();
            }
        });
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudo eliminar la categoría',
            life: 5000
        });
    }
};

// Función para cargar datos
const loadData = async () => {
    try {
        const result = await categoriesStore.fetchCategoryGroupsWithCategories({ toast });
        isInitialLoad.value = false;
    } catch (error) {
        console.error('💥 Error cargando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error al cargar',
            detail: 'No se pudieron cargar los grupos de categorías',
            life: 5000
        });
    }
};

// Nueva función para refrescar datos
const refreshData = async () => {
    try {
        // Usamos refresh que fuerza la reconsulta
        await categoriesStore.refreshCategoryGroupsWithCategories({ toast });
        toast.add({
            severity: 'success',
            summary: 'Actualizado',
            detail: 'Los datos han sido actualizados correctamente',
            life: 3000
        });
    } catch (error) {
        console.error('💥 Error actualizando datos:', error);
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudieron actualizar los datos',
            life: 5000
        });
    }
};

const handleDeleteGroup = async (group) => {
    try {
        // Contar las categorías propias del usuario en este grupo
        const userCategories = group.categories.filter(cat => !cat.es_publico);
        const categoryCount = userCategories.length;

        // Crear mensaje de confirmación adecuado
        let message = `¿Estás seguro de eliminar el grupo "${group.nombre}"?`;

        if (categoryCount > 0) {
            message += `\n\nEsta acción también eliminará ${categoryCount} ${categoryCount === 1 ? 'categoría asociada' : 'categorías asociadas'
                } a este grupo.`;
        }

        // Mostrar diálogo de confirmación
        confirm.require({
            message: message,
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
                    detail: 'Eliminando grupo y sus categorías...',
                    life: 2000
                });

                // Eliminar grupo y sus categorías usando el store
                await categoriesStore.deleteCategoryGroup(group.id, { toast });

                // Recargar datos para reflejar los cambios
                await loadData();
            }
        });
    } catch (error) {
        console.error('💥 Error eliminando grupo:', error);

        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudo eliminar el grupo',
            life: 5000
        });
    }
};

// HOOKS
onMounted(() => {
    uiStore.setTitlePage('Categorías');
    loadData();
});
</script>

<style scoped>
/* Animación de expansión */
.expand-enter-active,
.expand-leave-active {
    transition: all 0.3s ease;
    max-height: 1000px;
    overflow: hidden;
}

.expand-enter-from,
.expand-leave-to {
    max-height: 0;
    opacity: 0;
}
</style>