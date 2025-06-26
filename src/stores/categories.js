import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useCategoriesStore = defineStore('categories', () => {
    // Estados
    const categoryGroups = ref([])
    const categories = ref([])
    const loading = ref(false)

    // Función para obtener grupos de categorías (públicos + del usuario)
    const fetchCategoryGroups = async ({ toast }) => {
        loading.value = true

        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id

            let query = supabase
                .from('category_groups')
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
                categoryGroups.value = data || []
            }

        } catch (error) {
            handleError(error, toast)
        } finally {
            loading.value = false
        }
    }

    // Función para obtener categorías (públicas + del usuario)
    const fetchCategories = async ({ toast }) => {
        loading.value = true

        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id

            let query = supabase
                .from('categories')
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
                categories.value = data || []
            }

        } catch (error) {
            handleError(error, toast)
        } finally {
            loading.value = false
        }
    }

    // Función para obtener category_groups con sus categorías anidadas
    const fetchCategoryGroupsWithCategories = async ({ toast }) => {
        loading.value = true

        try {
            const { data: { user } } = await supabase.auth.getUser()
            const userId = user?.id

            // **PASO 1:** Obtener todas las categorías primero
            let categoriesQuery = supabase
                .from('categories')
                .select('*')

            if (userId) {
                categoriesQuery = categoriesQuery.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                categoriesQuery = categoriesQuery.eq('is_public', true)
            }

            const { data: categoriesData, error: categoriesError } = await categoriesQuery

            if (categoriesError) {
                handleError(categoriesError, toast)
                return
            }

            // **PASO 2:** Obtener todos los grupos de categorías
            let groupsQuery = supabase
                .from('category_groups')
                .select('*')

            if (userId) {
                groupsQuery = groupsQuery.or(`is_public.eq.true,user_id.eq.${userId}`)
            } else {
                groupsQuery = groupsQuery.eq('is_public', true)
            }

            const { data: groupsData, error: groupsError } = await groupsQuery

            if (groupsError) {
                handleError(groupsError, toast)
                return
            }

            // **PASO 3:** Ordenar categorías (Privadas primero, luego alfabético)
            const sortedCategories = categoriesData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.is_public !== b.is_public) {
                    return a.is_public - b.is_public // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })

            // **PASO 4:** Agrupar categorías ordenadas por group_id
            const categoriesByGroup = {}
            sortedCategories.forEach(category => {
                const groupId = category.group_id
                if (!categoriesByGroup[groupId]) {
                    categoriesByGroup[groupId] = []
                }
                categoriesByGroup[groupId].push(category)
            })

            // **PASO 5:** Ordenar grupos (Privados primero, luego alfabético)
            const sortedGroups = groupsData.sort((a, b) => {
                // Primero: Privadas (false) antes que públicas (true)
                if (a.is_public !== b.is_public) {
                    return a.is_public - b.is_public // false (0) < true (1)
                }
                // Segundo: Orden alfabético por nombre (case insensitive)
                return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
            })

            // **PASO 6:** Agregar categorías ordenadas a cada grupo
            const groupsWithCategories = sortedGroups.map(group => ({
                ...group,
                categories: categoriesByGroup[group.id] || []
            }))

            // **PASO 7:** Actualizar estados del store
            categories.value = sortedCategories || []
            categoryGroups.value = groupsWithCategories || []

            return groupsWithCategories

        } catch (error) {
            handleError(error, toast)
            return []
        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función para crear un grupo de categorías
    const createCategoryGroup = async (groupData, { toast }) => {
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

            // Preparar datos para insertar
            const insertData = {
                name: groupData.name,
                description: groupData.description || null,
                icon_name: groupData.icon_name || 'pi pi-folder',
                icon_library: groupData.icon_type || 'primeicons', // NUEVO CAMPO
                color: groupData.color || '#6366f1',
                is_public: false,
                user_id: user.id  // ID del usuario actual
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('category_groups')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando grupo:', error)
                throw error
            }

            // Actualizar el estado local agregando el nuevo grupo
            if (data && data[0]) {
                const newGroup = {
                    ...data[0],
                    categories: [] // Inicializar sin categorías
                }
                categoryGroups.value.unshift(newGroup) // Agregar al inicio
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Grupo Creado',
                detail: `El grupo "${groupData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar el grupo creado

        } catch (error) {
            console.error('💥 Error creando grupo:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando el grupo de categorías',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función para actualizar un grupo de categorías
    const updateCategoryGroup = async (groupId, groupData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar (sin user_id porque no debe cambiar)
            const updateData = {
                name: groupData.name,
                description: groupData.description || null,
                icon_name: groupData.icon_name || 'pi pi-folder',
                icon_library: groupData.icon_type || 'primeicons', // NUEVO CAMPO
                color: groupData.color || '#6366f1',
                is_public: groupData.is_public || false
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('category_groups')
                .update(updateData)
                .eq('id', groupId)
                .eq('user_id', user.id)
                .select()

            if (error) {
                console.error('💥 Error actualizando grupo:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar el grupo. Verifica que sea tuyo.')
            }

            // Actualizar el estado local
            const groupIndex = categoryGroups.value.findIndex(g => g.id === groupId)
            if (groupIndex !== -1) {
                // Mantener las categorías existentes
                const existingCategories = categoryGroups.value[groupIndex].categories || []
                categoryGroups.value[groupIndex] = {
                    ...data[0],
                    categories: existingCategories
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Grupo Actualizado',
                detail: `El grupo "${groupData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return data[0]

        } catch (error) {
            console.error('💥 Error actualizando grupo:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando el grupo de categorías',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función genérica para guardar (crear o actualizar)
    const saveCategoryGroup = async (groupData, isEdit = false, { toast }) => {
        if (isEdit && groupData.id) {
            return await updateCategoryGroup(groupData.id, groupData, { toast })
        } else {
            return await createCategoryGroup(groupData, { toast })
        }
    }

    return {
        // Estados
        categoryGroups,
        categories,
        loading,

        // Funciones existentes
        fetchCategoryGroups,
        fetchCategories,
        fetchCategoryGroupsWithCategories,

        // NUEVAS funciones
        createCategoryGroup,
        updateCategoryGroup,
        saveCategoryGroup
    }
})