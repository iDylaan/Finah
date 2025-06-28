import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'
import { useBankStore } from '@/stores/banks'
import { useLevelStore } from '@/stores/levels'
import { useCategoriesStore } from '@/stores/categories'

export const useSessionStore = defineStore('session', () => {
    // Estados
    const user = ref(null)
    const profile = ref(null)
    const loading = ref(false)
    const initialized = ref(false)

    // Computed
    const isAuthenticated = computed(() => !!user.value)
    const userEmail = computed(() => user.value?.email || '')
    const userId = computed(() => user.value?.id || '')
    const username = computed(() => profile.value?.username || '')
    const fullName = computed(() => profile.value?.full_name || '')

    // Función para obtener el perfil del usuario (sin dependencia de toast)
    const fetchProfile = async (userId) => {
        try {
            const { data, error } = await supabase
                .from('profiles')
                .select('*')
                .eq('id', userId)
                .single()

            if (error && error.code !== 'PGRST116') { // No existe el perfil
                console.error('Error al obtener perfil:', error)
                return { data: null, error, success: false }
            }

            profile.value = data
            console.log('Perfil obtenido exitosamente:', data?.username || 'Sin username')
            return { data, error: null, success: true }
        } catch (error) {
            console.error('Error inesperado al obtener perfil:', error)
            return { data: null, error, success: false }
        }
    }

    // Función para crear o actualizar perfil
    const upsertProfile = async (userId, profileData, { toast }) => {
        try {
            const { data, error } = await supabase
                .from('profiles')
                .upsert({
                    id: userId,
                    ...profileData,
                    updated_at: new Date().toISOString()
                })
                .select()
                .single()

            if (error) throw error

            profile.value = data
            return { data, error: null }
        } catch (error) {
            console.error('Error al actualizar perfil:', error)
            handleError(error, toast)
            return { data: null, error }
        }
    }

    const resetPassword = async (email) => {
        loading.value = true
        try {
            const { error } = await supabase.auth.resetPasswordForEmail(email, {
                redirectTo: `${window.location.origin}/reset-password`
            })
            
            if (error) throw error
            return { error: null }
        } catch (error) {
            console.error('Error al enviar email de recuperación:', error)
            return { error }
        } finally {
            loading.value = false
        }
    }

    const updatePassword = async (newPassword) => {
        loading.value = true
        try {
            const { data, error } = await supabase.auth.updateUser({
                password: newPassword
            })
            
            if (error) throw error
            return { user: data.user, error: null }
        } catch (error) {
            console.error('Error al actualizar contraseña:', error)
            return { user: null, error }
        } finally {
            loading.value = false
        }
    }

    const updateProfile = async (updates) => {
        loading.value = true
        try {
            const { data, error } = await supabase.auth.updateUser({
                data: updates
            })
            
            if (error) throw error
            
            user.value = data.user
            return { user: data.user, error: null }
        } catch (error) {
            console.error('Error al actualizar perfil:', error)
            return { user: null, error }
        } finally {
            loading.value = false
        }
    }

    // Funciones de autenticación actualizadas
    const signIn = async (email, password, { toast }) => {
        loading.value = true
        try {
            const { data, error } = await supabase.auth.signInWithPassword({
                email,
                password
            })
            
            if (error) throw error
            
            user.value = data.user
            
            // Obtener perfil después del login y manejar errores
            const profileResult = await fetchProfile(data.user.id)
            if (!profileResult.success) {
                console.warn('No se pudo obtener el perfil del usuario, pero el login fue exitoso')
                
                // Mostrar advertencia pero no fallar el login
                if (toast) {
                    toast.add({
                        severity: 'warn',
                        summary: 'Perfil no disponible',
                        detail: 'Se inició sesión correctamente, pero no se pudo cargar tu perfil',
                        life: 4000
                    })
                }
            }
            
            return { user: data.user, error: null }
        } catch (error) {
            console.error('Error al iniciar sesión:', error)
            handleError(error, toast)
            return { user: null, error }
        } finally {
            loading.value = false
        }
    }

    const signUp = async (email, password, metadata = {}, { toast }) => {
        loading.value = true
        try {
            const { data, error } = await supabase.auth.signUp({
                email,
                password
            })
            
            if (error) throw error
            
            if (data.user) {
                user.value = data.user
                
                // Crear perfil inicial
                const profileData = {
                    username: metadata.username,
                    full_name: `${metadata.first_name} ${metadata.last_name}`.trim(),
                    avatar_url: null
                }
                
                // Intentar crear el perfil y manejar errores
                const upsertResult = await upsertProfile(data.user.id, profileData, { toast })
                if (!upsertResult.data) {
                    console.warn('El usuario fue creado pero no se pudo crear el perfil inicial')
                    
                    // Mostrar advertencia específica
                    if (toast) {
                        toast.add({
                            severity: 'warn',
                            summary: 'Perfil pendiente',
                            detail: 'Tu cuenta fue creada exitosamente, pero deberás completar tu perfil más tarde',
                            life: 5000
                        })
                    }
                }
            }
            
            return { user: data.user, error: null }
        } catch (error) {
            console.error('Error al registrarse:', error)
            handleError(error, toast)
            return { user: null, error }
        } finally {
            loading.value = false
        }
    }

    const signOut = async () => {
        loading.value = true
        try {
            // Limpiar la caché de los stores antes de cerrar sesión
            const bankStore = useBankStore();
            const levelStore = useLevelStore();
            const categoriesStore = useCategoriesStore();
            
            bankStore.clearCache();
            levelStore.clearCache();
            categoriesStore.clearCache();
            
            const { error } = await supabase.auth.signOut()
            if (error) throw error
            
            user.value = null
            profile.value = null
            return { error: null }
        } catch (error) {
            console.error('Error al cerrar sesión:', error)
            return { error }
        } finally {
            loading.value = false
        }
    }

    // Variable para evitar inicialización múltiple
    let isInitializing = false

    // Función simplificada para inicializar la sesión
    const initializeAuth = async () => {
        // Evitar inicialización múltiple
        if (initialized.value || isInitializing) {
            console.log('⚠️ Auth ya inicializado o en proceso:', { 
                initialized: initialized.value, 
                isInitializing,
                hasUser: !!user.value
            })
            return
        }
        
        isInitializing = true
        console.log('🔐 Iniciando inicialización de auth...')
        
        try {
            // Obtener sesión actual de forma síncrona
            const { data: { session }, error } = await supabase.auth.getSession()
            
            if (error) {
                console.error('❌ Error al obtener sesión:', error)
            } else if (session) {
                console.log('✅ Sesión encontrada:', session.user.email)
                user.value = session.user
                
                // Obtener perfil de forma no bloqueante
                fetchProfile(session.user.id).then(profileResult => {
                    if (!profileResult.success) {
                        console.warn('⚠️ No se pudo obtener perfil:', profileResult.error)
                    }
                }).catch(err => {
                    console.error('❌ Error obteniendo perfil:', err)
                })
                
            } else {
                console.log('ℹ️ No hay sesión activa')
            }
        } catch (error) {
            console.error('💥 Error al inicializar autenticación:', error)
        } finally {
            initialized.value = true
            isInitializing = false
            console.log('✅ Inicialización de auth completada - Estado:', {
                isAuthenticated: isAuthenticated.value,
                userEmail: userEmail.value,
                hasUser: !!user.value
            })
        }
    }

    // Configurar listener para cambios de autenticación (simplificado)
    const setupAuthListener = () => {
        console.log('🎧 Configurando auth listener...')
        
        supabase.auth.onAuthStateChange((event, session) => {
            console.log('🔔 Auth event:', event, session?.user?.email || 'no-user')
            
            switch (event) {
                case 'INITIAL_SESSION':
                    if (session) {
                        console.log('📝 Configurando usuario desde INITIAL_SESSION:', session.user.email)
                        user.value = session.user
                        
                        // Obtener perfil de forma no bloqueante
                        fetchProfile(session.user.id).catch(err => {
                            console.error('Error obteniendo perfil en INITIAL_SESSION:', err)
                        })
                    }
                    
                    // **IMPORTANTE:** Solo marcar como inicializado si no lo está ya
                    if (!initialized.value) {
                        initialized.value = true
                        console.log('✅ Auth marcado como inicializado desde INITIAL_SESSION')
                    }
                    break
                    
                case 'SIGNED_IN':
                    console.log('📝 Usuario inició sesión:', session.user.email)
                    user.value = session.user
                    
                    // Obtener perfil de forma no bloqueante
                    if (session.user) {
                        fetchProfile(session.user.id).catch(err => {
                            console.error('Error obteniendo perfil en SIGNED_IN:', err)
                        })
                    }
                    break
                    
                case 'SIGNED_OUT':
                    console.log('📝 Usuario cerró sesión')
                    user.value = null
                    profile.value = null
                    break
                    
                case 'TOKEN_REFRESHED':
                    console.log('📝 Token actualizado para:', session.user.email)
                    user.value = session.user
                    break
                    
                case 'USER_UPDATED':
                    console.log('📝 Usuario actualizado:', session.user.email)
                    user.value = session.user
                    break
            }
        })
        
        console.log('✅ Auth listener configurado')
    }

    return {
        // Estados
        user,
        profile,
        loading,
        initialized,
        
        // Computed
        isAuthenticated,
        userEmail,
        userId,
        username,
        fullName,
        
        // Funciones
        signIn,
        signUp,
        signOut,
        updateProfile,
        fetchProfile,
        upsertProfile,
        initializeAuth,
        setupAuthListener
    }
})