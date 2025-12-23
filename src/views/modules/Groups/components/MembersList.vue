<template>
    <div class="space-y-4">
        <!-- Empty State -->
        <div v-if="!members.length" class="text-center py-8">
            <i class="pi pi-users text-5xl text-surface-400 mb-3"></i>
            <p class="text-surface-600 dark:text-surface-400">
                No hay miembros en este grupo
            </p>
        </div>

        <!-- Lista de miembros -->
        <div v-else class="space-y-3">
            <Card 
                v-for="member in sortedMembers" 
                :key="member.id"
                class="member-card"
            >
                <template #content>
                    <div class="flex items-center justify-between gap-4">
                        <!-- Info del miembro -->
                        <div class="flex items-center gap-3 flex-1 min-w-0">
                            <!-- Avatar -->
                            <Avatar 
                                :label="getInitials(member.usuarios?.nombre_completo)"
                                :image="member.usuarios?.avatar_url"
                                size="large"
                                shape="circle"
                                class="flex-shrink-0"
                            />

                            <!-- Datos -->
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 mb-1">
                                    <h4 class="font-semibold text-surface-900 dark:text-surface-0 truncate">
                                        {{ member.usuarios?.nombre_completo || member.usuarios?.email }}
                                    </h4>
                                    <Tag 
                                        v-if="member.usuario_id === ownerId"
                                        value="Owner"
                                        severity="danger"
                                        rounded
                                        class="text-xs"
                                    />
                                </div>
                                <p class="text-sm text-surface-600 dark:text-surface-400 truncate">
                                    {{ member.usuarios?.email }}
                                </p>
                            </div>
                        </div>

                        <!-- Stats y acciones -->
                        <div class="flex items-center gap-4 flex-shrink-0">
                            <!-- Peso -->
                            <div class="text-right hidden sm:block">
                                <p class="text-xs text-surface-500 dark:text-surface-400">Peso</p>
                                <p class="font-semibold text-surface-900 dark:text-surface-0">
                                    {{ member.porcentaje_peso }}%
                                </p>
                            </div>

                            <!-- Selector de rol -->
                            <Dropdown
                                v-if="canEditRole(member)"
                                v-model="member.rol"
                                :options="availableRoles"
                                optionLabel="label"
                                optionValue="value"
                                @change="handleRoleChange(member)"
                                class="w-36"
                            >
                                <template #value="slotProps">
                                    <Tag 
                                        :value="getRoleLabel(slotProps.value)" 
                                        :severity="getRoleSeverity(slotProps.value)"
                                    />
                                </template>
                                <template #option="slotProps">
                                    <Tag 
                                        :value="slotProps.option.label" 
                                        :severity="getRoleSeverity(slotProps.option.value)"
                                        class="w-full"
                                    />
                                </template>
                            </Dropdown>

                            <!-- Tag de rol (solo lectura) -->
                            <Tag
                                v-else
                                :value="getRoleLabel(member.rol)"
                                :severity="getRoleSeverity(member.rol)"
                            />

                            <!-- Botón eliminar -->
                            <Button
                                v-if="canRemoveMember(member)"
                                icon="pi pi-trash"
                                severity="danger"
                                text
                                rounded
                                @click="handleRemove(member)"
                                v-tooltip.left="'Eliminar miembro'"
                            />
                        </div>
                    </div>

                    <!-- Stats móvil -->
                    <div class="sm:hidden mt-3 pt-3 border-t border-surface-200 dark:border-surface-700 flex justify-between text-sm">
                        <div>
                            <span class="text-surface-500 dark:text-surface-400">Peso:</span>
                            <span class="font-semibold text-surface-900 dark:text-surface-0 ml-1">
                                {{ member.porcentaje_peso }}%
                            </span>
                        </div>
                        <div>
                            <span class="text-surface-500 dark:text-surface-400">Desde:</span>
                            <span class="font-semibold text-surface-900 dark:text-surface-0 ml-1">
                                {{ formatDate(member.created_at) }}
                            </span>
                        </div>
                    </div>
                </template>
            </Card>
        </div>

        <!-- Resumen de pesos -->
        <Card v-if="members.length > 0" class="bg-surface-50 dark:bg-surface-900">
            <template #content>
                <div class="flex items-center justify-between">
                    <div class="flex items-center gap-2">
                        <i class="pi pi-chart-pie text-surface-500"></i>
                        <span class="font-medium text-surface-700 dark:text-surface-300">
                            Total de peso asignado
                        </span>
                    </div>
                    <div class="flex items-center gap-2">
                        <span class="text-2xl font-bold" :class="totalWeightClass">
                            {{ totalWeight }}%
                        </span>
                        <i 
                            v-if="totalWeight !== 100"
                            class="pi pi-exclamation-triangle text-orange-500"
                            v-tooltip.left="'El peso total debe sumar 100%'"
                        ></i>
                    </div>
                </div>
            </template>
        </Card>
    </div>
</template>

<script setup>
import { computed } from 'vue'
import { formatDate } from '@/lib/utils'
import Card from 'primevue/card'
import Avatar from 'primevue/avatar'
import Tag from 'primevue/tag'
import Dropdown from 'primevue/dropdown'
import Button from 'primevue/button'

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
        const nameA = a.usuarios?.nombre_completo || a.usuarios?.email || ''
        const nameB = b.usuarios?.nombre_completo || b.usuarios?.email || ''
        return nameA.localeCompare(nameB)
    })
})

const totalWeight = computed(() => {
    return props.members.reduce((sum, member) => sum + (member.porcentaje_peso || 0), 0)
})

const totalWeightClass = computed(() => {
    if (totalWeight.value === 100) return 'text-green-600 dark:text-green-400'
    if (totalWeight.value > 100) return 'text-red-600 dark:text-red-400'
    return 'text-orange-600 dark:text-orange-400'
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
</script>

<style scoped>
.member-card {
    transition: all 0.2s ease;
}

.member-card:hover {
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}

.space-y-4 > * + * {
    margin-top: 1rem;
}

.space-y-3 > * + * {
    margin-top: 0.75rem;
}
</style>
