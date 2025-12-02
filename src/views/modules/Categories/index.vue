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
        <div v-else-if="categoryGroups.length > 0" class="categories-content">
            <div v-for="group in categoryGroups" :key="group.id" class="category-group-card bg-surface-0 dark:bg-surface-800 border-surface-200 dark:border-surface-700">
                <!-- Header del Grupo -->
                <div class="group-header" @click="toggleGroup(group.id)">
                    <div class="group-info">
                        <!-- Icono del grupo -->
                        <div class="group-icon" :style="{ backgroundColor: group.color || '#6366f1' }">
                            <span v-if="group.biblioteca_iconos === 'material'"
                                class="material-symbols-outlined">{{ group.nombre_icono }}</span>
                            <i v-else :class="group.nombre_icono || 'pi pi-folder'"></i>
                        </div>

                        <!-- Nombre y descripción -->
                        <div class="group-text">
                            <h3 class="group-name">{{ group.nombre }}</h3>
                            <p v-if="group.descripcion" class="group-description">{{ group.descripcion }}</p>
                            <span class="group-count">{{ group.categories.length }} {{ group.categories.length === 1 ? 'categoría' : 'categorías' }}</span>
                        </div>
                    </div>

                    <!-- Acciones del grupo -->
                    <div class="group-actions">
                        <Button icon="pi pi-plus" severity="success" rounded text size="small"
                            @click.stop="handleNewCategory(group.id)" class="action-icon-btn" />

                        <Button icon="pi pi-ellipsis-v" severity="secondary" rounded text size="small"
                            @click.stop="(event) => toggleGroupMenu(event, group.id)" class="action-icon-btn" />

                        <!-- Menú popup para cada grupo -->
                        <Menu :ref="(el) => setGroupMenuRef(el, group.id)" :id="`group_menu_${group.id}`"
                            :model="getGroupMenuItems(group)" popup />
                    </div>
                </div>

                <!-- Contenido del Grupo (Categorías) -->
                <Transition name="expand">
                    <div v-show="!collapsedGroups[group.id]" class="group-content">
                        <!-- Mensaje si no hay categorías -->
                        <div v-if="group.categories.length === 0" class="empty-categories bg-surface-50 dark:bg-surface-900 border-surface-300 dark:border-surface-600">
                            <i class="pi pi-inbox"></i>
                            <span>No hay categorías en este grupo</span>
                            <Button label="Agregar categoría" icon="pi pi-plus" size="small" text
                                @click="handleNewCategory(group.id)" />
                        </div>

                        <!-- Lista de categorías en grid mobile -->
                        <div v-else class="categories-grid">
                            <div v-for="category in group.categories" :key="category.id" class="category-item bg-surface-50 dark:bg-surface-700 border-surface-200 dark:border-surface-600"
                                @click="() => handleCategoryClick(category, group)">
                                <!-- Icono de la categoría -->
                                <div class="category-icon" :style="{ backgroundColor: group.color || '#6366f1' }">
                                    <span v-if="category.biblioteca_iconos === 'material'"
                                        class="material-symbols-outlined">{{ category.nombre_icono }}</span>
                                    <i v-else :class="category.nombre_icono || 'pi pi-tag'"></i>
                                </div>

                                <!-- Info de la categoría -->
                                <div class="category-info">
                                    <h4 class="category-name">{{ category.nombre }}</h4>
                                    <p v-if="category.descripcion" class="category-description">
                                        {{ category.descripcion }}
                                    </p>
                                </div>

                                <!-- Badge y menú -->
                                <div class="category-actions">
                                    <Badge v-if="!category.es_publico" value="Personal" severity="success" size="small" />

                                    <!-- Menú de opciones solo para categorías privadas -->
                                    <Button v-if="!category.es_publico" icon="pi pi-ellipsis-v" severity="secondary"
                                        rounded text size="small"
                                        @click.stop="(event) => toggleCategoryMenu(event, category.id)"
                                        class="action-icon-btn" />

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
        <div v-else class="empty-state">
            <div class="empty-state-content">
                <i class="pi pi-folder-open empty-icon"></i>
                
                <h3 class="empty-title">No hay grupos de categorías</h3>
                
                <p class="empty-description">
                    No se encontraron grupos de categorías disponibles
                </p>
                
                <Button label="Recargar datos" icon="pi pi-refresh" @click="loadData" outlined />
            </div>
        </div>

        <!-- Modal Components -->
        <CategoryGroupForm v-model:visible="showCategoryGroupModal" :is-edit="modalEditMode"
            :edit-group-id="editingGroupId" :category-groups="categoryGroups" :is-loading="categoriesStore.loading"
            @submit="handleCategoryGroupSubmit" @close="handleModalClose" />

        <!-- Modal de Categoría -->
        <CategoryForm v-model:visible="showCategoryModal" :is-new="newCategoryMode" :category-id="editingCategoryId"
            :group-id="selectedGroupId" :category="selectedCategory" :category-groups="categoryGroups"
            :is-loading="categoriesStore.loading" @close="handleCategoryModalClose" @success="handleCategorySuccess" />
    </PageLayout>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useConfirm } from 'primevue/useconfirm';
import PageLayout from '@/components/PageLayout.vue';
import CategoryGroupForm from './components/CategoryGroupForm.vue';
import CategoryForm from './components/CategoryForm.vue';

// STORES & COMPOSABLES
const toast = useToast();
const confirm = useConfirm();
import { useCategoriesStore } from '@/stores/categories.js';
const categoriesStore = useCategoriesStore();

// VARIABLES
const isInitialLoad = ref(true);
const categoryGroups = computed(() => categoriesStore.categoryGroups);
const groupMenuRefs = ref({});
const categoryMenuRefs = ref({});
const collapsedGroups = ref({});

// FUNCTIONS - Toggle group collapse
const toggleGroup = (groupId) => {
    collapsedGroups.value[groupId] = !collapsedGroups.value[groupId];
};

// Modal state - Grupo
const showCategoryGroupModal = ref(false);
const modalEditMode = ref(false);
const editingGroupId = ref(null);

// Modal state - Categoría
const showCategoryModal = ref(false);
const newCategoryMode = ref(false);
const editingCategoryId = ref(null);
const selectedGroupId = ref(null);
const selectedCategory = ref(null);

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
const handleNewCategoryGroup = () => {
    // Resetear estado para creación
    modalEditMode.value = false;
    editingGroupId.value = null;
    showCategoryGroupModal.value = true;
};

const handleEditGroup = (group) => {
    // Configurar estado para edición
    modalEditMode.value = true;
    editingGroupId.value = group.id;
    showCategoryGroupModal.value = true;
};

const handleModalClose = () => {
    // Resetear todo el estado del modal
    showCategoryGroupModal.value = false;
    modalEditMode.value = false;
    editingGroupId.value = null;
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
const handleNewCategory = (groupID) => {
    // Configurar estado para nueva categoría
    newCategoryMode.value = true;
    selectedGroupId.value = groupID;
    editingCategoryId.value = null;
    selectedCategory.value = null;

    // Mostrar el modal
    showCategoryModal.value = true;
};

const handleEditCategory = (category) => {
    // Encontrar el grupo de la categoría
    const group = categoryGroups.value.find(g =>
        g.categories?.some(c => c.id === category.id)
    );

    if (group) {
        selectedGroupId.value = group.id;
    }

    // Configurar estado para edición
    newCategoryMode.value = false;
    editingCategoryId.value = category.id;
    selectedCategory.value = {
        ...category,
        group_id: group?.id // Asegurar que tenemos el group_id
    };

    // Mostrar el modal
    showCategoryModal.value = true;
};

const handleCategoryClick = (category, group) => {
    // Configurar estado para ver/editar
    newCategoryMode.value = false;
    editingCategoryId.value = category.id;
    selectedCategory.value = {
        ...category,
        group_id: group.id // Asegurar que tenemos el group_id
    };
    selectedGroupId.value = group.id;

    // Mostrar el modal
    showCategoryModal.value = true;
};

const handleCategoryModalClose = () => {
    // Resetear estado del modal
    showCategoryModal.value = false;
    newCategoryMode.value = false;
    editingCategoryId.value = null;
    selectedCategory.value = null;
    selectedGroupId.value = null;
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
    loadData();
});
</script>

<style scoped>
/* ===== CONTENT ===== */
.categories-content {
    display: flex;
    flex-direction: column;
    gap: 1rem;
}

/* ===== CATEGORY GROUP CARD ===== */
.category-group-card {
    border-radius: 12px;
    overflow: hidden;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
    transition: box-shadow 0.2s;
}

.category-group-card:hover {
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
}

/* ===== GROUP HEADER ===== */
.group-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 1rem;
    cursor: pointer;
    transition: background-color 0.2s;
    gap: 0.75rem;
}

.group-header:hover {
    background: var(--p-surface-50);
}

:global(.app-dark) .group-header:hover {
    background: var(--p-surface-700);
}

@media (min-width: 768px) {
    .group-header {
        padding: 1.25rem 1.5rem;
    }
}

.group-info {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    flex: 1;
    min-width: 0;
}

.group-icon {
    width: 48px;
    height: 48px;
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.group-icon .material-symbols-outlined,
.group-icon i {
    color: white;
    font-size: 24px;
}

.group-text {
    flex: 1;
    min-width: 0;
}

.group-name {
    font-size: 1.125rem;
    font-weight: 600;
    color: var(--p-surface-900);
    margin: 0 0 0.25rem 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

:global(.app-dark) .group-name {
    color: var(--p-surface-0);
}

.group-description {
    font-size: 0.875rem;
    color: var(--p-surface-600);
    margin: 0 0 0.25rem 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

:global(.app-dark) .group-description {
    color: var(--p-surface-400);
}

.group-count {
    font-size: 0.75rem;
    color: var(--p-surface-500);
    font-weight: 500;
}

:global(.app-dark) .group-count {
    color: var(--p-surface-500);
}

.group-actions {
    display: flex;
    gap: 0.25rem;
    flex-shrink: 0;
}

.action-icon-btn {
    width: 36px !important;
    height: 36px !important;
}

/* ===== GROUP CONTENT ===== */
.group-content {
    padding: 0 1rem 1rem 1rem;
}

@media (min-width: 768px) {
    .group-content {
        padding: 0 1.5rem 1.5rem 1.5rem;
    }
}

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

/* ===== EMPTY CATEGORIES ===== */
.empty-categories {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 2rem 1rem;
    gap: 0.75rem;
    border-radius: 8px;
    border-width: 1px;
    border-style: dashed;
}

.empty-categories i {
    font-size: 2rem;
    color: var(--p-surface-400);
}

:global(.app-dark) .empty-categories i {
    color: var(--p-surface-500);
}

.empty-categories span {
    font-size: 0.875rem;
    color: var(--p-surface-600);
}

:global(.app-dark) .empty-categories span {
    color: var(--p-surface-400);
}

/* ===== CATEGORIES GRID ===== */
.categories-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 0.75rem;
}

@media (min-width: 640px) {
    .categories-grid {
        grid-template-columns: repeat(2, 1fr);
    }
}

@media (min-width: 1024px) {
    .categories-grid {
        grid-template-columns: repeat(3, 1fr);
    }
}

/* ===== CATEGORY ITEM ===== */
.category-item {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    padding: 0.875rem;
    border-width: 1px;
    border-style: solid;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s;
    min-height: 64px;
}

.category-item:hover {
    background: var(--p-surface-100);
    border-color: var(--p-surface-300);
    transform: translateY(-1px);
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
}

:global(.app-dark) .category-item:hover {
    background: var(--p-surface-600);
    border-color: var(--p-surface-500);
}

.category-item:active {
    transform: scale(0.98);
}

.category-icon {
    width: 40px;
    height: 40px;
    border-radius: 8px;
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.12);
}

.category-icon .material-symbols-outlined,
.category-icon i {
    color: white;
    font-size: 20px;
}

.category-info {
    flex: 1;
    min-width: 0;
}

.category-name {
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--p-surface-900);
    margin: 0 0 0.125rem 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

:global(.app-dark) .category-name {
    color: var(--p-surface-100);
}

.category-description {
    font-size: 0.75rem;
    color: var(--p-surface-600);
    margin: 0;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

:global(.app-dark) .category-description {
    color: var(--p-surface-400);
}

.category-actions {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex-shrink: 0;
}

/* ===== EMPTY STATE ===== */
.empty-state {
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 400px;
    padding: 2rem 1rem;
}

.empty-state-content {
    text-align: center;
    max-width: 400px;
}

.empty-icon {
    font-size: 4rem;
    color: var(--p-surface-300);
    margin-bottom: 1.5rem;
}

:global(.app-dark) .empty-icon {
    color: var(--p-surface-600);
}

.empty-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: var(--p-surface-700);
    margin: 0 0 0.5rem 0;
}

:global(.app-dark) .empty-title {
    color: var(--p-surface-300);
}

.empty-description {
    font-size: 0.875rem;
    color: var(--p-surface-500);
    margin: 0 0 1.5rem 0;
}

:global(.app-dark) .empty-description {
    color: var(--p-surface-400);
}

/* ===== LOADING STATE ===== */
.categories-container :deep(.p-progress-spinner) {
    margin: 3rem auto;
}

/* ===== MATERIAL ICONS ===== */
.material-symbols-outlined {
    font-size: 20px;
}
</style>