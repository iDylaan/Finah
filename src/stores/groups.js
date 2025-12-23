import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useGroupsStore = defineStore('groups', () => {
    // ========================================
    // ESTADOS
    // ========================================
    const groups = ref([])
    const currentGroup = ref(null)
    const groupMembers = ref([])
    const invitations = ref([])
    const loading = ref(false)
    
    // ESTADOS PARA CACHÉ
    const groupsLoaded = ref(false)
    const membersLoaded = ref(false)
    const invitationsLoaded = ref(false)
    const lastGroupsFetchTime = ref(null)
    const lastMembersFetchTime = ref(null)
    const lastInvitationsFetchTime = ref(null)

    // ========================================
    // COMPUTED
    // ========================================
    const userGroups = computed(() => groups.value)
    const activeGroups = computed(() => groups.value.filter(g => g.activo))
    const hasGroups = computed(() => groups.value.length > 0)
    const isOwner = computed(() => {
        if (!currentGroup.value) return false
        const { data: { user } } = supabase.auth.getUser()
        return currentGroup.value.propietario_id === user?.id
    })
    const isAdmin = computed(() => {
        if (!currentGroup.value || !groupMembers.value.length) return false
        const { data: { user } } = supabase.auth.getUser()
        const member = groupMembers.value.find(m => m.usuario_id === user?.id)
        return member?.rol === 'owner' || member?.rol === 'administrador'
    })
    const pendingInvitations = computed(() => 
        invitations.value.filter(inv => inv.estado === 'pendiente')
    )

    // ========================================
    // FUNCIONES PRINCIPALES
    // ========================================

    /**
     * Obtener todos los grupos del usuario
     */
    const fetchGroups = async ({ toast, force = false } = {}) => {
        if (groupsLoaded.value && groups.value.length > 0 && !force) {
            return groups.value
        }

        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Obtener grupos donde el usuario es miembro
            const { data, error } = await supabase
                .from('miembros_grupo')
                .select(`
                    *,
                    grupo:grupos_usuario (
                        id,
                        nombre,
                        descripcion,
                        propietario_id,
                        color,
                        imagen_url,
                        limite_miembros,
                        activo,
                        fecha_creacion,
                        updated_at
                    )
                `)
                .eq('usuario_id', user.id)
                .order('fecha_creacion', { ascending: false })

            if (error) {
                console.error('💥 Error cargando grupos:', error)
                throw error
            }

            // Extraer los grupos y añadir el rol del usuario
            groups.value = (data || []).map(item => ({
                ...item.grupo,
                user_role: item.rol,
                user_weight: item.porcentaje_peso,
                member_id: item.id
            }))

            groupsLoaded.value = true
            lastGroupsFetchTime.value = Date.now()

            console.log('📦 Grupos cargados:', groups.value)
            return groups.value

        } catch (error) {
            console.error('💥 Error en fetchGroups:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Obtener detalles de un grupo específico
     */
    const fetchGroupById = async (groupId, { toast } = {}) => {
        loading.value = true

        try {
            const { data, error } = await supabase
                .from('grupos_usuario')
                .select('*')
                .eq('id', groupId)
                .single()

            if (error) {
                console.error('💥 Error cargando grupo:', error)
                throw error
            }

            currentGroup.value = data
            return data

        } catch (error) {
            console.error('💥 Error en fetchGroupById:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Crear un nuevo grupo
     */
    const createGroup = async (groupData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            const { data, error } = await supabase
                .rpc('crear_grupo_con_propietario', {
                    p_nombre: groupData.nombre,
                    p_descripcion: groupData.descripcion || null,
                    p_color: groupData.color || '#3B82F6',
                    p_imagen_url: groupData.imagen_url || null,
                    p_limite_miembros: groupData.limite_miembros || 10
                })

            if (error) {
                console.error('💥 Error creando grupo:', error)
                throw error
            }

            // Añadir el grupo a la lista local
            groups.value.unshift({
                ...data,
                user_role: 'owner',
                user_weight: 100
            })

            groupsLoaded.value = false // Forzar recarga para obtener relaciones

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Grupo creado',
                    detail: `El grupo "${data.nombre}" ha sido creado exitosamente`,
                    life: 3000
                })
            }

            return data

        } catch (error) {
            console.error('💥 Error en createGroup:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Actualizar un grupo existente
     */
    const updateGroup = async (groupId, groupData, { toast }) => {
        loading.value = true

        try {
            const { data, error } = await supabase
                .from('grupos_usuario')
                .update({
                    nombre: groupData.nombre,
                    descripcion: groupData.descripcion,
                    color: groupData.color,
                    imagen_url: groupData.imagen_url
                })
                .eq('id', groupId)
                .select()
                .single()

            if (error) {
                console.error('💥 Error actualizando grupo:', error)
                throw error
            }

            // Actualizar en la lista local
            const index = groups.value.findIndex(g => g.id === groupId)
            if (index !== -1) {
                groups.value[index] = {
                    ...groups.value[index],
                    ...data
                }
            }

            // Actualizar grupo actual si es el mismo
            if (currentGroup.value?.id === groupId) {
                currentGroup.value = { ...currentGroup.value, ...data }
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Grupo actualizado',
                    detail: `El grupo "${data.nombre}" ha sido actualizado`,
                    life: 3000
                })
            }

            return data

        } catch (error) {
            console.error('💥 Error en updateGroup:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Eliminar un grupo (solo owner)
     */
    const deleteGroup = async (groupId, { toast }) => {
        loading.value = true

        try {
            const { error } = await supabase
                .from('grupos_usuario')
                .delete()
                .eq('id', groupId)

            if (error) {
                console.error('💥 Error eliminando grupo:', error)
                throw error
            }

            // Remover de la lista local
            groups.value = groups.value.filter(g => g.id !== groupId)

            // Limpiar grupo actual si es el mismo
            if (currentGroup.value?.id === groupId) {
                currentGroup.value = null
                groupMembers.value = []
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Grupo eliminado',
                    detail: 'El grupo ha sido eliminado exitosamente',
                    life: 3000
                })
            }

        } catch (error) {
            console.error('💥 Error en deleteGroup:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // ========================================
    // GESTIÓN DE MIEMBROS
    // ========================================

    /**
     * Obtener miembros de un grupo
     */
    const fetchGroupMembers = async (groupId, { toast, force = false } = {}) => {
        if (membersLoaded.value && groupMembers.value.length > 0 && !force) {
            return groupMembers.value
        }

        loading.value = true

        try {
            const { data, error } = await supabase
                .from('miembros_grupo')
                .select(`
                    *,
                    usuario:auth.users!miembros_grupo_usuario_id_fkey (
                        id,
                        email
                    )
                `)
                .eq('grupo_id', groupId)
                .order('rol', { ascending: false })
                .order('fecha_creacion', { ascending: true })

            if (error) {
                console.error('💥 Error cargando miembros:', error)
                throw error
            }

            groupMembers.value = data || []
            membersLoaded.value = true
            lastMembersFetchTime.value = Date.now()

            console.log('👥 Miembros cargados:', groupMembers.value)
            return groupMembers.value

        } catch (error) {
            console.error('💥 Error en fetchGroupMembers:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Actualizar rol de un miembro
     */
    const updateMemberRole = async (memberId, newRole, { toast }) => {
        loading.value = true

        try {
            const { data, error } = await supabase
                .from('miembros_grupo')
                .update({
                    rol: newRole,
                    updated_at: new Date().toISOString()
                })
                .eq('id', memberId)
                .select()
                .single()

            if (error) {
                console.error('💥 Error actualizando rol:', error)
                throw error
            }

            // Actualizar en lista local
            const index = groupMembers.value.findIndex(m => m.id === memberId)
            if (index !== -1) {
                groupMembers.value[index] = { ...groupMembers.value[index], ...data }
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Rol actualizado',
                    detail: `El rol del miembro ha sido actualizado a ${newRole}`,
                    life: 3000
                })
            }

            return data

        } catch (error) {
            console.error('💥 Error en updateMemberRole:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Remover un miembro del grupo
     */
    const removeMember = async (memberId, { toast }) => {
        loading.value = true

        try {
            const { error } = await supabase
                .from('miembros_grupo')
                .delete()
                .eq('id', memberId)

            if (error) {
                console.error('💥 Error removiendo miembro:', error)
                throw error
            }

            // Remover de lista local
            groupMembers.value = groupMembers.value.filter(m => m.id !== memberId)

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Miembro removido',
                    detail: 'El miembro ha sido removido del grupo',
                    life: 3000
                })
            }

        } catch (error) {
            console.error('💥 Error en removeMember:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Salir de un grupo (el usuario actual)
     */
    const leaveGroup = async (groupId, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            const { error } = await supabase
                .from('miembros_grupo')
                .delete()
                .eq('grupo_id', groupId)
                .eq('usuario_id', user.id)

            if (error) {
                console.error('💥 Error saliendo del grupo:', error)
                throw error
            }

            // Remover grupo de lista local
            groups.value = groups.value.filter(g => g.id !== groupId)

            // Limpiar grupo actual si es el mismo
            if (currentGroup.value?.id === groupId) {
                currentGroup.value = null
                groupMembers.value = []
            }

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Has salido del grupo',
                    detail: 'Ya no eres miembro de este grupo',
                    life: 3000
                })
            }

        } catch (error) {
            console.error('💥 Error en leaveGroup:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // ========================================
    // GESTIÓN DE INVITACIONES
    // ========================================

    /**
     * Obtener invitaciones del grupo
     */
    const fetchInvitations = async (groupId, { toast, force = false } = {}) => {
        if (invitationsLoaded.value && invitations.value.length > 0 && !force) {
            return invitations.value
        }

        loading.value = true

        try {
            const { data, error } = await supabase
                .from('invitaciones_grupo')
                .select('*')
                .eq('grupo_id', groupId)
                .order('fecha_invitacion', { ascending: false })

            if (error) {
                console.error('💥 Error cargando invitaciones:', error)
                throw error
            }

            invitations.value = data || []
            invitationsLoaded.value = true
            lastInvitationsFetchTime.value = Date.now()

            return invitations.value

        } catch (error) {
            console.error('💥 Error en fetchInvitations:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Obtener invitaciones recibidas por el usuario autenticado
     */
    const fetchMyInvitations = async ({ toast, force = false } = {}) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Obtener email del usuario autenticado
            const userEmail = user.email

            // Obtener invitaciones donde el email del usuario coincida
            const { data, error } = await supabase
                .from('invitaciones_grupo')
                .select(`
                    *,
                    grupos_usuario:grupo_id (
                        id,
                        nombre,
                        descripcion,
                        color,
                        imagen_url
                    )
                `)
                .eq('email_invitado', userEmail)
                .order('fecha_invitacion', { ascending: false })

            if (error) {
                console.error('💥 Error cargando invitaciones del usuario:', error)
                throw error
            }

            invitations.value = data || []
            invitationsLoaded.value = true
            lastInvitationsFetchTime.value = Date.now()

            return invitations.value

        } catch (error) {
            console.error('💥 Error en fetchMyInvitations:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Crear invitación al grupo
     */
    const createInvitation = async (groupId, invitationData, { toast }) => {
        loading.value = true

        try {
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            const { data, error } = await supabase
                .from('invitaciones_grupo')
                .insert({
                    grupo_id: groupId,
                    email_invitado: invitationData.email,
                    invitado_por: user.id,
                    rol_asignado: invitationData.rol || 'miembro',
                    mensaje: invitationData.mensaje || null,
                    estado: 'pendiente'
                })
                .select()
                .single()

            if (error) {
                console.error('💥 Error creando invitación:', error)
                throw error
            }

            invitations.value.unshift(data)

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Invitación enviada',
                    detail: `Se ha enviado una invitación a ${invitationData.email}`,
                    life: 3000
                })
            }

            return data

        } catch (error) {
            console.error('💥 Error en createInvitation:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    /**
     * Cancelar invitación
     */
    const cancelInvitation = async (invitationId, { toast }) => {
        loading.value = true

        try {
            const { error } = await supabase
                .from('invitaciones_grupo')
                .delete()
                .eq('id', invitationId)

            if (error) {
                console.error('💥 Error cancelando invitación:', error)
                throw error
            }

            invitations.value = invitations.value.filter(inv => inv.id !== invitationId)

            if (toast) {
                toast.add({
                    severity: 'success',
                    summary: 'Invitación cancelada',
                    detail: 'La invitación ha sido cancelada',
                    life: 3000
                })
            }

        } catch (error) {
            console.error('💥 Error en cancelInvitation:', error)

            if (toast) {
                handleError(error, toast)
            }

            throw error

        } finally {
            loading.value = false
        }
    }

    // ========================================
    // FUNCIONES DE UTILIDAD
    // ========================================

    /**
     * Refrescar todos los datos del grupo
     */
    const refreshGroup = async (groupId, { toast }) => {
        try {
            await Promise.all([
                fetchGroupById(groupId, { toast }),
                fetchGroupMembers(groupId, { toast, force: true }),
                fetchInvitations(groupId, { toast, force: true })
            ])
        } catch (error) {
            console.error('💥 Error refrescando grupo:', error)
            throw error
        }
    }

    /**
     * Refrescar lista de grupos
     */
    const refreshGroups = async ({ toast }) => {
        return await fetchGroups({ toast, force: true })
    }

    /**
     * Limpiar todos los estados
     */
    const clearAll = () => {
        groups.value = []
        currentGroup.value = null
        groupMembers.value = []
        invitations.value = []
        groupsLoaded.value = false
        membersLoaded.value = false
        invitationsLoaded.value = false
        lastGroupsFetchTime.value = null
        lastMembersFetchTime.value = null
        lastInvitationsFetchTime.value = null
    }

    /**
     * Establecer grupo actual
     */
    const setCurrentGroup = (group) => {
        currentGroup.value = group
    }

    // ========================================
    // RETORNO
    // ========================================
    return {
        // Estados
        groups,
        currentGroup,
        groupMembers,
        invitations,
        loading,
        
        // Computed
        userGroups,
        activeGroups,
        hasGroups,
        isOwner,
        isAdmin,
        pendingInvitations,
        
        // Grupos
        fetchGroups,
        fetchGroupById,
        createGroup,
        updateGroup,
        deleteGroup,
        refreshGroups,
        setCurrentGroup,
        
        // Miembros
        fetchGroupMembers,
        updateMemberRole,
        removeMember,
        leaveGroup,
        
        // Invitaciones
        fetchInvitations,
        fetchMyInvitations,
        createInvitation,
        cancelInvitation,
        
        // Utilidades
        refreshGroup,
        clearAll
    }
})
