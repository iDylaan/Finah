<template>
    <PageLayout title="Mis Grupos" description="Gestiona tus grupos financieros compartidos">
        <!-- Acciones del header -->
        <template #actions>
            <Button icon="pi pi-refresh" @click="refreshData" :loading="groupsStore.loading" severity="secondary"
                outlined size="small" v-tooltip.bottom="'Actualizar'" />
            <Button icon="pi pi-plus" @click="showCreateDialog = true" :disabled="groupsStore.loading" size="small"
                label="Nuevo Grupo" class="mobile-icon-only" />
        </template>

        <!-- Loading State -->
        <div v-if="groupsStore.loading && !groups.length" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Empty State -->
        <div v-else-if="!groups.length" class="text-center py-12">
            <i class="pi pi-users text-6xl text-surface-400 mb-4"></i>
            <h3 class="text-xl font-semibold text-surface-700 dark:text-surface-300 mb-2">
                No tienes grupos todavía
            </h3>
            <p class="text-surface-500 dark:text-surface-400 mb-6">
                Crea tu primer grupo para comenzar a compartir gastos con tu familia o amigos
            </p>
            <Button icon="pi pi-plus" label="Crear mi primer grupo" @click="showCreateDialog = true" />
        </div>

        <!-- Lista de Grupos -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="(group, index) in groups" :key="group.id"
                class="group-card rounded-xl border border-surface-200 dark:border-surface-700 bg-white dark:bg-surface-800 overflow-hidden hover:shadow-lg transition-all duration-300 cursor-pointer animate__animated animate__fadeInUp animate__faster"
                :style="{ animationDelay: `${index * 0.05}s` }" @click="navigateToGroup(group)">
                <!-- Header del grupo con color -->
                <div class="h-24 relative flex items-center justify-center"
                    :style="{ backgroundColor: group.color || '#3B82F6' }">
                    <i v-if="group.biblioteca_iconos === 'primevue'"
                        :class="[group.nombre_icono || 'pi-users', 'text-5xl text-white']"></i>
                    <span v-else class="material-symbols-outlined text-5xl text-white">
                        {{ group.nombre_icono || 'group' }}
                    </span>
                </div>

                <!-- Contenido -->
                <div class="p-4">
                    <h3 class="text-lg font-semibold text-surface-900 dark:text-surface-0 mb-2 truncate">
                        {{ group.nombre }}
                    </h3>

                    <p v-if="group.descripcion"
                        class="text-sm text-surface-600 dark:text-surface-400 mb-3 line-clamp-2">
                        {{ group.descripcion }}
                    </p>

                    <!-- Stats del grupo -->
                    <div class="flex items-center justify-between text-sm text-surface-600 dark:text-surface-400">
                        <div class="flex items-center gap-2">
                            <i class="pi pi-users text-xs"></i>
                            <span>
                                {{ group.miembros_count || 0 }}
                                <span v-if="group.limite_miembros" class="text-surface-400">/ {{ group.limite_miembros }}</span>
                                <span class="ml-1">miembros</span>
                            </span>
                        </div>

                        <Button icon="pi pi-ellipsis-v" size="small" text @click.stop="toggleMenu($event, group)"
                            aria-haspopup="true" :aria-controls="`group-menu-${group.id}`" />
                    </div>
                </div>
            </div>
        </div>

        <!-- Context Menu -->
        <Menu ref="menu" :model="menuItems" :popup="true" />

        <!-- Dialog Crear/Editar Grupo -->
        <GroupFormDialog v-model:visible="showCreateDialog" :group="selectedGroup" @saved="handleGroupSaved" />

        <!-- Dialog Confirmar Eliminación -->
        <ConfirmDialog></ConfirmDialog>
    </PageLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useGroupsStore } from '@/stores/groups'
import { supabase } from '@/lib/supabase'
import PageLayout from '@/components/PageLayout.vue'
import GroupFormDialog from './components/GroupFormDialog.vue'

// Composables
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()
const groupsStore = useGroupsStore()

// Estados
const showCreateDialog = ref(false)
const selectedGroup = ref(null)
const menu = ref()
const groupsWithMembers = ref([])

// Computed
const groups = computed(() => groupsWithMembers.value.length > 0 ? groupsWithMembers.value : groupsStore.activeGroups)

// Menú contextual
const menuItems = computed(() => {
    if (!selectedGroup.value) return []

    const items = [
        {
            label: 'Ver detalles',
            icon: 'pi pi-eye',
            command: () => navigateToGroup(selectedGroup.value)
        }
    ]

    // Solo admins pueden editar
    if (selectedGroup.value.user_role === 'owner' || selectedGroup.value.user_role === 'administrador') {
        items.push({
            label: 'Editar',
            icon: 'pi pi-pencil',
            command: () => handleEditGroup(selectedGroup.value)
        })
    }

    // Solo owner puede eliminar
    if (selectedGroup.value.user_role === 'owner') {
        items.push({
            separator: true
        }, {
            label: 'Eliminar',
            icon: 'pi pi-trash',
            class: 'text-red-500',
            command: () => confirmDeleteGroup(selectedGroup.value)
        })
    } else {
        // Miembros y admins pueden salir
        items.push({
            separator: true
        }, {
            label: 'Salir del grupo',
            icon: 'pi pi-sign-out',
            class: 'text-orange-500',
            command: () => confirmLeaveGroup(selectedGroup.value)
        })
    }

    return items
})

// Métodos
const loadGroupsWithMemberCount = async () => {
    const baseGroups = groupsStore.activeGroups
    const groupsWithCount = await Promise.all(
        baseGroups.map(async (group) => {
            const { count } = await supabase
                .from('miembros_grupo')
                .select('*', { count: 'exact', head: true })
                .eq('grupo_id', group.id)
            
            return {
                ...group,
                miembros_count: count || 0
            }
        })
    )
    groupsWithMembers.value = groupsWithCount
}

const refreshData = async () => {
    try {
        await groupsStore.refreshGroups({ toast })
        await loadGroupsWithMemberCount()
    } catch (error) {
        console.error('Error al actualizar grupos:', error)
    }
}

const toggleMenu = (event, group) => {
    selectedGroup.value = group
    menu.value.toggle(event)
}

const navigateToGroup = (group) => {
    router.push({ name: 'group-details', params: { id: group.id } })
}

const handleEditGroup = (group) => {
    selectedGroup.value = { ...group }
    showCreateDialog.value = true
}

const handleGroupSaved = async () => {
    showCreateDialog.value = false
    selectedGroup.value = null
    await refreshData()
}

const confirmDeleteGroup = (group) => {
    confirm.require({
        message: `¿Estás seguro de eliminar el grupo "${group.nombre}"? Esta acción no se puede deshacer.`,
        header: 'Confirmar eliminación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Eliminar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await groupsStore.deleteGroup(group.id, { toast })
            } catch (error) {
                console.error('Error al eliminar grupo:', error)
            }
        }
    })
}

const confirmLeaveGroup = (group) => {
    confirm.require({
        message: `¿Estás seguro de salir del grupo "${group.nombre}"?`,
        header: 'Confirmar salida',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Salir',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-warning',
        accept: async () => {
            try {
                await groupsStore.leaveGroup(group.id, { toast })
            } catch (error) {
                console.error('Error al salir del grupo:', error)
            }
        }
    })
}

const getRoleLabel = (role) => {
    const labels = {
        'owner': 'Propietario',
        'administrador': 'Admin',
        'miembro': 'Miembro'
    }
    return labels[role] || role
}

const getRoleSeverity = (role) => {
    const severities = {
        'owner': 'danger',
        'administrador': 'warning',
        'miembro': 'info'
    }
    return severities[role] || 'secondary'
}

// Lifecycle
onMounted(async () => {
    try {
        await groupsStore.fetchGroups({ toast })
        await loadGroupsWithMemberCount()
    } catch (error) {
        console.error('Error al cargar grupos:', error)
    }
})
</script>

<style scoped>
.group-card {
    transition: all 0.3s ease;
}

.group-card:hover {
    transform: translateY(-4px);
}

.mobile-icon-only :deep(.p-button-label) {
    display: inline;
}

@media (max-width: 640px) {
    .mobile-icon-only :deep(.p-button-label) {
        display: none;
    }
}

.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    line-clamp: 2;
    overflow: hidden;
}
</style>
