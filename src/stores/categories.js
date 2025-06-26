import { ref } from 'vue'
import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase.js'
import { handleError } from '@/lib/utils.js'

export const useCategoriesStore = defineStore('categories', () => {
    // Estados
    const categories = ref([])
    const categoryGroups = ref([])
    const loading = ref(false)

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

    // NUEVA: Función para crear una nueva categoría
    const createCategory = async (categoryData, { toast }) => {
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

            // Validar que la categoría tenga un grupo asignado
            if (!categoryData.group_id) {
                throw new Error('La categoría debe pertenecer a un grupo')
            }

            // Preparar datos para insertar
            const insertData = {
                name: categoryData.name,
                description: categoryData.description || null,
                icon_name: categoryData.icon_name || 'pi pi-tag',
                icon_library: categoryData.icon_type || 'primeicons',
                is_public: false, // Por defecto, las categorías creadas por usuarios son privadas
                user_id: user.id,
                group_id: categoryData.group_id
            }

            // Insertar en la base de datos
            const { data, error } = await supabase
                .from('categories')
                .insert([insertData])
                .select() // Retornar el registro insertado

            if (error) {
                console.error('💥 Error insertando categoría:', error)
                throw error
            }

            // Actualizar el estado local agregando la nueva categoría
            if (data && data[0]) {
                // Agregar a la lista plana de categorías
                categories.value.unshift(data[0])

                // Agregar la categoría al grupo correspondiente en el estado anidado
                const groupIndex = categoryGroups.value.findIndex(g => g.id === categoryData.group_id)
                if (groupIndex !== -1) {
                    categoryGroups.value[groupIndex].categories.unshift(data[0])
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Creada',
                detail: `La categoría "${categoryData.name}" se creó exitosamente`,
                life: 3000
            })

            return data[0] // Retornar la categoría creada

        } catch (error) {
            console.error('💥 Error creando categoría:', error)

            // Mostrar mensaje de error
            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error creando la categoría',
                life: 5000
            })

            throw error // Re-lanzar para manejo en el componente

        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función para actualizar una categoría
    const updateCategory = async (categoryId, categoryData, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Preparar datos para actualizar
            const updateData = {
                name: categoryData.name,
                description: categoryData.description || null,
                icon_name: categoryData.icon_name || 'pi pi-tag',
                icon_library: categoryData.icon_type || 'primeicons',
                group_id: categoryData.group_id
                // No incluimos is_public ni user_id ya que no deben cambiarse en una actualización
            }

            // Actualizar en la base de datos
            const { data, error } = await supabase
                .from('categories')
                .update(updateData)
                .eq('id', categoryId)
                .eq('user_id', user.id) // Asegurar que solo el dueño pueda actualizarla
                .select()

            if (error) {
                console.error('💥 Error actualizando categoría:', error)
                throw error
            }

            if (!data || data.length === 0) {
                throw new Error('No se pudo actualizar la categoría. Verifica que sea tuya y no sea pública.')
            }

            // Actualizar el estado local
            const updatedCategory = data[0]
            
            // Actualizar en la lista plana de categorías
            const categoryIndex = categories.value.findIndex(c => c.id === categoryId)
            if (categoryIndex !== -1) {
                categories.value[categoryIndex] = {
                    ...categories.value[categoryIndex],
                    ...updatedCategory
                }
            }

            // Actualizar en la estructura de grupos con categorías
            // Primero verificar si la categoría está cambiando de grupo
            const oldGroupId = categories.value[categoryIndex]?.group_id
            const newGroupId = updatedCategory.group_id
            
            if (oldGroupId !== newGroupId) {
                // Si está cambiando de grupo, quitar de uno y agregar al otro
                
                // Quitar del grupo antiguo
                const oldGroupIndex = categoryGroups.value.findIndex(g => g.id === oldGroupId)
                if (oldGroupIndex !== -1) {
                    categoryGroups.value[oldGroupIndex].categories = 
                        categoryGroups.value[oldGroupIndex].categories.filter(c => c.id !== categoryId)
                }
                
                // Agregar al nuevo grupo
                const newGroupIndex = categoryGroups.value.findIndex(g => g.id === newGroupId)
                if (newGroupIndex !== -1) {
                    categoryGroups.value[newGroupIndex].categories.unshift(updatedCategory)
                }
            } else {
                // Si sigue en el mismo grupo, simplemente actualizar
                const groupIndex = categoryGroups.value.findIndex(g => g.id === newGroupId)
                if (groupIndex !== -1) {
                    const catIndex = categoryGroups.value[groupIndex].categories.findIndex(c => c.id === categoryId)
                    if (catIndex !== -1) {
                        categoryGroups.value[groupIndex].categories[catIndex] = {
                            ...categoryGroups.value[groupIndex].categories[catIndex],
                            ...updatedCategory
                        }
                    }
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Actualizada',
                detail: `La categoría "${categoryData.name}" se actualizó exitosamente`,
                life: 3000
            })

            return updatedCategory

        } catch (error) {
            console.error('💥 Error actualizando categoría:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error actualizando la categoría',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función para eliminar una categoría
    const deleteCategory = async (categoryId, { toast }) => {
        loading.value = true

        try {
            // Obtener el usuario actual
            const { data: { user }, error: userError } = await supabase.auth.getUser()

            if (userError || !user) {
                throw new Error('Usuario no autenticado')
            }

            // Eliminar de la base de datos
            const { error } = await supabase
                .from('categories')
                .delete()
                .eq('id', categoryId)
                .eq('user_id', user.id) // Solo el dueño puede eliminar

            if (error) {
                console.error('💥 Error eliminando categoría:', error)
                throw error
            }

            // Actualizar los estados locales
            // 1. Buscar la categoría para saber a qué grupo pertenece
            const categoryToDelete = categories.value.find(c => c.id === categoryId)
            const groupId = categoryToDelete?.group_id
            
            // 2. Quitar de la lista plana de categorías
            categories.value = categories.value.filter(c => c.id !== categoryId)
            
            // 3. Quitar de la estructura anidada de grupos
            if (groupId) {
                const groupIndex = categoryGroups.value.findIndex(g => g.id === groupId)
                if (groupIndex !== -1) {
                    categoryGroups.value[groupIndex].categories = 
                        categoryGroups.value[groupIndex].categories.filter(c => c.id !== categoryId)
                }
            }

            // Mostrar mensaje de éxito
            toast.add({
                severity: 'success',
                summary: 'Categoría Eliminada',
                detail: `La categoría ha sido eliminada exitosamente`,
                life: 3000
            })

            return true

        } catch (error) {
            console.error('💥 Error eliminando categoría:', error)

            toast.add({
                severity: 'error',
                summary: 'Error',
                detail: error.message || 'Error eliminando la categoría',
                life: 5000
            })

            throw error

        } finally {
            loading.value = false
        }
    }

    // NUEVA: Función genérica para guardar (crear o actualizar)
    const saveCategory = async (categoryData, isEdit = false, { toast }) => {
        if (isEdit && categoryData.id) {
            return await updateCategory(categoryData.id, categoryData, { toast })
        } else {
            return await createCategory(categoryData, { toast })
        }
    }

    return {
        // Estados
        categories,
        categoryGroups,
        loading,

        // Funciones existentes
        fetchCategories,
        fetchCategoryGroupsWithCategories,
        
        // NUEVAS funciones
        createCategory,
        updateCategory,
        deleteCategory,
        saveCategory
    }
})