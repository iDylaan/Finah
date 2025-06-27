import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'
import { LEVEL_COLORS } from '@/assets/constants/levels-colors.js';

export const useLevelStore = defineStore('levels', () => {
    // Estados
    const levels = ref([])
    const loading = ref(false)

    // Función para obtener niveles (públicos + del usuario)
    const fetchLevels = async ({ toast }) => {
        loading.value = true

        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id

            let query = supabase
                .from('levels')
                .select('*')

            if (userId) {
                // Mostrar públicos O del usuario actual
                query = query.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                // Solo públicos si no hay usuario
                query = query.eq('is_public', true)
            }

            const { data, error } = await query

            if (error) {
                handleError(error, toast)
            } else {
                // Ordenar: primero privados, luego por nombre
                levels.value = (data || []).sort((a, b) => {
                    // Primero: Privados (false) antes que públicos (true)
                    if (a.is_public !== b.is_public) {
                        return a.is_public - b.is_public // false (0) < true (1)
                    }
                    // Segundo: Orden alfabético por nombre
                    return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
                })
            }

        } catch (error) {
            handleError(error, toast)
        } finally {
            loading.value = false
        }
    }

    // Función para crear un nuevo nivel
    const createLevel = async (levelData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError) {
                throw new Error('Error obteniendo usuario: ' + userError.message)
            }

            if (!user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para insertar - aplicando trim
            const insertData = {
                name: levelData.name.trim(),
                color: levelData.colorKey.trim(), // Aplicar trim al color
                is_public: false, // Por defecto, los niveles creados por usuarios son privados
                user_id: user.id
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('levels')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando nivel:', error)
                throw error
            }

            // Actualizar el estado local agregando el nuevo nivel
            if (data && data[0]) {
                levels.value.unshift(data[0])
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Creado',
                detail: `El nivel "${levelData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar el nivel creado

        } catch (error) {
            console.error('💥 Error creando nivel:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando el nivel',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // Función para actualizar un nivel
    const updateLevel = async (levelId, levelData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar - aplicando trim
            const updateData = {
                name: levelData.name.trim(),
                color: levelData.colorKey.trim() // Aplicar trim al color
                // No incluimos is_public ni user_id ya que no deben cambiarse en una actualización
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('levels')
                .update(updateData)
                .eq('id', levelId)
                .eq('user_id', user.id) // Asegurar que solo el dueño pueda actualizarlo
                .select()

            if (error) {
                console.error('💥 Error actualizando nivel:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar el nivel. Verifica que sea tuyo y no sea público.')
            }

            // Actualizar el estado local
            const updatedLevel = data[0]
            const levelIndex = levels.value.findIndex(l => l.id === levelId)
            
            if (levelIndex !== -1) {
                levels.value[levelIndex] = {
                    ...levels.value[levelIndex],
                    ...updatedLevel
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Actualizado',
                detail: `El nivel "${levelData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return updatedLevel

        } catch (error) {
            console.error('💥 Error actualizando nivel:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando el nivel',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función para eliminar un nivel
    const deleteLevel = async (levelId, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Eliminar de la base de datos
            const { error } = await supabase
                .from('levels')
                .delete()
                .eq('id', levelId)
                .eq('user_id', user.id) // Solo el dueño puede eliminar

            if (error) {
                console.error('💥 Error eliminando nivel:', error)
                throw error
            }
            
            // Actualizar el estado local
            levels.value = levels.value.filter(l => l.id !== levelId)

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Nivel Eliminado',
                detail: `El nivel ha sido eliminado exitosamente`,
                life: 3000
            })

            return true

        } catch (error) {
            console.error('💥 Error eliminando nivel:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando el nivel',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // Función genérica para guardar nivel (crear o actualizar)
    const saveLevel = async (levelData, isEdit = false, { toast }) => {
        if (isEdit && levelData.id) {
            return await updateLevel(levelData.id, levelData, { toast })
        } else {
            return await createLevel(levelData, { toast })
        }
    }

    return {
        // Estados
        levels,
        loading,

        // Funciones
        fetchLevels,
        createLevel,
        updateLevel,
        deleteLevel,
        saveLevel
    }
})