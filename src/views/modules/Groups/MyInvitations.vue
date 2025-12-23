<template>
    <PageLayout 
        title="Mis Invitaciones" 
        description="Invitaciones a grupos que has recibido"
        :back-button="true"
    >
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
        </template>

        <!-- Loading State -->
        <div v-if="loading && !invitations.length" class="flex justify-center items-center py-12">
            <ProgressSpinner />
        </div>

        <!-- Empty State -->
        <div v-else-if="!invitations.length" class="text-center py-12">
            <i class="pi pi-envelope text-6xl text-surface-400 mb-4"></i>
            <h3 class="text-xl font-semibold text-surface-700 dark:text-surface-300 mb-2">
                No tienes invitaciones pendientes
            </h3>
            <p class="text-surface-500 dark:text-surface-400 mb-6">
                Cuando alguien te invite a un grupo, las invitaciones aparecerán aquí
            </p>
        </div>

        <!-- Lista de Invitaciones -->
        <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <Card 
                v-for="(invitation, index) in invitations" 
                :key="invitation.id"
                class="invitation-card animate__animated animate__fadeInUp animate__faster"
                :style="{ animationDelay: `${index * 0.05}s` }"
            >
                <template #header>
                    <div 
                        class="h-32 relative flex items-center justify-center"
                        :style="{ backgroundColor: invitation.grupos_usuario?.color || '#3B82F6' }"
                    >
                        <i 
                            :class="[invitation.grupos_usuario?.imagen_url || 'pi-users', 'text-6xl text-white']"
                        ></i>
                        
                        <!-- Badge de estado -->
                        <div class="absolute top-3 right-3">
                            <Tag 
                                :value="getStatusLabel(invitation.estado)" 
                                :severity="getStatusSeverity(invitation.estado)"
                                rounded
                            />
                        </div>
                    </div>
                </template>

                <template #content>
                    <h3 class="text-xl font-semibold text-surface-900 dark:text-surface-0 mb-3">
                        {{ invitation.grupos_usuario?.nombre }}
                    </h3>

                    <div class="space-y-3">
                        <!-- Descripción del grupo -->
                        <p 
                            v-if="invitation.grupos_usuario?.descripcion" 
                            class="text-sm text-surface-600 dark:text-surface-400 line-clamp-2"
                        >
                            {{ invitation.grupos_usuario?.descripcion }}
                        </p>

                        <!-- Información de la invitación -->
                        <div class="space-y-2 text-sm">
                            <div v-if="invitation.invitado_por" class="flex items-center gap-2 text-surface-600 dark:text-surface-400">
                                <i class="pi pi-user text-xs"></i>
                                <span>Has sido invitado a este grupo</span>
                            </div>
                            
                            <div class="flex items-center gap-2 text-surface-600 dark:text-surface-400">
                                <i class="pi pi-shield text-xs"></i>
                                <span>Rol asignado: {{ getRoleLabel(invitation.rol_asignado) }}</span>
                            </div>

                            <div class="flex items-center gap-2 text-surface-600 dark:text-surface-400">
                                <i class="pi pi-calendar text-xs"></i>
                                <span>Recibida: {{ formatDate(invitation.created_at) }}</span>
                            </div>

                            <div 
                                class="flex items-center gap-2"
                                :class="isExpired(invitation) ? 'text-red-600 dark:text-red-400' : 'text-surface-600 dark:text-surface-400'"
                            >
                                <i class="pi pi-clock text-xs"></i>
                                <span>{{ isExpired(invitation) ? 'Expiró' : 'Expira' }}: {{ formatDate(invitation.expires_at) }}</span>
                            </div>
                        </div>

                        <!-- Mensaje personalizado -->
                        <div 
                            v-if="invitation.mensaje" 
                            class="mt-3 p-3 bg-surface-50 dark:bg-surface-900 rounded-lg border border-surface-200 dark:border-surface-700"
                        >
                            <p class="text-sm text-surface-700 dark:text-surface-300 italic">
                                "{{ invitation.mensaje }}"
                            </p>
                        </div>
                    </div>
                </template>

                <template #footer>
                    <!-- Acciones según estado -->
                    <div v-if="invitation.estado === 'pendiente' && !isExpired(invitation)" class="flex gap-2">
                        <Button 
                            label="Rechazar"
                            icon="pi pi-times"
                            severity="secondary"
                            outlined
                            class="flex-1"
                            @click="handleReject(invitation)"
                            :loading="processingId === invitation.id"
                        />
                        <Button 
                            label="Aceptar"
                            icon="pi pi-check"
                            class="flex-1"
                            @click="handleAccept(invitation)"
                            :loading="processingId === invitation.id"
                        />
                    </div>

                    <!-- Estado procesado -->
                    <div v-else class="text-center text-sm text-surface-500 dark:text-surface-400">
                        <i 
                            :class="[
                                invitation.estado === 'aceptada' ? 'pi-check-circle text-green-600' :
                                invitation.estado === 'rechazada' ? 'pi-times-circle text-red-600' :
                                invitation.estado === 'cancelada' ? 'pi-ban text-orange-600' :
                                'pi-exclamation-triangle text-orange-600'
                            ]"
                            class="mr-2"
                        ></i>
                        {{ 
                            invitation.estado === 'aceptada' ? 'Ya aceptaste esta invitación' :
                            invitation.estado === 'rechazada' ? 'Rechazaste esta invitación' :
                            invitation.estado === 'cancelada' ? 'Invitación cancelada' :
                            'Invitación expirada'
                        }}
                    </div>
                </template>
            </Card>
        </div>

        <!-- Confirmación -->
        <ConfirmDialog></ConfirmDialog>
    </PageLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useConfirm } from 'primevue/useconfirm'
import { useSessionStore } from '@/stores/session'
import { supabase } from '@/lib/supabase'
import { formatDate } from '@/lib/utils'
import PageLayout from '@/components/PageLayout.vue'
import Card from 'primevue/card'
import Button from 'primevue/button'
import Tag from 'primevue/tag'
import ProgressSpinner from 'primevue/progressspinner'
import ConfirmDialog from 'primevue/confirmdialog'

// Composables
const router = useRouter()
const toast = useToast()
const confirm = useConfirm()
const sessionStore = useSessionStore()

// Estados
const loading = ref(false)
const processingId = ref(null)
const invitations = ref([])

// Computed
const userEmail = computed(() => sessionStore.user?.email)

// Métodos
const refreshData = async () => {
    loading.value = true
    try {
        const { data, error } = await supabase
            .from('invitaciones_grupo')
            .select(`
                *,
                grupos_usuario:grupo_id (
                    id,
                    nombre,
                    descripcion,
                    color,
                    imagen_url,
                    limite_miembros
                )
            `)
            .eq('email_invitado', userEmail.value)
            .order('created_at', { ascending: false })

        if (error) throw error

        invitations.value = data || []

        console.log('Invitaciones cargadas:', invitations.value)
    } catch (error) {
        console.error('Error al cargar invitaciones:', error)
        toast.add({
            severity: 'error',
            summary: 'Error',
            detail: 'No se pudieron cargar las invitaciones',
            life: 5000
        })
    } finally {
        loading.value = false
    }
}

const isExpired = (invitation) => {
    if (!invitation.expires_at) return false
    return new Date(invitation.expires_at) < new Date()
}

const handleAccept = (invitation) => {
    confirm.require({
        message: `¿Deseas unirte al grupo "${invitation.grupos_usuario?.nombre}"?`,
        header: 'Aceptar invitación',
        icon: 'pi pi-question-circle',
        acceptLabel: 'Aceptar',
        rejectLabel: 'Cancelar',
        accept: async () => {
            processingId.value = invitation.id
            try {
                // Llamar a la función de Supabase para aceptar invitación
                const { data, error } = await supabase.rpc('aceptar_invitacion_grupo', {
                    p_invitacion_id: invitation.id
                })

                if (error) throw error

                toast.add({
                    severity: 'success',
                    summary: '¡Bienvenido!',
                    detail: `Te has unido al grupo "${invitation.grupos_usuario?.nombre}"`,
                    life: 3000
                })

                // Redirigir al grupo
                setTimeout(() => {
                    router.push({ name: 'group-details', params: { id: invitation.grupo_id } })
                }, 1000)

            } catch (error) {
                console.error('Error al aceptar invitación:', error)
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: error.message || 'No se pudo aceptar la invitación',
                    life: 5000
                })
            } finally {
                processingId.value = null
            }
        }
    })
}

const handleReject = (invitation) => {
    confirm.require({
        message: `¿Estás seguro de rechazar la invitación al grupo "${invitation.grupos_usuario?.nombre}"?`,
        header: 'Rechazar invitación',
        icon: 'pi pi-exclamation-triangle',
        acceptLabel: 'Rechazar',
        rejectLabel: 'Cancelar',
        acceptClass: 'p-button-danger',
        accept: async () => {
            processingId.value = invitation.id
            try {
                const { error } = await supabase
                    .from('invitaciones_grupo')
                    .update({ estado: 'rechazada' })
                    .eq('id', invitation.id)

                if (error) throw error

                toast.add({
                    severity: 'info',
                    summary: 'Invitación rechazada',
                    detail: 'Has rechazado la invitación',
                    life: 3000
                })

                await refreshData()
            } catch (error) {
                console.error('Error al rechazar invitación:', error)
                toast.add({
                    severity: 'error',
                    summary: 'Error',
                    detail: 'No se pudo rechazar la invitación',
                    life: 5000
                })
            } finally {
                processingId.value = null
            }
        }
    })
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
        'administrador': 'Administrador',
        'miembro': 'Miembro'
    }
    return labels[role] || role
}

// Lifecycle
onMounted(async () => {
    await refreshData()
})
</script>

<style scoped>
.invitation-card {
    transition: all 0.3s ease;
}

.invitation-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 10px 20px rgba(0, 0, 0, 0.1);
}

.line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    line-clamp: 2;
    overflow: hidden;
}

.space-y-2 > * + * {
    margin-top: 0.5rem;
}

.space-y-3 > * + * {
    margin-top: 0.75rem;
}
</style>
