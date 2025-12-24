<template>
    <div class="space-y-4">
        <!-- Empty State -->
        <div v-if="!members.length" class="text-center py-12">
            <div
                class="w-20 h-20 mx-auto mb-4 rounded-full bg-surface-100 dark:bg-surface-800 flex items-center justify-center">
                <i class="pi pi-users text-4xl text-surface-400"></i>
            </div>
            <h3 class="text-lg font-semibold text-surface-700 dark:text-surface-300 mb-2">
                No hay miembros
            </h3>
            <p class="text-surface-500 dark:text-surface-400">
                Este grupo aún no tiene miembros
            </p>
        </div>

        <!-- Lista de miembros -->
        <div v-else>
            <!-- Grid de miembros -->
            <div class="space-y-2">
                <div v-for="member in sortedMembers" :key="member.id"
                    class="member-card group rounded-xl border border-surface-200 dark:border-surface-700 bg-white dark:bg-surface-800">
                    <div class="p-4">
                        <div class="flex items-center justify-between gap-4">
                            <!-- Info del miembro -->
                            <div class="flex items-center gap-3 flex-1 min-w-0">
                                <!-- Avatar con badge de owner -->
                                <div class="relative flex-shrink-0">
                                    <Avatar :label="getInitials(member.usuario?.full_name)"
                                        :image="member.usuario?.avatar_url" size="large" shape="circle"
                                        class="ring-2 ring-surface-100 dark:ring-surface-700"
                                        :class="member.usuario_id === ownerId ? 'ring-primary-200 dark:ring-primary-800' : ''" />
                                </div>

                                <!-- Datos del usuario -->
                                <div class="flex-1 min-w-0">
                                    <div class="flex items-center gap-2">
                                        <h4
                                            class="font-semibold text-surface-900 dark:text-surface-0 truncate text-xl mb-0">
                                            {{ member.usuario?.full_name || member.usuario?.username || 'Usuario' }}
                                        </h4>
                                        <Tag v-if="member.usuario_id === ownerId" severity="contrast" rounded>
                                            <span class="material-symbols-outlined"
                                                style="font-size: 1rem; font-weight: bold">crown</span>
                                        </Tag>
                                        <Tag v-else-if="member.rol === 'administrador'" severity="warning" rounded>
                                            <span class="material-symbols-outlined"
                                                style="font-size: 1rem; font-weight: bold">shield</span>
                                        </Tag>
                                        <Tag v-else-if="member.rol === 'miembro'" severity="info" rounded>
                                            <span class="material-symbols-outlined"
                                                style="font-size: 1rem; font-weight: bold">person</span>
                                        </Tag>
                                    </div>
                                    <div class="flex items-center gap-2 text-sm text-surface-600 dark:text-surface-400">
                                        <i class="pi pi-at text-xs"></i>
                                        <span class="truncate">{{ member.usuario?.username || 'sin usuario' }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Stats y acciones (Desktop) -->
                            <div class="hidden md:flex items-center gap-4 flex-shrink-0">
                                <!-- Peso con barra de progreso -->
                                <div class="text-right">
                                    <div class="flex items-center justify-end gap-2 mb-1">
                                        <i class="pi pi-percentage text-xs text-surface-400"></i>
                                        <span class="text-lg font-bold text-primary-600 dark:text-primary-400">
                                            {{ member.porcentaje_participacion || 0 }}%
                                        </span>
                                    </div>
                                    <div class="h-1.5 bg-surface-200 dark:bg-surface-700 rounded-full overflow-hidden">
                                        <div class="h-full bg-gradient-to-r from-primary-500 to-primary-600 rounded-full transition-all duration-300"
                                            :style="{ width: `${member.porcentaje_participacion || 0}%` }"></div>
                                    </div>
                                </div>

                                <!-- Selector de rol o Tag -->
                                <div>
                                    <Select v-if="canEditRole(member)" v-model="member.rol" :options="availableRoles"
                                        optionLabel="label" optionValue="value" @change="handleRoleChange(member)"
                                        placeholder="Seleccionar rol" class="w-full">
                                        <template #value="slotProps">
                                            <div class="flex items-center gap-2">
                                                <i :class="getRoleIcon(slotProps.value)" class="text-sm"></i>
                                                <span class="text-sm font-medium">{{ getRoleLabel(slotProps.value)
                                                    }}</span>
                                            </div>
                                        </template>
                                        <template #option="slotProps">
                                            <div class="flex items-center gap-2">
                                                <i :class="getRoleIcon(slotProps.option.value)" class="text-sm"></i>
                                                <span>{{ slotProps.option.label }}</span>
                                            </div>
                                        </template>
                                    </Select>
                                </div>
                            </div>

                            <!-- Botón de acciones (Mobile) -->
                            <Button icon="pi pi-ellipsis-v" text rounded size="small" class="md:hidden"
                                @click="toggleMobileMenu($event, member)" />
                        </div>

                        <!-- Stats móvil -->
                        <div class="md:hidden mt-4 pt-4 border-t border-surface-200 dark:border-surface-700 space-y-3">
                            <!-- Peso -->
                            <div class="flex items-center justify-between">
                                <span class="text-sm text-surface-500 dark:text-surface-400">Peso</span>
                                <div class="flex items-center gap-2">
                                    <div
                                        class="w-24 h-2 bg-surface-200 dark:bg-surface-700 rounded-full overflow-hidden">
                                        <div class="h-full bg-gradient-to-r from-primary-500 to-primary-600 rounded-full"
                                            :style="{ width: `${member.porcentaje_participacion || 0}%` }"></div>
                                    </div>
                                    <span
                                        class="text-sm font-bold text-primary-600 dark:text-primary-400 w-12 text-right">
                                        {{ member.porcentaje_participacion || 0 }}%
                                    </span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Resumen de pesos -->
        <Card v-if="members.length > 0"
            class="bg-gradient-to-r from-surface-50 to-surface-100 dark:from-surface-900 dark:to-surface-800 border-2"
            :class="totalWeightBorderClass">
            <template #content>
                <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div class="flex items-center gap-3">
                        <div class="w-12 h-12 rounded-full flex items-center justify-center" :class="totalWeightIconBg">
                            <i class="pi pi-chart-pie text-xl" :class="totalWeightIconColor"></i>
                        </div>
                        <div>
                            <p class="font-semibold text-surface-700 dark:text-surface-300 mb-1">
                                Distribución de peso
                            </p>
                            <p class="text-sm text-surface-600 dark:text-surface-400">
                                {{ totalWeight === 100 ? 'Distribución correcta' : totalWeight > 100 ? 'Excede el 100%'
            : 'Falta asignar peso' }}
                            </p>
                        </div>
                    </div>
                    <div class="flex items-center gap-3">
                        <div class="text-right">
                            <p class="text-xs text-surface-500 dark:text-surface-400 mb-1">Total asignado</p>
                            <p class="text-3xl font-bold" :class="totalWeightClass">
                                {{ totalWeight }}%
                            </p>
                        </div>
                        <i v-if="totalWeight !== 100" class="pi pi-exclamation-triangle text-2xl"
                            :class="totalWeight > 100 ? 'text-red-500' : 'text-orange-500'"
                            v-tooltip.left="totalWeight > 100 ? 'El peso total no puede exceder el 100%' : 'El peso total debe sumar 100%'"></i>
                        <i v-else class="pi pi-check-circle text-2xl text-green-500"></i>
                    </div>
                </div>
            </template>
        </Card>

        <!-- Menu contextual mobile -->
        <Menu ref="mobileMenu" :model="mobileMenuItems" :popup="true" />
    </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { formatDate } from '@/lib/utils'
import Menu from 'primevue/menu'

// Refs
const mobileMenu = ref()
const selectedMember = ref(null)

// Props
const props = defineProps({
    members: {
        type: Array,
        required: true
    },
    userRole: {
        type: String,
        default: null
    },
    ownerId: {
        type: String,
        required: true
    }
})

// Emits
const emit = defineEmits(['update-role', 'remove-member'])

// Computed
const isOwner = computed(() => props.userRole === 'owner')
const isAdmin = computed(() => props.userRole === 'administrador' || isOwner.value)

const sortedMembers = computed(() => {
    return [...props.members].sort((a, b) => {
        // Owner primero
        if (a.usuario_id === props.ownerId) return -1
        if (b.usuario_id === props.ownerId) return 1

        // Luego por rol
        const roleOrder = { 'owner': 0, 'administrador': 1, 'miembro': 2 }
        const roleCompare = roleOrder[a.rol] - roleOrder[b.rol]
        if (roleCompare !== 0) return roleCompare

        // Finalmente por nombre
        const nameA = a.usuario?.full_name || a.usuario?.username || ''
        const nameB = b.usuario?.full_name || b.usuario?.username || ''
        return nameA.localeCompare(nameB)
    })
})

const totalWeight = computed(() => {
    return props.members.reduce((sum, member) => sum + (member.porcentaje_participacion || 0), 0)
})

const totalWeightClass = computed(() => {
    if (totalWeight.value === 100) return 'text-green-600 dark:text-green-400'
    if (totalWeight.value > 100) return 'text-red-600 dark:text-red-400'
    return 'text-orange-600 dark:text-orange-400'
})

const totalWeightBorderClass = computed(() => {
    if (totalWeight.value === 100) return 'border-green-200 dark:border-green-800'
    if (totalWeight.value > 100) return 'border-red-200 dark:border-red-800'
    return 'border-orange-200 dark:border-orange-800'
})

const totalWeightIconBg = computed(() => {
    if (totalWeight.value === 100) return 'bg-green-100 dark:bg-green-900/30'
    if (totalWeight.value > 100) return 'bg-red-100 dark:bg-red-900/30'
    return 'bg-orange-100 dark:bg-orange-900/30'
})

const totalWeightIconColor = computed(() => {
    if (totalWeight.value === 100) return 'text-green-600 dark:text-green-400'
    if (totalWeight.value > 100) return 'text-red-600 dark:text-red-400'
    return 'text-orange-600 dark:text-orange-400'
})

const mobileMenuItems = computed(() => {
    if (!selectedMember.value) return []

    const items = []

    if (canEditRole(selectedMember.value)) {
        items.push({
            label: 'Cambiar rol',
            icon: 'pi pi-user-edit',
            items: availableRoles.map(role => ({
                label: role.label,
                icon: getRoleIcon(role.value),
                command: () => {
                    selectedMember.value.rol = role.value
                    handleRoleChange(selectedMember.value)
                }
            }))
        })
    }

    if (canRemoveMember(selectedMember.value)) {
        items.push({
            separator: true
        }, {
            label: 'Eliminar',
            icon: 'pi pi-trash',
            class: 'text-red-500',
            command: () => handleRemove(selectedMember.value)
        })
    }

    return items
})

const availableRoles = [
    { label: 'Administrador', value: 'administrador' },
    { label: 'Miembro', value: 'miembro' }
]

// Métodos
const getInitials = (name) => {
    if (!name) return '?'
    return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .toUpperCase()
        .substring(0, 2)
}

const canEditRole = (member) => {
    // Owner no se puede cambiar
    if (member.usuario_id === props.ownerId) return false

    // Solo owner y admin pueden cambiar roles
    return isAdmin.value
}

const canRemoveMember = (member) => {
    // Owner no se puede eliminar
    if (member.usuario_id === props.ownerId) return false

    // Solo owner y admin pueden eliminar
    return isAdmin.value
}

const handleRoleChange = (member) => {
    emit('update-role', {
        memberId: member.id,
        newRole: member.rol
    })
}

const handleRemove = (member) => {
    emit('remove-member', member.id)
}

const toggleMobileMenu = (event, member) => {
    selectedMember.value = member
    mobileMenu.value.toggle(event)
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

const getRoleIcon = (role) => {
    const icons = {
        'owner': 'pi pi-crown',
        'administrador': 'pi pi-shield',
        'miembro': 'pi pi-user'
    }
    return icons[role] || 'pi pi-user'
}

const getRoleBackgroundClass = (role) => {
    const classes = {
        'owner': 'bg-primary-100 dark:bg-primary-900/30 text-primary-700 dark:text-primary-400',
        'administrador': 'bg-orange-100 dark:bg-orange-900/30 text-orange-700 dark:text-orange-400',
        'miembro': 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400'
    }
    return classes[role] || 'bg-surface-100 dark:bg-surface-700 text-surface-700 dark:text-surface-300'
}
</script>

<style scoped>
.member-card {
    transition: all 0.2s ease;
}

.space-y-4>*+* {
    margin-top: 1rem;
}

.space-y-3>*+* {
    margin-top: 0.75rem;
}

.space-y-2>*+* {
    margin-top: 0.5rem;
}
</style>
