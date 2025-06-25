<template>
    <div class="p-6 max-w-5xl mx-auto">
        <!-- Header -->
        <div class="flex justify-between items-center mb-6">
            <div>
                <h1 class="text-3xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                    Categorías
                </h1>
                <p class="text-surface-600 dark:text-surface-400">
                    Gestiona la clasificación de tus ingresos, egresos y gastos
                </p>
            </div>

            <!-- Botón de recarga -->
            <div class="flex gap-2">
                <Button icon="pi pi-refresh" @click="loadData" :loading="categoriesStore.loading" severity="secondary"
                    outlined size="small" />
                <Button icon="pi pi-plus" @click="handleNewCategoryGroup" :disabled="categoriesStore.loading"
                    severity="success" outlined size="small" label="Nuevo" />
            </div>
        </div>

        <!-- Loading State -->
        <div v-if="categoriesStore.loading" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Content -->
        <div v-else-if="categoryGroups.length > 0" class="space-y-4">
            <!-- Lista de Grupos con Panel -->
            <Panel v-for="group in categoryGroups" :key="group.id" toggleable :collapsed="false"
                class="bg-surface-0 dark:bg-surface-800 border border-surface-200 dark:border-surface-700 rounded-lg overflow-hidden">
                <!-- Header del Grupo -->
                <template #header>
                    <div class="flex items-center gap-3">
                        <!-- Icono del grupo -->
                        <div class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 shadow-sm"
                            :style="{ backgroundColor: group.color || '#6366f1' }">
                            <span v-if="group.icon_library === 'material'" class="material-symbols-outlined">{{
                                group.icon_name }}</span>
                            <i v-else :class="group.icon_name || 'pi pi-folder'" class="text-white text-sm"></i>
                        </div>

                        <!-- Info del grupo -->
                        <div class="flex justify-center flex-col">
                            <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0 truncate my-auto">
                                {{ group.name }}
                            </h3>
                            <p v-if="group.description" class="text-sm text-surface-600 dark:text-surface-400 truncate">
                                {{ group.description }}
                            </p>
                        </div>
                    </div>
                </template>

                <template #icons>
                    <Button icon="pi pi-cog" severity="secondary" rounded text
                        @click="(event) => toggleGroupMenu(event, group.id)" />

                    <!-- Menú popup para cada grupo -->
                    <Menu :ref="(el) => setGroupMenuRef(el, group.id)" :id="`group_menu_${group.id}`"
                        :model="getGroupMenuItems(group)" popup />
                </template>

                <!-- Contenido del Panel (Lista de Categorías) -->
                <div class="pt-2">
                    <!-- Mensaje si no hay categorías -->
                    <Message v-if="group.categories.length === 0" severity="info" :closable="false" class="mb-0">
                        <div class="flex items-center gap-2">
                            <i class="pi pi-inbox"></i>
                            <span>No hay categorías en este grupo</span>
                        </div>
                    </Message>

                    <!-- Lista de categorías -->
                    <div v-else class="space-y-3">
                        <div v-for="category in group.categories" :key="category.id"
                            class="flex items-center gap-3 p-3 rounded-lg backdrop-blur-sm bg-surface-50/80 dark:bg-surface-700/50 border border-surface-200/50 dark:border-surface-600/50 hover:bg-surface-100/80 dark:hover:bg-surface-600/50 transition-all duration-200 cursor-pointer"
                            @click="() => handleCategoryClick(category)">
                            <!-- Icono de la categoría -->
                            <div class="w-8 h-8 rounded-md flex items-center justify-center flex-shrink-0 shadow-sm"
                                :style="{ backgroundColor: group.color || '#6366f1' }">
                                <span v-if="category.icon_library === 'material'" class="material-symbols-outlined">{{
                                    category.icon_name }}</span>
                                <i v-else :class="category.icon_name || 'pi pi-tag'" class="text-white text-xs"></i>
                            </div>

                            <!-- Info de la categoría -->
                            <div class="flex flex-col justify-center flex-1">
                                <h4 class="text-sm font-semibold text-surface-900 dark:text-surface-100 truncate mb-0">
                                    {{ category.name }}
                                </h4>
                                <p v-if="category.description"
                                    class="text-xs text-surface-600 dark:text-surface-400 truncate">
                                    {{ category.description }}
                                </p>
                            </div>

                            <!-- Badge personal y opciones -->
                            <div class="flex items-center gap-2">
                                <Badge v-if="!category.is_public" value="Personal" severity="success" size="small" />

                                <!-- Menú de opciones solo para categorías privadas -->
                                <Button v-if="!category.is_public" icon="pi pi-ellipsis-v" severity="secondary" rounded
                                    text size="small" @click.stop="(event) => toggleCategoryMenu(event, category.id)" />

                                <!-- Menú popup para cada categoría -->
                                <Menu v-if="!category.is_public" :ref="(el) => setCategoryMenuRef(el, category.id)"
                                    :id="`category_menu_${category.id}`" :model="getCategoryMenuItems(category)"
                                    popup />
                            </div>
                        </div>
                    </div>
                </div>
            </Panel>
        </div>

        <!-- Empty State -->
        <Card v-else
            class="backdrop-blur-md bg-surface-0/80 dark:bg-surface-800/80 border border-surface-200/30 dark:border-surface-700/30">
            <template #content>
                <div class="text-center py-12">
                    <div class="mb-6">
                        <i class="pi pi-folder-open text-6xl text-surface-300 dark:text-surface-600"></i>
                    </div>

                    <h3 class="text-xl font-semibold text-surface-700 dark:text-surface-300 mb-2">
                        No hay grupos de categorías
                    </h3>

                    <p class="text-surface-500 dark:text-surface-400 mb-6 max-w-md mx-auto">
                        No se encontraron grupos de categorías disponibles
                    </p>

                    <Button label="Recargar datos" icon="pi pi-refresh" @click="loadData" outlined />
                </div>
            </template>
        </Card>

        <!-- Modal Component -->
        <NewCategory v-model:visible="showNewCategoryGroupModal" :category-groups="categoryGroups"
            :is-loading="categoriesStore.loading" :edit-category="editingCategoryGroup"
            @submit="handleCategoryGroupSubmit" @close="handleModalClose" />
    </div>
</template>

<script setup>
// IMPORTS
import { ref, onMounted, computed } from 'vue';
import { useToast } from 'primevue/usetoast';
import { useCategoriesStore } from '@/stores/categories.js';
import NewCategory from './components/NewCategoryGroup.vue';

// STORES & COMPOSABLES
const toast = useToast();
const categoriesStore = useCategoriesStore();

// VARIABLES
const isInitialLoad = ref(true);
const categoryGroups = computed(() => categoriesStore.categoryGroups);
const groupMenuRefs = ref({});

// Modal state
const showNewCategoryGroupModal = ref(false);
const editingCategoryGroup = ref(null);
const showNewCategoryModal = ref(false);
const editingCategory = ref(null);

// FUNCTIONS
const getGroupMenuItems = (group) => {
    const items = [
        {
            label: 'Nueva categoría',
            icon: 'pi pi-plus',
            command: () => {
                handleNewCategory(group);
            }
        }
    ];

    if (!group.is_public) {
        items.push(
            {
                label: 'Editar',
                icon: 'pi pi-pencil',
                command: () => handleEditGroup(group)
            },
            {
                label: 'Eliminar',
                icon: 'pi pi-trash',
                command: () => handleDeleteGroup(group)
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

// Modal handlers
const handleNewCategory = (group) => {
    editingCategory.value = null;
    showNewCategoryModal.value = true;
};
const handleNewCategoryGroup = () => {
    editingCategoryGroup.value = null;
    showNewCategoryGroupModal.value = true;
};

const handleModalClose = () => {
    showNewCategoryGroupModal.value = false;
    editingCategoryGroup.value = null;
    showNewCategoryModal.value = true;
    editingCategory.value = null;
};

const handleCategoryGroupSubmit = async ({ data, isEdit, onSuccess, onError }) => {
    try {
        console.log('🔄 Procesando categoría:', { data, isEdit });

        let result;

        if (isEdit) {
            // Actualizar categoría existente
            result = await categoriesStore.updateCategory(data, { toast });
        } else {
            // Crear nueva categoría
            result = await categoriesStore.createCategory(data, { toast });
        }

        if (result && !result.error) {
            console.log('✅ Categoría procesada exitosamente:', result.data);

            // Recargar datos para mostrar cambios
            await loadData();

            // Ejecutar callback de éxito
            onSuccess();

            toast.add({
                severity: 'success',
                summary: isEdit ? 'Categoría actualizada' : 'Categoría creada',
                detail: `La categoría "${data.name}" fue ${isEdit ? 'actualizada' : 'creada'} exitosamente`,
                life: 3000
            });
        } else {
            console.error('❌ Error procesando categoría:', result?.error);

            // Ejecutar callback de error
            onError();

            toast.add({
                severity: 'error',
                summary: isEdit ? 'Error al actualizar' : 'Error al crear',
                detail: result?.error?.message || `No se pudo ${isEdit ? 'actualizar' : 'crear'} la categoría`,
                life: 5000
            });
        }

    } catch (error) {
        console.error('💥 Error inesperado:', error);

        // Ejecutar callback de error
        onError();

        toast.add({
            severity: 'error',
            summary: 'Error inesperado',
            detail: `Ocurrió un error al ${isEdit ? 'actualizar' : 'crear'} la categoría`,
            life: 5000
        });
    }
};

// Category actions
const handleCategoryClick = (category) => {
    console.log('Click en categoría:', category);
};

// Función para cargar datos
const loadData = async () => {
    try {
        const result = await categoriesStore.fetchCategoryGroupsWithCategories({ toast });
        isInitialLoad.value = false;
    } catch (error) {
        toast.add({
            severity: 'error',
            summary: 'Error al cargar',
            detail: 'No se pudieron cargar los grupos de categorías',
            life: 5000
        });
    }
};

// Group actions (placeholder)
const handleEditGroup = (group) => {
    console.log('Editar grupo:', group);
    toast.add({
        severity: 'info',
        summary: 'Función pendiente',
        detail: 'Edición de grupos aún no implementada',
        life: 3000
    });
};

const handleDeleteGroup = (group) => {
    console.log('Eliminar grupo:', group);
    toast.add({
        severity: 'warn',
        summary: 'Función pendiente',
        detail: 'Eliminación de grupos aún no implementada',
        life: 3000
    });
};

// HOOKS
onMounted(() => {
    loadData();
});
</script>

<style scoped>
/* Solo para line-clamp que no está disponible en Tailwind por defecto */
.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
}

.material-symbols-outlined {
    font-size: 20px;
}
</style>