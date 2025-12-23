<template>
    <PageLayout v-if="group" :title="group.nombre" :back-button="true">
        <!-- Acciones del header -->
        <template #actions>
            <Button 
                icon="pi pi-refresh" 
                @click="refreshData" 
                :loading="loading" 
                severity="secondary" 
                outlined 
                size="small"
                v-tooltip.bottom="'Actualizar'"
            />
            <Button 
                v-if="canEdit"
                icon="pi pi-pencil" 
                @click="showEditDialog = true" 
                size="small" 
                label="Editar"
                class="mobile-icon-only"
            />
        </template>

        <!-- Loading State -->
        <div v-if="loading" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Contenido -->
        <div v-else class="space-y-6">
            <!-- Header del grupo -->
            <Card class="overflow-hidden">
                <template #content>
                    <div class="flex flex-col md:flex-row gap-6">
                        <!-- Icono y color -->
                        <div 
                            class="w-full md:w-32 h-32 rounded-xl flex items-center justify-center flex-shrink-0"
                            :style="{ backgroundColor: group.color || '#3B82F6' }"
                        >
                            <i 
                                :class="[group.imagen_url || 'pi-users', 'text-6xl text-white']"
                            ></i>
                        </div>

                        <!-- Info -->
                        <div class="flex-1">
                            <div class="flex items-start justify-between mb-4">
                                <div>
                                    <h2 class="text-2xl font-bold text-surface-900 dark:text-surface-0 mb-2">
                                        {{ group.nombre }}
                                    </h2>
                                    <div class="flex items-center gap-2 mb-3">
                                        <Tag 
                                            :value="getRoleLabel(userRole)" 
                                            :severity="getRoleSeverity(userRole)"
                                            rounded
                                        />
                                        <Tag 
                                            v-if="group.activo"
                                            value="Activo" 
                                            severity="success"
                                            rounded
                                        />
                                    </div>
                                </div>
                            </div>

                            <p 
                                v-if="group.descripcion"
                                class="text-surface-600 dark:text-surface-400 mb-4"
                            >
                                {{ group.descripcion }}
                            </p>

                            <!-- Stats -->
                            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                                <div>
                                    <p class="text-sm text-surface-500 dark:text-surface-400">Miembros</p>
                                    <p class="text-lg font-semibold text-surface-900 dark:text-surface-0">
                                        {{ members.length }}
                                        <span v-if="group.limite_miembros" class="text-surface-500">
                                            / {{ group.limite_miembros }}
                                        </span>
                                    </p>
                                </div>
                                <div>
                                    <p class="text-sm text-surface-500 dark:text-surface-400">Tu peso</p>
                                    <p class="text-lg font-semibold text-surface-900 dark:text-surface-0">
                                        {{ userWeight }}%
                                    </p>
                                </div>
                                <div>
                                    <p class="text-sm text-surface-500 dark:text-surface-400">Invitaciones</p>
                                    <p class="text-lg font-semibold text-surface-900 dark:text-surface-0">
                                        {{ pendingInvitations.length }}
                                    </p>
                                </div>
                                <div>
                                    <p class="text-sm text-surface-500 dark:text-surface-400">Creado</p>
                                    <p class="text-lg font-semibold text-surface-900 dark:text-surface-0">
                                        {{ formatDate(group.created_at) }}
                                    </p>
                                </div>
                            </div>
                        </div>
                    </div>
                </template>
            </Card>

            <!-- Tabs -->
            <TabView v-model:activeIndex="activeTab">
                <!-- Tab: Miembros -->
                <TabPanel header="Miembros">
                    <MembersList
                        :members="members"
                        :user-role="userRole"
                        :owner-id="group.owner_id"
                        @update-role="handleUpdateRole"
                        @remove-member="handleRemoveMember"
                    />
                    
                    <Button
                        v-if="canInvite"
                        icon="pi pi-user-plus"
                        label="Invitar miembro"
                        @click="showInviteDialog = true"
                        class="mt-4"
                    />
                </TabPanel>

                <!-- Tab: Invitaciones -->
                <TabPanel header="Invitaciones">
                    <InvitationsList
                        :invitations="pendingInvitations"
                        :can-cancel="canInvite"
                        @cancel="handleCancelInvitation"
                        @refresh="loadInvitations"
                    />

                    <Button
                        v-if="canInvite && pendingInvitations.length === 0"
                        icon="pi pi-envelope"
                        label="Enviar invitación"
                        @click="showInviteDialog = true"
                        class="mt-4"
                    />
                </TabPanel>

                <!-- Tab: Configuración (solo owner) -->
                <TabPanel v-if="isOwner" header="Configuración">
                    <Card>
                        <template #content>
                            <div class="space-y-6">
                                <!-- Activar/Desactivar grupo -->
                                <div class="flex items-center justify-between pb-4 border-b border-surface-200 dark:border-surface-700">
                                    <div>
                                        <h3 class="font-semibold text-surface-900 dark:text-surface-0 mb-1">
                                            Estado del grupo
                                        </h3>
                                        <p class="text-sm text-surface-600 dark:text-surface-400">
                                            Los grupos inactivos no permiten nuevas transacciones
                                        </p>
                                    </div>
                                    <InputSwitch v-model="group.activo" @change="handleToggleActive" />
                                </div>

                                <!-- Zona de peligro -->
                                <div class="pt-4">
                                    <h3 class="font-semibold text-red-600 mb-3">Zona de peligro</h3>
                                    <div class="space-y-3">
                                        <div class="flex items-center justify-between p-4 bg-red-50 dark:bg-red-900/20 rounded-lg border border-red-200 dark:border-red-800">
                                            <div>
                                                <h4 class="font-medium text-surface-900 dark:text-surface-0 mb-1">
                                                    Eliminar grupo
                                                </h4>
                                                <p class="text-sm text-surface-600 dark:text-surface-400">
                                                    Esta acción no se puede deshacer
                                                </p>
                                            </div>
                                            <Button
                                                label="Eliminar"
                                                icon="pi pi-trash"
                                                severity="danger"
                                                @click="confirmDeleteGroup"
                                            />
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </template>
                    </Card>
                </TabPanel>
            </TabView>
        </div>

        <!-- Dialogs -->
        <GroupFormDialog
            v-model:visible="showEditDialog"
            :group="group"
            @saved="handleGroupUpdated"
        />

        <InvitationDialog
            v-model:visible="showInviteDialog"
            :group-id="groupId"
            @invited="handleInvitationSent"
        />

        <ConfirmDialog></ConfirmDialog>
    </PageLayout>

    <!-- Loading inicial -->
    <div v-else class="flex justify-center items-center min-h-screen">
        <ProgressSpinner />
    </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useGroupsStore } from '@/stores/groups'
import { useSessionStore } from '@/stores/session'
import { formatDate } from '@/lib/utils'
import PageLayout from '@/components/PageLayout.vue'
import GroupFormDialog from './components/GroupFormDialog.vue'
import InvitationDialog from './components/InvitationDialog.vue'
import MembersList from './components/MembersList.vue'
import InvitationsList from './components/InvitationsList.vue'
import Card from 'primevue/card'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import TabView from 'primevue/tabview'
import TabPanel from 'primevue/tabpanel'
import ProgressSpinner from 'primevue/progressspinner'
import InputSwitch from 'primevue/inputswitch'
import ConfirmDialog from 'primevue/confirmdialog'

// Composables
const route = useRoute()
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()
const groupsStore = useGroupsStore()
const sessionStore = useSessionStore()

// Estados
const loading = ref(false)
const showEditDialog = ref(false)
const showInviteDialog = ref(false)
const activeTab = ref(0)

// Computed
const groupId = computed(() => route.params.id)
const group = computed(() => groupsStore.currentGroup)
const members = computed(() => groupsStore.groupMembers)
const pendingInvitations = computed(() => groupsStore.pendingInvitations)

const userRole = computed(() => {
    if (!group.value || !sessionStore.user) return null
    const member = members.value.find(m => m.usuario_id === sessionStore.user.id)
    return member?.rol || null
})

const userWeight = computed(() => {
    if (!group.value || !sessionStore.user) return 0
    const member = members.value.find(m => m.usuario_id === sessionStore.user.id)
    return member?.porcentaje_peso || 0
})

const isOwner = computed(() => userRole.value === 'owner')
const isAdmin = computed(() => userRole.value === 'administrador' || isOwner.value)
const canEdit = computed(() => isAdmin.value)
const canInvite = computed(() => isAdmin.value)

// Métodos
const refreshData = async () => {
    loading.value = true
    try {
        await Promise.all([
            groupsStore.refreshGroup(groupId.value, { toast }),
            loadMembers(),
            loadInvitations()
        ])
    } catch (error) {
        console.error('Error al actualizar datos:', error)
    } finally {
        loading.value = false
    }
}

const loadMembers = async () => {
    try {
        await groupsStore.fetchGroupMembers(groupId.value, { toast })
    } catch (error) {
        console.error('Error al cargar miembros:', error)
    }
}

const loadInvitations = async () => {
    try {
        await groupsStore.fetchInvitations(groupId.value, { toast })
    } catch (error) {
        console.error('Error al cargar invitaciones:', error)
    }
}

const handleGroupUpdated = async () => {
    showEditDialog.value = false
    await refreshData()
}

const handleUpdateRole = async ({ memberId, newRole }) => {
    try {
        await groupsStore.updateMemberRole(groupId.value, memberId, newRole, { toast })
        await loadMembers()
    } catch (error) {
        console.error('Error al actualizar rol:', error)
    }
}

const handleRemoveMember = async (memberId) => {
    confirm.require({
        message: '¿Estás seguro de eliminar este miembro del grupo?',
        header: 'Confirmar eliminación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Eliminar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await groupsStore.removeMember(groupId.value, memberId, { toast })
                await loadMembers()
            } catch (error) {
                console.error('Error al eliminar miembro:', error)
            }
        }
    })
}

const handleInvitationSent = async () => {
    showInviteDialog.value = false
    await loadInvitations()
}

const handleCancelInvitation = async (invitationId) => {
    try {
        await groupsStore.cancelInvitation(invitationId, { toast })
        await loadInvitations()
    } catch (error) {
        console.error('Error al cancelar invitación:', error)
    }
}

const handleToggleActive = async () => {
    try {
        await groupsStore.updateGroup(groupId.value, { activo: group.value.activo }, { toast })
        toast.add({
            severity: 'success',
            summary: group.value.activo ? 'Grupo activado' : 'Grupo desactivado',
            life: 3000
        })
    } catch (error) {
        console.error('Error al cambiar estado:', error)
        group.value.activo = !group.value.activo // Revertir cambio
    }
}

const confirmDeleteGroup = () => {
    confirm.require({
        message: `¿Estás seguro de eliminar el grupo "${group.value.nombre}"? Todos los datos relacionados se eliminarán permanentemente.`,
        header: 'Confirmar eliminación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Eliminar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            try {
                await groupsStore.deleteGroup(groupId.value, { toast })
                router.push({ name: 'groups' })
            } catch (error) {
                console.error('Error al eliminar grupo:', error)
            }
        }
    })
}

const getRoleLabel = (role) => {
    const labels = {
        'owner': 'Propietario',
        'administrador': 'Administrador',
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
    await refreshData()
})

// Watch para cambios en el ID del grupo
watch(() => groupId.value, async (newId) => {
    if (newId) {
        await refreshData()
    }
})
</script>

<style scoped>
.space-y-6 > * + * {
    margin-top: 1.5rem;
}

.space-y-3 > * + * {
    margin-top: 0.75rem;
}

.mobile-icon-only :deep(.p-button-label) {
    display: inline;
}

@media (max-width: 640px) {
    .mobile-icon-only :deep(.p-button-label) {
        display: none;
    }
}
</style>
