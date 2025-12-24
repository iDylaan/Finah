<template>
    <div class="space-y-4">
        <!-- Empty State -->
        <div v-if="!invitations.length" class="text-center py-8">
            <i class="pi pi-envelope text-5xl text-surface-400 mb-3"></i>
            <p class="text-surface-600 dark:text-surface-400 mb-4">
                No hay invitaciones pendientes
            </p>
            <Button
                v-if="hasSpace && canCancel"
                icon="pi pi-user-plus"
                label="Invitar miembro"
                @click="emit('invite')"
            />
        </div>

        <!-- Lista de invitaciones -->
        <div v-else class="space-y-3">
            <Card 
                v-for="invitation in sortedInvitations" 
                :key="invitation.id"
                class="invitation-card"
            >
                <template #content>
                    <div class="flex items-start justify-between gap-4">
                        <!-- Info de la invitación -->
                        <div class="flex items-start gap-3 flex-1 min-w-0">
                            <!-- Icono -->
                            <div class="w-12 h-12 rounded-full bg-primary-100 dark:bg-primary-900/20 flex items-center justify-center flex-shrink-0">
                                <i class="pi pi-envelope text-primary-600 dark:text-primary-400 text-xl"></i>
                            </div>

                            <!-- Datos -->
                            <div class="flex-1 min-w-0">
                                <div class="flex items-center gap-2 mb-1 flex-wrap">
                                    <h4 class="font-semibold text-surface-900 dark:text-surface-0 truncate">
                                        {{ invitation.email_invitado }}
                                    </h4>
                                    <Tag 
                                        :value="getStatusLabel(invitation.estado)" 
                                        :severity="getStatusSeverity(invitation.estado)"
                                        rounded
                                        class="text-xs"
                                    />
                                    <Tag 
                                        :value="getRoleLabel(invitation.rol_asignado)" 
                                        :severity="getRoleSeverity(invitation.rol_asignado)"
                                        rounded
                                        class="text-xs"
                                    />
                                </div>

                                <div class="space-y-1 text-sm text-surface-600 dark:text-surface-400">
                                    <p>
                                        <i class="pi pi-user text-xs mr-1"></i>
                                        Invitado por: {{ invitation.invitador?.nombre_completo || invitation.invitador?.email }}
                                    </p>
                                    <p>
                                        <i class="pi pi-calendar text-xs mr-1"></i>
                                        Enviado: {{ formatDate(invitation.created_at) }}
                                    </p>
                                    <p v-if="invitation.expires_at" :class="isExpired(invitation) ? 'text-red-600 dark:text-red-400' : ''">
                                        <i class="pi pi-clock text-xs mr-1"></i>
                                        {{ isExpired(invitation) ? 'Expiró' : 'Expira' }}: {{ formatDate(invitation.expires_at) }}
                                    </p>
                                </div>

                                <!-- Mensaje -->
                                <div 
                                    v-if="invitation.mensaje" 
                                    class="mt-3 p-3 bg-surface-50 dark:bg-surface-900 rounded-lg border border-surface-200 dark:border-surface-700"
                                >
                                    <p class="text-sm text-surface-700 dark:text-surface-300 italic">
                                        "{{ invitation.mensaje }}"
                                    </p>
                                </div>
                            </div>
                        </div>

                        <!-- Acciones -->
                        <div class="flex flex-col gap-2 flex-shrink-0">
                            <Button
                                v-if="canCancel && invitation.estado === 'pendiente'"
                                icon="pi pi-times"
                                severity="danger"
                                text
                                rounded
                                @click="handleCancel(invitation)"
                                v-tooltip.left="'Cancelar invitación'"
                            />
                            <Button
                                v-if="invitation.estado === 'pendiente' && !isExpired(invitation)"
                                icon="pi pi-send"
                                severity="secondary"
                                text
                                rounded
                                @click="handleResend(invitation)"
                                v-tooltip.left="'Reenviar correo'"
                            />
                        </div>
                    </div>
                </template>
            </Card>
        </div>

        <!-- Estadísticas -->
        <Card v-if="invitations.length > 0" class="bg-surface-50 dark:bg-surface-900">
            <template #content>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div class="text-center">
                        <p class="text-2xl font-bold text-primary-600 dark:text-primary-400">
                            {{ stats.pending }}
                        </p>
                        <p class="text-sm text-surface-600 dark:text-surface-400">Pendientes</p>
                    </div>
                    <div class="text-center">
                        <p class="text-2xl font-bold text-green-600 dark:text-green-400">
                            {{ stats.accepted }}
                        </p>
                        <p class="text-sm text-surface-600 dark:text-surface-400">Aceptadas</p>
                    </div>
                    <div class="text-center">
                        <p class="text-2xl font-bold text-red-600 dark:text-red-400">
                            {{ stats.rejected }}
                        </p>
                        <p class="text-sm text-surface-600 dark:text-surface-400">Rechazadas</p>
                    </div>
                    <div class="text-center">
                        <p class="text-2xl font-bold text-orange-600 dark:text-orange-400">
                            {{ stats.expired }}
                        </p>
                        <p class="text-sm text-surface-600 dark:text-surface-400">Expiradas</p>
                    </div>
                </div>
            </template>
        </Card>
    </div>
</template>

<script setup>
import { computed } from 'vue'
import { useConfirm } from 'primevue/useconfirm'
import { useToast } from 'primevue/usetoast'
import { formatDate } from '@/lib/utils'

// Props
const props = defineProps({
    invitations: {
        type: Array,
        required: true
    },
    canCancel: {
        type: Boolean,
        default: false
    },
    hasSpace: {
        type: Boolean,
        default: true
    }
})

// Emits
const emit = defineEmits(['cancel', 'refresh', 'invite'])

// Composables
const confirm = useConfirm()
const toast = useToast()

// Computed
const sortedInvitations = computed(() => {
    return [...props.invitations].sort((a, b) => {
        // Pendientes primero
        if (a.estado === 'pendiente' && b.estado !== 'pendiente') return -1
        if (a.estado !== 'pendiente' && b.estado === 'pendiente') return 1
        
        // Luego por fecha (más recientes primero)
        return new Date(b.created_at) - new Date(a.created_at)
    })
})

const stats = computed(() => {
    const result = {
        pending: 0,
        accepted: 0,
        rejected: 0,
        expired: 0
    }

    props.invitations.forEach(inv => {
        if (isExpired(inv) && inv.estado === 'pendiente') {
            result.expired++
        } else if (inv.estado === 'pendiente') {
            result.pending++
        } else if (inv.estado === 'aceptada') {
            result.accepted++
        } else if (inv.estado === 'rechazada') {
            result.rejected++
        }
    })

    return result
})

// Métodos
const isExpired = (invitation) => {
    if (!invitation.expires_at) return false
    return new Date(invitation.expires_at) < new Date()
}

const handleCancel = (invitation) => {
    confirm.require({
        message: `¿Estás seguro de cancelar la invitación a ${invitation.email_invitado}?`,
        header: 'Confirmar cancelación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Cancelar invitación',
        rejectLabel: 'Volver',
        acceptClass: 'p-button-danger',
        accept: () => {
            emit('cancel', invitation.id)
        }
    })
}

const handleResend = (invitation) => {
    toast.add({
        severity: 'info',
        summary: 'Funcionalidad pendiente',
        detail: 'El reenvío de invitaciones estará disponible próximamente',
        life: 3000
    })
    // TODO: Implementar reenvío de correo
}

const getStatusLabel = (status) => {
    const labels = {
        'pendiente': 'Pendiente',
        'aceptada': 'Aceptada',
        'rechazada': 'Rechazada',
        'cancelada': 'Cancelada'
    }
    return labels[status] || status
}

const getStatusSeverity = (status) => {
    const severities = {
        'pendiente': 'warning',
        'aceptada': 'success',
        'rechazada': 'danger',
        'cancelada': 'secondary'
    }
    return severities[status] || 'secondary'
}

const getRoleLabel = (role) => {
    const labels = {
        'administrador': 'Admin',
        'miembro': 'Miembro'
    }
    return labels[role] || role
}

const getRoleSeverity = (role) => {
    const severities = {
        'administrador': 'warning',
        'miembro': 'info'
    }
    return severities[role] || 'secondary'
}
</script>

<style scoped>
.invitation-card {
    transition: all 0.2s ease;
}

.invitation-card:hover {
    box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1);
}

.space-y-4 > * + * {
    margin-top: 1rem;
}

.space-y-3 > * + * {
    margin-top: 0.75rem;
}

.space-y-1 > * + * {
    margin-top: 0.25rem;
}
</style>
